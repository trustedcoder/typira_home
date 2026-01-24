from flask import request
from flask_restx import Resource
from app.util.insights_dto import InsightsDto
from app.helpers.auth_helpers import token_required
from app.models.insights import UserInsight
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
        
        # If no insight record exists yet, return default initial values
        if not insight:
            return {
                'status': 1,
                'data': {
                    'timeSavedMinutes': 0,
                    'wordsPolished': 0,
                    'focusScore': 85,
                    'currentMood': "Steady",
                    'stressLevel': 20,
                    'healthScore': 90,
                    'energyLevel': "Stable",
                    'toneProfile': "Neutral",
                    'activityData': [],
                    'interactionModeData': [
                        {'label': 'Vision', 'value': 0, 'color': '0xFF00E5FF'},
                        {'label': 'Voice', 'value': 0, 'color': '0xFFD500F9'},
                        {'label': 'Text', 'value': 0, 'color': '0xFF2979FF'}
                    ]
                }
            }, 200

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
                # For activityData and interactionModeData, we still use mock/empty structure for now
                # until we implement the logging for those specific metrics.
                'activityData': [
                    {'x': 0, 'y': 3},
                    {'x': 1, 'y': 4},
                    {'x': 2, 'y': 3.5},
                    {'x': 3, 'y': 5},
                    {'x': 4, 'y': 8},
                    {'x': 5, 'y': 6},
                    {'x': 6, 'y': 7}
                ] if insight.time_saved_minutes > 0 else [],
                'interactionModeData': [
                    {'label': 'Vision', 'value': 40, 'color': '0xFF00E5FF'},
                    {'label': 'Voice', 'value': 35, 'color': '0xFFD500F9'},
                    {'label': 'Text', 'value': 25, 'color': '0xFF2979FF'}
                ] if insight.time_saved_minutes > 0 else [
                    {'label': 'Vision', 'value': 0, 'color': '0xFF00E5FF'},
                    {'label': 'Voice', 'value': 0, 'color': '0xFFD500F9'},
                    {'label': 'Text', 'value': 0, 'color': '0xFF2979FF'}
                ]
            }
        }, 200
