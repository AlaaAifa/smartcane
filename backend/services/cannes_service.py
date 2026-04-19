from sqlalchemy.orm import Session

from backend import models, schemas


def create_canne(db: Session, canne: schemas.CanneCreate):
    existing_canne = get_canne_by_sim(db, canne.sim_de_la_canne)
    if existing_canne:
        return None, "Une canne avec cette SIM existe deja"

    db_canne = models.Canne(**canne.model_dump())
    db.add(db_canne)
    db.commit()
    db.refresh(db_canne)
    return db_canne, None


def get_cannes(db: Session):
    return db.query(models.Canne).all()


def get_canne_by_sim(db: Session, sim_de_la_canne: str):
    return db.query(models.Canne).filter(models.Canne.sim_de_la_canne == sim_de_la_canne).first()


def update_canne(db: Session, sim_de_la_canne: str, canne_update: schemas.CanneUpdate):
    db_canne = get_canne_by_sim(db, sim_de_la_canne)
    if not db_canne:
        return None, "Canne non trouvee"

    for key, value in canne_update.model_dump(exclude_unset=True).items():
        setattr(db_canne, key, value)

    db.commit()
    db.refresh(db_canne)
    return db_canne, None


def delete_canne(db: Session, sim_de_la_canne: str):
    db_canne = get_canne_by_sim(db, sim_de_la_canne)
    if not db_canne:
        return False

    db.delete(db_canne)
    db.commit()
    return True
