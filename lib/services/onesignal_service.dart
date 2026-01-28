import 'package:onesignal_flutter/onesignal_flutter.dart';

class OneSignalService {
  static const String _appId = '5e951e24-852c-4bb4-a4b6-7801a21369b8';

  static Future<void> initialize() async {
    OneSignal.Debug.setLogLevel(OSLogLevel.verbose);
    
    OneSignal.initialize(_appId);
    
    OneSignal.Notifications.requestPermission(true);
    
    OneSignal.Notifications.addForegroundWillDisplayListener((event) {
      event.notification.display();
    });
    
    OneSignal.Notifications.addClickListener((event) {
      final data = event.notification.additionalData;
      if (data != null) {
        _handleNotificationClick(data);
      }
    });
  }

  static void _handleNotificationClick(Map<String, dynamic> data) {
    final type = data['type'] as String?;
    switch (type) {
      case 'new_quote':
        break;
      case 'quote_accepted':
        break;
      case 'service_completed':
        break;
      case 'new_review':
        break;
      default:
        break;
    }
  }

  static Future<void> setUserId(String userId) async {
    await OneSignal.login(userId);
  }

  static Future<void> removeUserId() async {
    await OneSignal.logout();
  }

  static Future<void> setUserTags(Map<String, String> tags) async {
    for (var entry in tags.entries) {
      await OneSignal.User.addTagWithKey(entry.key, entry.value);
    }
  }

  static Future<void> sendNotificationToUser({
    required String userId,
    required String title,
    required String message,
    Map<String, dynamic>? data,
  }) async {
  }
}
