from flask_restful import Api

from .resources import BlacklistListResource, BlacklistResource


def register_routes(app):
    api = Api(app)
    api.add_resource(BlacklistListResource, "/blacklists")
    api.add_resource(BlacklistResource, "/blacklists/<string:email>")
