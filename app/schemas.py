from datetime import date, datetime
from typing import Optional

from pydantic import BaseModel, ConfigDict

class PlantCreate(BaseModel):
    code: str
    name: str
    photo: Optional[str] = None
    death_cause: Optional[str] = None
    age: Optional[int] = None
    active: bool = True
    food: bool = False
    pruning: bool = False

class PlantResponse(BaseModel):
    id: int
    code: str
    name: str
    photo: Optional[str]
    death_cause: Optional[str]
    date: Optional[date]
    active: bool
    age: Optional[int]
    food: bool
    pruning: bool

    model_config = ConfigDict(from_attribute=True)
    