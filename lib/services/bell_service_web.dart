import 'package:flutter/foundation.dart';
import 'dart:js_interop';

/// Implémentation Web — utilise Web Audio API via JS interop
@JS('window.effortPlayBell')
external void _effortPlayBell(double frequency, double duration);

Future<void> playBellStartPlatform() async {
  if (!kIsWeb) return;
  try {
    _effortPlayBell(880, 2.5);
  } catch (e) {
    if (kDebugMode) debugPrint('Web bell start error: $e');
  }
}

Future<void> playBellEndPlatform() async {
  if (!kIsWeb) return;
  try {
    _effortPlayBell(660, 3.0);
  } catch (e) {
    if (kDebugMode) debugPrint('Web bell end error: $e');
  }
}
