bugambilia/
app
.
├── database.py
├── errors.py
├── main.py
├── models.py
├── routers
│   ├── plants.py
│   ├── seasons.py
│   ├── voice.py
│   └── watering.py
└── schemas.py

POST   /plants
GET    /plants
GET    /plants/{codigo}
PUT    /plants/{plant_id}
PUT   /plants/{plant_id}/photo
PUT   /plants/frequency/{plant_id}
DELETE /plants/{plant_id}


POST   /seasons
GET    /sesons
GET    /sesons/{season_id}

POST   /watering
GET    /watering
GET    /watering/today

POST    /VOICE
