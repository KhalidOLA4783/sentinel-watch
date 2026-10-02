from datetime import datetime
from typing import Optional
from pydantic import BaseModel, Field

class AlertBase(BaseModel):
    alert_type: str
    severity: str
    source_ip: str
    target_user: Optional[str] = None
    description: str
    details: Optional[str] = None
    anomaly_score: Optional[float] = None

class AlertCreate(AlertBase):
    pass

class AlertUpdate(BaseModel):
    status: str = Field(..., description="PENDING, ACKNOWLEDGED, RESOLVED, FALSE_POSITIVE")

class AlertOut(AlertBase):
    id: int
    timestamp: datetime
    status: str
    log_id: Optional[int] = None

    class Config:
        from_attributes = True

class BlacklistCreate(BaseModel):
    ip_address: str
    reason: str

class BlacklistOut(BaseModel):
    id: int
    ip_address: str
    reason: str
    blocked_at: datetime
    is_active: bool

    class Config:
        from_attributes = True
