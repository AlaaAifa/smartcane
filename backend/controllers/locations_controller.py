from typing import List

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from backend import schemas
from backend.database import get_db
from backend.services import locations_service

router = APIRouter(prefix="/locations", tags=["Locations"])


@router.post("", response_model=schemas.Location, status_code=status.HTTP_201_CREATED)
def create_location(location: schemas.LocationCreate, db: Session = Depends(get_db)):
    return locations_service.create_location(db, location)


@router.get("", response_model=List[schemas.Location])
def get_locations(db: Session = Depends(get_db)):
    return locations_service.get_locations(db)


@router.get("/{location_id}", response_model=schemas.Location)
def get_location(location_id: int, db: Session = Depends(get_db)):
    db_location = locations_service.get_location_by_id(db, location_id)
    if not db_location:
        raise HTTPException(status_code=404, detail="Location non trouvee")
    return db_location


@router.put("/{location_id}", response_model=schemas.Location)
def update_location(location_id: int, location_update: schemas.LocationUpdate, db: Session = Depends(get_db)):
    db_location = locations_service.update_location(db, location_id, location_update)
    if not db_location:
        raise HTTPException(status_code=404, detail="Location non trouvee")
    return db_location


@router.delete("/{location_id}")
def delete_location(location_id: int, db: Session = Depends(get_db)):
    deleted = locations_service.delete_location(db, location_id)
    if not deleted:
        raise HTTPException(status_code=404, detail="Location non trouvee")
    return {"message": f"Location {location_id} supprimee avec succes"}
