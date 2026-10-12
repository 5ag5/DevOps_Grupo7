from datetime import datetime

from ..extensions import db


class Blacklist(db.Model):
    __tablename__ = "blacklists"

    id = db.Column(db.Integer, primary_key=True)
    email = db.Column(db.String(255), nullable=False, unique=True, index=True)
    app_uuid = db.Column(db.String(36), nullable=False)
    blocked_reason = db.Column(db.String(255), nullable=True)
    ip_address = db.Column(db.String(45), nullable=False)  # 45 = longitud máxima IPv6
    created_at = db.Column(db.DateTime, nullable=False, default=datetime.utcnow)
