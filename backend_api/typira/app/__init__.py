from flask import Flask
from flask_sqlalchemy import SQLAlchemy
from config import config_by_name
from flask_cors import CORS
from flask_bcrypt import Bcrypt
from flask.cli import FlaskGroup


db = SQLAlchemy()
flask_bcrypt = Bcrypt()
cors = CORS()
flask_cli = FlaskGroup()


def create_app(config_name):
    app = Flask(__name__,)
    app.config.from_object(config_by_name[config_name])

    from app.api import blueprint
    app.register_blueprint(blueprint)

    db.init_app(app)
    cors.init_app(app)
    flask_bcrypt.init_app(app)

    return app
