from flask import request
from flask_restx import Resource
from app.util.user_dto import UserDto
from app.helpers.auth_helpers import token_required

ns = UserDto.api

@ns.route('/me')
class UserMe(Resource):
    @ns.doc('Get current user profile')
    @ns.doc(security="apikey")
    @token_required
    def get(self, current_user, *args, **kwargs):
        """
        Returns the profile of the currently logged-in user
        """
        return {
            'status': 1,
            'data': {
                'public_id': current_user.public_id,
                'email': current_user.email,
                'name': current_user.name,
                'fcm_token': current_user.fcm_tokens[-1].token if current_user.fcm_tokens else None
            }
        }, 200

    @ns.doc('Update current user profile')
    @ns.doc(security="apikey")
    @token_required
    def put(self, current_user, *args, **kwargs):
        """
        Updates the profile or FCM token of the currently logged-in user
        """
        from app.helpers.notification_method import NotificationMethod
        data = request.json
        if not data:
            return {'status': 0, 'message': 'No data provided'}, 400

        # Update name if provided
        if 'name' in data:
            current_user.name = data.get('name')

        # Update FCM Token if provided
        fcm_token = data.get('fcm_token')
        if fcm_token:
            NotificationMethod.save_fcm_token(current_user.id, fcm_token)

        from .. import db
        db.session.add(current_user)
        db.session.commit()

        return {
            'status': 1,
            'message': 'Profile updated successfully'
        }, 200
