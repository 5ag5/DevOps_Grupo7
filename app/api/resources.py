from flask import request
from flask_restful import Resource
from marshmallow import ValidationError

from ..auth import token_required
from ..services import BlacklistService, EmailAlreadyBlacklisted
from .schemas import BlacklistInputSchema, BlacklistSchema

input_schema = BlacklistInputSchema()
blacklist_schema = BlacklistSchema()
service = BlacklistService()


def get_client_ip():
    # Detrás de un balanceador (p. ej. AWS), la IP real llega en X-Forwarded-For
    forwarded_for = request.headers.get("X-Forwarded-For")
    if forwarded_for:
        return forwarded_for.split(",")[0].strip()
    return request.remote_addr


class BlacklistListResource(Resource):
    method_decorators = [token_required]

    def post(self):
        payload = request.get_json(silent=True)
        if payload is None:
            return {"msg": "El cuerpo de la solicitud debe ser un JSON válido"}, 400

        try:
            data = input_schema.load(payload)
        except ValidationError as err:
            return {"msg": "Datos inválidos", "errors": err.messages}, 400

        try:
            entry = service.add_email(
                email=data["email"],
                app_uuid=data["app_uuid"],
                ip_address=get_client_ip(),
                blocked_reason=data.get("blocked_reason"),
            )
        except EmailAlreadyBlacklisted as err:
            return {"msg": str(err)}, 409

        return {
            "msg": "Email agregado a la lista negra global",
            "blacklist": blacklist_schema.dump(entry),
        }, 201


class BlacklistResource(Resource):
    method_decorators = [token_required]

    def get(self, email):
        entry = service.get_entry(email)
        if entry is None:
            return {"email": email, "is_blacklisted": False, "blocked_reason": None}, 200

        return {
            "email": entry.email,
            "is_blacklisted": True,
            "blocked_reason": entry.blocked_reason,
        }, 200
