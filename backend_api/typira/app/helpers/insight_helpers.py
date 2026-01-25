from app import db
from app.models.insights import UserInsight, UserActivityHistory
import datetime

def increment_user_stats(user_id, minutes=0, words=0, focus=None, 
                         mood=None, mood_emoji=None, mood_color=None,
                         stress=None, stress_conclusion=None, stress_emoji=None, stress_color=None,
                         energy=None, energy_conclusion=None, energy_emoji=None, energy_color=None,
                         tone=None, tone_conclusion=None, tone_emoji=None, tone_color=None,
                         sentiment=None, interaction_mode=None):
    """
    Increments time saved and words polished for a user.
    Updates full bio-digital metadata suite (mood, stress, energy, tone, sentiment, focus) if provided.
    Creates the record if it doesn't exist.
    """
    if not user_id:
        return
        
    insight = UserInsight.query.filter_by(user_id=user_id).first()
    
    if not insight:
        insight = UserInsight(user_id=user_id)
        db.session.add(insight)
        db.session.commit()
        db.session.flush()
        
    insight.time_saved_minutes = (insight.time_saved_minutes or 0) + minutes
    insight.words_polished = (insight.words_polished or 0) + words
    
    # 1. Update Mood
    if mood:
        insight.current_mood = mood
    if mood_emoji:
        insight.mood_emoji = mood_emoji
    if mood_color:
        insight.mood_color = mood_color

    # 2. Update Stress
    if stress is not None:
        insight.stress_level = stress
    if stress_conclusion:
        insight.stress_conclusion = stress_conclusion
    if stress_emoji:
        insight.stress_emoji = stress_emoji
    if stress_color:
        insight.stress_color = stress_color

    # 3. Update Energy
    if energy:
        insight.energy_level = energy
    if energy_conclusion:
        insight.energy_conclusion = energy_conclusion
    if energy_emoji:
        insight.energy_emoji = energy_emoji
    if energy_color:
        insight.energy_color = energy_color

    # 4. Update Tone
    if tone:
        insight.tone_profile = tone
    if tone_conclusion:
        insight.tone_conclusion = tone_conclusion
    if tone_emoji:
        insight.tone_emoji = tone_emoji
    if tone_color:
        insight.tone_color = tone_color

    # 5. Update Focus & Sentiment
    if focus is not None:
        insight.focus_score = focus
    if sentiment is not None:
        insight.sentiment = sentiment
        
    # 6. Update Interaction Mode counts
    if interaction_mode:
        mode = interaction_mode.lower()
        if mode == 'vision':
            insight.vision_count = (insight.vision_count or 0) + 1
        elif mode == 'voice':
            insight.voice_count = (insight.voice_count or 0) + 1
        elif mode == 'text':
            insight.text_count = (insight.text_count or 0) + 1

    # 7. Update Daily Activity History
    if minutes > 0:
        today = datetime.date.today()
        history = UserActivityHistory.query.filter_by(user_id=user_id, date=today).first()
        if not history:
            history = UserActivityHistory(user_id=user_id, date=today, time_saved_minutes=minutes)
            db.session.add(history)
        else:
            history.time_saved_minutes = (history.time_saved_minutes or 0) + minutes
    
    db.session.commit()
    print(f"📊 Rich Bio-Insights updated for user {user_id}: +{minutes}m, +{words}w, Mood: {mood}, Stress: {stress}, Energy: {energy}, Tone: {tone}")
