import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

/// Opens a link in another app (dialer, maps, browser).
abstract interface class ExternalLauncher {
  /// True if an app handled [uri]; false if none could (never throws).
  Future<bool> open(Uri uri);
}

/// Facade (PAT-11): hides `url_launcher` behind a one-method interface.
class UrlLauncherService implements ExternalLauncher {
  const UrlLauncherService();

  @override
  Future<bool> open(Uri uri) async {
    try {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } on Exception {
      return false;
    }
  }
}

final externalLauncherProvider = Provider<ExternalLauncher>(
  (_) => const UrlLauncherService(),
);
