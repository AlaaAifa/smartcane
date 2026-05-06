import sys
import os
import requests

# Add project root to path
sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), "..")))

from backend.database import SessionLocal
from backend import models

def check_db():
    db = SessionLocal()
    try:
        print("--- RECHERCHE ALAA DANS MYSQL ---")
        user = db.query(models.Utilisateur).filter(models.Utilisateur.nom.like("%Alaa%")).first()
        if user:
            print(f"[OK] Utilisateur trouve: {user.nom} (CIN: {user.cin})")
            # Check location
            loc = db.query(models.Location).filter(models.Location.cin_utilisateur == user.cin).first()
            if loc:
                print(f"[OK] Location trouvee: SIM {loc.sim_de_la_canne}")
            else:
                print("[X] Aucune location trouvee pour cet utilisateur.")
        else:
            print("[X] Aucun utilisateur nomme 'Alaa' trouve.")
    finally:
        db.close()

def test_endpoint():
    print("\n--- TEST ENDPOINT GET /locations/by-cane/21600000001 ---")
    try:
        response = requests.get("http://localhost:8000/locations/by-cane/21600000001")
        if response.status_code == 200:
            print(f"[OK] Succes! Donnees retournees: {response.json()}")
        else:
            print(f"[X] Echec (Code {response.status_code}): {response.text}")
    except Exception as e:
        print(f"[X] Erreur de connexion: {e}")

if __name__ == "__main__":
    check_db()
    test_endpoint()
