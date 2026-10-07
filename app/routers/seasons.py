from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from app.database import get_db
from app.models import WateringSeason, Plant
from ..schemas import SeasonCreate, SeasonResponse



router = APIRouter(
    prefix="/seasons",
    tags=["Watering Seasons"]
)


@router.post("/", response_model=SeasonResponse)
def create_season(
    season: SeasonCreate,
    db: Session = Depends(get_db)
):

    new_season = WateringSeason(
        name=season.name,
        begin_month=season.begin_month,
        end_month=season.end_month,
        begin_day=season.begin_day,
        end_day=season.end_day
    )

    db.add(new_season)
    db.commit()
    db.refresh(new_season)

    return new_season

@router.get("/", response_model=list[SeasonResponse])
def get_seasons(
    db: Session = Depends(get_db)
):
    return db.query(WateringSeason).all()

@router.get("/{season_id}", response_model=SeasonResponse)
def get_season(
    season_id: int,
    db: Session = Depends(get_db)
):
    season = db.query(WateringSeason).filter(
        WateringSeason.id == season_id
    ).first()

    if not season:
        raise HTTPException(
            status_code=404,
            detail="Temporada no encontrada"
        )

    return season