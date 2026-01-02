from flask_restx import Namespace, fields

class AIDto:
    api = Namespace("ai", description="AI related operations")
