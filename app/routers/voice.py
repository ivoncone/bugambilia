from fastapi import APIRouter, HTTPException
from sqlalchemy.orm import Session
from datetime import date

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
        date_text = parts[-1]
        name = " ".join(items[1:-1])
        plant_date = datetime.strptime(
            date_text,
            "%Y-%M-%"
        ).date()

        # Por ahora solamente comprobamos que llegue
        return {
            "code": code,
            "name": name,
            "date": plant_date,
            "active": True
        }
    except Exception as e:
        raise voice_error(e)