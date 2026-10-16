from sqlalchemy.exc import IntegrityError

from ..extensions import db
from ..models import Blacklist
from ..services.exceptions import EmailAlreadyBlacklisted


class BlacklistRepository:
    """Capa de acceso a datos: único punto que interactúa con la base de datos."""

    def find_by_email(self, email):
        return Blacklist.query.filter_by(email=email).first()

    def save(self, entry):
        db.session.add(entry)
        try:
            db.session.commit()
        except IntegrityError:
            # Dos solicitudes simultáneas con el mismo email: la restricción
            # unique de la base rechaza la segunda.
            db.session.rollback()
            raise EmailAlreadyBlacklisted(entry.email)
        return entry
