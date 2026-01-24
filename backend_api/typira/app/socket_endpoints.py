from flask import request, session, current_app
from flask_socketio import emit
from app import socketio, db
from app.models.context import TypingHistory, Memory, UserAction
from app.models.users import User
from app.helpers.insight_helpers import increment_user_stats
# from app.helpers.auth_helpers import token_required_socket # We need a socket version of this
import datetime
import time

def get_socket_user_id():
    """Extract user_id from session or Authorization header."""
    user_id = session.get('user_id')
    if not user_id:
        auth_token = request.headers.get('Authorization') or \
                     request.headers.get('HTTP_AUTHORIZATION')
        if auth_token:
            if auth_token.startswith("Bearer "):
                auth_token = auth_token[7:]
            resp = User.decode_auth_token(auth_token)
            if resp['status'] == 1:
                user_id = resp['user_id']
                session['user_id'] = user_id
    return user_id

@socketio.on('connect', namespace='/agent')
def handle_agent_connect(auth=None):
    auth_token = request.headers.get('Authorization')
    if auth_token:
        if auth_token.startswith("Bearer "):
            auth_token = auth_token[7:]
        resp = User.decode_auth_token(auth_token)
        if resp['status'] == 1:
            session['user_id'] = resp['user_id']
    emit('con_response', {'status': 'connected', 'authenticated': 'user_id' in session}, namespace='/agent')

@socketio.on('connect', namespace='/home')
def handle_home_connect(auth=None):
    auth_token = request.headers.get('Authorization')
    if auth_token:
        if auth_token.startswith("Bearer "):
            auth_token = auth_token[7:]
        resp = User.decode_auth_token(auth_token)
        if resp['status'] == 1:
            session['user_id'] = resp['user_id']
    emit('con_response', {'status': 'connected'}, namespace='/home')

@socketio.on('get_priority', namespace='/home')
def handle_get_priority(data=None):
    user_id = get_socket_user_id()
    platform = data.get('platform') if data else None
    if user_id:
        find_priority(user_id, platform=platform)

def find_priority(user_id, platform=None):
    """Synchronous helper to find a priority task and emit it."""
    from app.business.gemini_business import GeminiBusiness
    
    # 1. Fetch History & Memories (Personalization)
    history = TypingHistory.query.filter_by(user_id=user_id).order_by(TypingHistory.date_updated.desc()).limit(30).all()
    
    # Exclude actions:
    # - Approved actions are excluded forever.
    # - Declined actions are excluded for 1 hour.
    one_hour_ago = datetime.datetime.utcnow() - datetime.timedelta(hours=1)
    
    excluded_actions = UserAction.query.filter(
        UserAction.user_id == user_id,
        db.or_(
            UserAction.decision == 'approved',
            db.and_(
                UserAction.decision == 'declined',
                UserAction.timestamp >= one_hour_ago
            )
        )
    ).all()
    
    handled_ids = [a.action_id for a in excluded_actions]
    
    memories = Memory.query.filter_by(user_id=user_id).order_by(Memory.timestamp.desc()).limit(20).all()
    
    # 2. Fetch Recent Action Context (for Gemini to avoid repetition)
    recent_actions = UserAction.query.filter_by(user_id=user_id).order_by(UserAction.timestamp.desc()).limit(15).all()
    action_history = [f"{a.decision.upper()}: {a.context or a.action_id} at {a.timestamp.strftime('%Y-%m-%d %H:%M:%S')}" for a in recent_actions]

    history_list = [f"{h.content} (Logged on {h.date_updated.strftime('%Y-%m-%d %H:%M:%S')})" for h in history]
    memory_list = [f"{m.content} (Logged on {m.timestamp.strftime('%Y-%m-%d %H:%M:%S')})" for m in memories]
    
    # Handle New User / No Context
    if not history_list and not memory_list:
        emit('priority_task', {
            'thought': "I'm Typira, your new personal assistant. It seems we haven't talked yet! Use the voice, text, or camera below, or start typing with the Typira keyboard so I can start learning how to help you.",
            'label': "Ready",
            'action_id': "none",
            'type': "none"
        }, room=request.sid, namespace='/home')
        return

    # 3. Get Priority Task
    current_time = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    task = GeminiBusiness.get_priority_task(history_list, memory_list, action_history, "mobile_home", current_time=current_time, user_platform=platform)

    print(task)
    
    # Stream Thoughts
    thoughts = task.get('thoughts', [])
    for thought in thoughts:
        emit('thought_update', {'text': thought}, room=request.sid, namespace='/home')
        socketio.sleep(3) # Short pause for readability
    
    # 3. Emit Result
    # We check if the primary action (the first one) has already been handled.
    primary_action_id = task.get('actions', [{}])[0].get('id', 'none')
    
    if primary_action_id in handled_ids and primary_action_id != 'none':
        emit('priority_task', {
                "thoughts": ["I'm having a bit of trouble connecting to my brain..."],
                "title": "Standing by",
                "plan": "I'm standing by to assist with your tasks.",
                "actions": [
                    {
                        "id": "none",
                        "label": "Ready",
                        "type": "none",
                        "payload": ""
                    }
                ]
            }, room=request.sid, namespace='/home')
    else:
        # User 'plan' as the final presented thought for approval
        task['thought'] = task.get('plan', '')
        emit('priority_task', task, room=request.sid, namespace='/home')

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
        from app.helpers.insight_helpers import increment_user_stats
        import datetime

        atoms = split_into_sentences(text)
        num_atoms = len(atoms)
        
        # Word count for insights
        total_words = sum(len(atom.split()) for atom in atoms)
        increment_user_stats(user_id, words=total_words)
        
        for i, atom in enumerate(atoms):
            if not atom or len(atom.strip()) < 3:
                continue
                
            clean_text = scrub_pii(atom)
            is_last = (i == num_atoms - 1)
            
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
                    last_entry.date_updated = datetime.datetime.utcnow()
                    db.session.commit()
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
                    existing.date_updated = datetime.datetime.utcnow()
                    existing.content = clean_text 
                else:
                    new_entry = TypingHistory(
                        user_id=user_id, 
                        content=clean_text,
                        semantic_hash=s_hash,
                        app_context=app_context,
                        timestamp=datetime.datetime.utcnow(),
                        date_updated=datetime.datetime.utcnow()
                    )
                    db.session.add(new_entry)
                
                db.session.commit()

