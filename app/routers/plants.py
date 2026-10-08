from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from ..database import get_db
from ..models import Plant
from ..schemas import PlantCreate, PlantResponse
from ..errors import error_create_plant, error_get_plants, error_get_item_plant, error_plant_code_not_found

from datetime import datetime, timedelta, date



router = APIRouter(
    prefix="/plants",
    tags=["Plants"]
)

@router.post(
    "/", response_model=PlantResponse 
)
def create_plant(
    plant: PlantCreate,
    db: Session = Depends(get_db)
):
    try:
        existing_plant = (
            db.query(Plant)
            .filter(Plant.code == plant.code)
            .first()
        )
        if existing_plant:
            raise HTTPException(
                status_code=400,
                detail="El codigo de la planta ya eiste"
            )
        
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
            age=age,
            days=days,
            active=plant.active
        )
        db.add(new_plant)
        db.commit()
        db.refresh(new_plant)

        return new_plant
    except Exception as e:
        db.rollback()
        raise error_create_plant(e)

@router.get(
    "/",
    response_model=list[PlantResponse]
)
def get_plants(
    db: Session = Depends(get_db)
):
    try:
        plants = db.query(Plant).all()
        result = []
        for plant in plants:
            years,  days = calculate_age(plant.age)
            result.append({
                "code": plant.code,
                "name": plant.name,
                "age_years": years,
                "age_days": days,
                "photo": plant.photo,
                "death_cause": plant.death_cause,
                "date": plant.date,
                "active": plant.active
            })

        return result
    except Exception as e:
        db.rollback()
        raise error_get_plants(e)

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
            raise error_plant_code_not_found
    
        years,  days = calculate_age(plant.age)
        plant = ({
                "code": plant.code,
                "name": plant.name,
                "age_years": years,
                "age_days": days,
                "active": plant.active
            })

        return plant
    except Exception as e:
        db.rollback()
        raise error_get_item_plant