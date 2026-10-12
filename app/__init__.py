from flask import Flask

from .api import register_routes
from .config import Config
from .extensions import db, ma


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
        return {"status": "ok"}, 200

    with app.app_context():
        db.create_all()

    return app
