/// Facade (PAT-11) over the platform push APIs (Firebase Cloud Messaging):
/// permission, device token and token refresh. The rest of the app never
/// imports Firebase.
abstract interface class PushService {
  /// False when Firebase is not configured on this build (no
  /// `google-services.json` / `GoogleService-Info.plist`): push is off and
  /// every other member answers as if the user had said no.
  bool get isAvailable;

  /// `android` or `ios`, as `POST /api/devices` expects.
  String get platform;

  /// Shows the system dialog when needed (Android 13+, iOS). True if the app
  /// may show notifications.
  Future<bool> requestPermission();

  /// Current FCM registration token, or null when there is none.
  Future<String?> getToken();

  /// New tokens issued by FCM while the app runs (Observer, PAT-06).
  Stream<String> get onTokenRefresh;
}
