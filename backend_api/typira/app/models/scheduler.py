from .. import db
import datetime

class Schedule(db.Model):
    __tablename__ = "schedules"

    id = db.Column(db.Integer, primary_key=True, autoincrement=True)
    user_id = db.Column(db.Integer, db.ForeignKey('users.id'), nullable=False)
    title = db.Column(db.String(255), nullable=False)
    action_description = db.Column(db.Text, nullable=True)
    timezone = db.Column(db.String(50), nullable=False, default="UTC")
    date_or_repeat = db.Column(db.String(100), nullable=False) # e.g., "Everyday", "Monday", or "2026-01-25"
    time = db.Column(db.String(10), nullable=False) # "HH:mm"
    is_repeat = db.Column(db.Boolean, default=False)
    timestamp = db.Column(db.DateTime, default=datetime.datetime.utcnow)
    last_run = db.Column(db.DateTime, nullable=True)

    def __repr__(self):
        return f"<Schedule '{self.title}' for User {self.user_id}>"
