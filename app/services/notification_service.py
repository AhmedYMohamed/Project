import logging
import os
import json
from typing import Optional, Dict, Any, List
import requests

logger = logging.getLogger(__name__)

class NotificationService:
    """
    Service for sending Push Notifications via Firebase Cloud Messaging (FCM).
    Includes a safe fallback mode when Firebase credentials are not provided.
    """

    @staticmethod
    def send_push_notification(
        fcm_token: Optional[str],
        title: str,
        body: str,
        data: Optional[Dict[str, Any]] = None
    ) -> bool:
        """
        Sends a push notification to a single device token.
        """
        if not fcm_token:
            logger.info(f"[PUSH NOTIFICATION SKIPPED] No FCM token provided for notification: '{title}'")
            return False

        logger.info(f"📱 [PUSH NOTIFICATION OUTBOUND] To Token: {fcm_token[:15]}... | Title: '{title}' | Body: '{body}' | Data: {data}")

        # Check if Firebase credentials / Server Key are configured
        server_key = os.getenv("FIREBASE_SERVER_KEY")
        if server_key:
            try:
                headers = {
                    "Authorization": f"key={server_key}",
                    "Content-Type": "application/json"
                }
                payload = {
                    "to": fcm_token,
                    "notification": {
                        "title": title,
                        "body": body,
                        "sound": "default"
                    },
                    "data": data or {}
                }
                response = requests.post(
                    "https://fcm.googleapis.com/fcm/send",
                    headers=headers,
                    data=json.dumps(payload),
                    timeout=5
                )
                if response.status_code == 200:
                    logger.info(f"✅ FCM Notification sent successfully: {response.json()}")
                    return True
                else:
                    logger.error(f"❌ FCM Notification failed status {response.status_code}: {response.text}")
                    return False
            except Exception as e:
                logger.error(f"❌ Error sending FCM notification: {e}")
                return False
        else:
            # Console mock delivery for dev mode / testing
            logger.info("ℹ️ FIREBASE_SERVER_KEY not set. Push notification logged in mock dev mode.")
            return True

    @classmethod
    def send_notification_to_user(
        cls,
        user: Any,
        title: str,
        body: str,
        data: Optional[Dict[str, Any]] = None
    ) -> bool:
        """
        Helper to send notification directly using a User model instance.
        """
        if not user:
            return False
        fcm_token = getattr(user, "fcmToken", None)
        return cls.send_push_notification(fcm_token=fcm_token, title=title, body=body, data=data)
