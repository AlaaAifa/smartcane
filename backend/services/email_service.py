import os
from fastapi_mail import ConnectionConfig, FastMail, MessageSchema, MessageType
from pydantic import EmailStr
from dotenv import load_dotenv

load_dotenv()

conf = ConnectionConfig(
    MAIL_USERNAME=os.getenv("MAIL_USERNAME"),
    MAIL_PASSWORD=os.getenv("MAIL_PASSWORD"),
    MAIL_FROM=os.getenv("MAIL_FROM"),
    MAIL_PORT=int(os.getenv("MAIL_PORT", 587)),
    MAIL_SERVER=os.getenv("MAIL_SERVER"),
    MAIL_FROM_NAME=os.getenv("MAIL_FROM_NAME"),
    MAIL_STARTTLS=os.getenv("MAIL_STARTTLS") == "True",
    MAIL_SSL_TLS=os.getenv("MAIL_SSL_TLS") == "True",
    USE_CREDENTIALS=os.getenv("USE_CREDENTIALS") == "True",
    VALIDATE_CERTS=os.getenv("VALIDATE_CERTS") == "True"
)

class EmailService:
    @staticmethod
    async def send_reply_email(client_email: EmailStr, subject: str, reply_body: str, original_message: str):
        body = f"""Bonjour,

C’est le centre SmartCane.

Nous vous confirmons que nous avons bien reçu votre message concernant votre demande.

Message reçu :
"{original_message}"

Notre équipe vous répond :

"{reply_body}"

Si vous avez besoin d’une assistance supplémentaire, n’hésitez pas à nous recontacter.

Cordialement,
L’équipe SmartCane"""

        message = MessageSchema(
            subject=subject,
            recipients=[client_email],
            body=body,
            subtype=MessageType.plain
        )

        fm = FastMail(conf)
        await fm.send_message(message)