@socketio.on('analyze', namespace='/agent')
def handle_analyze(data):
    user_id = get_socket_user_id()
    if not user_id:
        return
    
    from flask import current_app
    text = data.get('text')
    app_context = data.get('app_context')
    is_full = data.get('is_full_context', False)

    socketio.start_background_task(
        async_persist_context, 
        current_app._get_current_object(),
        user_id, text, app_context, is_full
    )

    # --- Agentic AI Suggestion Engine (Gemini 3) ---
    from app.business.gemini_business import GeminiBusiness
    
    # 1. Gather Personal Context from TypingHistory
    # Get top 30 most recent items or frequent (ordered by update time for relevance)
    recent_history = TypingHistory.query.filter_by(user_id=user_id).order_by(TypingHistory.date_updated.desc()).limit(30).all()
    
    combined_history = [f"{h.content} (Logged on {h.date_updated.strftime('%Y-%m-%d %H:%M:%S')})" for h in recent_history]
    
    # 2. Call the Agentic Brain
    current_time = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    platform = data.get('platform')
    analysis = GeminiBusiness.analyze_context(text, combined_history, app_context, current_time=current_time, user_platform=platform)
    
    # 3. Stream 'Thought Process' to UI
    thoughts = analysis.get('thoughts', [])
    for thought in thoughts:
        emit('thought_update', {'text': thought})
        socketio.sleep(10) # Allow user to read the thinking process
        
    # 4. Finalize and Show Actions
    insights = analysis.get('insights')
    if insights:
        bio = insights.get('bio_data', {})
        mood_data = bio.get('current_mood', {})
        stress_data = bio.get('stress_level', {})
        energy_data = bio.get('energy_level', {})
        tone_data = bio.get('tone_profile', {})
        
        increment_user_stats(
            user_id, 
            minutes=insights.get('time_saved_minutes', 0), 
            words=insights.get('words_polished', 0),
            focus=insights.get('focus_score'),
            mood=mood_data.get('mood'),
            mood_emoji=mood_data.get('emoji'),
            mood_color=mood_data.get('hex_color'),
            stress=stress_data.get('level'),
            stress_conclusion=stress_data.get('conclusion'),
            stress_emoji=stress_data.get('emoji'),
            stress_color=stress_data.get('hex_color'),
            energy=energy_data.get('level'),
            energy_conclusion=energy_data.get('conclusion'),
            energy_emoji=energy_data.get('emoji'),
            energy_color=energy_data.get('hex_color'),
            tone=tone_data.get('tone'),
            tone_conclusion=tone_data.get('conclusion'),
            tone_emoji=tone_data.get('emoji'),
            tone_color=tone_data.get('hex_color'),
            sentiment=mood_data.get('sentiment')
        )

    emit('thought_update', {'text': analysis.get('final_thought', 'Ready.')})
    emit('suggestion_ready', {
        'thought': analysis.get('final_thought', ''),
        'actions': analysis.get('actions', []),
        'insights': insights
    })
    
