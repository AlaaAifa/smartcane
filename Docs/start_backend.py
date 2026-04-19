#!/usr/bin/env python3
"""
Script de démarrage pour le backend Smart Cane
"""

import os
import sys
import subprocess
from pathlib import Path

def check_requirements():
    """Vérifie si toutes les dépendances sont installées"""
    print("Vérification des dépendances...")
    
    required_packages = [
        'fastapi', 'uvicorn', 'pydantic', 'python-multipart', 
        'requests', 'fastapi-mail', 'python-dotenv', 'aiosqlite'
    ]
    
    missing_packages = []
    for package in required_packages:
        try:
            __import__(package.replace('-', '_'))
            print(f"  {package} - OK")
        except ImportError:
            missing_packages.append(package)
            print(f"  {package} - MANQUANT")
    
    if missing_packages:
        print(f"\nInstallation des packages manquants: {missing_packages}")
        subprocess.check_call([sys.executable, "-m", "pip", "install"] + missing_packages)
    
    print("Toutes les dépendances sont installées!\n")

def start_backend():
    """Démarre le serveur backend"""
    print("Démarrage du serveur Smart Cane Backend...")
    print("Serveur disponible sur: http://127.0.0.1:8001")
    print("Documentation API: http://127.0.0.1:8001/docs")
    print("Appuyez sur Ctrl+C pour arrêter le serveur\n")
    
    # Changer vers le répertoire backend
    backend_dir = Path(__file__).parent / "backend"
    os.chdir(backend_dir)
    
    # Démarrer le serveur
    try:
        subprocess.run([sys.executable, "main.py"])
    except KeyboardInterrupt:
        print("\nArrêt du serveur...")

if __name__ == "__main__":
    check_requirements()
    start_backend()
