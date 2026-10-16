import os


class Config:
    # Ejemplo PostgreSQL: postgresql://usuario:password@localhost:5432/blacklist_db
    SQLALCHEMY_DATABASE_URI = os.environ.get("DATABASE_URL", "sqlite:///blacklist.db")
    SQLALCHEMY_TRACK_MODIFICATIONS = False

    # Clave con la que Flask-JWT-Extended firma y valida los tokens.
    # Nunca se debe escribir el valor real aquí: se lee de la variable de entorno.
    JWT_SECRET_KEY = os.environ.get("JWT_SECRET_KEY")

    # Flask-RESTful captura las excepciones de los recursos y respondería 500;
    # así llegan a los manejadores de error de Flask-JWT-Extended (401/403).
    PROPAGATE_EXCEPTIONS = True