@socketio.on('approve_action', namespace='/home')
def handle_approve_action(data):
    """
    Handles user approval of an agent-proposed priority task.
    Specifically for the Home Screen loop.
    """
    user_id = get_socket_user_id()
    if not user_id: return
    
    from app.business.gemini_business import GeminiBusiness
    action_id = data.get('action_id')
    payload = data.get('payload')
    user_input = data.get('user_input')
    platform = data.get('platform')
    
    emit('thought_update', {'text': "Starting..."}, namespace='/home')
    
    # 1. Fetch History for personalization
    history = TypingHistory.query.filter_by(user_id=user_id).order_by(TypingHistory.date_updated.desc()).limit(30).all()
    memories = Memory.query.filter_by(user_id=user_id).order_by(Memory.timestamp.desc()).limit(10).all()
    combined_history = [f"{h.content} (Logged on {h.date_updated.strftime('%Y-%m-%d %H:%M:%S')})" for h in history] + \
                       [f"{m.content} (Logged on {m.timestamp.strftime('%Y-%m-%d %H:%M:%S')})" for m in memories]
    
    # 2. Record approval for the priority loop memory
    new_action = UserAction(user_id=user_id, action_id=action_id, decision='approved', context=str(payload))
    db.session.add(new_action)
    
    db.session.commit()
    
    # 3. Call the Agentic Brain for specialized execution
    current_time = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    execution = GeminiBusiness.perform_agentic_action(action_id, payload, combined_history, user_input=user_input, current_time=current_time, user_platform=platform)

    print(execution)
    
    # 4. Stream 'Thought Process' to UI
    thoughts = execution.get('thoughts', [])
    for thought in thoughts:
        emit('thought_update', {'text': thought}, namespace='/home')
        socketio.sleep(3) # Short pause for readability

    # 5. Save to Memory for future reference
    if execution.get('result'):
        new_memory = Memory(user_id=user_id, content=execution['result'], source_type='agent_action', tags=action_id)
        db.session.add(new_memory)
        db.session.commit()

    # 6. Return result specifically for the Mobile App
    insights = execution.get('insights')
    if insights:
        bio = insights.get('bio_data', {})
        mood_data = bio.get('current_mood', {})
        stress_data = bio.get('stress_level', {})
        energy_data = bio.get('energy_level', {})
        tone_data = bio.get('tone_profile', {})

        increment_user_stats(
            user_id, 
            minutes=insights.get('time_saved_minutes', 0), 
            words=insights.get('words_polished', 0),
            focus=insights.get('focus_score'),
            mood=mood_data.get('mood'),
            mood_emoji=mood_data.get('emoji'),
            mood_color=mood_data.get('hex_color'),
            stress=stress_data.get('level'),
            stress_conclusion=stress_data.get('conclusion'),
            stress_emoji=stress_data.get('emoji'),
            stress_color=stress_data.get('hex_color'),
            energy=energy_data.get('level'),
            energy_conclusion=energy_data.get('conclusion'),
            energy_emoji=energy_data.get('emoji'),
            energy_color=energy_data.get('hex_color'),
            tone=tone_data.get('tone'),
            tone_conclusion=tone_data.get('conclusion'),
            tone_emoji=tone_data.get('emoji'),
            tone_color=tone_data.get('hex_color'),
            sentiment=mood_data.get('sentiment')
        )

    emit('action_result', {
        'thought': thoughts[-1] if thoughts else 'Task complete.',
        'result': execution.get('result', ''),
        'action_id': action_id,
        'insights': insights
    }, namespace='/home')

