import 'dart:convert';
import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';
import 'package:freshchat_sdk/freshchat_sdk.dart' hide Importance, Priority;
import 'package:rahiq_driver/services/freshchat_service.dart';
import 'package:rahiq_driver/data/storage/auth_storage.dart';
import 'package:rahiq_driver/data/api/api_client.dart';
import 'package:rahiq_driver/data/api/driver/driver_auth_api.dart';

/// Android channel the app's own notifications post through.
///
/// The id carries a version suffix because a channel's settings are frozen
/// the moment Android first creates it -- re-issuing the same id with new
/// flags is a no-op on every device that already has it. `showBadge: false`
/// was added to the original `high_importance_channel` long after that
/// channel had been created on installed devices, so it went on badging the
/// launcher icon anyway. Handing those devices a channel that was *born*
/// without badges is the only way the flag takes effect; bump the suffix
/// again if any other channel setting ever has to change.
const AndroidNotificationChannel _appChannel = AndroidNotificationChannel(
  'high_importance_channel_v2', // id
  'High Importance Notifications', // title
  description: 'This channel is used for important notifications.',
  importance: Importance.max,
  showBadge: false,
);

/// The channels the Freshchat SDK posts through.
///
/// It hardcodes these two ids -- `fc_conv_notif_ch` for an agent's reply,
/// `fc_campaign_notif_ch` for a campaign push -- and creates them itself the
/// first time it has something to show, with badges on and nothing exposed to
/// say otherwise: `setNotificationConfig` reaches priority, importance, sound
/// and icons, and stops there. Claiming the ids first is the way in, because
/// Android leaves an id that already exists alone; the SDK then finds the
/// channels in place and posts through them untouched.
///
/// The importance is the SDK's own default, so a chat notification behaves
/// exactly as it did and only the badge changes. The names are ours only
/// because the SDK never gets to set its own -- English, like the channel
/// above.
const List<AndroidNotificationChannel> _freshchatChannels =
    <AndroidNotificationChannel>[
      AndroidNotificationChannel(
        'fc_conv_notif_ch', // id
        'Support Messages', // title
        description: 'Replies from the support team.',
        importance: Importance.defaultImportance,
        showBadge: false,
      ),
      AndroidNotificationChannel(
        'fc_campaign_notif_ch', // id
        'Offers and Announcements', // title
        description: 'Occasional news and offers from the support team.',
        importance: Importance.defaultImportance,
        showBadge: false,
      ),
    ];

/// Every channel above, in the order they are created.
const List<AndroidNotificationChannel> _badgeFreeChannels =
    <AndroidNotificationChannel>[_appChannel, ..._freshchatChannels];

/// Channels to remove on startup, listed only so they can be deleted.
///
/// `high_importance_channel` is the badge-enabled predecessor of
/// [_appChannel]; dropping it also clears whatever it still has sitting in
/// the tray, which is what the launcher counts. The fallback channel is
/// Firebase's own -- it creates and badges that one whenever a push names a
/// channel the app has not created yet, which is exactly what happened
/// between install and the first run of this code.
const List<String> _legacyChannelIds = <String>[
  'high_importance_channel',
  'fcm_fallback_notification_channel',
];

