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

POST   /plantas
GET    /plantas
GET    /plantas/{codigo}
PUT    /plantas/{codigo}
DELETE /plantas/{codigo}

POST   /plantas/{codigo}/foto

POST   /plantas/{codigo}/temporadas
GET    /plantas/{codigo}/temporadas

POST   /plantas/{codigo}/riegos
GET    /plantas/{codigo}/riegos

GET    /plantas/{codigo}/proximo-riego
GET    /riegos/hoy