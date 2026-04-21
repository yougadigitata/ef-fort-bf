import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Helper robuste pour lancer une URL (tel:, https://wa.me, mailto:, etc.)
///
/// Contrairement à `canLaunchUrl` + `launchUrl`, cette méthode :
///  - tente directement `launchUrl` (plus fiable sur Android 11+ où
///    `canLaunchUrl` peut renvoyer `false` à tort si l'app cible n'est
///    pas listée dans `<queries>` du manifest),
///  - bascule sur `LaunchMode.platformDefault` en secours,
///  - affiche un `SnackBar` de feedback en cas d'échec (au lieu d'un
///    bouton qui semble "ne rien faire").
class SafeLauncher {
  static Future<void> launch(
    BuildContext context,
    Uri uri, {
    String? fallbackMessage,
    LaunchMode mode = LaunchMode.externalApplication,
  }) async {
    try {
      final ok = await launchUrl(uri, mode: mode);
      if (!ok && context.mounted && fallbackMessage != null) {
        _showFallback(context, fallbackMessage);
      }
    } catch (_) {
      try {
        await launchUrl(uri, mode: LaunchMode.platformDefault);
      } catch (_) {
        if (context.mounted && fallbackMessage != null) {
          _showFallback(context, fallbackMessage);
        }
      }
    }
  }

  static void _showFallback(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFFFF7900),
        duration: const Duration(seconds: 6),
      ),
    );
  }
}
