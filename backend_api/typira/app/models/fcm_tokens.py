from .. import db
import datetime


class FCMTokens(db.Model):
    """
    FCMTokens Model for storing fcm_tokens of users
    """
    __tablename__ = 'fcm_tokens'

    id = db.Column(db.Integer, primary_key=True, autoincrement=True)
    user_id = db.Column(db.Integer, db.ForeignKey("users.id"), nullable=False)
    token = db.Column(db.String(190), nullable=True)
    date_created = db.Column(db.DateTime, default=datetime.datetime.now())

    user = db.relationship('User', back_populates='fcm_tokens')

    def __init__(self, user_id, token):
        self.user_id = user_id
        self.token = token

    def __repr__(self):
        return f"{self.user_id, self.token}"