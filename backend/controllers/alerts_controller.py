from typing import List

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from backend import schemas
from backend.database import get_db
from backend.services import alerts_service

router = APIRouter(prefix="/alerts", tags=["Alerts"])


@router.post("", response_model=schemas.Alert, status_code=status.HTTP_201_CREATED)
def create_alert(alert: schemas.AlertCreate, db: Session = Depends(get_db)):
    db_alert, error = alerts_service.create_alert(db, alert)
    if error:
        raise HTTPException(status_code=400, detail=error)
    return db_alert


@router.get("", response_model=List[schemas.Alert])
def get_alerts(db: Session = Depends(get_db)):
    return alerts_service.get_alerts(db)


@router.get("/{alert_id}", response_model=schemas.Alert)
def get_alert(alert_id: str, db: Session = Depends(get_db)):
    db_alert = alerts_service.get_alert_by_id(db, alert_id)
    if not db_alert:
        raise HTTPException(status_code=404, detail="Alerte non trouvee")
    return db_alert


@router.put("/{alert_id}", response_model=schemas.Alert)
def update_alert(alert_id: str, alert_update: schemas.AlertUpdate, db: Session = Depends(get_db)):
    db_alert = alerts_service.update_alert(db, alert_id, alert_update)
    if not db_alert:
        raise HTTPException(status_code=404, detail="Alerte non trouvee")
    return db_alert


@router.delete("/{alert_id}")
def delete_alert(alert_id: str, db: Session = Depends(get_db)):
    deleted = alerts_service.delete_alert(db, alert_id)
    if not deleted:
        raise HTTPException(status_code=404, detail="Alerte non trouvee")
    return {"message": f"Alerte {alert_id} supprimee avec succes"}
