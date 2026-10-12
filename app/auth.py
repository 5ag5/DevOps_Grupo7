import hmac
from functools import wraps

from flask import current_app, request


def token_required(fn):
    """Exige el encabezado 'Authorization: Bearer <token>' con el token estático."""

    @wraps(fn)
    def wrapper(*args, **kwargs):
        auth_header = request.headers.get("Authorization", "")
        scheme, _, token = auth_header.partition(" ")

        if scheme != "Bearer" or not token:
            return {"msg": "Token de autorización no proporcionado"}, 401

        expected = current_app.config.get("STATIC_TOKEN")
        if not expected or not hmac.compare_digest(token.strip(), expected):
            return {"msg": "Token de autorización inválido"}, 403

        return fn(*args, **kwargs)

    return wrapper
