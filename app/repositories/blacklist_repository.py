from ..extensions import db
from ..models import Blacklist


class BlacklistRepository:
    """Capa de acceso a datos: único punto que interactúa con la base de datos."""

    def find_by_email(self, email):
        return Blacklist.query.filter_by(email=email).first()

    def save(self, entry):
        db.session.add(entry)
        db.session.commit()
        return entry
