import os
import datetime
from app import create_app, db
from app.models.users import User
from app.models.context import TypingHistory, Memory, UserAction
from app.models.insights import UserInsight, UserActivityHistory
from sqlalchemy import text

def seed_database():
    config_name = os.getenv("ENV", "dev")
    app = create_app(config_name)
    
    with app.app_context():
        print(f"Seeding database for environment: {config_name}")
        
        # 1. Ensure Demo User exists
        demo_email = "demo@typira.ai"
        user = User.query.filter_by(email=demo_email).first()
        if not user:
            user = User(
                email=demo_email,
                name="Demo User",
                public_id="demo_user_123",
                password=User.generate_password("password123"),
                is_email_verified=True
            )
            db.session.add(user)
            db.session.commit()
            print(f"Created user: {demo_email}")
        else:
            print(f"User {demo_email} already exists.")

        # Clear existing demo data to avoid duplicates/clutter for recording
        print("Clearing old demo data...")
        TypingHistory.query.filter_by(user_id=user.id).delete()
        Memory.query.filter_by(user_id=user.id).delete()
        UserAction.query.filter_by(user_id=user.id).delete()
        UserInsight.query.filter_by(user_id=user.id).delete()
        UserActivityHistory.query.filter_by(user_id=user.id).delete()
        db.session.commit()

        # 2. Seed Typing History (Reflecting "Startup", "Deadline", "Stressed")
        typing_snippets = [
            ("I need to finish the investor deck by tomorrow morning. Feeling the pressure.", "WhatsApp"),
            ("Let's schedule a sync for the seed round preparation. We need to be sharp.", "Slack"),
            ("The neural network model is training slower than expected. Might pull an all-nighter.", "Notes"),
            ("Hey Sarah, can you review the pitch deck once more? Specifically the roadmap.", "Gmail"),
            ("Maybe we should pivot the marketing strategy for the Q3 launch.", "Telegram"),
            ("Running late for the founder's meeting. Traffic is insane.", "iMessage")
        ]
        
        for content, context in typing_snippets:
            th = TypingHistory(
                user_id=user.id,
                content=content,
                app_context=context,
                timestamp=datetime.datetime.utcnow() - datetime.timedelta(hours=2)
            )
            db.session.add(th)
        print(f"Seeded {len(typing_snippets)} typing history records.")

        # 3. Seed Memories (Multimodal Context)
        memories = [
            ("Filed electric bill from photo.", "Camera", "finance, productivity"),
            ("Reminder: Buy groceries for the party.", "Voice", "personal, task"),
            ("Investor meeting tomorrow at 10 AM.", "User Input", "work, startup"),
            ("User prefers dark mode for coding sessions.", "Behavioral", "preference"),
            ("Analyzed messy desk photo: identified 3 unpaid invoices.", "Camera", "finance, insights")
        ]
        
        for content, source, tags in memories:
            m = Memory(
                user_id=user.id,
                content=content,
                source_type=source,
                tags=tags,
                timestamp=datetime.datetime.utcnow() - datetime.timedelta(days=1)
            )
            db.session.add(m)
        print(f"Seeded {len(memories)} memory records.")

        # 4. Seed User Actions (Agentic History)
        actions = [
            ("calendar_event_1", "approved", "Added 'Investor Meeting' to calendar."),
            ("reminder_1", "approved", "Set reminder for 'Buy groceries'."),
            ("reschedule_1", "declined", "User busy: Declined rescheduling 3 PM meeting."),
            ("email_draft_1", "approved", "Polished email to Sarah regarding pitch deck.")
        ]
        
        for action_id, decision, context in actions:
            ua = UserAction(
                user_id=user.id,
                action_id=action_id,
                decision=decision,
                context=context,
                timestamp=datetime.datetime.utcnow() - datetime.timedelta(hours=1)
            )
            db.session.add(ua)
        print(f"Seeded {len(actions)} user action records.")

        # 5. Seed User Insights (Premium Dashboard Visuals)
        insight = UserInsight(
            user_id=user.id,
            time_saved_minutes=145,
            words_polished=1240,
            focus_score=78,
            current_mood="Productive but Stressed",
            mood_emoji="🔥",
            mood_color="#FF4B2B",
            stress_level=65,
            stress_conclusion="High due to upcoming deadlines",
            stress_emoji="😰",
            stress_color="#E94057",
            energy_level="Caffeinated",
            energy_conclusion="Spiking but unstable",
            energy_emoji="⚡",
            energy_color="#FBC2EB",
            tone_profile="Professional & Urgent",
            tone_conclusion="Concise and goal-oriented",
            tone_emoji="💼",
            tone_color="#8E2DE2",
            sentiment="Neutral-Positive",
            health_score=82,
            vision_count=15,
            voice_count=22,
            text_count=150
        )
        db.session.add(insight)
        
        # History for charts
        for i in range(7):
            ah = UserActivityHistory(
                user_id=user.id,
                date=datetime.date.today() - datetime.timedelta(days=i),
                time_saved_minutes=20 + (i * 5)
            )
            db.session.add(ah)
            
        print("Seeded user insights and activity history.")

        db.session.commit()
        print("Database seeding completed successfully!")

if __name__ == "__main__":
    seed_database()
