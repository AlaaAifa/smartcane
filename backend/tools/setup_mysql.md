# Configuration MySQL pour Smart Cane

## Problème Actuel
La connexion MySQL échoue avec l'erreur : "Access denied for user 'root'@'localhost' (using password: NO)"

## Solutions Possibles

### Option 1: Utiliser un mot de passe pour root
1. Ouvrez `backend/.env`
2. Ajoutez le mot de passe MySQL pour root :
```
DB_PASSWORD=votre_mot_de_passe_mysql
```

### Option 2: Créer un utilisateur dédié pour Smart Cane
```sql
-- Connectez-vous à MySQL avec root
mysql -u root -p

-- Créez la base de données si elle n'existe pas
CREATE DATABASE IF NOT EXISTS smart_cane_db;

-- Créez un utilisateur dédié
CREATE USER 'smartcane'@'localhost' IDENTIFIED BY 'smartcane123';

-- Donnez les permissions
GRANT ALL PRIVILEGES ON smart_cane_db.* TO 'smartcane'@'localhost';

-- Appliquez les changements
FLUSH PRIVILEGES;

-- Quittez
EXIT;
```

Puis modifiez `backend/.env` :
```
DB_USER=smartcane
DB_PASSWORD=smartcane123
```

### Option 3: Importer la structure de la base de données
Si la base de données n'existe pas, importez le fichier SQL :

```bash
mysql -u root -p smart_cane_db < tools/spl/smart_cane_db.sql
```

## Configuration Recommandée dans `backend/.env`
```
# MySQL Database Configuration
DB_HOST=localhost
DB_PORT=3306
DB_USER=smartcane
DB_PASSWORD=smartcane123
DB_NAME=smart_cane_db
```

## Test de Connexion
Après configuration, testez avec :
```bash
python test_mysql.py
```

## Démarrage du Backend
Une fois MySQL configuré :
```bash
python main.py
```
