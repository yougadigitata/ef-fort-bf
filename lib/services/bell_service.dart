import 'package:flutter/foundation.dart';
import 'bell_service_stub.dart'
    if (dart.library.js_interop) 'bell_service_web.dart'
    if (dart.library.io) 'bell_service_mobile.dart';

/// Service de cloche sonore — wrapper multi-plateforme v2.0
/// Sons : intro, fin examen, clic, bonne/mauvaise réponse, dashboard, transition, applaudissements
class BellService {
  // ── Sons EXISTANTS (inchangés) ──────────────────────────────────────

  /// Son d'intro — Splash Screen (première animation)
  static Future<void> playStart() async {
    try {
      await playBellStartPlatform();
    } catch (e) {
      if (kDebugMode) debugPrint('BellService.playStart error: $e');
    }
  }

  /// Fin d'examen — Double cloche
  static Future<void> playEnd() async {
    try {
      await playBellEndPlatform();
    } catch (e) {
      if (kDebugMode) debugPrint('BellService.playEnd error: $e');
    }
  }

  /// Son de clic — interaction bouton
  static Future<void> playClick() async {
    try {
      await playBellClickPlatform();
    } catch (e) {
      if (kDebugMode) debugPrint('BellService.playClick error: $e');
    }
  }

  // ── Sons NOUVEAUX (ajoutés sans rien supprimer) ─────────────────────

  /// Bonne réponse QCM — ding positif lumineux
  static Future<void> playCorrect() async {
    try {
      await playBellCorrectPlatform();
    } catch (e) {
      if (kDebugMode) debugPrint('BellService.playCorrect error: $e');
    }
  }

  /// Mauvaise réponse QCM — ploc doux discret
  static Future<void> playWrong() async {
    try {
      await playBellWrongPlatform();
    } catch (e) {
      if (kDebugMode) debugPrint('BellService.playWrong error: $e');
    }
  }

  /// Arrivée sur le Dashboard — fanfare de succès
  static Future<void> playDashboard() async {
    try {
      await playBellDashboardPlatform();
    } catch (e) {
      if (kDebugMode) debugPrint('BellService.playDashboard error: $e');
    }
  }

  /// Transition entre écrans — glissement doux
  static Future<void> playTransition() async {
    try {
      await playBellTransitionPlatform();
    } catch (e) {
      if (kDebugMode) debugPrint('BellService.playTransition error: $e');
    }
  }

  /// Soumission examen — applaudissements + mélodie de victoire
  static Future<void> playApplause() async {
    try {
      await playBellApplausePlatform();
    } catch (e) {
      if (kDebugMode) debugPrint('BellService.playApplause error: $e');
    }
  }
}
