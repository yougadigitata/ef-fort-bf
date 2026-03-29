import 'package:flutter/foundation.dart';
import 'bell_service_stub.dart'
    if (dart.library.js_interop) 'bell_service_web.dart'
    if (dart.library.io) 'bell_service_mobile.dart';

/// Service de cloche sonore — wrapper multi-plateforme
class BellService {
  static Future<void> playStart() async {
    try {
      await playBellStartPlatform();
    } catch (e) {
      if (kDebugMode) debugPrint('BellService.playStart error: $e');
    }
  }

  static Future<void> playEnd() async {
    try {
      await playBellEndPlatform();
    } catch (e) {
      if (kDebugMode) debugPrint('BellService.playEnd error: $e');
    }
  }

  /// Son de clic — noircissement d'une case
  static Future<void> playClick() async {
    try {
      await playBellClickPlatform();
    } catch (e) {
      if (kDebugMode) debugPrint('BellService.playClick error: $e');
    }
  }
}
