import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Background message handler — must be top-level function.
@pragma('vm:entry-point')
Future<void> _firebaseBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint('[FCM Background] ${message.notification?.title}');
}

/// Manages Firebase Cloud Messaging: permission, token upload,
/// foreground notifications, and notification tap routing.
class FCMService {
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  /// Callback invoked when a notification tap should navigate somewhere.
  /// Receives the GoRouter path string, e.g. '/job/JOB-001'.
  void Function(String path)? onNavigate;

  /// Callback invoked when a job cancellation is received.
  void Function(String reason)? onJobCancelled;

  /// Callback invoked when route is updated (foreground).
  VoidCallback? onRouteUpdated;

  static const _channelId = 'waste_collect_jobs';
  static const _channelName = 'Job Notifications';

  Future<void> init() async {
    // Register background handler
    FirebaseMessaging.onBackgroundMessage(_firebaseBackgroundHandler);

    // Initialise local notifications
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    await _localNotifications.initialize(
      const InitializationSettings(android: androidInit, iOS: iosInit),
      onDidReceiveNotificationResponse: _onLocalNotificationTap,
    );

    // Create Android notification channel
    const channel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: 'Job assignment and status notifications',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    );
    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    // Request permission
    await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // Upload FCM token
    final fcmToken = await FirebaseMessaging.instance.getToken();
    if (fcmToken != null) {
      debugPrint('[FCM] Token: $fcmToken');
      await _uploadToken(fcmToken);
    }

    // Refresh handler
    FirebaseMessaging.instance.onTokenRefresh.listen(_uploadToken);

    // Foreground message handler
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Tap from background/terminated
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

    // App launched from notification (terminated state)
    final initial = await FirebaseMessaging.instance.getInitialMessage();
    if (initial != null) {
      _handleNotificationTap(initial);
    }
  }

  void _handleForegroundMessage(RemoteMessage message) {
    final title = message.notification?.title ?? 'WasteCollect';
    final body = message.notification?.body ?? '';
    final type = message.data['type'] as String?;

    debugPrint('[FCM Foreground] type=$type title=$title');

    // Show local notification
    _localNotifications.show(
      message.hashCode,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: '${type ?? ''}|${message.data['job_id'] ?? ''}',
    );

    // Handle specific foreground actions
    if (type == 'ROUTE_UPDATED') {
      onRouteUpdated?.call();
    }
  }

  void _handleNotificationTap(RemoteMessage message) {
    final type = message.data['type'] as String?;
    final jobId = message.data['job_id'] as String?;
    final reason = message.data['reason'] as String? ?? '';

    debugPrint('[FCM Tap] type=$type jobId=$jobId');

    switch (type) {
      case 'JOB_ASSIGNED':
        if (jobId != null) onNavigate?.call('/job/$jobId');
        break;
      case 'JOB_CANCELLED':
        onJobCancelled?.call(reason);
        onNavigate?.call('/home');
        break;
      case 'ROUTE_UPDATED':
        onRouteUpdated?.call();
        break;
    }
  }

  void _onLocalNotificationTap(NotificationResponse response) {
    final payload = response.payload;
    if (payload == null) return;

    final parts = payload.split('|');
    final type = parts.isNotEmpty ? parts[0] : '';
    final jobId = parts.length > 1 ? parts[1] : '';

    switch (type) {
      case 'JOB_ASSIGNED':
        if (jobId.isNotEmpty) onNavigate?.call('/job/$jobId');
        break;
      case 'JOB_CANCELLED':
        onNavigate?.call('/home');
        break;
    }
  }

  Future<void> _uploadToken(String token) async {
    // The actual HTTP upload is done via the Dio client from job_provider.
    // This callback lets the app layer handle it to avoid circular deps.
    debugPrint('[FCM] Token ready for upload: ${token.substring(0, 20)}...');
    onTokenReady?.call(token);
  }

  /// Optional callback so the app layer can upload the token via Dio.
  void Function(String token)? onTokenReady;
}
