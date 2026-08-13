import Flutter
import UIKit
import GoogleMaps
import UserNotifications
import freshchat_sdk

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    let mapKey = "AIzaSyB___mbW9IyVrmRpxFN1sYXwPjtZVhZ-x0"
    GMSServices.provideAPIKey(mapKey)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }

  // MARK: - Freshchat push
  //
  // The Dart side registers the FCM token with Freshchat, which is the Android
  // path — the plugin's iOS `setPushRegistrationToken` wants the raw APNs
  // token, and only the app delegate ever sees that. Without these three
  // hooks Freshchat has nowhere to push to and no way to hear about a message
  // that did arrive, so an open conversation only picked new messages up on
  // the SDK's own sync when the screen was reopened.
  //
  // Every branch either forwards to Freshchat or falls through to `super`, so
  // the app's own notifications keep reaching firebase_messaging and
  // flutter_local_notifications exactly as before.

  override func application(
    _ application: UIApplication,
    didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
  ) {
    FreshchatSdkPlugin().setPushRegistrationToken(deviceToken)
    super.application(
      application,
      didRegisterForRemoteNotificationsWithDeviceToken: deviceToken
    )
  }

  override func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    willPresent notification: UNNotification,
    withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
  ) {
    let plugin = FreshchatSdkPlugin()
    let payload = notification.request.content.userInfo

    if plugin.isFreshchatNotification(payload) {
      // Hand it to the SDK and present nothing: the conversation the user is
      // looking at updates itself, and a banner over it would be noise.
      plugin.handlePushNotification(payload)
      completionHandler([])
      return
    }

    super.userNotificationCenter(
      center,
      willPresent: notification,
      withCompletionHandler: completionHandler
    )
  }

  override func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    didReceive response: UNNotificationResponse,
    withCompletionHandler completionHandler: @escaping () -> Void
  ) {
    let plugin = FreshchatSdkPlugin()
    let payload = response.notification.request.content.userInfo

    if plugin.isFreshchatNotification(payload) {
      // Opens the conversation the notification came from.
      plugin.handlePushNotification(payload)
      completionHandler()
      return
    }

    super.userNotificationCenter(
      center,
      didReceive: response,
      withCompletionHandler: completionHandler
    )
  }
}
