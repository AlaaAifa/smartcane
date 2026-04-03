from fastapi import FastAPI, HTTPException, Depends
from fastapi.middleware.cors import CORSMiddleware
from typing import Dict, List, Optional
from models import UserDocument, Alert, StaffUser, LoginRequest, TokenResponse
import uvicorn
from datetime import datetime
import uuid

app = FastAPI(title="Smart Cane API", version="2.0.0")

# CORS for desktop app
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

# ==================== IN-MEMORY DATABASE ====================
db_users: Dict[str, UserDocument] = {}
db_alerts: Dict[str, Alert] = {}
db_staff: Dict[str, StaffUser] = {}

# Seed default admin account
db_staff["admin_001"] = StaffUser(
    staff_id="admin_001",
    name="Admin Principal",
    email="alaa@gmail.com",
    password="123456",
    role="admin",
    shift="matin"
)
db_staff["staff_001"] = StaffUser(
    staff_id="staff_001",
    name="Mohamed Ben Ali",
    email="staff@smartcane.com",
    password="staff123",
    role="staff",
    shift="soir"
)

# Seed demo users
db_users["user_001"] = UserDocument(
    user_id="user_001",
    nom="Ben Slama",
    prenom="Mohamed",
    birthday="1985-06-15",
    email="m.benslama@example.com",
    phone_number_malvoyant="+216 20 123 456",
    phone_number_famille="+216 55 987 654",
    status="normal",
    is_online=True,
    latitude=36.8065,
    longitude=10.1815
)
db_users["user_002"] = UserDocument(
    user_id="user_002",
    nom="Trabelsi",
    prenom="Fatma",
    birthday="1990-03-22",
    email="f.trabelsi@example.com",
    phone_number_malvoyant="+216 22 333 444",
    phone_number_famille="+216 55 111 222",
    status="normal",
    is_online=False,
    latitude=36.8190,
    longitude=10.1660
)
db_users["user_003"] = UserDocument(
    user_id="user_003",
    nom="Bouazizi",
    prenom="Ahmed",
    birthday="1978-11-05",
    email="a.bouazizi@example.com",
    phone_number_malvoyant="+216 25 555 666",
    phone_number_famille="+216 98 777 888",
    status="normal",
    is_online=True,
    latitude=36.7980,
    longitude=10.1720
)

# Seed demo alerts
db_alerts["alert_001"] = Alert(
    alert_id="alert_001",
    user_id="user_001",
    type="SOS",
    latitude=36.8065,
    longitude=10.1815,
    timestamp="2026-03-31T14:30:00Z",
    status="active"
)
db_alerts["alert_002"] = Alert(
    alert_id="alert_002",
    user_id="user_002",
    type="HELP",
    latitude=36.8190,
    longitude=10.1660,
    timestamp="2026-03-31T15:10:00Z",
    status="active"
)
db_alerts["alert_003"] = Alert(
    alert_id="alert_003",
    user_id="user_003",
    type="SOS",
    latitude=36.7980,
    longitude=10.1720,
    timestamp="2026-03-30T09:45:00Z",
    status="resolved",
    resolved_by="staff_001",
    resolved_at="2026-03-30T09:55:00Z"
)

# ==================== AUTH ====================
@app.post("/auth/login", response_model=TokenResponse)
async def login(req: LoginRequest):
    for staff in db_staff.values():
        if staff.email == req.email and staff.password == req.password:
            # Simple token = staff_id (in production: use real JWT)
            return TokenResponse(
                token=f"token_{staff.staff_id}",
                role=staff.role,
                name=staff.name,
                staff_id=staff.staff_id
            )
    raise HTTPException(status_code=401, detail="Email ou mot de passe incorrect")

