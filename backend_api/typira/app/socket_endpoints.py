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

    # --- Agentic AI Suggestion Engine (Gemini 3) ---
    from app.business.gemini_business import GeminiBusiness
    
    # 1. Gather Personal Context from TypingHistory
    # Get top 30 most frequent intents
    frequent_history = TypingHistory.query.filter_by(user_id=1).order_by(TypingHistory.frequency.desc()).limit(30).all()
    # Get last 20 recent sentences
    recent_history = TypingHistory.query.filter_by(user_id=1).order_by(TypingHistory.timestamp.desc()).limit(20).all()
    
    combined_history = list(set([h.content for h in frequent_history] + [h.content for h in recent_history]))
    
    # 2. Call the Agentic Brain
    analysis = GeminiBusiness.analyze_context(text, combined_history, app_context)
    
    # 3. Stream 'Thought Process' to UI
    thoughts = analysis.get('thoughts', [])
    for thought in thoughts:
        emit('thought_update', {'text': thought})
        socketio.sleep(10) # Allow user to read the thinking process
        
    # 4. Finalize and Show Actions
    emit('thought_update', {'text': analysis.get('final_thought', 'Ready.')})
    print(analysis.get('actions', []))
    emit('suggestion_ready', {
        'thought': analysis.get('final_thought', ''),
        'actions': analysis.get('actions', [])
    })
    
@socketio.on('perform_action')
def handle_perform_action(data):
    """
    Handles iterative agentic loops (Step 2 of an action).
    Expected data: {'action_id': '...', 'payload': '...', 'context': '...'}
    """
    from app.business.gemini_business import GeminiBusiness
    action_id = data.get('action_id')
    payload = data.get('payload')
    context = data.get('context', '')
    
    emit('thought_update', {'text': f"Executing {action_id}..."})
    
    # Fetch History for personalization
    frequent_history = TypingHistory.query.filter_by(user_id=1).order_by(TypingHistory.frequency.desc()).limit(30).all()
    recent_history = TypingHistory.query.filter_by(user_id=1).order_by(TypingHistory.timestamp.desc()).limit(20).all()
    combined_history = list(set([h.content for h in frequent_history] + [h.content for h in recent_history]))
    
    # Call the Agentic Brain for specialized execution
    execution = GeminiBusiness.perform_agentic_action(action_id, payload, context, combined_history)
    
    # Return result
    emit('thought_update', {'text': execution.get('thought', 'Task complete.')})
    emit('suggestion_ready', {
        'thought': execution.get('thought', ''),
        'result': execution.get('result', ''),
        'actions': [] # Usually clear actions after execution
    })
