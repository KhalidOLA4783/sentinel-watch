from datetime import datetime
from typing import Optional
from pydantic import BaseModel

class UserRegister(BaseModel):
    username: str
    email: str
    password: str
    full_name: Optional[str] = None
    role: Optional[str] = "ADMIN"
    organization: Optional[str] = "SentinelWatch SOC"

class UserLogin(BaseModel):
    username_or_email: str
    password: str

class UserOut(BaseModel):
    id: int
    username: str
    email: str
    full_name: Optional[str] = None
    role: str
    organization: str
    agent_key: Optional[str] = None
    created_at: datetime

    class Config:
        from_attributes = True

class AuthResponse(BaseModel):
    token: str
    token_type: str = "bearer"
    user: UserOut

class ChangeCredentialsRequest(BaseModel):
    current_username_or_email: str
    current_password: str
    new_username: Optional[str] = None
    new_password: str

