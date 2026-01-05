import uuid
from app import db
from app.models.users import User
from app.helpers.user_method import UserMethod


class AuthBusiness:
    @staticmethod
    def register_user(data):
        if UserMethod.check_if_user_email_exists(data['email']):
            response_object = {
                'status': 0,
                'message': 'User already exists. Please Log in.',
            }
            return response_object, 409

        new_user = User(
            email=data['email'],
            password=User.generate_password(data['password']),
            public_id=str(uuid.uuid4()),
            name=data['name'],
            fcm_token=data['fcm_token'],
        )
        db.session.add(new_user)
        db.session.commit()

        response_object = AuthBusiness.login_user(data)
        return response_object

    @staticmethod
    def login_user(data):
        try:
            # fetch the user data
            user = User.query.filter(User.email == data['email']).first()
            if user and User.check_password(user.password, data['password']):
                auth_response = user.encode_auth_token(user.public_id)
                if auth_response['status'] == 1:
                    user.fcm_token = data['fcm_token']
                    db.session.commit()
                    response_object = {
                        'status': 1,
                        'public_id': user.public_id,
                        'message': 'Successfully logged in.',
                        'authorization': auth_response['token']
                    }
                    return response_object
                else:
                    response_object = {
                        'status': 0,
                        'message': auth_response['message']
                    }
                    return response_object
            else:
                response_object = {
                    'status': 0,
                    'message': 'Invalid Details.'
                }
                return response_object
        except Exception as e:
            response_object = {
                'status': 0,
                'message': f'An error occurred. Try again {e}'
            }
            return response_object,409