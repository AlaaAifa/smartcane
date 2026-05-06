import firebase_admin
from firebase_admin import credentials, db
import json
import os

# CONFIGURATION
SERVICE_ACCOUNT_KEY = "c:/Users/acer/Desktop/smartcane/iot/firebase_credentials.json"
DATABASE_URL = "https://smartcane-97717-default-rtdb.europe-west1.firebasedatabase.app"

if not firebase_admin._apps:
    cred = credentials.Certificate(SERVICE_ACCOUNT_KEY)
    firebase_admin.initialize_app(cred, {'databaseURL': DATABASE_URL})

ref = db.reference('alerts')
alerts = ref.get()

print("--- ALERTS IN FIREBASE ---")
if alerts:
    print(json.dumps(alerts, indent=2))
else:
    print("No alerts found in 'alerts' path.")
