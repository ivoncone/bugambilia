from fastapi import FastAPI

from .database import engine, Base
from .routers import plants, seasons, watering
from . import models


Base.metadata.create_all(bind=engine)


app = FastAPI(
    title="Bugambilia API",
    description="Sistema inteligente para cuidado de plantas",
    version="1.0.0"
)

app.include_router(plants.router)
app.include_router(seasons.router)
app.include_router(plants.router)
app.include_router(watering.router)

@app.get("/")
def root():
    return {
        "mensaje": "Bugambilia funcionando 🌱"
    }