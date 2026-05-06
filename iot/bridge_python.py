import serial
import firebase_admin
from firebase_admin import credentials, db
import time
import json
import requests

# --- CONFIGURATION ---
# 1. Provide the path to your Firebase Service Account JSON file
# Get this from: Firebase Console > Project Settings > Service Accounts > Generate New Private Key
SERVICE_ACCOUNT_KEY = "firebase_credentials.json"

# 2. Provide your Firebase Database URL
DATABASE_URL = "https://smartcane-97717-default-rtdb.europe-west1.firebasedatabase.app" 

# 3. Configure your Serial Port (Check Device Manager on Windows, e.g., 'COM6')
SERIAL_PORT = 'COM6' 
BAUD_RATE = 115200

# 4. SmartCane ID (SIM number used for registration)
CANE_SIM = "21600000001" 

# 5. Backend API URL
BACKEND_URL = "http://localhost:8000"

# --- INITIALIZATION ---
try:
    cred = credentials.Certificate(SERVICE_ACCOUNT_KEY)
    firebase_admin.initialize_app(cred, {
        'databaseURL': DATABASE_URL
    })
    print("✅ Firebase Initialized.")
except Exception as e:
    print(f"❌ Firebase Init Error: {e}")
    print("Make sure you have firebase_credentials.json in this folder.")

try:
    ser = serial.Serial(SERIAL_PORT, BAUD_RATE, timeout=1)
    print(f"✅ Serial Port {SERIAL_PORT} Opened.")
except Exception as e:
    print(f"❌ Serial Error: {e}")
    ser = None

def get_user_info():
    """Fetches the full client profile linked to this CANE_SIM from the backend."""
    try:
        response = requests.get(f"{BACKEND_URL}/locations/by-cane/{CANE_SIM}")
        if response.status_code == 200:
            user_data = response.json()
            print(f"✅ User identified: {user_data['nom']}")
            return {
                "name": user_data['nom'],
                "phone": user_data.get('numero_de_telephone', 'N/A'),
                "address": user_data.get('adresse', 'N/A'),
                "cin": user_data.get('cin', 'N/A'),
                "age": user_data.get('age', 0),
                "email": user_data.get('email', 'N/A'),
                "emergency_phone": user_data.get('contact_familial', 'N/A'),
                "health_notes": user_data.get('etat_de_sante', '')
            }
        else:
            print(f"⚠️ User lookup failed: {response.status_code}")
    except Exception as e:
        print(f"❌ Error fetching user info: {e}")
    
    return None

def push_alert_to_firebase(alert_type, lat, lng, status):
    try:
        enriched_user = get_user_info()
        if not enriched_user:
            enriched_user = {"name": "Utilisateur Inconnu", "phone": "N/A", "cin": "UNKNOWN"}

        # Chemin spécifique pour l'appareil
        active_ref = db.reference('smartcane/device1/active_alert')
        current_alert = active_ref.get()

        now_ms = int(time.time() * 1000)
        
        if current_alert:
            # MISE À JOUR : L'alerte existe déjà, on incrémente le compteur
            print(f"🔄 Mise à jour de l'alerte active (Type: {alert_type})")
            active_ref.update({
                "type": alert_type,
                "count": current_alert.get("count", 1) + 1,
                "lastUpdatedAt": now_ms,
                "latitude": float(lat),
                "longitude": float(lng),
                "caneStatus": status
            })
        else:
            # CRÉATION : Nouvelle alerte
            print(f"🆕 Création d'une nouvelle alerte active")
            new_alert = {
                "id": f"alert_{now_ms}",
                "type": alert_type,
                "status": "active",
                "count": 1,
                "createdAt": now_ms,
                "lastUpdatedAt": now_ms,
                "latitude": float(lat),
                "longitude": float(lng),
                "caneStatus": status,
                "user": {
                    "name": enriched_user["name"],
                    "phone": enriched_user["phone"],
                    "cin": enriched_user["cin"]
                }
            }
            active_ref.set(new_alert)

        print(f"🚀 Alerte {alert_type} synchronisée pour {enriched_user['name']} !")
    except Exception as e:
        print(f"❌ Firebase Error: {e}")

# --- MAIN LOOP ---
def run_bridge():
    global ser
    print("🚀 Bridge Python actif. En attente d'événements de l'ESP32...")
    
    while True:
        try:
            if ser is None or not ser.is_open:
                try:
                    ser = serial.Serial(SERIAL_PORT, BAUD_RATE, timeout=1)
                    print(f"✅ Serial Port {SERIAL_PORT} Re-Opened.")
                except Exception as e:
                    print(f"⏳ En attente de l'ESP32 sur {SERIAL_PORT}... ({e})")
                    time.sleep(2)
                    continue

            line = ser.readline().decode('utf-8', errors='ignore').strip()
            if not line:
                continue
                
            print(f"📩 Reçu de l'ESP32: {line}") # Debug: voir tout ce qui arrive

            # 1. Gestion du format EVENT: (Protocole standard)
            if line.startswith("EVENT:"):
                parts = line.split(":")
                if len(parts) >= 5:
                    alert_type = parts[1]
                    lat = parts[2]
                    lng = parts[3]
                    status = parts[4]
                    push_alert_to_firebase(alert_type, lat, lng, status)
            
            # 2. Gestion du format texte (Très flexible)
            clean_line = line.upper()
            
            if "SOS" in clean_line and ("ALERTE" in clean_line or "PRESS" in clean_line or "HOLD" in clean_line):
                print("🎯 Détection SOS (Format texte flexible)")
                push_alert_to_firebase("SOS", "36.8065", "10.1815", "SOS_ACTIVE")
            
            elif "HELP" in clean_line and ("ALERTE" in clean_line or "PRESS" in clean_line or "HOLD" in clean_line):
                print("🎯 Détection HELP (Format texte flexible)")
                push_alert_to_firebase("HELP", "36.8065", "10.1815", "WAITING")

            elif line.startswith("DEBUG:"):
                print(f"💡 ESP32 DEBUG: {line}")

        except (UnicodeDecodeError, serial.SerialException, PermissionError) as e:
            print(f"⚠️ Erreur de connexion série : {e}")
            if ser:
                try:
                    ser.close()
                except:
                    pass
            ser = None
            time.sleep(2)
        except KeyboardInterrupt:
            print("\nArrêt du bridge.")
            if ser:
                ser.close()
            break
        except Exception as e:
            print(f"❌ Erreur inattendue : {e}")
            time.sleep(1)

if __name__ == "__main__":
    run_bridge()
