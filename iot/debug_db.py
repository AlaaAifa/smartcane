import sys
import os

# Add project root to path
sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), "..")))

from backend.database import SessionLocal
from backend import models

db = SessionLocal()
try:
    print("--- UTILISATEURS ---")
    users = db.query(models.Utilisateur).all()
    for u in users:
        print(f"CIN: {u.cin} | NOM: {u.nom} | EMAIL: {u.email}")

    print("\n--- LOCATIONS ---")
    locs = db.query(models.Location).all()
    for l in locs:
        print(f"ID: {l.id} | SIM: {l.sim_de_la_canne} | UTILISATEUR (CIN): {l.cin_utilisateur}")

finally:
    db.close()
