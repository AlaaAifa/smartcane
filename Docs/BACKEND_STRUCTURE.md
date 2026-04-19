# Structure du Backend

Ce document explique la structure actuelle du backend de **Smart Cane**.

## Vue Generale

Le backend est organise comme un package Python base sur **FastAPI**.
La structure suit une separation simple par responsabilite :

- `models` : definition des tables SQLAlchemy
- `services` : logique metier et acces database
- `controllers` : `router` FastAPI et gestion HTTP
- `schemas` : validation et format des donnees API avec Pydantic
- `database.py` : connexion MySQL, `engine`, `SessionLocal`, `Base`
- `main.py` : creation de `app`, chargement des `router`, demarrage
- `tools` : fichiers auxiliaires, anciens scripts, SQL, templates et guides

## Arborescence

```text
backend/
  controllers/
    utilisateurs_controller.py
    cannes_controller.py
    locations_controller.py
    abonnements_controller.py
    alerts_controller.py
  models/
    utilisateur.py
    canne.py
    location.py
    abonnement.py
    alert.py
  services/
    utilisateurs_service.py
    cannes_service.py
    locations_service.py
    abonnements_service.py
    alerts_service.py
  tools/
    deprecated/
    spl/
    templates/
  .env
  database.py
  main.py
  schemas.py
```

## Role de chaque dossier

### `models`

Le dossier `models` contient les classes SQLAlchemy qui representent la structure reelle de la base MySQL.

Chaque fichier contient une entite :

- `Utilisateur`
- `Canne`
- `Location`
- `Abonnement`
- `Alert`

Ces classes definissent :

- le nom de la table avec `__tablename__`
- les `Column`
- les `ForeignKey`
- les `relationship`

Le dossier `models` est la reference pour la structure database.

### `services`

Le dossier `services` contient la logique applicative.
Un `service` parle a la database via SQLAlchemy et execute les operations CRUD.

Exemples :

- verifier si un `user` existe deja
- creer une `canne`
- modifier une `alert`
- supprimer une `location`

Le but est de ne pas mettre cette logique directement dans les `controllers`.

### `controllers`

Le dossier `controllers` contient les `router` FastAPI.
Chaque `controller` expose les `endpoint` HTTP pour une ressource.

Exemples :

- `POST /users`
- `GET /cannes`
- `PUT /locations/{location_id}`
- `DELETE /alerts/{alert_id}`

Le `controller` :

- recoit la `request`
- valide les donnees avec `schemas`
- appelle le `service`
- retourne la `response`
- leve une `HTTPException` si necessaire

### `tools`

Le dossier `tools` contient les fichiers non essentiels au runtime principal.

Il regroupe :

- `deprecated` : ancien code et anciens tests
- `spl` : fichier SQL pour la base
- `templates` : template email
- fichiers `.md` de support technique

Ce dossier sert a garder le backend principal propre.

## Pourquoi `schemas.py` existe

`schemas.py` ne decrit pas la database.
Il decrit le contrat API.

Il sert a :

- valider les donnees d'entree
- definir le format de sortie
- separer `request` et `response`
- generer automatiquement `/docs`

Exemples :

- `UtilisateurCreate` : donnees attendues pour creer un `user`
- `UtilisateurUpdate` : donnees autorisees pour un `update`
- `Utilisateur` : donnees renvoyees par l'API

Donc :

- `models` = structure database
- `schemas` = structure API

## Flux d'une request

Le flux standard est :

1. le client appelle un `endpoint`
2. le `controller` recoit la `request`
3. FastAPI valide le body avec `schemas`
4. le `controller` appelle le `service`
5. le `service` utilise `models` et `database session`
6. le resultat est retourne comme `response`

Exemple sur `POST /users` :

1. `utilisateurs_controller.py` recoit les donnees
2. `UtilisateurCreate` valide le body
3. `utilisateurs_service.py` verifie `cin` et `email`
4. `models.Utilisateur` est cree puis sauvegarde
5. la `response_model` retourne un objet `Utilisateur`

## Database

La connexion database est centralisee dans `database.py`.

Ce fichier charge les variables depuis `backend/.env` :

- `DB_HOST`
- `DB_PORT`
- `DB_USER`
- `DB_PASSWORD`
- `DB_NAME`

Puis il prepare :

- `engine`
- `SessionLocal`
- `Base`
- `get_db()`

`get_db()` est utilise dans les `controllers` avec `Depends`.

## Main App

`main.py` est le point d'entree principal.

Il fait trois choses :

1. cree l'objet `FastAPI`
2. lance `create_all()` pour creer les tables
3. fait `include_router()` pour chaque `controller`

Les `router` actifs aujourd'hui sont :

- `users`
- `cannes`
- `locations`
- `abonnements`
- `alerts`

## Avantages de cette structure

Cette structure apporte plusieurs benefices :

- code plus lisible
- responsabilites mieux separees
- maintenance plus simple
- ajout de nouveaux `endpoint` plus propre
- test de chaque couche plus facile

## Regle de travail recommandee

Quand une nouvelle fonctionnalite est ajoutee :

1. creer ou modifier le `model` si la table change
2. creer ou modifier le `schema`
3. ajouter la logique dans le `service`
4. exposer le `endpoint` dans le `controller`
5. enregistrer le `router` dans `main.py` si besoin

## Resume

Le backend actuel suit cette logique :

- `models` pour la database
- `services` pour la logique
- `controllers` pour l'API
- `schemas` pour la validation
- `tools` pour les fichiers auxiliaires

Cette base est plus propre que l'ancienne structure flat et elle est prete pour evoluer.
