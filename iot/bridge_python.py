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
last_alerts = {"SOS": 0, "HELP": 0}
COOLDOWN_SECONDS = 5

try:
    cred = credentials.Certificate(SERVICE_ACCOUNT_KEY)
    firebase_admin.initialize_app(cred, {
        'databaseURL': DATABASE_URL
    })
    print("✅ Firebase Initialized.")
except Exception as e:
    print(f"❌ Firebase Init Error: {e}")

try:
    ser = serial.Serial(SERIAL_PORT, BAUD_RATE, timeout=1)
    print(f"✅ Serial Port {SERIAL_PORT} Opened.")
except Exception as e:
    print(f"❌ Serial Error: {e}")
    ser = None

def get_user_info():
    """Fetches the full client profile linked to this CANE_SIM from the backend."""
    try:
        response = requests.get(f"{BACKEND_URL}/locations/by-cane/{CANE_SIM}", timeout=5)
        if response.status_code == 200:
            user_data = response.json()
            print(f"✅ User identified: {user_data.get('nom', 'Unknown')}")
            return {
                "name": user_data.get('nom', 'Utilisateur Inconnu'),
                "phone": user_data.get('numero_de_telephone'),
                "address": user_data.get('adresse'),
                "cin": user_data.get('cin'),
                "age": user_data.get('age', 0),
                "email": user_data.get('email'),
                "emergency_phone": user_data.get('contact_familial'),
                "health_notes": user_data.get('etat_de_sante', '')
            }
        else:
            print(f"⚠️ User lookup failed: {response.status_code}")
    except Exception as e:
        print(f"❌ Error fetching user info: {e}")
    return None

def push_alert_to_backend(alert_id, alert_type, lat, lng, status, user_cin=None, is_update=False):
    """Synchronizes the alert with the MySQL backend via the API."""
    try:
        payload = {
            "type": alert_type,
            "latitude": float(lat),
            "longitude": float(lng),
            "cane_status": status,
        }
        
        clean_user_id = None
        if user_cin and isinstance(user_cin, str) and user_cin not in ["N/A", "UNKNOWN", "unknown"]:
            clean_user_id = user_cin

        if is_update:
            url = f"{BACKEND_URL}/alerts/{alert_id}"
            resp = requests.put(url, json=payload, timeout=5)
            if resp.status_code == 404:
                payload["alert_id"] = alert_id
                payload["user_id"] = clean_user_id
                payload["status"] = "active"
                resp = requests.post(f"{BACKEND_URL}/alerts", json=payload, timeout=5)
        else:
            payload["alert_id"] = alert_id
            payload["user_id"] = clean_user_id
            payload["status"] = "active"
            url = f"{BACKEND_URL}/alerts"
            resp = requests.post(url, json=payload, timeout=5)
            
        if resp.status_code in [200, 201]:
            action = "UPDATED" if is_update else "CREATED"
            print(f"✅ MySQL Sync Success: Alert {alert_id} {action}")
        else:
            print(f"⚠️ MySQL Sync Fail: {resp.status_code}")
    except Exception as e:
        print(f"❌ MySQL Sync Error: {e}")

