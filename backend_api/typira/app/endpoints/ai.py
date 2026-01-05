from flask import request
from flask_restx import Resource, reqparse
from werkzeug.datastructures import FileStorage

from app.util.ai_dto import AIDto
from app.business.gemini_business import GeminiBusiness
from app.helpers.auth_helpers import token_required

ns = AIDto.api

upload_parser = ns.parser()
upload_parser.add_argument('audio_file', location='files',
                           type=FileStorage, required=True)

@ns.route('/speech_to_text')
@ns.expect(upload_parser)
class SpeechToText(Resource):
    @ns.doc('Receives an audio file and transcribes it.')
    @ns.doc(security="apikey")
    @token_required
    def post(self, **kwargs):
        """Receives an audio file and transcribes it."""
        args = upload_parser.parse_args()
        audio_file = args['audio_file']
        return GeminiBusiness.speech_to_text(audio_file)

analyze_parser = ns.parser()
analyze_parser.add_argument('text', type=str, required=True, location='json', help='The text content typed by the user')
analyze_parser.add_argument('app_context', type=str, required=False, location='json', help='The app package name or context identifier')

@ns.route('/analyze')
@ns.expect(analyze_parser)
class AnalyzeResource(Resource):
    @ns.doc('Analyzes text context and saves history.')
    @ns.doc(security="apikey")
    @token_required
    def post(self, current_user, **kwargs):
        """Receives text context, saves history, and returns agent thoughts."""
        from app.models.context import TypingHistory
        from app import db
        import datetime

        args = analyze_parser.parse_args()
        text_content = args['text']
        app_context = args.get('app_context')

        # 1. Save to History (The "Marathon Context")
        history_entry = TypingHistory(
            user_id=current_user.id,
            content=text_content,
            app_context=app_context,
            timestamp=datetime.datetime.utcnow()
        )
        db.session.add(history_entry)
        db.session.commit()

        # 2. (Future) Trigger "Thought Trace" analysis here
        # For now, return a placeholder acknowledgement
        return {
            "status": "success",
            "message": "Context ingested",
            "thought_trace": "Analyzing context...",
            "suggested_actions": []
        }, 200















