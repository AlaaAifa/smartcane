from sqlalchemy.orm import Session

from backend import models, schemas


def create_location(db: Session, location: schemas.LocationCreate):
    # 1. Vérifier si la canne existe, sinon la créer
    db_canne = db.query(models.Canne).filter(models.Canne.sim_de_la_canne == location.sim_de_la_canne).first()
    if not db_canne:
        db_canne = models.Canne(
            sim_de_la_canne=location.sim_de_la_canne,
            statut="louee",
            version="Smart Pro V2"  # Version par défaut pour les auto-créations
        )
        db.add(db_canne)
        db.flush() # Assure que la canne est enregistrée avant de créer la location
    else:
        # Mettre à jour le statut de la canne existante
        db_canne.statut = "louee"

    # 2. Créer la location
    db_location = models.Location(**location.model_dump())
    db.add(db_location)
    db.commit()
    db.refresh(db_location)
    return db_location


def get_locations(db: Session):
    return db.query(models.Location).all()


def get_location_by_id(db: Session, location_id: int):
    return db.query(models.Location).filter(models.Location.id == location_id).first()


def update_location(db: Session, location_id: int, location_update: schemas.LocationUpdate):
    db_location = get_location_by_id(db, location_id)
    if not db_location:
        return None

    for key, value in location_update.model_dump(exclude_unset=True).items():
        setattr(db_location, key, value)

    db.commit()
    db.refresh(db_location)
    return db_location


def delete_location(db: Session, location_id: int):
    db_location = get_location_by_id(db, location_id)
    if not db_location:
        return False

    db.delete(db_location)
    db.commit()
    return True
