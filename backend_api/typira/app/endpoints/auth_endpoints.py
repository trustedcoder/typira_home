from flask import request
from flask_restx import Resource
from app.util.auth_dto import AuthDto
from app.business.auth_business import AuthBusiness

ns = AuthDto.api

@ns.route('/register')
class Register(Resource):
    @ns.expect(AuthDto.registration_model)
    def post(self):
        """
        Register a new user
        """
        data = request.get_json()
        return AuthBusiness.register_user(data=data)

@ns.route('/login')
class Login(Resource):
    @ns.expect(AuthDto.login_model)  # Link the model to endpoint for docs
    def post(self):
        """
        Authenticate a user with JWT token
        """
        data = request.get_json()
        return AuthBusiness.login_user(data=data)
