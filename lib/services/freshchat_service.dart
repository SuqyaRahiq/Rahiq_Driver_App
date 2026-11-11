import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:freshchat_sdk/freshchat_sdk.dart';
import 'package:rahiq_driver/data/api/api_client.dart';
import 'package:rahiq_driver/data/api/driver/driver_auth_api.dart';
import 'package:rahiq_driver/data/storage/auth_storage.dart';

class FreshchatService {
  /// Talks to the app delegate, which owns the raw APNs token. Nothing on the
  /// Dart side can reach it: the plugin's iOS `setPushRegistrationToken`
  /// expects `NSData`, so the Flutter method takes a token string it cannot
  /// use here. iOS only.
  static const MethodChannel _pushChannel = MethodChannel(
    'com.rahiq.driver/freshchat_push',
  );

  /// The tag the chat screen is opened with, so the driver lands in the
  /// managers channel rather than a channel list.
  static const List<String> supportTags = ["talk_with_managers"];

  /// Ceiling on any single call into the native SDK.
  ///
  /// The plugin's async getters complete their platform-channel result only
  /// from inside a Freshchat callback, with no error path — so an SDK that
  /// never answers (misconfigured, not initialized, offline mid-handshake)
  /// leaves the Dart future pending *forever*. A `try`/`catch` cannot rescue
  /// a future that never settles; only a timeout can. Every `await` on the
  /// SDK below carries one, so support chat degrades instead of freezing
  /// whatever screen is waiting on it.
  static const Duration _nativeCallTimeout = Duration(seconds: 8);

  /// In-flight [ensureAuthenticated] call, so the things that can ask for
  /// authentication at once — startup, login, opening the chat, the SDK's own
  /// token events — share one attempt instead of racing to mint competing
  /// tokens.
  static Future<void>? _authInFlight;

  /// Tokens the SDK has rejected in a row. A token signed with the wrong key
  /// is rejected every time, and each rejection comes back as an event asking
  /// for a new one, so without a stop the app would keep minting against the
  /// backend for as long as it stayed open. Reset once one is accepted.
  static int _rejectedTokens = 0;
  static const int _maxRejectedTokens = 3;

  /// Unread support messages, for the profile tile's badge. A notifier rather
  /// than screen state because the count changes from the SDK's own events —
  /// a push arriving, or the driver reading the thread on the native chat
  /// screen — not from anything the Flutter side does.
  static final ValueNotifier<int> unreadCount = ValueNotifier<int>(0);

  /// Re-reads the unread count from the SDK. Safe to call often; it is a
  /// local lookup, not a network round trip.
  ///
  /// Counts every channel rather than filtering on [supportTags], which the
  /// topic does carry in the Freshchat dashboard. Both reads return the same
  /// number — the app has a single entry into Freshchat, so every unread
  /// message it can receive is a managers message — and the unfiltered read
  /// cannot silently go dark if that tag is ever renamed or removed there.
  static Future<void> refreshUnreadCount() async {
    try {
      final result = await Freshchat.getUnreadCountAsync.timeout(
        _nativeCallTimeout,
      );

      // Both platforms answer with {status, count}. A failed lookup still
      // carries a count — 0 on iOS — so trusting it would clear a badge that
      // should have stayed on. Android reports STATUS_SUCCESS/STATUS_ERROR.
      final status = result['status']?.toString().toUpperCase() ?? '';
      if (!status.contains('SUCCESS')) return;

      final raw = result['count'];
      final count = raw is int ? raw : int.tryParse('$raw') ?? 0;
      if (count != unreadCount.value) {
        unreadCount.value = count;
      }
    } catch (_) {
      // Only a badge: a stale count is the right failure.
    }
  }

  static void init() {
    Freshchat.onFreshchatEvents.listen((event) {
      final eventName = (event is Map ? event['event_name'] : null)
          ?.toString()
          .toLowerCase();
      if (eventName == null) return;

      // A conversation being resolved ("End conversation" -> thank-you
      // dialog) means the *next* time the driver opens the chat, it should
      // look like a fresh session again. Freshchat's event names aren't part
      // of the plugin's public API, so this matches on "resolv" rather than
      // an exact constant.
      if (eventName.contains('resolv')) {
        AuthStorage.setChatNeedsWelcome(true);
      }

      // `FCEventIdTokenStatusChange`: the SDK's view of our JWT moved, which
      // includes it lapsing mid-session. Left unanswered the SDK drops to
      // unauthenticated and stops syncing.
      if (eventName.contains('token')) {
        ensureAuthenticated().then((_) => registerPushToken());
      }
    });

    // Fires whenever the SDK's message count changes — a new message pushed
    // in, or the driver reading the thread on the native chat screen, which is
    // what clears the badge again.
    Freshchat.onMessageCountUpdate.listen((_) => refreshUnreadCount());
    refreshUnreadCount();

    // FCM tokens rotate (app reinstall, data clear, backup restore, etc.);
    // Freshchat only ever pushes to whatever token was last handed to it via
    // setPushRegistrationToken, so it has to be re-sent on every refresh, not
    // just once at startup.
    if (Platform.isAndroid) {
      FirebaseMessaging.instance.onTokenRefresh.listen((token) {
        Freshchat.setPushRegistrationToken(token);
      });
    }

    // On iOS, listen for callbacks from AppDelegate when APNs token arrives
    if (Platform.isIOS) {
      _pushChannel.setMethodCallHandler((call) async {
        if (call.method == 'onApnsTokenReceived') {
          await registerPushToken(maxRetries: 3);
        }
      });
    }

    // The plugin's own hook for "the SDK wants a fresh token". It overlaps
    // with the token event above; either may fire first depending on
    // platform, and [ensureAuthenticated] is idempotent, so listening to both
    // closes the gap if one is silent.
    Freshchat.onJwtRefresh.listen((_) async {
      await ensureAuthenticated();
      await registerPushToken();
    });

    // `onRestoreIdGenerated` is deliberately not listened to. Restore ids
    // belong to the external-id scheme that JWT sign-in replaces, and
    // Freshchat does not mint one for a JWT user.
  }

