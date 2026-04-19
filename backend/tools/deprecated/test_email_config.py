import os
from dotenv import load_dotenv
from fastapi_mail import FastMail, MessageSchema, ConnectionConfig, MessageType
import asyncio

load_dotenv('config.env')

async def test_email():
    print("=== Test de configuration email ===")
    
    # Vérifier les variables d'environnement
    mail_username = os.getenv("MAIL_USERNAME")
    mail_password = os.getenv("MAIL_PASSWORD")
    mail_from = os.getenv("MAIL_FROM")
    mail_port = os.getenv("MAIL_PORT", 587)
    mail_server = os.getenv("MAIL_SERVER")
    
    print(f"MAIL_USERNAME: {mail_username}")
    print(f"MAIL_PASSWORD: {'*' * len(mail_password) if mail_password else 'Non configuré'}")
    print(f"MAIL_FROM: {mail_from}")
    print(f"MAIL_PORT: {mail_port}")
    print(f"MAIL_SERVER: {mail_server}")
    
    if not all([mail_username, mail_password, mail_from, mail_server]):
        print("ERREUR: Configuration email incomplète!")
        return False
    
    try:
        # Configuration de la connexion
        conf = ConnectionConfig(
            MAIL_USERNAME=mail_username,
            MAIL_PASSWORD=mail_password,
            MAIL_FROM=mail_from,
            MAIL_PORT=int(mail_port),
            MAIL_SERVER=mail_server,
            MAIL_FROM_NAME="Smart Cane Test",
            MAIL_STARTTLS=True,
            MAIL_SSL_TLS=False,
            USE_CREDENTIALS=True,
            VALIDATE_CERTS=True,
        )
        
        # Créer le message
        message = MessageSchema(
            subject="Test Email - Smart Cane",
            recipients=["aifaalaa97@gmail.com"],  # Email de test
            body="<h1>Email de test</h1><p>Ceci est un email de test pour vérifier la configuration SMTP.</p>",
            subtype=MessageType.html,
        )
        
        # Envoyer l'email
        fm = FastMail(conf)
        await fm.send_message(message)
        print("SUCCÈS: Email envoyé avec succès!")
        return True
        
    except Exception as e:
        print(f"ERREUR: Échec de l'envoi d'email: {e}")
        print(f"Type d'erreur: {type(e).__name__}")
        return False

if __name__ == "__main__":
    asyncio.run(test_email())
