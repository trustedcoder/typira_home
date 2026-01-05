from flask_restx import Namespace, fields

class AuthDto:
    api = Namespace("auth", description="Authentication related operations")

    login_model = api.model('login', {
        'email': fields.String(required=True, description='User email', pattern=r'(^[a-zA-Z0-9_.+-]+@[a-zA-Z0-9-]+\.[a-zA-Z0-9-.]+$)'),
        'password': fields.String(required=True, description='User password'),
    })

    registration_model = api.model('register', {
        'name': fields.String(required=True, description='name of user', pattern=r'\S+'),
        'email': fields.String(required=True, description='User email', pattern=r'(^[a-zA-Z0-9_.+-]+@[a-zA-Z0-9-]+\.[a-zA-Z0-9-.]+$)'),
        'password': fields.String(required=True, description='User password', pattern=r'\S+'),
        'fcm_token': fields.String(required=True, description='FCM token'),
    })
