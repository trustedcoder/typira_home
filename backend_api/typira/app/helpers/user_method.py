from app.models.users import User
from app import db


class UserMethod:
    @staticmethod
    def check_if_user_email_exists(email):
        return User.query.filter_by(email=email).first()

    @staticmethod
    def get_user_email(user_id):
        user = User.query.filter(User.id == user_id).first()
        if user:
            return user.email
        return ''