from .. import db
import datetime

class TypingHistory(db.Model):
    __tablename__ = "typing_history"

    id = db.Column(db.Integer, primary_key=True, autoincrement=True)
    user_id = db.Column(db.Integer, db.ForeignKey('users.id'))
    content = db.Column(db.Text, nullable=False)
    semantic_hash = db.Column(db.String(64), nullable=True, index=True)
    frequency = db.Column(db.Integer, default=1)
    timestamp = db.Column(db.DateTime, default=datetime.datetime.utcnow)
    app_context = db.Column(db.String(255), nullable=True)

    def __repr__(self):
        return f"<TypingHistory '{self.id}'>"

class Memory(db.Model):
    __tablename__ = "memories"

    id = db.Column(db.Integer, primary_key=True, autoincrement=True)
    user_id = db.Column(db.Integer, db.ForeignKey('users.id'))
    content = db.Column(db.Text, nullable=False)
    source_type = db.Column(db.String(255))
    tags = db.Column(db.String(255), nullable=True)
    timestamp = db.Column(db.DateTime, default=datetime.datetime.utcnow)

    def __repr__(self):
        return f"<Memory '{self.id}'>"