@socketio.on('perform_action', namespace='/agent')
def handle_perform_action(data):
    """
    Handles keyboard-triggered proactive actions.
    Maintains original behavior without recording UserAction decisions.
    """
    user_id = get_socket_user_id()
    if not user_id:
        return
    
    from app.business.gemini_business import GeminiBusiness
    action_id = data.get('action_id')
    payload = data.get('payload')
    context = data.get('context', '')
    
    emit('thought_update', {'text': f"Processing..."})
    
    history = TypingHistory.query.filter_by(user_id=user_id).order_by(TypingHistory.date_updated.desc()).limit(30).all()
    memories = Memory.query.filter_by(user_id=user_id).order_by(Memory.timestamp.desc()).limit(10).all()
    combined_history = [f"{h.content} (Logged on {h.date_updated.strftime('%Y-%m-%d %H:%M:%S')})" for h in history] + \
                       [f"{m.content} (Logged on {m.timestamp.strftime('%Y-%m-%d %H:%M:%S')})" for m in memories]
    
    # Execute action WITHOUT recording a UserAction (keep it separate from priority deduplication)
    current_time = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    execution = GeminiBusiness.perform_keyboard_agentic_action(action_id, payload, context, combined_history, current_time=current_time)
    
    # Update Insights
    insights = execution.get('insights')
    if insights:
        bio = insights.get('bio_data', {})
        mood_data = bio.get('current_mood', {})
        stress_data = bio.get('stress_level', {})
        energy_data = bio.get('energy_level', {})
        tone_data = bio.get('tone_profile', {})

        increment_user_stats(
            user_id, 
            minutes=insights.get('time_saved_minutes', 0), 
            words=insights.get('words_polished', 0),
            focus=insights.get('focus_score'),
            mood=mood_data.get('mood'),
            mood_emoji=mood_data.get('emoji'),
            mood_color=mood_data.get('hex_color'),
            stress=stress_data.get('level'),
            stress_conclusion=stress_data.get('conclusion'),
            stress_emoji=stress_data.get('emoji'),
            stress_color=stress_data.get('hex_color'),
            energy=energy_data.get('level'),
            energy_conclusion=energy_data.get('conclusion'),
            energy_emoji=energy_data.get('emoji'),
            energy_color=energy_data.get('hex_color'),
            tone=tone_data.get('tone'),
            tone_conclusion=tone_data.get('conclusion'),
            tone_emoji=tone_data.get('emoji'),
            tone_color=tone_data.get('hex_color'),
            sentiment=mood_data.get('sentiment')
        )
    
    # Still return result for UI feedback
    emit('suggestion_ready', {
        'thought': execution.get('thought', ''),
        'result': execution.get('result', ''),
        'actions': [],
        'insights': insights
    })

@socketio.on('decline_action', namespace='/home')
def handle_decline_action(data):
    """
    Handles user declining a priority task.
    Records in UserAction and Memory.
    """
    user_id = get_socket_user_id()
    if not user_id: return
    
    from app.models.context import Memory
    action_id = data.get('action_id')
    
    # 1. Record decision in UserAction
    payload = data.get('payload')
    new_action = UserAction(user_id=user_id, action_id=action_id, decision='declined', context=str(payload) if payload else None)
    db.session.add(new_action)
    
    db.session.commit()
    
    # 3. We NO LONGER call find_priority here. 
    # The frontend will wait 5 seconds and call 'get_priority' manually.

