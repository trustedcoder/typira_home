import firebase_admin
from firebase_admin import credentials, messaging
import os
from ..models.users import User
from ..models.fcm_tokens import FCMTokens
from .. import db


# Initialize Firebase Admin SDK
# Try to find the service account file in the root directory
base_dir = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
cert_path = os.path.join(base_dir, 'typira-ee2d4-firebase-adminsdk-fbsvc-43257b6e08.json')

if not firebase_admin._apps:
    try:
        cred = credentials.Certificate(cert_path)
        firebase_admin.initialize_app(cred)
    except Exception as e:
        print(f"Failed to initialize Firebase Admin: {e}")

class NotificationMethod:
    @staticmethod
    def send_push_to_all(tokens: list[str], title: str, body: str, data: dict = None):
        """
        Send push notification to multiple device tokens (Android + iOS).
        """
        if not tokens:
            return

        # Ensure all data values are strings
        if data:
            data = {k: str(v) for k, v in data.items()}

        notification = messaging.Notification(
            title=title,
            body=body,
        )

        message = messaging.MulticastMessage(
            notification=notification,
            tokens=tokens,
            data=data,
            apns=messaging.APNSConfig(
                payload=messaging.APNSPayload(
                    aps=messaging.Aps(
                        sound='default',
                        badge=1,
                    )
                )
            ),
            android=messaging.AndroidConfig(
                notification=messaging.AndroidNotification(
                    sound='default'
                )
            )
        )

        response = messaging.send_each_for_multicast(message)
        print(f"Successfully sent {response.success_count} messages; {response.failure_count} failed.")

    @staticmethod
    def save_fcm_token(user_id, token):
        """
        Saves a user's FCM token ensuring uniqueness.
        """
        if not token:
            return None

        # Check if the token already exists for this user
        existing_token = FCMTokens.query.filter_by(token=token, user_id=user_id).first()
        if existing_token:
            return existing_token

        # Check if this token is used by anyone else (should be unique globally)
        other_user_token = FCMTokens.query.filter_by(token=token).first()
        if other_user_token:
            # If it's the same token but different user, update the user_id (reassigned device)
            other_user_token.user_id = user_id
            db.session.commit()
            return other_user_token

        # Create new entry
        new_fcm = FCMTokens(user_id=user_id, token=token)
        db.session.add(new_fcm)
        db.session.commit()
        return new_fcm

    @staticmethod
    def send_push_notification_to_a_user(user_id, title, body, data: dict = None):
        """
        Sends a push notification to a specific user using their fcm_tokens in the FCMTokens table.
        """
        user_tokens = FCMTokens.query.filter_by(user_id=user_id).all()
        if user_tokens:
            tokens = [t.token for t in user_tokens if t.token]
            if tokens:
                NotificationMethod.send_push_to_all(tokens, title, body, data)

    @staticmethod
    def send_push_notification_to_all_users(title, body, data: dict = None):
        """
        Sends a push notification to all users globally using the FCMTokens table.
        """
        all_tokens = [fcm_token.token for fcm_token in FCMTokens.query.all() if fcm_token.token]
        if all_tokens:
            # Multi-cast chunking (max 500 per call is handled by messaging.send_each_for_multicast usually, 
            # but MultiCastMessage class itself has a tokens limit of 500)
            for i in range(0, len(all_tokens), 500):
                chunk = all_tokens[i:i + 500]
                NotificationMethod.send_push_to_all(chunk, title, body, data)

