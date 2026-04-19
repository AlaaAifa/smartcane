from typing import List

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from backend import schemas
from backend.database import get_db
from backend.services import abonnements_service

router = APIRouter(prefix="/abonnements", tags=["Abonnements"])


@router.post("", response_model=schemas.Abonnement, status_code=status.HTTP_201_CREATED)
def create_abonnement(abonnement: schemas.AbonnementCreate, db: Session = Depends(get_db)):
    return abonnements_service.create_abonnement(db, abonnement)


@router.get("", response_model=List[schemas.Abonnement])
def get_abonnements(db: Session = Depends(get_db)):
    return abonnements_service.get_abonnements(db)


@router.get("/{abonnement_id}", response_model=schemas.Abonnement)
def get_abonnement(abonnement_id: int, db: Session = Depends(get_db)):
    db_abonnement = abonnements_service.get_abonnement_by_id(db, abonnement_id)
    if not db_abonnement:
        raise HTTPException(status_code=404, detail="Abonnement non trouve")
    return db_abonnement


@router.put("/{abonnement_id}", response_model=schemas.Abonnement)
def update_abonnement(
    abonnement_id: int,
    abonnement_update: schemas.AbonnementUpdate,
    db: Session = Depends(get_db),
):
    db_abonnement = abonnements_service.update_abonnement(db, abonnement_id, abonnement_update)
    if not db_abonnement:
        raise HTTPException(status_code=404, detail="Abonnement non trouve")
    return db_abonnement


@router.delete("/{abonnement_id}")
def delete_abonnement(abonnement_id: int, db: Session = Depends(get_db)):
    deleted = abonnements_service.delete_abonnement(db, abonnement_id)
    if not deleted:
        raise HTTPException(status_code=404, detail="Abonnement non trouve")
    return {"message": f"Abonnement {abonnement_id} supprime avec succes"}
