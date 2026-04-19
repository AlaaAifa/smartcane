#!/usr/bin/env python3
"""
Script de test complet pour l'API Smart Cane avec MySQL
"""

import requests
import json
from datetime import date, datetime

base_url = "http://127.0.0.1:8001"

def print_test_header(test_name):
    print(f"\n{'='*60}")
    print(f"TEST: {test_name}")
    print('='*60)

def print_response(response, test_name):
    print(f"Status: {response.status_code}")
    if response.status_code == 200:
        try:
            data = response.json()
            print(f"Response: {json.dumps(data, indent=2, ensure_ascii=False)}")
        except:
            print(f"Response: {response.text}")
    else:
        print(f"Error: {response.text}")
    print('-' * 40)

def test_api_complete():
    print("=== TEST COMPLET DE L'API SMART CANE ===")
    
    # Test 1: Authentification
    print_test_header("Authentification")
    try:
        response = requests.post(f"{base_url}/auth/login", 
                                json={"email": "aifaalaa97@gmail.com", "password": "123456"})
        print_response(response, "Login Admin")
        
        if response.status_code == 200:
            token_data = response.json()
            headers = {"Authorization": f"Bearer {token_data['token']}"}
        else:
            headers = {}
    except Exception as e:
        print(f"ERREUR Login: {e}")
        headers = {}
    
    # Test 2: Dashboard Stats
    print_test_header("Dashboard Stats")
    try:
        response = requests.get(f"{base_url}/dashboard/stats", headers=headers)
        print_response(response, "Stats")
    except Exception as e:
        print(f"ERREUR Stats: {e}")
    
    # Test 3: Utilisateurs
    print_test_header("Gestion des Utilisateurs")
    
    # GET all users
    try:
        response = requests.get(f"{base_url}/users", headers=headers)
        print_response(response, "Get All Users")
    except Exception as e:
        print(f"ERREUR Get Users: {e}")
    
    # POST new user
    try:
        new_user = {
            "cin": "TEST001",
            "nom": "Test User",
            "age": 45,
            "adresse": "Test Address",
            "email": "test@example.com",
            "numero_de_telephone": "+216 12 345 678",
            "contact_familial": "+216 98 765 432",
            "etat_de_sante": "Bon état"
        }
        response = requests.post(f"{base_url}/users", json=new_user, headers=headers)
        print_response(response, "Create User")
    except Exception as e:
        print(f"ERREUR Create User: {e}")
    
    # Test 4: Cannes
    print_test_header("Gestion des Cannes")
    
    # GET all cannes
    try:
        response = requests.get(f"{base_url}/cannes", headers=headers)
        print_response(response, "Get All Cannes")
    except Exception as e:
        print(f"ERREUR Get Cannes: {e}")
    
    # POST new canne
    try:
        new_canne = {
            "sim_de_la_canne": "SIM_TEST001",
            "version": "Test Model",
            "statut": "disponible",
            "type": "location"
        }
        response = requests.post(f"{base_url}/cannes", json=new_canne, headers=headers)
        print_response(response, "Create Cane")
    except Exception as e:
        print(f"ERREUR Create Cane: {e}")
    
    # Test 5: Locations
    print_test_header("Gestion des Locations")
    
    # GET all locations
    try:
        response = requests.get(f"{base_url}/locations", headers=headers)
        print_response(response, "Get All Locations")
    except Exception as e:
        print(f"ERREUR Get Locations: {e}")
    
    # POST new location
    try:
        new_location = {
            "sim_de_la_canne": "SIM001",
            "cin_utilisateur": "USER001",
            "date_de_location": str(date.today())
        }
        response = requests.post(f"{base_url}/locations", json=new_location, headers=headers)
        print_response(response, "Create Location")
    except Exception as e:
        print(f"ERREUR Create Location: {e}")
    
    # Test 6: Abonnements
    print_test_header("Gestion des Abonnements")
    
    # GET all abonnements
    try:
        response = requests.get(f"{base_url}/abonnements", headers=headers)
        print_response(response, "Get All Abonnements")
    except Exception as e:
        print(f"ERREUR Get Abonnements: {e}")
    
    # POST new abonnement
    try:
        new_abonnement = {
            "sim_de_la_canne": "SIM002",
            "cin_utilisateur": "USER002",
            "type_d_abonnement": "mensuel",
            "date_de_debut": str(date.today()),
            "date_de_fin": str(date(date.today().year, date.today().month + 1, date.today().day))
        }
        response = requests.post(f"{base_url}/abonnements", json=new_abonnement, headers=headers)
        print_response(response, "Create Abonnement")
    except Exception as e:
        print(f"ERREUR Create Abonnement: {e}")
    
    # Test 7: Staff
    print_test_header("Gestion du Staff")
    
    # GET all staff
    try:
        response = requests.get(f"{base_url}/staff", headers=headers)
        print_response(response, "Get All Staff")
    except Exception as e:
        print(f"ERREUR Get Staff: {e}")
    
    # POST new staff
    try:
        new_staff = {
            "staff_id": "STAFF_TEST001",
            "name": "Test Staff",
            "email": "stafftest@example.com",
            "password": "test123",
            "role": "staff",
            "shift": "soir"
        }
        response = requests.post(f"{base_url}/staff", json=new_staff, headers=headers)
        print_response(response, "Create Staff")
    except Exception as e:
        print(f"ERREUR Create Staff: {e}")
    
    # Test 8: Endpoints de mise à jour
    print_test_header("Tests de Mise à Jour")
    
    # UPDATE user
    try:
        update_user = {
            "nom": "Test User Updated",
            "age": 46,
            "adresse": "Updated Address"
        }
        response = requests.put(f"{base_url}/users/TEST001", json=update_user, headers=headers)
        print_response(response, "Update User")
    except Exception as e:
        print(f"ERREUR Update User: {e}")
    
    # UPDATE canne
    try:
        update_canne = {
            "version": "Updated Model",
            "statut": "louee"
        }
        response = requests.put(f"{base_url}/cannes/SIM_TEST001", json=update_canne, headers=headers)
        print_response(response, "Update Cane")
    except Exception as e:
        print(f"ERREUR Update Cane: {e}")
    
    print("\n" + "="*60)
    print("TESTS TERMINÉS")
    print("="*60)

if __name__ == "__main__":
    test_api_complete()
