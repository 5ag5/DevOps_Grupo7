from flask_jwt_extended import JWTManager
from flask_jwt_extended.exceptions import InvalidHeaderError


def init_jwt(app):
    """Configura Flask-JWT-Extended y sus respuestas de error.

    Los endpoints protegidos usan @jwt_required. El token se genera con
    generar_token.py usando el mismo JWT_SECRET_KEY del servidor.
    """
    jwt = JWTManager(app)

    # Sin encabezado Authorization
    @jwt.unauthorized_loader
    def missing_token(reason):
        return {"msg": "Token de autorización no proporcionado"}, 401

    # Encabezado sin el formato "Bearer <token>": la librería lo trataría como
    # token inválido (403), pero se responde 401 como falta de credenciales.
    @app.errorhandler(InvalidHeaderError)
    def bad_header(error):
        return {"msg": "Token de autorización no proporcionado"}, 401

    # Token mal formado o con firma que no corresponde al JWT_SECRET_KEY
    @jwt.invalid_token_loader
    def invalid_token(reason):
        return {"msg": "Token de autorización inválido"}, 403

    @jwt.expired_token_loader
    def expired_token(expired_token):
        return {"msg": "Token de autorización expirado"}, 403

    return jwt
