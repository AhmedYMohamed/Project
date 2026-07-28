import unittest
from types import SimpleNamespace
from app.services.notification_service import NotificationService

class DummyUser:
    def __init__(self, user_id, role, fcm_token):
        self.userId = user_id
        self.role = role
        self.fcmToken = fcm_token

class TestPushNotifications(unittest.TestCase):

    def test_notification_service_mock_send(self):
        """Verify NotificationService logs and handles push sending without crashing."""
        result = NotificationService.send_push_notification(
            fcm_token="test_fcm_token_12345",
            title="اختبار الإشعارات",
            body="تجربة إرسال إشعار للموبايل",
            data={"type": "test", "reportId": "rep-123"}
        )
        self.assertTrue(result)

    def test_notification_service_empty_token(self):
        """Verify missing FCM token is handled gracefully."""
        result = NotificationService.send_push_notification(
            fcm_token=None,
            title="اختبار",
            body="مواطنون"
        )
        self.assertFalse(result)

    def test_notification_service_user_helper(self):
        """Verify sending notification to User object."""
        user = DummyUser(user_id="user-test-1", role="citizen", fcm_token="token_abc_xyz")
        result = NotificationService.send_notification_to_user(
            user=user,
            title="تحديث حالة",
            body="تمت الموافقة"
        )
        self.assertTrue(result)

if __name__ == '__main__':
    unittest.main()
