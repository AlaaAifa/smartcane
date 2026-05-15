import datetime

from sqlalchemy.orm import Session

from backend import models, schemas


def create_alert(db: Session, alert: schemas.AlertCreate):
    existing_alert = get_alert_by_id(db, alert.alert_id)
    if existing_alert:
        return None, "Une alerte avec cet identifiant existe deja"

    db_alert = models.Alert(**alert.model_dump())
    db.add(db_alert)
    db.commit()
    db.refresh(db_alert)
    return db_alert, None


def get_alerts(db: Session):
    return db.query(models.Alert).all()


def get_alert_by_id(db: Session, alert_id: str):
    return db.query(models.Alert).filter(models.Alert.alert_id == alert_id).first()


def update_alert(db: Session, alert_id: str, alert_update: schemas.AlertUpdate):
    db_alert = get_alert_by_id(db, alert_id)
    if not db_alert:
        return None

    update_data = alert_update.model_dump(exclude_unset=True)
    if update_data.get("status") == "resolved" and "resolved_at" not in update_data:
        update_data["resolved_at"] = datetime.datetime.utcnow()

    for key, value in update_data.items():
        setattr(db_alert, key, value)

    db.commit()
    db.refresh(db_alert)
    return db_alert


def delete_alert(db: Session, alert_id: str):
    db_alert = get_alert_by_id(db, alert_id)
    if not db_alert:
        return False

    db.delete(db_alert)
    db.commit()
    return True


def clear_alert_history(db: Session):
    try:
        db.query(models.Alert).filter(models.Alert.status == "resolved").delete()
        db.commit()
        return True
    except Exception:
        db.rollback()
        return False
