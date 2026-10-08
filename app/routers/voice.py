from fastapi import APIRouter, HTTPException, Depends
from sqlalchemy.orm import Session
from datetime import date, datetime
import traceback

from ..database import get_db
from ..routers.plants import create_plant
from ..errors import voice_error
from ..schemas import (
    PlantVoiceRequest,
    PlantVoiceResponse,
    PlantCreate
)

router = APIRouter(
    prefix="/voice",
    tags=["Voice"]
)


@router.post(
    "/",
    response_model=PlantVoiceResponse
)
def plant_from_voice(data: PlantVoiceRequest, db: Session = Depends(get_db)):
    try:
        text = data.text.strip()

        print("Texto recibido:", text)

        items = text.split()
        code = items[0]
        date_text = " ".join(items[-3:])
        name = " ".join(items[1:-3])
        plant_date = datetime.strptime(
            date_text,
            "%Y %m %d"
        ).date()

        plant = PlantCreate(
            code=code,
            name=name,
            photo=None,
            death_cause=None,
            date=plant_date,
            active=True
        )
        new_plant = create_plant(
            plant=plant,
            db=db
        )
        db.add(new_plant) 
        db.commit() 
        db.refresh(new_plant) 

        return {
            "code": code,
            "name": name,
            "date": plant_date,
            "active": True
        }
    except Exception as e:
        print("========== ERROR ==========") 
        print("Tipo:", type(e).__name__) 
        print("Mensaje:", str(e)) 
        traceback.print_exc() 
        print("===========================") 
        raise
        #raise voice_error(e)