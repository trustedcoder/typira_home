from flask import Blueprint
from flask_restx import Api
import os
from .endpoints.auth_endpoints import ns as auth_namespace
from .endpoints.ai import ns as ai_namespace
from .endpoints.user_endpoints import ns as user_namespace
from .endpoints.insights_endpoints import ns as insights_namespace
from .endpoints.memory_endpoints import api as memory_namespace
from .endpoints.scheduler_endpoints import ns as scheduler_namespace

# version 1
blueprint = Blueprint("api", __name__, url_prefix="/api")


authorizations = {"apikey": {"type": "apiKey", "in": "header", "name": "Authorization"}}

if os.getenv("ENV","dev") == 'prod':
    # swagger_doc = False
    swagger_doc = "/doc/"

else:
    swagger_doc = "/doc/"


api = Api(
    blueprint,
    title="Typira Agentic Keyboard Api",
    version="1.0",
    authorizations=authorizations,
    doc=swagger_doc,
)
api.add_namespace(auth_namespace)
api.add_namespace(ai_namespace)
api.add_namespace(user_namespace)
api.add_namespace(insights_namespace)
api.add_namespace(memory_namespace)
api.add_namespace(scheduler_namespace)
