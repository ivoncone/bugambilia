from datetime import datetime, timedelta

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from app.database import get_db
from app.models.watering import Watering
from app.models.plant import Plant
from app.schemas.watering import WateringCreate, WateringResponse


router = APIRouter(
    prefix="/watering",
    tags=["Watering"]
)


@router.post("/", response_model=WateringResponse)
def create_watering(
    data: WateringCreate,
    db: Session = Depends(get_db)
):
    # Buscar planta
    plant = db.query(Plant).filter(
        Plant.id == data.plant_id
    ).first()

    if not plant:
        raise HTTPException(
            status_code=404,
            detail="La planta no existe"
        )

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

        # Si tu modelo Plant tiene is_dead
        if hasattr(plant, "is_dead"):
            plant.is_dead = True

    # Actualizar edad de la planta
    # Ajusta esta lógica según cómo tengas almacenada la edad
    if hasattr(plant, "age"):
        plant.age = plant.age + 1

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