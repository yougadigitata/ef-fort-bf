import 'package:flutter/foundation.dart';
import 'bell_service_stub.dart'
    if (dart.library.js_interop) 'bell_service_web.dart'
    if (dart.library.io) 'bell_service_mobile.dart';

/// Service de cloche sonore — wrapper multi-plateforme v3.0
/// Sons DISTINCTS pour chaque événement :
///   playStart()       → Onboarding (première animation) — mélodie douce ascendante
///   playWelcome()     → Écran de bienvenue — fanfare chaleureuse
///   playDashboard()   → Arrivée sur le Dashboard — fanfare triomphante
///   playClick()       → Navigation boutons — pop/tick discret
///   playExamStart()   → Début d'examen — cloche de départ
///   playReminder()    → Rappel 5 min avant la fin — cloche courte
///   playEnd()         → Fin d'examen — double cloche
///   playMark()        → Noircissement case OMR — clic mécanique
///   playApplause()    → Soumission examen — applaudissements + victoire
///   playCorrect()     → Bonne réponse QCM — accord harmonieux
///   playWrong()       → Mauvaise réponse QCM — son neutre discret

class BellService {
  // ── Sons DISTINCTS v3.0 ──────────────────────────────────────────

  /// Onboarding — première animation (mélodie douce ascendante Do-Mi-Sol)
  static Future<void> playStart() async {
    try {
      await playBellStartPlatform();
    } catch (e) {
      if (kDebugMode) debugPrint('BellService.playStart error: $e');
    }
  }

  /// Écran de bienvenue — fanfare chaleureuse
  static Future<void> playWelcome() async {
    try {
      await playBellTransitionPlatform();
    } catch (e) {
      if (kDebugMode) debugPrint('BellService.playWelcome error: $e');
    }
  }

  /// Arrivée sur le Dashboard — fanfare de succès triomphante
  static Future<void> playDashboard() async {
    try {
      await playBellDashboardPlatform();
    } catch (e) {
      if (kDebugMode) debugPrint('BellService.playDashboard error: $e');
    }
  }

  /// Navigation entre les boutons — pop/tick discret
  static Future<void> playClick() async {
    try {
      await playBellClickPlatform();
    } catch (e) {
      if (kDebugMode) debugPrint('BellService.playClick error: $e');
    }
  }

  /// Début d'examen (Examens Types) — cloche de début
  static Future<void> playExamStart() async {
    try {
      await playBellExamStartPlatform();
    } catch (e) {
      if (kDebugMode) debugPrint('BellService.playExamStart error: $e');
    }
  }

  /// Rappel 5 minutes avant la fin de l'examen — cloche courte d'alerte
  static Future<void> playReminder() async {
    try {
      await playBellReminderPlatform();
    } catch (e) {
      if (kDebugMode) debugPrint('BellService.playReminder error: $e');
    }
  }

  /// Fin de l'examen — double cloche
  static Future<void> playEnd() async {
    try {
      await playBellEndPlatform();
    } catch (e) {
      if (kDebugMode) debugPrint('BellService.playEnd error: $e');
    }
  }

  /// Noircissement d'une case (feuille de réponse OMR) — clic mécanique
  static Future<void> playMark() async {
    try {
      await playBellMarkPlatform();
    } catch (e) {
      if (kDebugMode) debugPrint('BellService.playMark error: $e');
    }
  }

  /// Soumission de l'examen — applaudissements + mélodie de victoire
  static Future<void> playApplause() async {
    try {
      await playBellApplausePlatform();
    } catch (e) {
      if (kDebugMode) debugPrint('BellService.playApplause error: $e');
    }
  }

  /// Bonne réponse QCM — accord harmonieux positif
  static Future<void> playCorrect() async {
    try {
      await playBellCorrectPlatform();
    } catch (e) {
      if (kDebugMode) debugPrint('BellService.playCorrect error: $e');
    }
  }

  /// Mauvaise réponse QCM — son neutre discret
  static Future<void> playWrong() async {
    try {
      await playBellWrongPlatform();
    } catch (e) {
      if (kDebugMode) debugPrint('BellService.playWrong error: $e');
    }
  }
}
