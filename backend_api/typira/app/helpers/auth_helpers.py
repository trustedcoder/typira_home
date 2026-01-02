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
        except IndexError:
            return {'status': 0, 'message': 'Bearer token malformed'}, 401

        decoded_token = User.decode_auth_token(auth_token)
        print(decoded_token)
        if decoded_token['status'] == 0:
            return decoded_token, 401

        kwargs['user_id'] = decoded_token['user_id']
        return f(*args, **kwargs)
    return decorated
