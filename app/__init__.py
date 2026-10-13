import socket

from flask import Flask
from sqlalchemy import text

from .api import register_routes
from .config import Config
from .extensions import db, ma

APP_VERSION = "v1"   # cámbielo en cada despliegue: v2, v3...


def create_app(config_overrides=None):
    app = Flask(__name__)
    app.config.from_object(Config)
    if config_overrides:
        app.config.update(config_overrides)

    db.init_app(app)
    ma.init_app(app)
    register_routes(app)

    @app.route("/health")
    def health():
        try:
            db.session.execute(text("SELECT 1"))
            return {"status": "ok", "database": "up",
                    "version": APP_VERSION, "host": socket.gethostname()}, 200
        except Exception:
            return {"status": "error", "database": "down",
                    "version": APP_VERSION, "host": socket.gethostname()}, 500

    with app.app_context():
        db.create_all()

    return app