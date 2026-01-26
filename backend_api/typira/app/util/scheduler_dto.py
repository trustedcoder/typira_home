from flask_restx import Namespace, fields

class SchedulerDto:
    api = Namespace('scheduler', description='Scheduler related operations')
    
    schedule = api.model('schedule', {
        'id': fields.Integer(readOnly=True, description='The unique identifier of the schedule'),
        'title': fields.String(required=True, description='Title of the schedule'),
        'action_description': fields.String(description='What the AI should do'),
        'timezone': fields.String(description='Timezone for the schedule'),
        'date_or_repeat': fields.String(required=True, description='Date or repeat frequency'),
        'time': fields.String(required=True, description='Time of day (HH:mm)'),
        'is_repeat': fields.Boolean(description='Whether the schedule repeats'),
        'timestamp': fields.DateTime(readOnly=True, description='Creation timestamp'),
        'last_run': fields.DateTime(readOnly=True, description='Last time the schedule was executed')
    })
