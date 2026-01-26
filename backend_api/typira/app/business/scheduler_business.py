import datetime
import pytz
import traceback
from flask import current_app
from app import db, socketio
from app.models.scheduler import Schedule
from app.models.context import Memory, TypingHistory, UserAction
from app.business.gemini_business import GeminiBusiness
from app.helpers.insight_helpers import increment_user_stats

def dispatch_due_schedules():
    print("dispatch_due_schedules")
    """
    Called every minute by APScheduler. Checks for schedules that match the current time.
    """
    # Use app context since this runs in a separate thread
    with current_app.app_context():
        try:
            now_utc = datetime.datetime.utcnow()
            schedules = Schedule.query.all()
            
            for schedule in schedules:
                if is_due(schedule, now_utc):
                    # We use a socket background task or separate thread to not block the main scheduler loop
                    process_schedule(schedule)
        except Exception as e:
            print(f"Error in dispatch_due_schedules: {e}")
            traceback.print_exc()

def is_due(schedule, now_utc):
    """
    Determines if a schedule is due based on time and frequency.
    """
    try:
        # 1. Check if it already ran in this same minute (to avoid overlaps)
        if schedule.last_run:
            if schedule.last_run.strftime("%Y-%m-%d %H:%M") == now_utc.strftime("%Y-%m-%d %H:%M"):
                return False

        # 2. Parse schedule timezone
        tz = pytz.timezone(schedule.timezone or 'UTC')
        local_now = now_utc.replace(tzinfo=pytz.utc).astimezone(tz)
        
        # 3. Check time match (HH:mm)
        local_time_str = local_now.strftime("%H:%M")
        if local_time_str != schedule.time:
            return False
            
        # 4. Check Date or Repeat
        if schedule.date_or_repeat == "Everyday":
            return True
        
        # Day of week match (Monday, Tuesday, etc.)
        current_day = local_now.strftime("%A")
        if schedule.date_or_repeat == current_day:
            return True
            
        # Specific date match (YYYY-MM-DD)
        if schedule.date_or_repeat == local_now.strftime("%Y-%m-%d"):
            return True
            
        return False
    except Exception as e:
        print(f"Error checking schedule {schedule.id}: {e}")
        return False

def process_schedule(schedule):
    """
    Executes the AI logic for a due schedule, stores results in memory, and sends a push notification.
    """
    try:
        from app.helpers.notification_method import NotificationMethod
        print(f"⏰ [SCHEDULER] Processing schedule: {schedule.title} for user {schedule.user_id}")
        
        # 1. Update last_run immediately to prevent double triggers
        schedule.last_run = datetime.datetime.utcnow()
        db.session.add(schedule)
        db.session.commit()
        
        # 2. Gather context
        user_id = schedule.user_id
        history = TypingHistory.query.filter_by(user_id=user_id).order_by(TypingHistory.date_updated.desc()).limit(30).all()
        memories = Memory.query.filter_by(user_id=user_id).order_by(Memory.timestamp.desc()).limit(20).all()
        recent_actions = UserAction.query.filter_by(user_id=user_id).order_by(UserAction.timestamp.desc()).limit(15).all()

        history_list = [f"{h.content} (Logged on {h.date_updated.strftime('%Y-%m-%d %H:%M:%S')})" for h in history]
        memory_list = [f"{m.content} (Logged on {m.timestamp.strftime('%Y-%m-%d %H:%M:%S')})" for m in memories]
        action_history = [f"{a.decision.upper()}: {a.context or a.action_id} at {a.timestamp.strftime('%Y-%m-%d %H:%M:%S')}" for a in recent_actions]
        
        # 3. Call AI
        current_time_str = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        insight = GeminiBusiness.generate_scheduled_insight(
            schedule.action_description, 
            history_list, 
            memory_list, 
            action_history, 
            current_time=current_time_str
        )
        
        title = insight.get('title', 'Scheduled Update')
        short_desc = insight.get('short_description', 'I have a new personal insight for you.')
        full_findings = insight.get('full_formatted_result', '')

        # 4. Store in Memory
        new_memory = Memory(
            user_id=user_id,
            content=full_findings,
            source_type='scheduled_insight',
            tags=f"scheduler_{schedule.id}",
            timestamp=datetime.datetime.utcnow()
        )
        db.session.add(new_memory)
        db.session.commit()
        
        # 5. Send Push Notification
        # We pass memory_id in the data payload so the app can navigate to it
        notification_data = {
            "type": "scheduled_insight",
            "memory_id": f"mem_{new_memory.id}",
            "title": title,
            "description": short_desc
        }
        
        NotificationMethod.send_push_notification_to_a_user(
            user_id=user_id,
            title=title,
            body=short_desc,
            data=notification_data
        )

    except Exception as e:
        print(f"Error processing schedule {schedule.id}: {e}")
        traceback.print_exc()
