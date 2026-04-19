# Guide de Configuration Email - Smart Cane

## Problème Résolu
La fonctionnalité "mot de passe oublié" ne fonctionnait pas car l'envoi d'emails n'était pas configuré. Le code de vérification était généré mais jamais envoyé.

## Solution Actuelle (Mode Développement)
Pour le développement, le système affiche maintenant le code de vérification dans la console du backend. Vous pouvez utiliser ce code pour tester la fonctionnalité.

## Configuration Email pour Production

### Étape 1: Configurer Gmail (Recommandé)
1. Activez la vérification en deux étapes sur votre compte Gmail
2. Générez un "mot de passe d'application" :
   - Allez dans les paramètres Google > Sécurité
   - Activez la vérification en deux étapes
   - Allez dans "Mots de passe des applications"
   - Créez un nouveau mot de passe pour "Smart Cane"

### Étape 2: Mettre à jour le fichier .env
Modifiez le fichier `backend/.env` avec vos informations :

```env
# Email Configuration
MAIL_USERNAME=votre_email@gmail.com
MAIL_PASSWORD=votre_mot_de_passe_application
MAIL_FROM=votre_email@gmail.com
MAIL_PORT=587
MAIL_SERVER=smtp.gmail.com
MAIL_FROM_NAME=Smart Cane
MAIL_STARTTLS=True
MAIL_SSL_TLS=False
USE_CREDENTIALS=True
VALIDATE_CERTS=True
```

### Étape 3: Redémarrer le backend
```bash
cd backend
uvicorn main:app --host 0.0.0.0 --port 8000 --reload
```

## Test Actuel

### Pour tester sans configuration email:
1. Allez sur http://localhost:3001
2. Cliquez sur "Mot de passe oublié ?"
3. Entrez `aifaalaa97@gmail.com`
4. Regardez la console du backend pour voir le code de 6 chiffres
5. Utilisez ce code pour vérifier

### Exemple de ce que vous verrez dans la console:
```
==================================================
AUTHENTICATION - PASSWORD RESET REQUEST
USER EMAIL: aifaalaa97@gmail.com
VERIFICATION CODE: 123456
EXPIRES AT: 14:30:00
==================================================
```

## Autres Fournisseurs Email

### Outlook/Hotmail:
```env
MAIL_SERVER=smtp-mail.outlook.com
MAIL_PORT=587
```

### Yahoo:
```env
MAIL_SERVER=smtp.mail.yahoo.com
MAIL_PORT=587
```

## Dépannage

### "Code de vérification incorrect"
- Assurez-vous d'utiliser le code affiché dans la console
- Le code expire après 10 minutes
- Vérifiez qu'il n'y a pas d'espaces dans le code

### Erreur d'envoi d'email
- Vérifiez votre mot de passe d'application Gmail
- Assurez-vous que le port 587 n'est pas bloqué
- Vérifiez les identifiants dans `backend/.env`

## Sécurité
- N'utilisez jamais votre mot de passe Gmail normal
- Utilisez toujours un mot de passe d'application
- Ne commitez jamais le fichier `backend/.env` avec de vrais identifiants