def push_alert_to_firebase(alert_type, lat, lng, status):
    global last_alerts
    current_time = time.time()
    
    # Cooldown check specific to alert type
    if alert_type in last_alerts:
        if current_time - last_alerts[alert_type] < COOLDOWN_SECONDS:
            return
        last_alerts[alert_type] = current_time
    else:
        last_alerts[alert_type] = current_time
    
    try:
        enriched_user = get_user_info()
        if not enriched_user:
            enriched_user = {"name": "Utilisateur Inconnu", "phone": "N/A", "cin": "UNKNOWN"}

        active_ref = db.reference('smartcane/device1/active_alert')
        current_alert = active_ref.get()
        now_ms = int(time.time() * 1000)
        
        if current_alert:
            print(f"🔄 Updating active alert: {alert_type}")
            alert_id = current_alert.get("id")
            active_ref.update({
                "type": alert_type,
                "count": current_alert.get("count", 1) + 1,
                "lastUpdatedAt": now_ms,
                "latitude": float(lat),
                "longitude": float(lng),
                "caneStatus": status
            })
            if alert_id:
                push_alert_to_backend(alert_id, alert_type, lat, lng, status, is_update=True)
        else:
            print(f"🆕 Creating new active alert: {alert_type}")
            alert_id = f"alert_{now_ms}"
            new_alert = {
                "id": alert_id,
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
            push_alert_to_backend(alert_id, alert_type, lat, lng, status, user_cin=enriched_user["cin"])

        print(f"🚀 {alert_type} synced for {enriched_user['name']}!")
    except Exception as e:
        print(f"❌ Firebase Error: {e}")

# --- MAIN LOOP ---
def run_bridge():
    global ser
    print("\n🚀 Bridge Python actif. En attente d'événements de l'ESP32...")
    print("⚠️  IMPORTANT: Le Moniteur Série d'Arduino IDE doit être fermé.\n")
    
    while True:
        try:
            if ser is None or not ser.is_open:
                try:
                    ser = serial.Serial(SERIAL_PORT, BAUD_RATE, timeout=1)
                    ser.setDTR(False)
                    ser.setRTS(False)
                    time.sleep(0.5)
                    ser.reset_input_buffer()
                    print(f"✅ Serial Port {SERIAL_PORT} Reconnected.")
                except:
                    time.sleep(2)
                    continue

            if ser.in_waiting > 0:
                line = ser.readline().decode('utf-8', errors='ignore').strip()
                if not line: continue
                    
                print(f"📩 ESP32: {line}")

                clean_line = line.upper()
                
                # 1. Standard Protocol
                if line.startswith("EVENT:"):
                    parts = line.split(":")
                    if len(parts) >= 5:
                        push_alert_to_firebase(parts[1], parts[2], parts[3], parts[4])
                
                # 2. Failover logic (Interception)
                elif "SOS VALID" in clean_line or "SOS VALIDE" in clean_line:
                    print("⚠️ Failover: Intercepting SOS (ESP32 connection failed)")
                    push_alert_to_firebase("SOS", "36.8065", "10.1815", "SOS_ACTIVE")
                elif "HELP VALID" in clean_line or "HELP VALIDE" in clean_line:
                    print("⚠️ Failover: Intercepting HELP (ESP32 connection failed)")
                    push_alert_to_firebase("HELP", "36.8065", "10.1815", "HELP_ACTIVE")
                
                # 3. Telemetry
                if "PITCH:" in clean_line and "ROLL:" in clean_line:
                    try:
                        p_val = line.split("P" if "P:" in clean_line else "Pitch:")[1].split()[0].replace(":", "").replace("°", "").strip()
                        r_val = line.split("R" if "R:" in clean_line else "Roll:")[1].split()[0].replace(":", "").replace("°", "").strip()
                        db.reference('smartcane/device1/telemetry').update({
                            "pitch": float(p_val), "roll": float(r_val), "lastSeen": int(time.time() * 1000)
                        })
                    except: pass

                if any(x in clean_line for x in ["STATUS:", "[TILTED]", "[FALLEN]"]):
                    try:
                        status = "NORMAL"
                        if "[TILTED]" in clean_line: status = "TILTED"
                        elif "[FALLEN]" in clean_line: status = "FALLEN"
                        elif "STATUS:" in clean_line: status = line.split("STATUS:")[1].strip()
                        db.reference('smartcane/device1/telemetry').update({"status": status, "lastSeen": int(time.time() * 1000)})
                        active_ref = db.reference('smartcane/device1/active_alert')
                        if active_ref.get(): active_ref.update({"caneStatus": status})
                    except: pass

                if "GPS:" in clean_line:
                    try:
                        coords = line.split("GPS:")[1].strip().split()[0].split(",")
                        if len(coords) >= 2:
                            db.reference('smartcane/device1/telemetry').update({
                                "latitude": float(coords[0]), "longitude": float(coords[1]), "lastSeen": int(time.time() * 1000)
                            })
                    except: pass

            else:
                time.sleep(0.05)

        except (serial.SerialException, PermissionError, OSError) as e:
            print(f"⚠️ Serial Connection Lost: {e}")
            if ser: 
                try: ser.close()
                except: pass
            ser = None
            time.sleep(2)
        except KeyboardInterrupt:
            print("\n👋 Bridge stopped by user.")
            if ser: ser.close()
            break
        except Exception as e:
            print(f"❌ Unexpected Error: {e}")
            time.sleep(1)

if __name__ == "__main__":
    run_bridge()


if __name__ == "__main__":
    run_bridge()
