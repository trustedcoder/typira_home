from flask_restx import Namespace, fields

class UserDto:
    api = Namespace('user', description='user related operations')
    user_detail = api.model('user_detail', {
        'public_id': fields.String(description='user public identifier'),
        'email': fields.String(required=True, description='user email address'),
        'name': fields.String(required=True, description='user name'),
        'fcm_token': fields.String(description='firebase cloud messaging token'),
    })
