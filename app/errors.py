from fastapi import HTTPException


def error_create_plant(error):
    return HTTPException(
        status_code=500,
        detail=f"Error al crear el planta: {str(error)}"
    )
def error_get_plants(error):
    return HTTPException(
        status_code=500,
        detail=f"Error al traer lista de plantas: {str(error)}"
    )
def error_plant_code_not_found(error):
    return HTTPException(
        status_code=404,
        detail=f"Planta no encontrada: {str(error)}"
    )
def error_season_not_found(error):
    return HTTPException(
        status_code=404,
        detail=f"Season no encontrada: {str(error)}"
    )
def error_create_season(error):
    return HTTPException(
        status_code=500,
        detail=f"Error al crear season: {str(error)}"
    )
def error_get_all_seasons(error):
    return HTTPException(
        status_code=500,
        detail=f"Error al traer seasons: {str(error)}"
    )
def error_watering_today(error):
    return HTTPException(
        status_code=500,
        detail=f"Error al traer las plantas de riego de hoy: {str(error)}"
    )
def error_get_item_plant(error):
    return HTTPException(
        status_code=500,
        detail=f"Error al traer planta: {str(error)}"
    )
def error_create_watering(error):
    return HTTPException(
        status_code=500,
        detail=f"Error al crear el riego: {str(error)}"
    )