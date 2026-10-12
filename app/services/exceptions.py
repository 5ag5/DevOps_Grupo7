class EmailAlreadyBlacklisted(Exception):
    """El email ya existe en la lista negra global."""

    def __init__(self, email):
        self.email = email
        super().__init__(f"El email {email} ya se encuentra en la lista negra global")
