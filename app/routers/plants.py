from fastapi import APIRouter, Depends, HTTPException, UploadFile, File
from sqlalchemy.orm import Session

from datetime import datetime, timedelta, date

import cloudinary
import cloudinary.uploader

from ..database import get_db
from ..models import Plant
from ..schemas import PlantCreate, PlantResponse
from ..errors import error_create_plant, error_get_plants, error_update_plant_photo, error_get_item_plant, error_plant_code_not_found, plant_exists
from ..core.cloudinary_config import cloudinary



router = APIRouter(
    prefix="/plants",
    tags=["Plants"]
)

@router.post(
    "/", response_model=PlantResponse 
)
def create_plant(plant: PlantCreate, db: Session = Depends(get_db)):
    try:
        existing_plant = (
            db.query(Plant)
            .filter(Plant.code == plant.code)
            .first()
        )
        if existing_plant:
            raise plant_exists()
        
        years = 0
        days = 0
        if plant.date:
            today = date.today()
            years = today.year - plant.date.year
            if (today.month, today.day) < (plant.date.month, plant.date.day):
                years -= 1
            annniversary = plant.date.replace(
                year=plant.date.year + years
            )
            days = (today - annniversary).days
        new_plant = Plant(
            code=plant.code,
            name=plant.name,
            photo=plant.photo,
            death_cause=plant.death_cause,
            date=plant.date,
            age=years,
            days=days,
            active=plant.active
        )
        db.add(new_plant)
        db.commit()
        db.refresh(new_plant)

        return new_plant
    except HTTPException:
        raise

    except Exception as e:
        db.rollback()
        raise error_create_plant(e)

#Obtener todas las plantas
@router.get(
    "/",
    response_model=list[PlantResponse]
)
def get_plants(db: Session = Depends(get_db)):
    try:
        plants = db.query(Plant).all()

        return plants
    except Exception as e:
        db.rollback()
        raise error_get_plants(e)

#Obtener una planta por codigo
@router.get(
    "/{code}",
    response_model=PlantResponse
)
def get_plant(
    code: str,
    db: Session = Depends(get_db)
):
    try:
        plant = (
            db.query(Plant)
            .filter(Plant.code == code)
            .first()
        )

        if not plant:
            raise error_plant_code_not_found()
        return plant
    except HTTPException:
        raise
    except Exception as e:
        db.rollback()
        raise error_get_item_plant

@router.put("/{plant_id}/photo")
def update_plant_photo(
    plant_id: int,
    photo: UploadFile = File(...),
    db: Session = Depends(get_db)
):
    try:

        # Buscar planta
        plant = (
            db.query(Plant)
            .filter(Plant.id == plant_id)
            .first()
        )

        if not plant:
            raise error_plant_code_not_found()
        
        print("Nombre del archivo:", photo.filename)
        print("Content-Type:", photo.content_type)
        
        if photo.content_type not in (
            "image/jpeg",
            "image/png",
            "image/webp"
        ):
            raise HTTPException(
                status_code=400,
                detail="Solo se permiten imágenes JPG, PNG o WEBP"
            )


                # Subir la imagen a Cloudinary
        resultado = cloudinary.uploader.upload(
            photo.file,
            folder="bugambilia/plantas",
            resource_type="image"
        )

        # Guardar la URL segura en la base de datos
        plant.photo = resultado["secure_url"]

        db.commit()
        db.refresh(plant)

        return {
            "message": "Foto actualizada correctamente",
            "plant_id": plant.id,
            "photo": plant.photo
        }


    except HTTPException:
        db.rollback()
        raise

    except Exception as e:
        db.rollback()
        raise error_update_plant_photo(e)
    
    finally:
        photo.file.close()