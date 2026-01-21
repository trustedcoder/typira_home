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
                'fcm_token': current_user.fcm_token
            }
        }, 200
