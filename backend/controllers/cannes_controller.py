from typing import List

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from backend import schemas
from backend.database import get_db
from backend.services import cannes_service

router = APIRouter(prefix="/cannes", tags=["Cannes"])


@router.post("", response_model=schemas.Canne, status_code=status.HTTP_201_CREATED)
def create_canne(canne: schemas.CanneCreate, db: Session = Depends(get_db)):
    db_canne, error = cannes_service.create_canne(db, canne)
    if error:
        raise HTTPException(status_code=400, detail=error)
    return db_canne


@router.get("", response_model=List[schemas.Canne])
def get_cannes(db: Session = Depends(get_db)):
    return cannes_service.get_cannes(db)


@router.get("/{sim_de_la_canne}", response_model=schemas.Canne)
def get_canne(sim_de_la_canne: str, db: Session = Depends(get_db)):
    db_canne = cannes_service.get_canne_by_sim(db, sim_de_la_canne)
    if not db_canne:
        raise HTTPException(status_code=404, detail="Canne non trouvee")
    return db_canne


@router.put("/{sim_de_la_canne}", response_model=schemas.Canne)
def update_canne(sim_de_la_canne: str, canne_update: schemas.CanneUpdate, db: Session = Depends(get_db)):
    db_canne, error = cannes_service.update_canne(db, sim_de_la_canne, canne_update)
    if error:
        raise HTTPException(status_code=404, detail=error)
    return db_canne


@router.delete("/{sim_de_la_canne}")
def delete_canne(sim_de_la_canne: str, db: Session = Depends(get_db)):
    deleted = cannes_service.delete_canne(db, sim_de_la_canne)
    if not deleted:
        raise HTTPException(status_code=404, detail="Canne non trouvee")
    return {"message": f"Canne {sim_de_la_canne} supprimee avec succes"}
