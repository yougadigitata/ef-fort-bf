import 'package:flutter/foundation.dart';
import 'dart:js_interop';

/// Implémentation Web — utilise Web Audio API via JS interop
@JS('window.effortPlayBell')
external void _effortPlayBell(double frequency, double duration);

@JS('window.effortPlayWelcomeMelody')
external void _effortPlayWelcomeMelody();

@JS('window.effortPlayDoubleBell')
external void _effortPlayDoubleBell();

Future<void> playBellStartPlatform() async {
  if (!kIsWeb) return;
  try {
    // Mélodie de bienvenue premium (Do-Mi-Sol-Do)
    _effortPlayWelcomeMelody();
  } catch (e) {
    // Fallback sur cloche simple
    try {
      _effortPlayBell(880, 2.5);
    } catch (_) {}
    if (kDebugMode) debugPrint('Web bell start error: $e');
  }
}

Future<void> playBellEndPlatform() async {
  if (!kIsWeb) return;
  try {
    _effortPlayDoubleBell();
  } catch (e) {
    try {
      _effortPlayBell(660, 3.0);
    } catch (_) {}
    if (kDebugMode) debugPrint('Web bell end error: $e');
  }
}

Future<void> playBellClickPlatform() async {
  if (!kIsWeb) return;
  try {
    _effortPlayBell(1100, 0.08); // Son court aigü de clic
  } catch (e) {
    if (kDebugMode) debugPrint('Web bell click error: $e');
  }
}
