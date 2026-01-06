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

def async_persist_context(app, user_id, text, app_context, is_full):
    """
    Background task to persist and deduplicate context.
    Includes 'Expansion Absorption' to merge fragments typed in a short window.
    """
    with app.app_context():
        from app import db
        from app.models.context import TypingHistory
        from app.helpers.atomizer import split_into_sentences, scrub_pii
        from app.helpers.semantic import get_semantic_hash
        import datetime

        atoms = split_into_sentences(text)
        num_atoms = len(atoms)
        print(f"DEBUG: [Dedupe] Processing {num_atoms} atoms from source text")
        
        for i, atom in enumerate(atoms):
            if not atom or len(atom.strip()) < 3:
                continue
                
            clean_text = scrub_pii(atom)
            is_last = (i == num_atoms - 1)
            print(f"DEBUG: [Dedupe] Atom {i+1}/{num_atoms}: '{clean_text[:30]}...' (is_last: {is_last})")
            
            # 1. Expansion Absorption Logic (Only for the last fragment/atom)
            if is_last:
                one_minute_ago = datetime.datetime.utcnow() - datetime.timedelta(seconds=60)
                last_entry = TypingHistory.query.filter(
                    TypingHistory.user_id == user_id,
                    TypingHistory.app_context == app_context,
                    TypingHistory.timestamp >= one_minute_ago
                ).order_by(TypingHistory.timestamp.desc()).first()

                if last_entry and clean_text.startswith(last_entry.content) and len(clean_text) > len(last_entry.content):
                    # Absorption: Update the previous fragment with the fuller sentence
                    s_hash = get_semantic_hash(clean_text)
                    last_entry.content = clean_text
                    last_entry.semantic_hash = s_hash
                    last_entry.timestamp = datetime.datetime.utcnow()
                    db.session.commit()
                    print(f"DEBUG: [Dedupe] ABSORBED expansion: '{clean_text[:20]}...' (Hash: {s_hash[:8] if s_hash else 'None'})")
                    continue

            # 2. Standard Semantic Deduplication / Novel Entry (Upsert)
            s_hash = get_semantic_hash(clean_text)
            if s_hash:
                existing = TypingHistory.query.filter_by(
                    user_id=user_id,
                    semantic_hash=s_hash,
                    app_context=app_context
                ).first()
                
                if existing:
                    existing.frequency += 1
                    existing.timestamp = datetime.datetime.utcnow()
                    existing.content = clean_text 
                    print(f"DEBUG: [Dedupe] UPDATED existing intent: {s_hash[:8]} (Freq: {existing.frequency})")
                else:
                    new_entry = TypingHistory(
                        user_id=user_id, 
                        content=clean_text,
                        semantic_hash=s_hash,
                        app_context=app_context,
                        timestamp=datetime.datetime.utcnow()
                    )
                    db.session.add(new_entry)
                    print(f"DEBUG: [Dedupe] CREATED new entry for intent: {s_hash[:8]}")
                
                db.session.commit()
            else:
                print(f"DEBUG: [Dedupe] SKIP: Could not generate semantic hash for atom")

@socketio.on('analyze')
def handle_analyze(data):
    """
    Handles typing history chunks via WebSocket.
    Expected data: {'token': '...', 'text': '...', 'app_context': '...'}
    """
    from flask import current_app
    text = data.get('text')
    app_context = data.get('app_context')
    is_full = data.get('is_full_context', False)

    print(f"Analyzing text from {request.sid}: {text}...")

    # Offload persistence to background thread for zero-latency suggestions
    # We pass the real app object to the thread so we can push an app context
    socketio.start_background_task(
        async_persist_context, 
        current_app._get_current_object(),
        1, text, app_context, is_full
    )

    # Analysis logic continues...
    
    emit('thought_update', {'text': 'Agent is listening...'})
    print(text)
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
                {'id': 'check_cal', 'label': '🔎 Check Calendar'},
                {'id': 'check_cal', 'label': '🔎 Check Calendar'},
                {'id': 'check_cal', 'label': '🔎 Check Calendar'},
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
