from typing import List, Union

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from backend import schemas
from backend.database import get_db
from backend.services import utilisateurs_service

router = APIRouter(prefix="/users", tags=["Users"])


@router.post("", response_model=Union[schemas.Client, schemas.Staff, schemas.Utilisateur], status_code=status.HTTP_201_CREATED)
def create_user(user: Union[schemas.ClientCreate, schemas.StaffCreate], db: Session = Depends(get_db)):
    db_user, error = utilisateurs_service.create_user(db, user)
    if error:
        raise HTTPException(status_code=400, detail=error)
    return db_user


@router.get("", response_model=List[Union[schemas.Client, schemas.Staff, schemas.Utilisateur]])
def get_users(db: Session = Depends(get_db)):
    return utilisateurs_service.get_users(db)


@router.get("/{cin}", response_model=Union[schemas.Client, schemas.Staff, schemas.Utilisateur])
def get_user(cin: str, db: Session = Depends(get_db)):
    db_user = utilisateurs_service.get_user_by_cin(db, cin)
    if not db_user:
        raise HTTPException(status_code=404, detail="Utilisateur non trouve")
    return db_user


@router.put("/{cin}", response_model=Union[schemas.Client, schemas.Staff, schemas.Utilisateur])
def update_user(cin: str, user_update: Union[schemas.ClientUpdate, schemas.StaffUpdate, schemas.UtilisateurUpdate], db: Session = Depends(get_db)):
    db_user, error = utilisateurs_service.update_user(db, cin, user_update)
    if error == "Utilisateur non trouve":
        raise HTTPException(status_code=404, detail=error)
    if error:
        raise HTTPException(status_code=400, detail=error)
    return db_user


@router.delete("/{cin}")
def delete_user(cin: str, db: Session = Depends(get_db)):
    deleted = utilisateurs_service.delete_user(db, cin)
    if not deleted:
        raise HTTPException(status_code=404, detail="Utilisateur non trouve")
    return {"message": f"Utilisateur {cin} supprime avec succes"}
