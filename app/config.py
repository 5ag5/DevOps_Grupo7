import os


class Config:
    # Ejemplo PostgreSQL: postgresql://usuario:password@localhost:5432/blacklist_db
    SQLALCHEMY_DATABASE_URI = os.environ.get("DATABASE_URL", "sqlite:///blacklist.db")
    SQLALCHEMY_TRACK_MODIFICATIONS = False

    # Token estático para el encabezado "Authorization: Bearer <token>".
    # Nunca se debe escribir el valor real aquí: se lee de la variable de entorno.
    STATIC_TOKEN = os.environ.get("STATIC_TOKEN")
