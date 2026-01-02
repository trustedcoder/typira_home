from .. import db,flask_bcrypt
import datetime
import jwt
import logging
from app.models.blacklisted_tokens import BlacklistToken
from config import key

class User(db.Model):
    __tablename__ = "users"

    id = db.Column(db.Integer, primary_key=True, autoincrement=True)
    public_id = db.Column(db.String(225), unique=True, nullable=True)
    email = db.Column(db.String(225), unique=True, nullable=True)
    password = db.Column(db.String(225), nullable=True)
    is_email_verified = db.Column(db.Boolean, default=False)

    def __repr__(self):
        return "{}".format(self.email)

    @staticmethod
    def generate_password(pass_word):
        return flask_bcrypt.generate_password_hash(pass_word).decode('utf-8')

    @staticmethod
    def check_password(password, pass_word):
        return flask_bcrypt.check_password_hash(password, pass_word)

    def encode_auth_token(self, public_id):
        """
        Generates the Auth Token
        """
        try:
            payload = {
                'exp': datetime.datetime.now(datetime.timezone.utc) + datetime.timedelta(days=30, seconds=5),
                'iat': datetime.datetime.now(datetime.timezone.utc),
                'sub': public_id
            }
            auth_token = jwt.encode(
                payload,
                key,
                algorithm='HS256'
            )
            response_object = {
                'status': 1,
                'message': 'Authorization Token generated successfully',
                'token': auth_token,
            }
            return response_object
        except Exception as e:
            response_object = {
                'status': 0,
                'message': 'An error occurred. Try Again',
            }
            return response_object

    @staticmethod
    def decode_auth_token(auth_token):
        """
        Decodes the auth token
        """
        try:
            payload = jwt.decode(auth_token, key, algorithms=['HS256'])
            is_blacklisted_token = BlacklistToken.check_blacklist(auth_token)
            if is_blacklisted_token:
                response_object = {
                    'status': 0,
                    'message': 'Please log in again.',
                }
                return response_object
            else:
                user = User.query.filter_by(public_id=payload['sub']).first()
                if user:
                    response_object = {
                        'status': 1,
                        'message': 'Authorization Token Decoded successfully',
                        'user_id': user.id,
                        'expire_date': payload['exp'],
                    }
                    return response_object
                else:
                    response_object = {
                        'status': 0,
                        'message': 'Please log in again.',
                    }
                    return response_object
        except jwt.ExpiredSignatureError:
            response_object = {
                'status': 0,
                'message': 'Blocked.',
            }
            return response_object
        except Exception as e:
            logging.error('{}'.format(e))
            response_object = {
                'status': 0,
                'message': 'Blocked.',
            }
            return response_object