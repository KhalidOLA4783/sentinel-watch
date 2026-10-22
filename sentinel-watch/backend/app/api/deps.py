import base64
import hashlib
import hmac
import json
import secrets
import time
from typing import Optional, Dict, Any
from datetime import datetime, timedelta
from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from sqlalchemy.orm import Session

from app.config import settings
from app.database import get_db
from app.models.user import User

security_scheme = HTTPBearer(auto_error=False)

def b64url_encode(data: bytes) -> str:
    return base64.urlsafe_b64encode(data).decode("utf-8").rstrip("=")

def b64url_decode(data_str: str) -> bytes:
    padding = '=' * (-len(data_str) % 4)
    return base64.urlsafe_b64decode(data_str + padding)

def create_access_token(data: Dict[str, Any], expires_delta: Optional[timedelta] = None) -> str:
    """
    Génère un JWT signé avec HMAC-SHA256 (sans dépendance externe tierce).
    """
    header = {"alg": "HS256", "typ": "JWT"}
    payload = data.copy()
    now = int(time.time())
    if expires_delta:
        expire = now + int(expires_delta.total_seconds())
    else:
        expire = now + (settings.ACCESS_TOKEN_EXPIRE_MINUTES * 60)
    payload.update({"iat": now, "exp": expire})

    encoded_header = b64url_encode(json.dumps(header, separators=(",", ":")).encode("utf-8"))
    encoded_payload = b64url_encode(json.dumps(payload, separators=(",", ":")).encode("utf-8"))
    signing_input = f"{encoded_header}.{encoded_payload}".encode("utf-8")

    signature = hmac.new(settings.SECRET_KEY.encode("utf-8"), signing_input, hashlib.sha256).digest()
    encoded_sig = b64url_encode(signature)

    return f"{encoded_header}.{encoded_payload}.{encoded_sig}"

def decode_access_token(token: str) -> Dict[str, Any]:
    """
    Valide et déchiffre le JWT en temps constant.
    """
    parts = token.split(".")
    if len(parts) != 3:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Format de jeton d'authentification invalide.",
            headers={"WWW-Authenticate": "Bearer"},
        )
    encoded_header, encoded_payload, encoded_sig = parts
    signing_input = f"{encoded_header}.{encoded_payload}".encode("utf-8")
    expected_sig = hmac.new(settings.SECRET_KEY.encode("utf-8"), signing_input, hashlib.sha256).digest()

    try:
        sig_bytes = b64url_decode(encoded_sig)
    except Exception:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Signature de jeton invalide.",
            headers={"WWW-Authenticate": "Bearer"},
        )

    if not secrets.compare_digest(expected_sig, sig_bytes):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Signature de jeton non reconnue.",
            headers={"WWW-Authenticate": "Bearer"},
        )

    try:
        payload = json.loads(b64url_decode(encoded_payload).decode("utf-8"))
    except Exception:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Contenu de jeton illisible.",
            headers={"WWW-Authenticate": "Bearer"},
        )

    # Vérification de l'expiration
    exp = payload.get("exp")
    if exp is not None and time.time() > exp:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Session expirée. Veuillez vous reconnecter.",
            headers={"WWW-Authenticate": "Bearer"},
        )

    return payload

def hash_password(password: str, salt: Optional[str] = None) -> str:
    """
    Hachage PBKDF2-HMAC-SHA256 avec sel aléatoire par utilisateur.
    Format retourné : pbkdf2_sha256$iterations$salt$hash
    """
    if not salt:
        salt = secrets.token_hex(16)
    iterations = 100000
    derived = hashlib.pbkdf2_hmac("sha256", password.encode("utf-8"), salt.encode("utf-8"), iterations)
    return f"pbkdf2_sha256${iterations}${salt}${derived.hex()}"

def verify_password(plain_password: str, hashed_password: str) -> bool:
    """
    Vérifie le mot de passe en temps constant.
    Prend en charge le format PBKDF2 avec sel dynamique et rétrocompatible.
    """
    if hashed_password.startswith("pbkdf2_sha256$"):
        try:
            _, iter_str, salt, target_hash = hashed_password.split("$")
            iterations = int(iter_str)
            computed = hashlib.pbkdf2_hmac("sha256", plain_password.encode("utf-8"), salt.encode("utf-8"), iterations).hex()
            return secrets.compare_digest(computed, target_hash)
        except Exception:
            return False
    # Rétrocompatibilité avec l'ancien sel statique s'il y a lieu
    legacy_salt = b"sentinelwatch_secure_salt_2026"
    legacy_hash = hashlib.pbkdf2_hmac("sha256", plain_password.encode("utf-8"), legacy_salt, 100000).hex()
    return secrets.compare_digest(legacy_hash, hashed_password)

def get_current_user(
    auth: Optional[HTTPAuthorizationCredentials] = Depends(security_scheme),
    db: Session = Depends(get_db)
) -> User:
    """
    Dépendance FastAPI d'extraction et de validation de l'utilisateur authentifié.
    """
    if not auth or not auth.credentials:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Authentification requise pour cette ressource.",
            headers={"WWW-Authenticate": "Bearer"},
        )
    payload = decode_access_token(auth.credentials)
    user_id = payload.get("sub")
    if user_id is None:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Identifiant utilisateur absent du jeton.",
            headers={"WWW-Authenticate": "Bearer"},
        )
    user = db.query(User).filter(User.id == int(user_id)).first()
    if not user:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Utilisateur inexistant ou supprimé.",
            headers={"WWW-Authenticate": "Bearer"},
        )
    return user

def require_role(*allowed_roles: str):
    """
    Générateur de dépendance RBAC : autorise l'accès uniquement aux rôles spécifiés.
    """
    def role_checker(current_user: User = Depends(get_current_user)) -> User:
        if current_user.role not in allowed_roles:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail=f"Action non autorisée pour le rôle '{current_user.role}'."
            )
        return current_user
    return role_checker
