from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from ..database import get_db
from ..models import Plant
from ..schemas import PlantCreate, PlantResponse

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
    
    new_plant = Plant(
        code=plant.code,
        name=plant.name,
        photo=plant.photo,
        death_cause=plant.death_cause,
        date=plant.date,
        age=plant.age,
        active=plant.active
    )
    db.add(new_plant)
    db.commit()
    db.refresh(new_plant)

    return new_plant

@router.get(
    "/",
    response_model=list[PlantResponse]
)
def get_plants(
    db: Session = Depends(get_db)
):

    plants = db.query(Plant).all()

    return plants

@router.get(
    "/{code}",
    response_model=PlantResponse
)
def get_plant(
    code: str,
    db: Session = Depends(get_db)
):

    plant = (
        db.query(Plant)
        .filter(Plant.code == code)
        .first()
    )

    if not plant:
        raise HTTPException(
            status_code=404,
            detail="Planta no encontrada"
        )

    return plant