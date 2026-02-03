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

        from app.helpers.notification_method import NotificationMethod
        new_user = User(
            email=data['email'],
            password=User.generate_password(data['password']),
            public_id=str(uuid.uuid4()),
            name=data['name']
        )
        db.session.add(new_user)
        db.session.commit()

        # Save FCM Token if provided
        fcm_token = data.get('fcm_token')
        if fcm_token:
            NotificationMethod.save_fcm_token(new_user.id, fcm_token)

        response_object = AuthBusiness.login_user(data)
        return response_object

    @staticmethod
    def login_user(data):
        try:
            from app.helpers.notification_method import NotificationMethod
            # fetch the user data
            user = User.query.filter(User.email == data['email']).first()
            if user and User.check_password(user.password, data['password']):
                auth_response = user.encode_auth_token(user.public_id)
                if auth_response['status'] == 1:
                    # Update FCM Token if provided
                    fcm_token = data.get('fcm_token')
                    if fcm_token:
                        NotificationMethod.save_fcm_token(user.id, fcm_token)

                    response_object = {
                        'status': 1,
                        'public_id': user.public_id,
                        'name': user.name,
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
            return response_object, 409

    @staticmethod
    def delete_user(public_id):
        try:
            user = User.query.filter_by(public_id=public_id).first()
            if not user:
                return {'status': 0, 'message': 'User not found'}, 404
            
            # Clean up related data - Schedules, Memories, etc.
            # (Assuming cascades are handled in models or manual cleanup here)
            # For Typira, we should ensure all history and memories linked to this user are purged.
            
            db.session.delete(user)
            db.session.commit()
            
            return {'status': 1, 'message': 'Account and all data deleted successfully.'}
        except Exception as e:
            db.session.rollback()
            return {'status': 0, 'message': f'Could not delete account: {str(e)}'}, 500