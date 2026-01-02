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















