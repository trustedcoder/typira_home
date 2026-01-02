import os
from dotenv import load_dotenv, find_dotenv

load_dotenv(find_dotenv())


class Config:
    SECRET_KEY = os.environ.get("SECRET_KEY")
    SQLALCHEMY_DATABASE_URI = os.environ.get("DATABASE_URL")
    SQLALCHEMY_TRACK_MODIFICATIONS = False
    SQLALCHEMY_COMMIT_ON_TEARDOWN = True
    DEBUG = True
    SWAGGER_UI_JSONEDITOR = True
    RESTPLUS_VALIDATE = True
    SWAGGER_UI_DOC_EXPANSION = 'list'


class DevelopmentConfig(Config):
    DEBUG = True


class ProductionConfig(Config):
    DEBUG = False


config_by_name = dict(
    dev=DevelopmentConfig,
    prod=ProductionConfig
)

key = Config.SECRET_KEY

# Allowed levels for TechStack
LEVEL_BEGINNER = 0
LEVEL_INTERMEDIATE = 1
LEVEL_ADVANCED = 2

PAGINATION_COUNT = 50

PIN_TYPE_PASSWORD_RESET = 0
PIN_TYPE_EMAIL_VERIFY = 1