@socketio.on('analyze_image', namespace='/home')
def handle_analyze_image(data):
    """
    Handles image analysis request from the Mobile Home screen.
    """
    user_id = get_socket_user_id()
    if not user_id: return

    from app.business.gemini_business import GeminiBusiness
    image_base64 = data.get('image')
    mime_type = data.get('mime_type', 'image/jpeg')
    platform = data.get('platform')

    emit('thought_update', {'text': "Analyzing your image..."}, namespace='/home')

    # 1. Fetch Context
    history = TypingHistory.query.filter_by(user_id=user_id).order_by(TypingHistory.date_updated.desc()).limit(30).all()
    memories = Memory.query.filter_by(user_id=user_id).order_by(Memory.timestamp.desc()).limit(20).all()
    recent_actions = UserAction.query.filter_by(user_id=user_id).order_by(UserAction.timestamp.desc()).limit(15).all()

    history_list = [f"{h.content} (Logged on {h.date_updated.strftime('%Y-%m-%d %H:%M:%S')})" for h in history]
    memory_list = [f"{m.content} (Logged on {m.timestamp.strftime('%Y-%m-%d %H:%M:%S')})" for m in memories]
    action_history = [f"{a.decision.upper()}: {a.context or a.action_id} at {a.timestamp.strftime('%Y-%m-%d %H:%M:%S')}" for a in recent_actions]

    # 2. Call Gemini
    current_time = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    analysis = GeminiBusiness.analyze_image(image_base64, mime_type, history_list, memory_list, action_history, current_time=current_time, user_platform=platform)

    # 3. Stream Thoughts
    thoughts = analysis.get('thoughts', [])
    for thought in thoughts:
        emit('thought_update', {'text': thought}, namespace='/home')
        socketio.sleep(3)

    # 4. Store Representative Context in Memory
    # Extract the summary from the 'save_to_memory' action payload or use the plan
    save_action = next((a for a in analysis.get('actions', []) if a['id'] == 'save_to_memory'), None)
    memory_content = save_action['payload'] if save_action else analysis.get('plan', '')
    
    new_memory = Memory(user_id=user_id, content=f"Visual Context: {memory_content}", source_type='image_analysis')
    db.session.add(new_memory)
    
    # Update Insights
    insights = analysis.get('insights')
    if insights:
        bio = insights.get('bio_data', {})
        mood_data = bio.get('current_mood', {})
        stress_data = bio.get('stress_level', {})
        energy_data = bio.get('energy_level', {})
        tone_data = bio.get('tone_profile', {})

        increment_user_stats(
            user_id, 
            minutes=insights.get('time_saved_minutes', 0), 
            words=insights.get('words_polished', 0),
            focus=insights.get('focus_score'),
            mood=mood_data.get('mood'),
            mood_emoji=mood_data.get('emoji'),
            mood_color=mood_data.get('hex_color'),
            stress=stress_data.get('level'),
            stress_conclusion=stress_data.get('conclusion'),
            stress_emoji=stress_data.get('emoji'),
            stress_color=stress_data.get('hex_color'),
            energy=energy_data.get('level'),
            energy_conclusion=energy_data.get('conclusion'),
            energy_emoji=energy_data.get('emoji'),
            energy_color=energy_data.get('hex_color'),
            tone=tone_data.get('tone'),
            tone_conclusion=tone_data.get('conclusion'),
            tone_emoji=tone_data.get('emoji'),
            tone_color=tone_data.get('hex_color'),
            sentiment=mood_data.get('sentiment')
        )
    
    db.session.commit()

    # 5. Emit Result
    # Reuse onPriorityTask structure for UI compatibility
    analysis['thought'] = analysis.get('plan', '')
    emit('priority_task', analysis, namespace='/home')

@socketio.on('analyze_voice', namespace='/home')
def handle_analyze_voice(data):
    """
    Handles voice recording analysis request from the Mobile Home screen.
    """
    user_id = get_socket_user_id()
    if not user_id: return

    from app.business.gemini_business import GeminiBusiness
    audio_base64 = data.get('audio')
    mime_type = data.get('mime_type', 'audio/m4a')
    platform = data.get('platform')

    emit('thought_update', {'text': "Transcribing your voice..."}, namespace='/home')

    # 1. Fetch Context
    history = TypingHistory.query.filter_by(user_id=user_id).order_by(TypingHistory.date_updated.desc()).limit(30).all()
    memories = Memory.query.filter_by(user_id=user_id).order_by(Memory.timestamp.desc()).limit(20).all()
    recent_actions = UserAction.query.filter_by(user_id=user_id).order_by(UserAction.timestamp.desc()).limit(15).all()

    history_list = [f"{h.content} (Logged on {h.date_updated.strftime('%Y-%m-%d %H:%M:%S')})" for h in history]
    memory_list = [f"{m.content} (Logged on {m.timestamp.strftime('%Y-%m-%d %H:%M:%S')})" for m in memories]
    action_history = [f"{a.decision.upper()}: {a.context or a.action_id} at {a.timestamp.strftime('%Y-%m-%d %H:%M:%S')}" for a in recent_actions]

    # 2. Call Gemini
    current_time = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    analysis = GeminiBusiness.analyze_voice(audio_base64, mime_type, history_list, memory_list, action_history, current_time=current_time, user_platform=platform)

    # 3. Stream Thoughts
    thoughts = analysis.get('thoughts', [])
    for thought in thoughts:
        emit('thought_update', {'text': thought}, namespace='/home')
        socketio.sleep(3)

    # 4. Store Transcription and Insight in Memory
    transcription = analysis.get('transcription', 'Audio recording')
    plan = analysis.get('plan', '')
    
    new_memory = Memory(user_id=user_id, content=f"Voice Command: {transcription}\nInsight: {plan}", source_type='voice_analysis')
    db.session.add(new_memory)
    
    # Update Insights
    insights = analysis.get('insights')
    if insights:
        bio = insights.get('bio_data', {})
        mood_data = bio.get('current_mood', {})
        stress_data = bio.get('stress_level', {})
        energy_data = bio.get('energy_level', {})
        tone_data = bio.get('tone_profile', {})

        increment_user_stats(
            user_id, 
            minutes=insights.get('time_saved_minutes', 0), 
            words=insights.get('words_polished', 0),
            focus=insights.get('focus_score'),
            mood=mood_data.get('mood'),
            mood_emoji=mood_data.get('emoji'),
            mood_color=mood_data.get('hex_color'),
            stress=stress_data.get('level'),
            stress_conclusion=stress_data.get('conclusion'),
            stress_emoji=stress_data.get('emoji'),
            stress_color=stress_data.get('hex_color'),
            energy=energy_data.get('level'),
            energy_conclusion=energy_data.get('conclusion'),
            energy_emoji=energy_data.get('emoji'),
            energy_color=energy_data.get('hex_color'),
            tone=tone_data.get('tone'),
            tone_conclusion=tone_data.get('conclusion'),
            tone_emoji=tone_data.get('emoji'),
            tone_color=tone_data.get('hex_color'),
            sentiment=mood_data.get('sentiment')
        )
    
    db.session.commit()

    # 5. Emit Result
    analysis['thought'] = analysis.get('plan', '')
    emit('priority_task', analysis, namespace='/home')

