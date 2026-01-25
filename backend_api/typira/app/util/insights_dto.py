from flask_restx import Namespace, fields

class InsightsDto:
    api = Namespace('insights', description='insights related operations')
    
    activity_spot = api.model('activity_spot', {
        'x': fields.Float(required=True, description='x value (e.g. day index)'),
        'y': fields.Float(required=True, description='y value (e.g. activity value)')
    })

    interaction_slice = api.model('interaction_slice', {
        'label': fields.String(required=True),
        'value': fields.Float(required=True),
        'color': fields.String(required=True)
    })

    stats = api.model('insights_stats', {
        'timeSavedMinutes': fields.Integer(description='Time saved in minutes'),
        'wordsPolished': fields.Integer(description='Words polished'),
        'focusScore': fields.Integer(description='Focus score (0-100)'),
        'currentMood': fields.String(description='Current mood'),
        'stressLevel': fields.Integer(description='Stress level (0-100)'),
        'healthScore': fields.Integer(description='Health score (0-100)'),
        'energyLevel': fields.String(description='Energy level'),
        'toneProfile': fields.String(description='Tone profile'),
        'sentiment': fields.String(description='Categorical sentiment (positive/negative/neutral)'),
        'moodEmoji': fields.String(description='Current mood emoji'),
        'moodColor': fields.String(description='Current mood hex color'),
        'stressEmoji': fields.String(description='Stress emoji'),
        'stressConclusion': fields.String(description='Stress conclusion'),
        'stressColor': fields.String(description='Stress hex color'),
        'energyEmoji': fields.String(description='Energy emoji'),
        'energyConclusion': fields.String(description='Energy conclusion'),
        'energyColor': fields.String(description='Energy hex color'),
        'toneEmoji': fields.String(description='Tone emoji'),
        'toneConclusion': fields.String(description='Tone conclusion'),
        'toneColor': fields.String(description='Tone hex color'),
        'activityData': fields.List(fields.Nested(activity_spot)),
        'interactionModeData': fields.List(fields.Nested(interaction_slice))
    })
