from flask import request
from flask_socketio import emit
from app import socketio, db
from app.models.context import TypingHistory
# from app.helpers.auth_helpers import token_required_socket # We need a socket version of this
import datetime
import time

@socketio.on('connect')
def handle_connect():
    print(f"Client connected: {request.sid}")
    emit('con_response', {'status': 'connected'})

@socketio.on('disconnect')
def handle_disconnect():
    print(f"Client disconnected: {request.sid}")

@socketio.on('analyze')
def handle_analyze(data):
    """
    Handles typing history chunks via WebSocket.
    Expected data: {'token': '...', 'text': '...', 'app_context': '...'}
    """
    token = data.get('token')
    text = data.get('text')
    app_context = data.get('app_context')

    # 1. Verification (Simulated token_required for now)
    # Ideally, we'd use a decorator or a helper that works with Socket.IO
    # For now, let's assume verification happens in on_connect or per-message
    
    # if not token:
    #    emit('error', {'message': 'Unauthorized'})
    #    return

    print(f"Analyzing text from {request.sid}: {text}...")

    # 2. Save to DB (Persistence)
    # We save the incremental delta if provided, otherwise the full text (if it's a small chunk)
    delta = data.get('incremental_delta')
    persistence_content = delta if delta else text
    is_full = data.get('is_full_context', False)

    # Note: For typing history, we only want to persist new additions (deltas)
    # Full context snapshots are for analysis only.
    if persistence_content and not is_full:
        # history_entry = TypingHistory(
        #     user_id=1, 
        #     content=persistence_content,
        #     app_context=app_context,
        #     timestamp=datetime.datetime.utcnow()
        # )
        # db.session.add(history_entry)
        # db.session.commit()
        pass

    # We use the FULL text for analysis to ensure the agent understands the whole window
    
    emit('thought_update', {'text': 'Agent is listening...'})
    print(f"Agent is listening: {app_context}")
    socketio.sleep(3)
    print(f"Agent is listeningv: {app_context}")
    
    if "meeting" in text.lower() or "schedule" in text.lower():
        socketio.sleep(3)
        emit('thought_update', {'text': 'I detect a scheduling intent...'})
        socketio.sleep(3)
        emit('thought_update', {'text': 'Checking your calendar for availability...'})
        socketio.sleep(3)
        emit('suggestion_ready', {
            'thought': 'I found a slot tomorrow at 10 AM. Should I draft the invite?',
            'actions': [
                {'id': 'draft_invite', 'label': '📅 Draft Invite'},
                {'id': 'check_cal', 'label': '🔎 Check Calendar'}
            ]
        })
    elif "draft" in text.lower() or "email" in text.lower():
        emit('thought_update', {'text': 'Synthesizing email context...'})
        socketio.sleep(3)
        emit('suggestion_ready', {
            'thought': 'I can draft this email for you based on our previous history.',
            'actions': [
                {'id': 'draft_email', 'label': '✉️ Draft Email'},
                {'id': 'make_formal', 'label': '👔 Make Formal'}
            ]
        })
    else:
        emit('thought_update', {'text': 'Tracking context for future actions...'})
        emit('suggestion_ready', {
            'thought': 'Agent is active in the background.',
            'actions': []
        })
