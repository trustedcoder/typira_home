from functools import wraps
from flask import request
from app.models.users import User

def token_required(f):
    @wraps(f)
    def decorated(*args, **kwargs):
        auth_header = request.headers.get('Authorization')
        if not auth_header:
            return {'status': 0, 'message': 'Authorization header missing'}, 401

        try:
            auth_token = auth_header
            if auth_token.startswith("Bearer "):
                auth_token = auth_token[7:]

            print(auth_token)
        except IndexError:
            return {'status': 0, 'message': 'Bearer token malformed'}, 401

        decoded_token = User.decode_auth_token(auth_token)
        print(decoded_token)
        if decoded_token['status'] == 0:
            return decoded_token, 401

        user_id = decoded_token['user_id']
        current_user = User.query.filter_by(id=user_id).first()
        if not current_user:
            return {'status': 0, 'message': 'User not found'}, 404

        kwargs['user_id'] = user_id
        kwargs['current_user'] = current_user
        return f(*args, **kwargs)
    return decorated
