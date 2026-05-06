import sys
import os
import datetime

# Add project root to path
sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), "..")))

from backend.database import SessionLocal
from backend import models

def create_manual_link():
    db = SessionLocal()
    try:
        cin = "12131415"
        sim = "+21600000001"
        
        # 1. Check user
        user = db.query(models.Utilisateur).filter(models.Utilisateur.cin == cin).first()
        if not user:
            print(f"[X] Utilisateur avec CIN {cin} non trouve.")
            return

        print(f"[OK] Utilisateur trouve: {user.nom}")

        # 2. Check if cane exists, else create
        cane = db.query(models.Canne).filter(models.Canne.sim_de_la_canne == sim).first()
        if not cane:
            print(f"[*] Creation de la canne SIM {sim}...")
            cane = models.Canne(sim_de_la_canne=sim, statut="louee", version="Smart Pro V2")
            db.add(cane)
            db.flush()
        else:
            cane.statut = "louee"
            print(f"[OK] Canne SIM {sim} deja existante.")

        # 3. Create Location
        print(f"[*] Creation de la location pour {user.nom}...")
        new_loc = models.Location(
            sim_de_la_canne=sim,
            cin_utilisateur=cin,
            date_de_location=datetime.date.today()
        )
        db.add(new_loc)
        
        # Update user's sim field for consistency
        user.sim_de_la_canne = sim
        
        db.commit()
        print(f"[SUCCESS] {user.nom} est maintenant lie a la canne {sim}.")

    except Exception as e:
        db.rollback()
        print(f"[ERROR] Erreur: {e}")
    finally:
        db.close()

if __name__ == "__main__":
    create_manual_link()
