from datetime import datetime, timedelta, date, time

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from app.database import get_db
from ..models import Plant, Watering
from ..schemas import WateringCreate, WateringResponse
from ..errors import error_create_watering, error_plant_code_not_found, error_watering_today, error_inactive_plant


router = APIRouter(
    prefix="/watering",
    tags=["Watering"]
)

@router.post("/", response_model=WateringResponse)
def create_watering(data: WateringCreate, db: Session = Depends(get_db)):
    try:
           # Buscar planta
        plant = db.query(Plant).filter(
            Plant.id == data.plant_id
        ).first()

        if not plant:
            raise error_plant_code_not_found
        #Si la planta ya ha muerte detener la función
        if not plant.active:
            raise error_inactive_plant()

        # Fecha del riego
        watering_date = data.watering_date or datetime.now()

        # Calcular próximo riego
        schedule_watering = None

        if data.days_to_water is not None:
            schedule_watering = (
                watering_date +
                timedelta(days=data.days_to_water)
            )

        # Si la planta murió, actualizar datos de la planta
        if data.is_dead:
            plant.death_cause = data.death_cause
            plant.active = False

        # Actualizar edad de la planta
        # Ajusta esta lógica según cómo tengas almacenada la edad
        if plant.date:
            today = date.today()
            years = today.year - plant.date.year
            plant.years = years
            plant.next_watering_day = watering_date
            if (today.month, today.day) < (plant.date.month, plant.date.day):
                years -= 1
            annniversary = plant.date.replace(
                year=plant.date.year + years
            )
            plant.days = (today - annniversary).days

        # Crear riego
        watering = Watering(
            season_id=data.season_id,
            plant_id=data.plant_id,
            days_to_water=data.days_to_water,
            watering_date=watering_date,
            schedule_watering=schedule_watering,
            notes=data.notes,
            food=data.food,
            pruning=data.pruning,
        )

        db.add(watering)
        db.commit()
        db.refresh(watering)

        return watering
    except HTTPException:
        raise
    except Exception as e:
        db.rollback()
        raise error_create_watering(e)

@router.get("/today")
def get_watering_today(db: Session = Depends(get_db)):
    try:
        today = datetime.now().date()

        start_of_day = datetime.combine(today, time.min)
        start_of_next_day = start_of_day + timedelta(days=1)

        plants = (
            db.query(Plant)
            .filter(
                Plant.next_watering_day >= start_of_day,
                Plant.next_watering_day < start_of_next_day
            )
            .all()
        )
        if not plants:
            return {
                "message": "No hay riegos programados para hoy"
            }

        return plants
    except Exception as e:
        db.rollback()
        raise error_watering_today(e)