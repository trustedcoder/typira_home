from flask import request
from flask_restx import Resource
from ..util.memory_dto import MemoryDto
from ..models.context import Memory, TypingHistory, UserAction
from ..helpers.time_helpers import get_time_ago
from ..helpers.auth_helpers import token_required
from .. import db

api = MemoryDto.api
_memory_item = MemoryDto.memory_item
_pagination_model = MemoryDto.pagination_model

@api.route('/memories')
class MemoryList(Resource):
    @api.doc('list_memories')
    @api.marshal_with(_pagination_model)
    @token_required
    def get(self, current_user, *args, **kwargs):
        """List all memories for the user (paginated)"""
        page = request.args.get('page', 1, type=int)
        per_page = request.args.get('per_page', 20, type=int)
        
        pagination = Memory.query.filter_by(user_id=current_user.id).order_by(Memory.timestamp.desc()).paginate(page=page, per_page=per_page, error_out=False)
        
        items = []
        for item in pagination.items:
            items.append({
                'id': f"mem_{item.id}",
                'title': item.tags if item.tags else "Memory",
                'content': item.content,
                'icon': "🧠",
                'time_ago': get_time_ago(item.timestamp),
                'timestamp': item.timestamp
            })
        print(items)
            
        return {
            'items': items,
            'total': pagination.total,
            'pages': pagination.pages,
            'current_page': pagination.page,
            'has_next': pagination.has_next,
            'has_prev': pagination.has_prev
        }

@api.route('/typing-history')
class TypingHistoryList(Resource):
    @api.doc('list_typing_history')
    @api.marshal_with(_pagination_model)
    @token_required
    def get(self, current_user, *args, **kwargs):
        """List all typing history for the user (paginated)"""
        page = request.args.get('page', 1, type=int)
        per_page = request.args.get('per_page', 20, type=int)
        
        pagination = TypingHistory.query.filter_by(user_id=current_user.id).order_by(TypingHistory.timestamp.desc()).paginate(page=page, per_page=per_page, error_out=False)
        
        items = []
        for item in pagination.items:
            items.append({
                'id': f"type_{item.id}",
                'title': item.app_context if item.app_context else "Typing History",
                'content': item.content,
                'icon': "⌨️",
                'time_ago': get_time_ago(item.timestamp),
                'timestamp': item.timestamp
            })
            
        return {
            'items': items,
            'total': pagination.total,
            'pages': pagination.pages,
            'current_page': pagination.page,
            'has_next': pagination.has_next,
            'has_prev': pagination.has_prev
        }

@api.route('/user-actions')
class UserActionList(Resource):
    @api.doc('list_user_actions')
    @api.marshal_with(_pagination_model)
    @token_required
    def get(self, current_user, *args, **kwargs):
        """List all user actions (approved/declined) (paginated)"""
        page = request.args.get('page', 1, type=int)
        per_page = request.args.get('per_page', 20, type=int)
        
        pagination = UserAction.query.filter_by(user_id=current_user.id).order_by(UserAction.timestamp.desc()).paginate(page=page, per_page=per_page, error_out=False)
        
        items = []
        for item in pagination.items:
            icon = "✅" if item.decision == 'approved' else "❌"
            title = "Action Approved" if item.decision == 'approved' else "Action Declined"
            
            items.append({
                'id': f"act_{item.id}",
                'title': title,
                'content': item.context if item.context else item.action_id,
                'icon': icon,
                'time_ago': get_time_ago(item.timestamp),
                'timestamp': item.timestamp
            })
            
        return {
            'items': items,
            'total': pagination.total,
            'pages': pagination.pages,
            'current_page': pagination.page,
            'has_next': pagination.has_next,
            'has_prev': pagination.has_prev
        }
