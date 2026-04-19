from typing import Union

from sqlalchemy.orm import Session

from backend import models, schemas


def create_user(db: Session, user: Union[schemas.ClientCreate, schemas.StaffCreate]):
    existing_cin = db.query(models.Utilisateur).filter(models.Utilisateur.cin == user.cin).first()
    if existing_cin:
        return None, "Un utilisateur avec ce CIN existe deja"

    existing_email = db.query(models.Utilisateur).filter(models.Utilisateur.email == user.email).first()
    if existing_email:
        return None, "Cet e-mail est deja utilise"

    if user.role == "client":
        db_user = models.Client(**user.model_dump())
    elif user.role == "staff":
        db_user = models.Staff(**user.model_dump())
    else:
        return None, "Role invalide"

    db.add(db_user)
    db.commit()
    db.refresh(db_user)
    return db_user, None


def get_users(db: Session):
    return db.query(models.Utilisateur).all()


def get_user_by_cin(db: Session, cin: str):
    return db.query(models.Utilisateur).filter(models.Utilisateur.cin == cin).first()


def update_user(db: Session, cin: str, user_update: Union[schemas.ClientUpdate, schemas.StaffUpdate]):
    db_user = get_user_by_cin(db, cin)
    if not db_user:
        return None, "Utilisateur non trouve"

    if user_update.email and user_update.email != db_user.email:
        existing_email = db.query(models.Utilisateur).filter(models.Utilisateur.email == user_update.email).first()
        if existing_email:
            return None, "Cet e-mail est deja utilise"

    for key, value in user_update.model_dump(exclude_unset=True).items():
        setattr(db_user, key, value)

    db.commit()
    db.refresh(db_user)
    return db_user, None


def delete_user(db: Session, cin: str):
    db_user = get_user_by_cin(db, cin)
    if not db_user:
        return False

    db.delete(db_user)
    db.commit()
    return True