  /// Hands the current push token (APNs on iOS, FCM on Android) to Freshchat
  /// with automatic retries so that early startup or network delays do not
  /// drop the token.
  static Future<bool> registerPushToken({
    int maxRetries = 5,
    Duration delay = const Duration(milliseconds: 600),
  }) async {
    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      final success = await _executeTokenRegistration();
      if (success) return true;
      if (attempt < maxRetries) {
        await Future.delayed(delay);
      }
    }
    return false;
  }

  static Future<bool> _executeTokenRegistration() async {
    if (Platform.isIOS) {
      try {
        final applied = await _pushChannel.invokeMethod<bool>('syncPushToken');
        return applied == true;
      } catch (_) {
        return false;
      }
    }

    if (!Platform.isAndroid) return false;

    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token == null || token.isEmpty) return false;
      Freshchat.setPushRegistrationToken(token);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Reads the token status straight from the SDK.
  ///
  /// The copy in storage cannot answer this. It says nothing about whether the
  /// SDK ever received a token — after a cold start it holds none, however
  /// fresh ours is — and nothing about whether Freshchat accepted it.
  static Future<JwtTokenStatus> _idTokenStatus() async {
    try {
      return await Freshchat.getUserIdTokenStatus.timeout(_nativeCallTimeout);
    } catch (_) {
      // Treat an unreadable status as "no token": re-sending one the SDK
      // already has is harmless, skipping one it needs is not.
      return JwtTokenStatus.TOKEN_NOT_SET;
    }
  }

  /// Brings the SDK to an authenticated state, doing the least work that gets
  /// it there.
  ///
  /// With user authentication enforced, an unauthenticated SDK does not sync,
  /// and the chat screen drops a driver whose token is missing or rejected.
  /// Safe to call from anywhere, as often as you like — concurrent callers
  /// share the one attempt, and a healthy token costs a single status read.
  static Future<void> ensureAuthenticated() {
    return _authInFlight ??= _authenticate().whenComplete(() {
      _authInFlight = null;
    });
  }

  static Future<void> _authenticate() async {
    try {
      // Minting a token needs the driver's own session.
      if (!AuthStorage.isLoggedIn) return;

      final status = await _idTokenStatus();

      // Already good, or a token is mid-handshake and a second one would only
      // restart it.
      if (status == JwtTokenStatus.TOKEN_VALID) {
        _rejectedTokens = 0;
        return;
      }
      if (status == JwtTokenStatus.TOKEN_NOT_PROCESSED) return;

      if (status == JwtTokenStatus.TOKEN_INVALID &&
          ++_rejectedTokens > _maxRejectedTokens) {
        return;
      }

      // Cold start: the SDK holds nothing, but the token saved last session is
      // still good and still names the same `freshchat_uuid`, so restoring
      // with it costs a method call rather than a round trip.
      final stored = AuthStorage.freshchatToken;
      if (status == JwtTokenStatus.TOKEN_NOT_SET && !_isTokenExpired(stored)) {
        Freshchat.restoreUserWithIdToken(stored!);
        await _awaitTokenSettled();
        return;
      }

      final token = await _mintIdToken();
      if (token == null) return;

      // [Freshchat.restoreUserWithIdToken] is the call for a signed-in user:
      // it creates the user the token's `reference_id` names, or picks up the
      // existing one — and their conversation history — on a reinstall or a
      // second device. [Freshchat.setUserWithIdToken] only updates a user
      // already restored.
      Freshchat.restoreUserWithIdToken(token);
      await _awaitTokenSettled();
    } catch (_) {
      // Most callers are fire-and-forget event listeners, so an escaping
      // error would only surface as an unhandled async error.
    }
  }

  /// Waits for the SDK to finish processing a token it was just handed.
  ///
  /// `restoreUserWithIdToken` returns the moment the token is handed over;
  /// the SDK validates it against the server afterwards and sits at
  /// `TOKEN_NOT_PROCESSED` until that lands. Opening the chat before then
  /// opens it on an SDK that is still unauthenticated.
  static Future<void> _awaitTokenSettled() async {
    const step = Duration(milliseconds: 150);
    const limit = Duration(seconds: 5);
    final deadline = DateTime.now().add(limit);

    while (DateTime.now().isBefore(deadline)) {
      await Future.delayed(step);
      final status = await _idTokenStatus();
      if (status == JwtTokenStatus.TOKEN_NOT_PROCESSED ||
          status == JwtTokenStatus.TOKEN_NOT_SET) {
        continue;
      }
      if (status == JwtTokenStatus.TOKEN_VALID) _rejectedTokens = 0;
      return;
    }
  }

  /// Asks the backend for a JWT naming this device's Freshchat user and
  /// stores it, or returns null if it could not be obtained.
  ///
  /// The token's `freshchat_uuid` claim has to match the uuid the SDK is
  /// currently using, which is why that goes up with the request; the backend
  /// pairs it with the driver's own `reference_id` and signs it.
  static Future<String?> _mintIdToken() async {
    try {
      final freshchatUuid = await Freshchat.getFreshchatUserId.timeout(
        _nativeCallTimeout,
      );
      if (freshchatUuid.isEmpty) return null;

      final response = await DriverAuthApi(
        ApiClient(),
      ).generateFreshchatToken(freshchatUuid);
      if (response.statusCode != 200 || response.data['success'] != true) {
        return null;
      }

      final token = response.data['data']?['token'] as String?;
      if (token == null || token.isEmpty) return null;

      await AuthStorage.saveFreshchatToken(token);
      return token;
    } catch (_) {
      return null;
    }
  }

  /// Cheap local pre-check, used only to decide whether the stored token is
  /// worth re-sending before spending a round trip on a new one. Anything it
  /// cannot parse counts as expired, so the fallback is always the safe one.
  static bool _isTokenExpired(String? token) {
    if (token == null || token.isEmpty) return true;
    try {
      final parts = token.split('.');
      if (parts.length != 3) return true;
      final payload = base64Url.normalize(parts[1]);
      final payloadMap = jsonDecode(utf8.decode(base64Url.decode(payload)));
      if (payloadMap is Map && payloadMap['exp'] is int) {
        // Treated as expired 5 minutes early.
        final exp = (payloadMap['exp'] as int) * 1000 - 300000;
        return DateTime.now().millisecondsSinceEpoch > exp;
      }
    } catch (_) {
      return true;
    }
    return true;
  }

  static Future<void> showConversations(
    BuildContext context, {
    List<String> tags = supportTags,
    String? filteredViewTitle = "Talk with Managers",
  }) async {
    await ensureAuthenticated();
    await registerPushToken(maxRetries: 3);
    final effectiveTags = tags.isEmpty ? supportTags : tags;
    if (effectiveTags.isNotEmpty) {
      await _maybeTriggerWelcomeBot(effectiveTags.first);
    }
    Freshchat.showConversations(
      tags: effectiveTags,
      filteredViewTitle: filteredViewTitle ?? "Talk with Managers",
    );
  }

  /// Nudges the bot's welcome flow when the chat screen is opened on a
  /// conversation Freshchat has told us it resolved.
  ///
  /// [Freshchat.sendMessage] posts a real message on the driver's behalf — the
  /// SDK has no silent variant. It is taken up by the bot's own flow only
  /// when it lands on a resolved conversation, because that starts a new one
  /// for the bot to take over; sent into a conversation that is still open it
  /// just sits in the thread as a stray "Hello" from the driver. So the
  /// greeting goes out on Freshchat's own resolve event and nothing else — a
  /// guess at when the conversation *might* have ended server-side is exactly
  /// what used to leave it visible.
  ///
  /// The cost is that a conversation auto-resolved server-side while the app
  /// was closed goes unnoticed: the driver lands back in it with no greeting,
  /// and whatever they type triggers the bot the same way this would have.
  static Future<void> _maybeTriggerWelcomeBot(String tag) async {
    if (!AuthStorage.chatNeedsWelcome) return;

    Freshchat.sendMessage(tag, "Hello");
    await AuthStorage.setChatNeedsWelcome(false);
  }

  /// Signs the saved driver in to Freshchat.
  ///
  /// Identity comes from the JWT the backend signs, not from `identifyUser`'s
  /// external-id/restore-id pair. With the account in strict JWT mode, the
  /// old pair (and `setUser`) is rejected, and an external id alone is
  /// something anyone holding the app key could claim. The name and phone an
  /// agent sees travel in the token's claims instead.
  ///
  /// Called at startup and on every profile save, so it stays cheap when
  /// there is nothing to do.
  static Future<void> authenticateUser() async {
    try {
      await ensureAuthenticated();

      // Re-bind the push token to the user the restore just settled on;
      // Freshchat delivers to whichever user a token is registered against.
      await registerPushToken();

      // The count read at startup belonged to whoever the SDK had before this
      // driver was restored, so take it again now that it means something.
      await refreshUnreadCount();
    } catch (_) {
      // Support chat is a side errand; it must never break sign-in.
    }
  }
}
