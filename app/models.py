from sqlalchemy import(
    Column,
    Integer,
    String, 
    Text,
    Boolean,
    Date,
    DateTime,
    Numeric, 
    ForeignKey
)

from sqlalchemy.sql import func
from sqlalchemy.orm import relationship

from .database import Base

class Plant(Base):
    __tablename__ = "plant"

    id = Column(Integer, primary_key=True, index=True)
    code = Column(String(20), unique=True, nullable=False, index=True)
    name = Column(String(100), nullable=False)
    photo = Column(String(500))
    death_cause = Column(Text)
    date = Column(Date, server_default=func.current_date())
    active = Column(Boolean, default=True)
    age = Column(Integer)
    season = relationship("WateringSeason", back_populates="plant")
    watering = relationship("Watering", back_populates="plant", cascade="all, delete-orphan")
    food = Column(Boolean, default=False)
    pruning = Column(Boolean, default=False)

class WateringSeason(Base):
    __tablename__ = "season"

    id = Column(Integer, primary_key=True, index=True)
    plant_id = Column(Integer, ForeignKey("plant.id"), nullable=False)
    name = Column(String(100), nullable=False)
    begin_date = Column(Date, nullable=False)
    end_date = Column(Date, nullable=False)
    plant = relationship("Plant", back_populates="season")

class Watering(Base):
    __tablename__ = "watering"

    id = Column(Integer, primary_key=True, index=True)
    plant_id = Column(Integer, ForeignKey("plant.id"), nullable=False)
    watering_date = Column(DateTime, server_default=func.now(), nullable=False)
    notes = Column(Text)
    plant = relationship("Plant", back_populates="watering")
