from flask_restx import Namespace, fields

class MemoryDto:
    api = Namespace('memory', description='Memory, typing history and user actions related operations')
    
    memory_item = api.model('memory_item', {
        'id': fields.String(description='Unique identifier'),
        'title': fields.String(required=True, description='Title of the item'),
        'content': fields.String(required=True, description='Content/Description of the item'),
        'icon': fields.String(description='Emoji or icon name representing the content'),
        'time_ago': fields.String(description='Human readable time since the item was created'),
        'timestamp': fields.DateTime(description='Exact timestamp')
    })

    pagination_model = api.model('pagination', {
        'items': fields.List(fields.Nested(memory_item)),
        'total': fields.Integer(description='Total number of items'),
        'pages': fields.Integer(description='Total number of pages'),
        'current_page': fields.Integer(description='Current page number'),
        'has_next': fields.Boolean(description='Whether there is a next page'),
        'has_prev': fields.Boolean(description='Whether there is a previous page')
    })
