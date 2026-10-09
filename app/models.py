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
    date = Column(Date)
    next_watering_day = Column(Date, nullable=True)
    active = Column(Boolean, default=True)
    age = Column(Integer)
    days = Column(Integer)


class WateringSeason(Base):
    __tablename__ = "season"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String(100), nullable=False)
    begin_month = Column(Integer, nullable=False)
    begin_day = Column(Integer, nullable=False)
    end_month = Column(Integer, nullable=False)
    end_day = Column(Integer, nullable=False)

class Watering(Base):
    __tablename__ = "watering"

    id = Column(Integer, primary_key=True, index=True)
    season_id = Column(Integer, ForeignKey("season.id"), nullable=False)
    plant_id = Column(Integer, ForeignKey("plant.id"), nullable=False)
    days_to_water = Column(Integer)
    schedule_watering = Column(DateTime)
    watering_date = Column(DateTime, server_default=func.now(), nullable=False)
    notes = Column(Text)
    food = Column(Boolean, default=False)
    pruning = Column(Boolean, default=False)


