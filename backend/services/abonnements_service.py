from sqlalchemy.orm import Session

from backend import models, schemas


def create_abonnement(db: Session, abonnement: schemas.AbonnementCreate):
    db_abonnement = models.Abonnement(**abonnement.model_dump())
    db.add(db_abonnement)
    db.commit()
    db.refresh(db_abonnement)
    return db_abonnement


def get_abonnements(db: Session):
    return db.query(models.Abonnement).all()


def get_abonnement_by_id(db: Session, abonnement_id: int):
    return db.query(models.Abonnement).filter(models.Abonnement.id == abonnement_id).first()


def update_abonnement(db: Session, abonnement_id: int, abonnement_update: schemas.AbonnementUpdate):
    db_abonnement = get_abonnement_by_id(db, abonnement_id)
    if not db_abonnement:
        return None

    for key, value in abonnement_update.model_dump(exclude_unset=True).items():
        setattr(db_abonnement, key, value)

    db.commit()
    db.refresh(db_abonnement)
    return db_abonnement


def delete_abonnement(db: Session, abonnement_id: int):
    db_abonnement = get_abonnement_by_id(db, abonnement_id)
    if not db_abonnement:
        return False

    db.delete(db_abonnement)
    db.commit()
    return True
