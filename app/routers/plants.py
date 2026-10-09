from fastapi import APIRouter, Depends, HTTPException, UploadFile, File
from sqlalchemy.orm import Session

from datetime import datetime, timedelta, date

import cloudinary
import cloudinary.uploader

from ..database import get_db
from ..models import Plant
from ..schemas import PlantCreate, PlantResponse, PlantWateringUpdate
from ..errors import error_create_plant, error_get_plants, error_delete_plant, error_update_plant, error_update_plant_photo, error_get_item_plant, error_plant_code_not_found, plant_exists
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


@router.put("/{plant_id}", response_model=PlantResponse)
def update_plant_watering(
    plant_id: int,
    plant_data: PlantWateringUpdate,
    db: Session = Depends(get_db)
):
    try:
        plant = db.query(Plant).filter(
            Plant.id == plant_id
        ).first()

        if plant is None:
            raise error_plant_code_not_found()

        plant.next_watering_day = plant_data.next_watering_day

        db.commit()
        db.refresh(plant)

        return plant

    except HTTPException:
        raise
    except Exception as e:
        db.rollback()
        raise error_update_plant(e)


@router.delete("/{plant_id}")
def delete_plant(plant_id: int, db:Session = Depends(get_db)):
    try:
        plant = db.query(Plant).filter(
            Plant.id == plant_id
        ).first()
        if plant is None:
            raise error_plant_code_not_found()
        db.delete(plant)
        db.commit()
        return {
            "message": "Planta eliminada correctamente.", 
            "plant_id": plant_id
        }
    except HTTPException:
        raise
    except Exception as e:
        print(f"Error{e}")
        raise error_delete_plant(e)
