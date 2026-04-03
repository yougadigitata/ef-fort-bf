// ══════════════════════════════════════════════════════════════
// SECURITE v1.0 — Bloquer les captures d'écran
// • Android : utilise FLAG_SECURE via platform channel
// • Web : CSS user-select none + watermark
// • Admin : exempté du blocage
// ══════════════════════════════════════════════════════════════

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/api_service.dart';

class SecuriteService {
  static const _channel = MethodChannel('ef_fort_bf/securite');
  static bool _isSecured = false;

  /// Activer le blocage selon le statut de l'utilisateur
  static Future<void> appliquerSecurite() async {
    if (ApiService.isAdmin) {
      // Admin : désactiver le blocage
      await desactiverBlocage();
    } else {
      // Utilisateur normal : activer le blocage
      await activerBlocage();
    }
  }

  /// Activer le blocage des captures d'écran
  static Future<void> activerBlocage() async {
    if (_isSecured) return;
    
    if (!kIsWeb) {
      try {
        await _channel.invokeMethod('setSecureFlag', {'secure': true});
        _isSecured = true;
        if (kDebugMode) debugPrint('🔒 Capture d\'écran bloquée');
      } catch (e) {
        // Sur les plateformes non-Android, ignoré silencieusement
        if (kDebugMode) debugPrint('SecuriteService: $e');
      }
    }
  }

  /// Désactiver le blocage (pour l'admin)
  static Future<void> desactiverBlocage() async {
    if (!_isSecured && !kIsWeb) return;
    
    if (!kIsWeb) {
      try {
        await _channel.invokeMethod('setSecureFlag', {'secure': false});
        _isSecured = false;
        if (kDebugMode) debugPrint('🔓 Capture d\'écran autorisée (admin)');
      } catch (e) {
        if (kDebugMode) debugPrint('SecuriteService desactiver: $e');
      }
    }
  }
}

/// Widget protégé contre les captures d'écran
/// Pour le web, il affiche un watermark si l'utilisateur n'est pas admin
class SecureScreenWrapper extends StatelessWidget {
  final Widget child;
  final bool forceProtect; // Forcer la protection même pour les non-abonnés

  const SecureScreenWrapper({
    super.key,
    required this.child,
    this.forceProtect = false,
  });

  @override
  Widget build(BuildContext context) {
    final isAdmin = ApiService.isAdmin;
    
    // Admin : pas de protection
    if (isAdmin) return child;

    // Web : overlay semi-transparent avec watermark
    if (kIsWeb) {
      return Stack(
        children: [
          child,
          // Watermark discret pour décourager les screenshots
          IgnorePointer(
            child: Positioned.fill(
              child: CustomPaint(
                painter: _WatermarkPainter(),
              ),
            ),
          ),
        ],
      );
    }

    // Mobile/Desktop : le blocage est géré par SecuriteService au niveau système
    return child;
  }
}

/// Peintre de watermark (pour le web)
class _WatermarkPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final textPainter = TextPainter(
      text: const TextSpan(
        text: 'EF-FORT.BF',
        style: TextStyle(
          color: Color(0x12000000),
          fontSize: 28,
          fontWeight: FontWeight.w900,
          letterSpacing: 4,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    // Répéter le watermark en diagonale
    canvas.save();
    canvas.rotate(-0.4);
    double y = -size.height;
    while (y < size.height * 2) {
      double x = -size.width;
      while (x < size.width * 2) {
        textPainter.paint(canvas, Offset(x, y));
        x += 200;
      }
      y += 150;
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
