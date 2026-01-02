from flask_restx import Namespace, fields

class AuthDto:
    api = Namespace("auth", description="Authentication related operations")

    login_model = api.model('login', {
        'email': fields.String(required=True, description='User email'),
        'password': fields.String(required=True, description='User password'),
    })

    registration_model = api.model('register', {
        'email': fields.String(required=True, description='User email'),
        'password': fields.String(required=True, description='User password'),
    })
