from ..models import Blacklist
from ..repositories import BlacklistRepository
from .exceptions import EmailAlreadyBlacklisted


class BlacklistService:
    """Capa de negocio: reglas de la lista negra global, sin dependencias de HTTP."""

    def __init__(self, repository=None):
        self.repository = repository or BlacklistRepository()

    @staticmethod
    def normalize_email(email):
        return email.strip().lower()

    def add_email(self, email, app_uuid, ip_address, blocked_reason=None):
        email = self.normalize_email(email)
        if self.repository.find_by_email(email):
            raise EmailAlreadyBlacklisted(email)

        entry = Blacklist(
            email=email,
            app_uuid=str(app_uuid),
            blocked_reason=blocked_reason,
            ip_address=ip_address,
        )
        return self.repository.save(entry)

    def get_entry(self, email):
        """Retorna el registro si el email está en la lista negra, o None."""
        return self.repository.find_by_email(self.normalize_email(email))
