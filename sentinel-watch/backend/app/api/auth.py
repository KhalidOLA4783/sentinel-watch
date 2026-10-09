import hashlib
import secrets
from datetime import datetime
from typing import Optional
from fastapi import APIRouter, Depends, HTTPException, status, Request
from sqlalchemy.orm import Session

from app.database import get_db, SessionLocal
from app.models.user import User
from app.models.log import AccessLog
from app.detection.engine import detection_engine
from app.schemas.user import UserRegister, UserLogin, UserOut, AuthResponse

router = APIRouter(prefix="/auth", tags=["Authentication & Users"])

SALT = b"sentinelwatch_secure_salt_2026"

def hash_password(password: str) -> str:
    """Hachage sécurisé du mot de passe avec PBKDF2-HMAC-SHA256 (bibliothèque standard)."""
    return hashlib.pbkdf2_hmac("sha256", password.encode("utf-8"), SALT, 100000).hex()

def verify_password(plain_password: str, hashed_password: str) -> bool:
    """Vérification en temps constant."""
    return secrets.compare_digest(hash_password(plain_password), hashed_password)

def seed_default_admin():
    """Crée l'administrateur par défaut si aucun compte n'existe encore."""
    db = SessionLocal()
    try:
        if db.query(User).count() == 0:
            default_admin = User(
                username="admin",
                email="admin@sentinelwatch.com",
                hashed_password=hash_password("Admin123!"),
                full_name="Administrateur SOC",
                role="ADMIN",
                organization="SentinelWatch SOC",
                agent_key="sw_key_master_sentinelwatch"
            )
            db.add(default_admin)
            db.commit()
        else:
            admin_user = db.query(User).filter(User.username == "admin").first()
            if admin_user and not admin_user.agent_key:
                admin_user.agent_key = "sw_key_master_sentinelwatch"
                db.commit()
    except Exception:
        pass
    finally:
        db.close()

@router.post("/register", response_model=AuthResponse, status_code=status.HTTP_201_CREATED)
def register(user_in: UserRegister, db: Session = Depends(get_db)):
    """Création d'un nouveau compte utilisateur ou analyste SOC avec son organisation."""
    # Vérification unicité username
    if db.query(User).filter(User.username == user_in.username).first():
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Ce nom d'utilisateur est déjà utilisé."
        )
    # Vérification unicité email
    if db.query(User).filter(User.email == user_in.email).first():
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Cette adresse email est déjà enregistrée."
        )

    org_name = (user_in.organization or f"SOC {user_in.username}").strip()

    new_user = User(
        username=user_in.username.strip(),
        email=user_in.email.strip().lower(),
        hashed_password=hash_password(user_in.password),
        full_name=user_in.full_name or user_in.username,
        role=user_in.role or "ADMIN",
        organization=org_name,
        agent_key=f"sw_key_{secrets.token_hex(12)}"
    )
    db.add(new_user)
    db.commit()
    db.refresh(new_user)

    token = f"sw_token_{new_user.id}_{secrets.token_hex(16)}"
    return AuthResponse(token=token, user=UserOut.model_validate(new_user))

@router.post("/login", response_model=AuthResponse)
def login(creds: UserLogin, request: Request, db: Session = Depends(get_db)):
    """Connexion d'un utilisateur par nom d'utilisateur ou email avec protection anti-bruteforce en direct."""
    client_ip = request.client.host if request.client else "127.0.0.1"
    identifier = creds.username_or_email.strip()
    user = db.query(User).filter(
        (User.username == identifier) | (User.email == identifier.lower())
    ).first()

    if not user or not verify_password(creds.password, user.hashed_password):
        # Enregistrement de l'échec d'authentification dans les logs de sécurité
        failed_log = AccessLog(
            timestamp=datetime.utcnow(),
            user_identifier=identifier or "unknown",
            ip_address=client_ip,
            http_method="POST",
            endpoint="/api/v1/auth/login",
            http_status=401,
            is_flagged=False
        )
        db.add(failed_log)
        db.commit()
        db.refresh(failed_log)

        # Déclenchement immédiat de l'analyse heuristique (Force Brute) et IA
        detection_engine.analyze_log(db, failed_log)

        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Identifiants incorrects (nom d'utilisateur ou mot de passe invalide)."
        )

    # Enregistrement de la connexion légitime
    success_log = AccessLog(
        timestamp=datetime.utcnow(),
        user_identifier=user.username,
        ip_address=client_ip,
        http_method="POST",
        endpoint="/api/v1/auth/login",
        http_status=200,
        is_flagged=False
    )
    db.add(success_log)
    db.commit()
    db.refresh(success_log)

    token = f"sw_token_{user.id}_{secrets.token_hex(16)}"
    return AuthResponse(token=token, user=UserOut.model_validate(user))

@router.get("/me", response_model=UserOut)
def get_current_user_info(db: Session = Depends(get_db)):
    """Retourne les informations du profil administrateur par défaut."""
    user = db.query(User).first()
    if not user:
        raise HTTPException(status_code=404, detail="Aucun utilisateur configuré.")
    return user
