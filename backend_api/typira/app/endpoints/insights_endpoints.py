from flask import request
from flask_restx import Resource
from app.util.insights_dto import InsightsDto
from app.helpers.auth_helpers import token_required
from app.models.insights import UserInsight, UserActivityHistory
import datetime
from app import db

ns = InsightsDto.api

@ns.route('/stats')
class InsightsStats(Resource):
    @ns.doc('Get insight statistics')
    @ns.doc(security="apikey")
    @token_required
    def get(self, current_user, *args, **kwargs):
        """
        Returns insight statistics for the currently logged-in user
        """
        user_id = current_user.id
        insight = UserInsight.query.filter_by(user_id=user_id).first()
        
        # If no insight record exists yet, create one with defaults
        if not insight:
            insight = UserInsight(user_id=user_id)
            db.session.add(insight)
            db.session.commit()
            # We continue with the newly created insight object and empty/default data

        # Calculate interaction mode data percentages
        total_interactions = insight.vision_count + insight.voice_count + insight.text_count
        if total_interactions > 0:
            vision_pct = (insight.vision_count / total_interactions) * 100
            voice_pct = (insight.voice_count / total_interactions) * 100
            text_pct = (insight.text_count / total_interactions) * 100
        else:
            vision_pct, voice_pct, text_pct = 0, 0, 0

        # Fetch last 7 days of activity history
        today = datetime.date.today()
        seven_days_ago = today - datetime.timedelta(days=6)
        history_records = UserActivityHistory.query.filter(
            UserActivityHistory.user_id == user_id,
            UserActivityHistory.date >= seven_days_ago
        ).order_by(UserActivityHistory.date.asc()).all()

        # Map history to activityData (x=0 to 6)
        history_map = {record.date: record.time_saved_minutes for record in history_records}
        activity_data = []
        for i in range(7):
            date = seven_days_ago + datetime.timedelta(days=i)
            minutes = history_map.get(date, 0)
            activity_data.append({'x': i, 'y': minutes})

        return {
            'status': 1,
            'data': {
                'timeSavedMinutes': insight.time_saved_minutes,
                'wordsPolished': insight.words_polished,
                'focusScore': insight.focus_score,
                'currentMood': insight.current_mood,
                'stressLevel': insight.stress_level,
                'healthScore': insight.health_score,
                'energyLevel': insight.energy_level,
                'toneProfile': insight.tone_profile,
                'sentiment': insight.sentiment,
                'moodEmoji': insight.mood_emoji or "😊",
                'moodColor': insight.mood_color or "#FFC107",
                'stressEmoji': insight.stress_emoji or "😌",
                'stressConclusion': insight.stress_conclusion or "Optimal Flow",
                'stressColor': insight.stress_color or "#40C4FF",
                'energyEmoji': insight.energy_emoji or "⚡️",
                'energyConclusion': insight.energy_conclusion or "Typing Bursts",
                'energyColor': insight.energy_color or "#FFAB40",
                'toneEmoji': insight.tone_emoji or "🗣️",
                'toneConclusion': insight.tone_conclusion or "Vocabulary Analysis",
                'toneColor': insight.tone_color or "#D500F9",
                'activityData': activity_data,
                'interactionModeData': [
                    {'label': 'Vision', 'value': round(vision_pct, 1), 'color': '#00E5FF'},
                    {'label': 'Voice', 'value': round(voice_pct, 1), 'color': '#D500F9'},
                    {'label': 'Text', 'value': round(text_pct, 1), 'color': '#2979FF'}
                ]
            }
        }, 200
