# 🏗️ Architecture & Stack Technique - Smart Cane Dashboard v2.0

Ce document récapitule l'ensemble des technologies, langages et outils utilisés pour le développement de l'écosystème **Smart Cane**.

---

## 🧩 1. Le Backend (Le Cerveau)
Le backend gère la logique métier, le stockage des données et les alertes de sécurité.

*   **Langage :** [Python 3.10+](https://www.python.org/) 🐍
    *   Utilisé pour sa simplicité et sa puissance de traitement des données.
*   **Framework API :** [FastAPI](https://fastapi.tiangolo.com/) ⚡
    *   Framework moderne et extrêmement rapide pour construire des API REST.
*   **Validation des Données :** [Pydantic](https://docs.pydantic.dev/) ✅
    *   Assure que chaque information (Email, GPS, etc.) respecte le bon format avant d'être traitée.
*   **Base de Données :** In-Memory (Dictionnaires Python) 💾
    *   Stockage en mémoire vive pour une réactivité maximale durant le développement.
*   **Serveur Web :** [Uvicorn](https://www.uvicorn.org/) 🗼
    *   Serveur ASGI ultra-performant pour faire tourner l'API.

---

## 📱 2. Le Frontend (Dashboard)
L'interface utilisateur premium utilisée par les opérateurs du centre.

*   **Framework UI :** [Flutter SDK](https://flutter.dev/) 💙
    *   Développé par Google, il permet de créer des interfaces fluides et modernes pour Desktop (Windows/Web).
*   **Langage :** [Dart](https://dart.dev/) 🎯
    *   Langage typé, optimisé pour les interfaces réactives.
*   **Cartographie :** [Flutter Map](https://pub.dev/packages/flutter_map) + [OpenStreetMap](https://www.openstreetmap.org/) 🗺️
    *   Intégration de cartes interactives pour le suivi GPS en temps réel.
*   **Communication API :** [http](https://pub.dev/packages/http) 📡
    *   Bibliothèque de requêtes pour échanger des données avec le serveur Python.

---

## 🎨 3. Design & UX (Expérience Utilisateur)
*   **Esthétique :** Design Dark Mode Premium avec accentuation des couleurs d'alerte (Rouge SOS).
*   **Responsivité :** Utilisation de `LayoutBuilder` pour s'adapter à toutes les tailles d'écran (Desktop, Laptop, Tablette).
*   **Micro-animations :** Effets de survol et transitions fluides entre les pages.

---

## 🛠️ 4. Fonctionnalités Implémentées
1.  **Système SOS & HELP :** Réception d'alertes en temps réel avec localisation précise.
2.  **Tracking Temps Réel :** Suivi simultané de tous les utilisateurs du centre sur une carte dynamique.
3.  **Gestion du Staff :** Création de membres, attribution de shifts (Matin/Soir) et suivi de performance.
4.  **Gestion des Profils :** Fiches détaillées (Médical, Emergency, Adresse) sécurisées par rôles (Admin/Staff).
5.  **Navigation Avancée :** Système d'historique de routes pour une navigation sans perte d'état.

---

## 🚀 5. Commandes de Lancement
*   **Démarrer le Serveur :** `python backend/main.py`
*   **Démarrer le Dashboard :** `flutter run -d chrome` (ou `windows`)
