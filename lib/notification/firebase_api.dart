import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:students_follow_app/main.dart';

class FirebaseApi {
  final _firebaseMessaging = FirebaseMessaging.instance;
  bool _notificationsInitialized = false;

  Future<void> initNotifications() async {
    if (_notificationsInitialized) return;

    // Bildirim izinlerini iste
    NotificationSettings settings =
        await _firebaseMessaging.requestPermission();

    // Kullanıcı izni verdiyse token al
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
      await initNotifications(); // Sadece bir kez çağırılır
    }

    // Uygulama kapalıyken açıldığında gelen mesajları işleyin
    FirebaseMessaging.instance.getInitialMessage().then(handleMessage);

    // Uygulama arka plandan açıldığında gelen mesajları işleyin
    FirebaseMessaging.onMessageOpenedApp.listen(handleMessage);
  }
}
