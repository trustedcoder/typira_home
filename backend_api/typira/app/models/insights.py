from .. import db
import datetime

class UserInsight(db.Model):
    __tablename__ = "user_insights"

    id = db.Column(db.Integer, primary_key=True, autoincrement=True)
    user_id = db.Column(db.Integer, db.ForeignKey('users.id'), unique=True)
    time_saved_minutes = db.Column(db.Integer, default=0)
    words_polished = db.Column(db.Integer, default=0)
    focus_score = db.Column(db.Integer, default=85)
    
    # Mood Metadata
    current_mood = db.Column(db.String(100), default="Steady")
    mood_emoji = db.Column(db.String(20))
    mood_color = db.Column(db.String(10))
    
    # Stress Metadata
    stress_level = db.Column(db.Integer, default=20)
    stress_conclusion = db.Column(db.String(100))
    stress_emoji = db.Column(db.String(20))
    stress_color = db.Column(db.String(10))
    
    # Energy Metadata
    energy_level = db.Column(db.String(100), default="Stable")
    energy_conclusion = db.Column(db.String(100))
    energy_emoji = db.Column(db.String(20))
    energy_color = db.Column(db.String(10))
    
    # Tone Metadata
    tone_profile = db.Column(db.String(100), default="Neutral")
    tone_conclusion = db.Column(db.String(100))
    tone_emoji = db.Column(db.String(20))
    tone_color = db.Column(db.String(10))
    
    # Sentiment (Categorical)
    sentiment = db.Column(db.String(20), default="Neutral")
    
    health_score = db.Column(db.Integer, default=90)
    last_updated = db.Column(db.DateTime, default=datetime.datetime.utcnow, onupdate=datetime.datetime.utcnow)

    def __repr__(self):
        return f"<UserInsight for user '{self.user_id}'>"
