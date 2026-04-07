import 'package:flutter/foundation.dart';
import 'dart:js_interop';

/// Implémentation Web — utilise Web Audio API via JS interop

@JS('window.effortPlayBell')
external void _effortPlayBell(double frequency, double duration);

@JS('window.effortPlayWelcomeMelody')
external void _effortPlayWelcomeMelody();

@JS('window.effortPlayDoubleBell')
external void _effortPlayDoubleBell();

@JS('window.effortPlayClick')
external void _effortPlayClickJS();

@JS('window.effortPlayCorrect')
external void _effortPlayCorrectJS();

@JS('window.effortPlayWrong')
external void _effortPlayWrongJS();

@JS('window.effortPlayDashboard')
external void _effortPlayDashboardJS();

@JS('window.effortPlayTransition')
external void _effortPlayTransitionJS();

@JS('window.effortPlayApplause')
external void _effortPlayApplauseJS();

// ── Mélodie d'intro (Splash Screen — première animation) ──
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

// ── Double cloche (fin d'examen) ──
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

// ── Son de clic bouton (discret) ──
Future<void> playBellClickPlatform() async {
  if (!kIsWeb) return;
  try {
    _effortPlayClickJS();
  } catch (e) {
    if (kDebugMode) debugPrint('Web bell click error: $e');
  }
}

// ── Son bonne réponse ──
Future<void> playBellCorrectPlatform() async {
  if (!kIsWeb) return;
  try {
    _effortPlayCorrectJS();
  } catch (e) {
    if (kDebugMode) debugPrint('Web bell correct error: $e');
  }
}

// ── Son mauvaise réponse ──
Future<void> playBellWrongPlatform() async {
  if (!kIsWeb) return;
  try {
    _effortPlayWrongJS();
  } catch (e) {
    if (kDebugMode) debugPrint('Web bell wrong error: $e');
  }
}

// ── Son dashboard (arrivée) ──
Future<void> playBellDashboardPlatform() async {
  if (!kIsWeb) return;
  try {
    _effortPlayDashboardJS();
  } catch (e) {
    if (kDebugMode) debugPrint('Web bell dashboard error: $e');
  }
}

// ── Son transition écran ──
Future<void> playBellTransitionPlatform() async {
  if (!kIsWeb) return;
  try {
    _effortPlayTransitionJS();
  } catch (e) {
    if (kDebugMode) debugPrint('Web bell transition error: $e');
  }
}

// ── Son applaudissements (soumission examen) ──
Future<void> playBellApplausePlatform() async {
  if (!kIsWeb) return;
  try {
    _effortPlayApplauseJS();
  } catch (e) {
    if (kDebugMode) debugPrint('Web bell applause error: $e');
  }
}
