from marshmallow import fields, validate

from ..extensions import ma
from ..models import Blacklist


class BlacklistInputSchema(ma.Schema):
    """Valida el cuerpo de la solicitud POST /blacklists."""

    email = fields.Email(required=True)
    app_uuid = fields.UUID(required=True)
    blocked_reason = fields.String(
        required=False, allow_none=True, validate=validate.Length(max=255)
    )


class BlacklistSchema(ma.SQLAlchemyAutoSchema):
    class Meta:
        model = Blacklist
        load_instance = False
