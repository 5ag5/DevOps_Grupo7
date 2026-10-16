"""Genera el JWT que usan los clientes en 'Authorization: Bearer <token>'.

Uso (con la misma JWT_SECRET_KEY configurada en el servidor):
    PowerShell:  $env:JWT_SECRET_KEY="mi-clave-secreta"; python generar_token.py
    Bash:        JWT_SECRET_KEY=mi-clave-secreta python generar_token.py

El token no expira. Para invalidarlo, cambie JWT_SECRET_KEY en el servidor.
"""
import os
import sys

from flask import Flask
from flask_jwt_extended import JWTManager, create_access_token

IDENTITY = "blacklist-client"


def main():
    secret = os.environ.get("JWT_SECRET_KEY")
    if not secret:
        sys.exit("Defina la variable de entorno JWT_SECRET_KEY antes de generar el token.")

    app = Flask(__name__)
    app.config["JWT_SECRET_KEY"] = secret
    JWTManager(app)

    with app.app_context():
        print(create_access_token(identity=IDENTITY, expires_delta=False))


if __name__ == "__main__":
    main()
