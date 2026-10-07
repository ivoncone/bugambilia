bugambilia/
│
├── app/
│   ├── main.py
│   ├── database.py
│   │
│   ├── models/
│   │   ├── planta.py
│   │   ├── temporada.py
│   │   └── riego.py
│   │
│   ├── schemas/
│   │   ├── planta.py
│   │   ├── temporada.py
│   │   └── riego.py
│   │
│   ├── routers/
│   │   ├── plantas.py
│   │   ├── temporadas.py
│   │   └── riegos.py
│   │
│   └── services/
│       └── riego.py
│
├── uploads/
│   └── plantas/
│
├── requirements.txt
└── .env

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