@socketio.on('analyze_text', namespace='/home')
def handle_analyze_text(data):
    """
    Handles manual text command analysis request from the Mobile Home screen.
    """
    user_id = get_socket_user_id()
    if not user_id: return

    from app.business.gemini_business import GeminiBusiness
    text = data.get('text')
    platform = data.get('platform')

    if not text: return

    # 0. Store in Typing History
    new_history = TypingHistory(user_id=user_id, content=text)
    db.session.add(new_history)
    db.session.commit()

    emit('thought_update', {'text': "Analyzing your input..."}, namespace='/home')

    # 1. Fetch Context
    history = TypingHistory.query.filter_by(user_id=user_id).order_by(TypingHistory.date_updated.desc()).limit(30).all()
    memories = Memory.query.filter_by(user_id=user_id).order_by(Memory.timestamp.desc()).limit(20).all()
    recent_actions = UserAction.query.filter_by(user_id=user_id).order_by(UserAction.timestamp.desc()).limit(15).all()

    history_list = [f"{h.content} (Logged on {h.date_updated.strftime('%Y-%m-%d %H:%M:%S')})" for h in history]
    memory_list = [f"{m.content} (Logged on {m.timestamp.strftime('%Y-%m-%d %H:%M:%S')})" for m in memories]
    action_history = [f"{a.decision.upper()}: {a.context or a.action_id} at {a.timestamp.strftime('%Y-%m-%d %H:%M:%S')}" for a in recent_actions]

    # 2. Call Gemini
    current_time = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    analysis = GeminiBusiness.analyze_text_command(text, history_list, memory_list, action_history, current_time=current_time, user_platform=platform)

    # 3. Stream Thoughts
    thoughts = analysis.get('thoughts', [])
    for thought in thoughts:
        emit('thought_update', {'text': thought}, namespace='/home')
        socketio.sleep(3)

    # 4. Emit Result
    insights = analysis.get('insights')
    if insights:
        bio = insights.get('bio_data', {})
        mood_data = bio.get('current_mood', {})
        stress_data = bio.get('stress_level', {})
        energy_data = bio.get('energy_level', {})
        tone_data = bio.get('tone_profile', {})

        increment_user_stats(
            user_id, 
            minutes=insights.get('time_saved_minutes', 0), 
            words=insights.get('words_polished', 0),
            focus=insights.get('focus_score'),
            mood=mood_data.get('mood'),
            mood_emoji=mood_data.get('emoji'),
            mood_color=mood_data.get('hex_color'),
            stress=stress_data.get('level'),
            stress_conclusion=stress_data.get('conclusion'),
            stress_emoji=stress_data.get('emoji'),
            stress_color=stress_data.get('hex_color'),
            energy=energy_data.get('level'),
            energy_conclusion=energy_data.get('conclusion'),
            energy_emoji=energy_data.get('emoji'),
            energy_color=energy_data.get('hex_color'),
            tone=tone_data.get('tone'),
            tone_conclusion=tone_data.get('conclusion'),
            tone_emoji=tone_data.get('emoji'),
            tone_color=tone_data.get('hex_color'),
            sentiment=mood_data.get('sentiment')
        )

    analysis['thought'] = analysis.get('plan', '')
    emit('priority_task', analysis, namespace='/home')
