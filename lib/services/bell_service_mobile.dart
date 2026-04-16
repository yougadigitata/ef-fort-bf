import 'package:audioplayers/audioplayers.dart';

// ── Lecteurs audio dédiés ────────────────────────────────────────
final AudioPlayer _bellPlayer = AudioPlayer();      // Sons longs (cloches, mélodies)
final AudioPlayer _clickPlayer = AudioPlayer();     // Sons courts (clics, marks)
final AudioPlayer _notifPlayer = AudioPlayer();     // Sons de notification intermédiaires

/// Implémentation Mobile — Sons DISTINCTS pour chaque événement
/// Fichiers audio :
///   onboarding.mp3  → mélodie douce ascendante
///   welcome.mp3     → fanfare chaleureuse
///   dashboard.mp3   → fanfare de succès triomphante
///   click.mp3       → pop/tick discret
///   exam_start.mp3  → cloche de début d'examen
///   reminder.mp3    → cloche courte d'alerte (rappel 5 min)
///   exam_end.mp3    → double cloche de fin d'examen
///   mark.mp3        → clic mécanique (noircissement case OMR)
///   applause.mp3    → applaudissements + victoire

/// 1. Onboarding — mélodie douce ascendante
Future<void> playBellStartPlatform() async {
  try {
    await _bellPlayer.stop();
    await _bellPlayer.play(AssetSource('sounds/onboarding.mp3'));
  } catch (_) {}
}

/// 2. Fin d'examen — double cloche
Future<void> playBellEndPlatform() async {
  try {
    await _bellPlayer.stop();
    await _bellPlayer.play(AssetSource('sounds/exam_end.mp3'));
  } catch (_) {}
}

/// 3. Clic bouton / navigation QCM — pop/tick discret
Future<void> playBellClickPlatform() async {
  try {
    await _clickPlayer.setVolume(0.6);
    await _clickPlayer.stop();
    await _clickPlayer.play(AssetSource('sounds/click.mp3'));
  } catch (_) {}
}

/// 4. Bonne réponse QCM — ding positif (accord harmonieux)
Future<void> playBellCorrectPlatform() async {
  try {
    await _notifPlayer.setVolume(0.7);
    await _notifPlayer.stop();
    await _notifPlayer.play(AssetSource('sounds/dashboard.mp3'));
  } catch (_) {}
}

/// 5. Mauvaise réponse QCM — son discret neutre
Future<void> playBellWrongPlatform() async {
  try {
    await _notifPlayer.setVolume(0.5);
    await _notifPlayer.stop();
    await _notifPlayer.play(AssetSource('sounds/reminder.mp3'));
  } catch (_) {}
}

/// 6. Arrivée sur le Dashboard — fanfare de succès
Future<void> playBellDashboardPlatform() async {
  try {
    await _bellPlayer.stop();
    await _bellPlayer.play(AssetSource('sounds/dashboard.mp3'));
  } catch (_) {}
}

/// 7. Transition entre écrans / Écran de bienvenue — mélodie douce
Future<void> playBellTransitionPlatform() async {
  try {
    await _notifPlayer.setVolume(0.35);
    await _notifPlayer.stop();
    await _notifPlayer.play(AssetSource('sounds/welcome.mp3'));
  } catch (_) {}
}

/// 8. Soumission examen — applaudissements + victoire
Future<void> playBellApplausePlatform() async {
  try {
    await _bellPlayer.stop();
    await _bellPlayer.play(AssetSource('sounds/applause.mp3'));
  } catch (_) {}
}

/// 9. Début d'examen — cloche de départ
Future<void> playBellExamStartPlatform() async {
  try {
    await _bellPlayer.stop();
    await _bellPlayer.play(AssetSource('sounds/exam_start.mp3'));
  } catch (_) {}
}

/// 10. Rappel 5 minutes avant la fin — cloche courte d'alerte
Future<void> playBellReminderPlatform() async {
  try {
    await _notifPlayer.stop();
    await _notifPlayer.play(AssetSource('sounds/reminder.mp3'));
  } catch (_) {}
}

/// 11. Noircissement d'une case OMR — clic mécanique
Future<void> playBellMarkPlatform() async {
  try {
    await _clickPlayer.setVolume(0.5);
    await _clickPlayer.stop();
    await _clickPlayer.play(AssetSource('sounds/mark.mp3'));
  } catch (_) {}
}
