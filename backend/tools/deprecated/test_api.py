import requests
import json

# Test de l'API
base_url = "http://127.0.0.1:8001"

def test_api():
    print("=== Test de l'API Smart Cane ===")
    
    # Test 1: Racine
    try:
        response = requests.get(f"{base_url}/")
        print(f"1. Racine: {response.status_code} - {response.json()}")
    except Exception as e:
        print(f"1. Racine: ERREUR - {e}")
    
    # Test 2: Stats dashboard
    try:
        response = requests.get(f"{base_url}/dashboard/stats")
        print(f"2. Stats: {response.status_code} - {response.json()}")
    except Exception as e:
        print(f"2. Stats: ERREUR - {e}")
    
    # Test 3: Login
    try:
        login_data = {"email": "aifaalaa97@gmail.com", "password": "123456"}
        response = requests.post(f"{base_url}/auth/login", json=login_data)
        print(f"3. Login: {response.status_code} - {response.json()}")
    except Exception as e:
        print(f"3. Login: ERREUR - {e}")
    
    # Test 4: Users
    try:
        response = requests.get(f"{base_url}/users")
        print(f"4. Users: {response.status_code} - {len(response.json())} utilisateurs trouvés")
    except Exception as e:
        print(f"4. Users: ERREUR - {e}")
    
    # Test 5: Alerts
    try:
        response = requests.get(f"{base_url}/alerts")
        print(f"5. Alerts: {response.status_code} - {len(response.json())} alertes trouvées")
    except Exception as e:
        print(f"5. Alerts: ERREUR - {e}")
    
    # Test 6: Staff
    try:
        response = requests.get(f"{base_url}/staff")
        print(f"6. Staff: {response.status_code} - {len(response.json())} membres du personnel")
    except Exception as e:
        print(f"6. Staff: ERREUR - {e}")

if __name__ == "__main__":
    test_api()
