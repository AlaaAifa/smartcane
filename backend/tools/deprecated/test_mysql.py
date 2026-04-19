#!/usr/bin/env python3
"""
Script de test pour la connexion MySQL et les opérations de base
"""

import sys
import os
from mysql_database import db

def test_mysql_connection():
    print("=== Test de Connexion MySQL ===")
    
    # Test 1: Connexion à la base de données
    print("1. Test de connexion...")
    if db.test_connection():
        print("   SUCCÈS: Connexion établie")
    else:
        print("   ÉCHEC: Connexion impossible")
        return False
    
    # Test 2: Récupération des staff
    print("2. Test récupération staff...")
    try:
        staff_members = db.get_all_staff()
        print(f"   SUCCÈS: {len(staff_members)} membres du personnel trouvés")
        for staff in staff_members:
            print(f"      - {staff.name} ({staff.email}) - {staff.role}")
    except Exception as e:
        print(f"   ÉCHEC: {e}")
    
    # Test 3: Récupération des utilisateurs
    print("3. Test récupération utilisateurs...")
    try:
        utilisateurs = db.get_all_users()
        print(f"   SUCCÈS: {len(utilisateurs)} utilisateurs trouvés")
        for user in utilisateurs[:3]:  # Limiter à 3 pour l'affichage
            print(f"      - {user['nom']} ({user['email']}) - Âge: {user['age']}")
    except Exception as e:
        print(f"   ÉCHEC: {e}")
    
    # Test 4: Récupération des cannes
    print("4. Test récupération cannes...")
    try:
        cannes = db.get_all_cannes()
        print(f"   SUCCÈS: {len(cannes)} cannes trouvées")
        for canne in cannes[:3]:  # Limiter à 3 pour l'affichage
            print(f"      - {canne['sim_de_la_canne']} ({canne['version']}) - {canne['statut']}")
    except Exception as e:
        print(f"   ÉCHEC: {e}")
    
    # Test 5: Récupération des locations
    print("5. Test récupération locations...")
    try:
        locations = db.get_all_locations()
        print(f"   SUCCÈS: {len(locations)} locations trouvées")
        for location in locations[:3]:  # Limiter à 3 pour l'affichage
            print(f"      - {location['sim_de_la_canne']} -> {location['utilisateur_nom']}")
    except Exception as e:
        print(f"   ÉCHEC: {e}")
    
    # Test 6: Récupération des abonnements
    print("6. Test récupération abonnements...")
    try:
        abonnements = db.get_all_abonnements()
        print(f"   SUCCÈS: {len(abonnements)} abonnements trouvés")
        for abonnement in abonnements[:3]:  # Limiter à 3 pour l'affichage
            print(f"      - {abonnement['sim_de_la_canne']} -> {abonnement['utilisateur_nom']}")
    except Exception as e:
        print(f"   ÉCHEC: {e}")
    
    print("\n=== Test terminé ===")
    return True

if __name__ == "__main__":
    test_mysql_connection()
