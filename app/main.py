from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from .database import engine, Base
from .routers import plants, seasons, watering, voice
from . import models


Base.metadata.create_all(bind=engine)


app = FastAPI(
    title="Bugambilia API",
    description="Sistema inteligente para cuidado de plantas",
    version="1.0.0"
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(plants.router)
app.include_router(seasons.router)
app.include_router(plants.router)
app.include_router(watering.router)
app.include_router(voice.router)

@app.get("/")
def root():
    return {
        "mensaje": "Bugambilia funcionando 🌱"
    }