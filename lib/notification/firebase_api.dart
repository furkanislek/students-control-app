import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:Tudora/main.dart';

class FirebaseApi {
  final _firebaseMessaging = FirebaseMessaging.instance;
  bool _notificationsInitialized = false;

  Future<void> initNotifications() async {
    if (_notificationsInitialized) return;

    NotificationSettings settings =
        await _firebaseMessaging.requestPermission();

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      final fCMToken = await _firebaseMessaging.getToken();
      print("Token : $fCMToken");
    }

    _notificationsInitialized = true;
  }

  void handleMessage(RemoteMessage? message) {
    if (message == null) return;

    navigatorKey.currentState?.pushNamed(
      'home',
      arguments: message,
    );
  }

  Future<void> initPushNotifications() async {
    if (!_notificationsInitialized) {
      await initNotifications(); 
    }

    FirebaseMessaging.instance.getInitialMessage().then(handleMessage);

    FirebaseMessaging.onMessageOpenedApp.listen(handleMessage);
  }
}
