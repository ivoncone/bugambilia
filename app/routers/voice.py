from fastapi import APIRouter, HTTPException
from sqlalchemy.orm import Session
from datetime import date, datetime
import traceback

from ..errors import voice_error
from ..schemas import (
    PlantVoiceRequest,
    PlantVoiceResponse
)

router = APIRouter(
    prefix="/voice",
    tags=["Voice"]
)


@router.post(
    "/",
    response_model=PlantVoiceResponse
)
def plant_from_voice(data: PlantVoiceRequest):
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

        # Por ahora solamente comprobamos que llegue
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