/// Puts every channel this app can post through in place with badges off, and
/// clears out the ones it used to post through.
///
/// Top-level and free of instance state because the FCM background isolate
/// calls it too: a Freshchat push arriving while the app is dead is handled
/// in a process where [NotificationService.init] has never run, and the SDK
/// would otherwise get to create its channels there first.
///
/// Creating a channel that already exists is a no-op, so this is safe to run
/// as often as it likes. Failures are swallowed: a badge is not worth taking
/// down the push handling this sits in front of.
@pragma('vm:entry-point')
Future<void> _createBadgeFreeChannels() async {
  final AndroidFlutterLocalNotificationsPlugin? android =
      FlutterLocalNotificationsPlugin()
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
  if (android == null) return;

  try {
    for (final AndroidNotificationChannel channel in _badgeFreeChannels) {
      await android.createNotificationChannel(channel);
    }

    for (final String legacyId in _legacyChannelIds) {
      await android.deleteNotificationChannel(channelId: legacyId);
    }
  } catch (e) {
    debugPrint('Failed to reconcile notification channels: $e');
  }
}

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('Handling a background message: ${message.messageId}');

  // Freshchat pushes are data-only (no `notification` block), so they'd
  // otherwise be silently dropped by this app's own handler. Without this,
  // Freshchat's SDK only picks new messages up on its own lazy sync when the
  // conversation screen is next opened, which shows up as a long delay.
  //
  // The SDK builds and posts that notification itself, on channels it
  // creates on the spot unless they are already there -- so claim them
  // before handing it the push. See [_createBadgeFreeChannels].
  await _createBadgeFreeChannels();

  if (await Freshchat.isFreshchatNotification(message.data)) {
    Freshchat.handlePushNotification(message.data);
  }
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() {
    return _instance;
  }

  NotificationService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  Future<void> init() async {
    if (_isInitialized) return;

    // Request permissions for iOS and Android 13+
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      announcement: false,
      badge: false,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );
    debugPrint('User granted permission: ${settings.authorizationStatus}');

    // Register background handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Initialize local notifications
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@drawable/ic_notification');

    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: false,
          requestSoundPermission: true,
        );

    const InitializationSettings initializationSettings =
        InitializationSettings(
          android: initializationSettingsAndroid,
          iOS: initializationSettingsIOS,
        );

    await _localNotificationsPlugin.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Put the Android channels in place, every one of them badge-free
    await _createBadgeFreeChannels();

    // Update foreground notification presentation options for iOS
    await _firebaseMessaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: false,
      sound: true,
    );

    // Listen to foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      debugPrint('Got a message whilst in the foreground!');
      debugPrint('Message data: ${message.data}');

      // Freshchat pushes are data-only (no `notification` block), so they'd
      // otherwise fall through untouched below. Forwarding them lets the SDK
      // update the open conversation immediately instead of relying on its
      // own lazy sync, which is what caused the long display delay.
      if (await Freshchat.isFreshchatNotification(message.data)) {
        Freshchat.handlePushNotification(message.data);
        // Ties the badge to the event we just saw rather than waiting on the
        // SDK's own count-changed broadcast to reach us.
        FreshchatService.refreshUnreadCount();
        return;
      }

      if (message.notification != null) {
        debugPrint(
          'Message also contained a notification: ${message.notification}',
        );
        _showLocalNotification(message);
      }
    });

    // Handle messages when app is opened from background
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) async {
      debugPrint('A new onMessageOpenedApp event was published!');
      if (await Freshchat.isFreshchatNotification(message.data)) {
        Freshchat.handlePushNotification(message.data);
        return;
      }
      _handleNotificationClick(message.toMap());
    });

    // Check if app was opened from a terminated state
    RemoteMessage? initialMessage = await _firebaseMessaging
        .getInitialMessage();
    if (initialMessage != null) {
      if (await Freshchat.isFreshchatNotification(initialMessage.data)) {
        Freshchat.handlePushNotification(initialMessage.data);
      } else {
        _handleNotificationClick(initialMessage.toMap());
      }
    }

    _firebaseMessaging.onTokenRefresh.listen((fcmToken) async {
      final token = AuthStorage.getAccessToken();
      if (token != null && token.isNotEmpty) {
        try {
          String? deviceId;
          final DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
          if (Platform.isIOS) {
            final IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
            deviceId = iosInfo.identifierForVendor;
          } else if (Platform.isAndroid) {
            final AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
            deviceId = androidInfo.id;
          }
          final localeCode = AuthStorage.getLanguage();
          final api = DriverAuthApi(ApiClient());
          await api.updateDeviceToken(
            fcmToken,
            Platform.isIOS ? "IOS" : "ANDROID",
            deviceId ?? "dummy_device_id",
            locale: localeCode,
          );
        } catch (e) {
          debugPrint('Failed to sync refreshed FCM token: $e');
        }
      }
    });

    _isInitialized = true;
  }

  Future<String?> getToken() async {
    if (!kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.iOS ||
            defaultTargetPlatform == TargetPlatform.macOS)) {
      await _firebaseMessaging.getAPNSToken();
    }
    return await _firebaseMessaging.getToken();
  }

  void _showLocalNotification(RemoteMessage message) {
    RemoteNotification? notification = message.notification;
    AndroidNotification? android = message.notification?.android;

    if (notification != null && android != null && !kIsWeb) {
      _localNotificationsPlugin.show(
        id: notification.hashCode,
        title: notification.title,
        body: notification.body,
        notificationDetails: NotificationDetails(
          android: AndroidNotificationDetails(
            _appChannel.id,
            _appChannel.name,
            channelDescription: _appChannel.description,
            icon: android.smallIcon ?? '@drawable/ic_notification',
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: false,
            presentSound: true,
          ),
        ),
        payload: jsonEncode(message.toMap()),
      );
    }
  }

  void _onNotificationTapped(NotificationResponse response) {
    if (response.payload != null) {
      debugPrint('Notification payload: ${response.payload}');
      try {
        final Map<String, dynamic> data = jsonDecode(response.payload!);
        _handleNotificationClick(data);
      } catch (e) {
        debugPrint('Error decoding notification payload: $e');
      }
    }
  }

  void _handleNotificationClick(Map<String, dynamic> data) {
    debugPrint('Handling notification click with data: $data');
  }
}
