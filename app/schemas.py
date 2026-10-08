from datetime import date, datetime
from typing import Optional

from pydantic import BaseModel, ConfigDict, computed_field

class PlantCreate(BaseModel):
    code: str
    name: str
    photo: Optional[str] = None
    date: Optional[date]
    death_cause: Optional[str] = None
    age: Optional[int] = None
    days: Optional[int] = None
    active: bool = True


class PlantResponse(BaseModel):
    id: int
    code: str
    name: str
    age:  Optional[int]
    days:  Optional[int]
    photo: Optional[str]
    death_cause: Optional[str]
    date: Optional[date]
    active: bool

    model_config = ConfigDict(from_attributes=True)

class SeasonCreate(BaseModel):
    name: str
    begin_month: int
    end_month: int
    begin_day: int
    end_day: int

class SeasonResponse(BaseModel):
    id: int
    name: str
    begin_month: int
    end_month: int
    begin_day: int
    end_day: int

    class Config:
        from_attributes = True

class WateringCreate(BaseModel):
    plant_id: int
    notes: Optional[str]
    food: bool
    pruning: bool


class WateringResponse(BaseModel):
    id: int
    plant_id: int
    watering_date: datetime
    notes: Optional[str] = None
    age: Optional[int]

    class Config:
        from_attributes = True

class WateringBase(BaseModel):
    season_id: int
    plant_id: int
    days_to_water: Optional[int] = None
    watering_date: Optional[datetime] = None
    notes: Optional[str] = None
    food: bool = False
    pruning: bool = False

    # Datos de la planta
    is_dead: bool = False
    death_cause: Optional[str] = None


class WateringCreate(WateringBase):
    pass


class WateringResponse(BaseModel):
    id: int
    season_id: int
    plant_id: int
    days_to_water: Optional[int]
    schedule_watering: Optional[datetime]
    watering_date: datetime
    notes: Optional[str]
    food: bool
    pruning: bool

    class Config:
        from_attributes = True

        
    