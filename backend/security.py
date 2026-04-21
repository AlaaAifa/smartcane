import bcrypt

def get_password_hash(password: str) -> str:
    # On encode le mot de passe en bytes (limité à 72 caractères par bcrypt)
    pwd_bytes = password.encode('utf-8')
    # On génère un sel et on hache
    salt = bcrypt.gensalt()
    hashed = bcrypt.hashpw(pwd_bytes, salt)
    return hashed.decode('utf-8')

def verify_password(plain_password: str, hashed_password: str) -> bool:
    try:
        password_byte_enc = plain_password.encode('utf-8')
        hashed_password_enc = hashed_password.encode('utf-8')
        return bcrypt.checkpw(password_byte_enc, hashed_password_enc)
    except Exception:
        # En cas d'erreur (ex: mauvais format de hash), on refuse la connexion
        return False