# ==================== DASHBOARD STATS ====================
@app.get("/dashboard/stats")
async def get_dashboard_stats():
    total_users = len(db_users)
    active_alerts = sum(1 for a in db_alerts.values() if a.status == "active")
    sos_count = sum(1 for a in db_alerts.values() if a.type == "SOS" and a.status == "active")
    help_count = sum(1 for a in db_alerts.values() if a.type == "HELP" and a.status == "active")
    resolved_count = sum(1 for a in db_alerts.values() if a.status == "resolved")
    online_count = sum(1 for u in db_users.values() if u.is_online)
    return {
        "total_users": total_users,
        "online_users": online_count,
        "active_alerts": active_alerts,
        "sos_count": sos_count,
        "help_count": help_count,
        "resolved_count": resolved_count,
    }

# ==================== USERS ====================
@app.get("/users", response_model=List[UserDocument])
async def get_all_users():
    return list(db_users.values())

@app.get("/users/{user_id}", response_model=UserDocument)
async def get_user(user_id: str):
    if user_id not in db_users:
        raise HTTPException(status_code=404, detail="User not found")
    return db_users[user_id]

@app.post("/users", response_model=UserDocument)
async def create_or_update_user(user: UserDocument):
    if not user.user_id:
        user.user_id = f"user_{uuid.uuid4().hex[:8]}"
    db_users[user.user_id] = user
    return user

# ==================== ALERTS ====================
@app.post("/alerts")
async def receive_alert(alert: Alert):
    alert.alert_id = f"alert_{uuid.uuid4().hex[:8]}"
    alert.status = "active"
    db_alerts[alert.alert_id] = alert

    # Update user status
    if alert.user_id in db_users:
        db_users[alert.user_id].status = alert.type

    print(f"!!! {alert.type} ALERT from {alert.user_id} !!!")
    return {"status": "success", "alert_id": alert.alert_id}

@app.get("/alerts", response_model=List[Alert])
async def get_all_alerts():
    return list(db_alerts.values())

@app.get("/alerts/active", response_model=List[Alert])
async def get_active_alerts():
    return [a for a in db_alerts.values() if a.status == "active"]

@app.get("/alerts/history", response_model=List[Alert])
async def get_alerts_history():
    return [a for a in db_alerts.values() if a.status == "resolved"]

@app.delete("/alerts/history")
async def clear_alerts_history():
    global db_alerts
    # Keep only active alerts
    db_alerts = {k: v for k, v in db_alerts.items() if v.status != "resolved"}
    return {"status": "success", "message": "Alert history cleared"}

@app.put("/alerts/{alert_id}/resolve")
async def resolve_alert(alert_id: str, staff_id: str = "staff_001"):
    if alert_id not in db_alerts:
        raise HTTPException(status_code=404, detail="Alert not found")
    alert = db_alerts[alert_id]
    alert.status = "resolved"
    alert.resolved_by = staff_id
    alert.resolved_at = datetime.now().isoformat()

    # Reset user status
    if alert.user_id in db_users:
        db_users[alert.user_id].status = "normal"

    return {"status": "success", "message": f"Alert {alert_id} resolved"}

# ==================== STAFF ====================
@app.get("/staff", response_model=List[StaffUser])
async def get_all_staff():
    return list(db_staff.values())

@app.post("/staff", response_model=StaffUser)
async def create_staff(staff: StaffUser):
    if not staff.staff_id:
        staff.staff_id = f"staff_{uuid.uuid4().hex[:8]}"
    db_staff[staff.staff_id] = staff
    return staff

# ==================== PERFORMANCE (Admin) ====================
@app.get("/performance")
async def get_staff_performance():
    performance = {}
    for staff in db_staff.values():
        resolved = sum(1 for a in db_alerts.values() if a.resolved_by == staff.staff_id and a.status == "resolved")
        pending = sum(1 for a in db_alerts.values() if a.status == "active")
        processed = resolved  # Simplification for demo
        
        performance[staff.staff_id] = {
            "staff_name": staff.name,
            "role": staff.role,
            "shift": staff.shift,
            "alerts_processed": processed,
            "alerts_resolved": resolved,
            "alerts_pending": pending,
        }
    return performance

@app.get("/")
async def root():
    return {"message": "Smart Cane API v2.0 — Dashboard Ready"}

if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8000)
