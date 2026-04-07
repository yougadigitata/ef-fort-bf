import 'package:audioplayers/audioplayers.dart';

final AudioPlayer _bellPlayer = AudioPlayer();
final AudioPlayer _clickPlayer = AudioPlayer();

/// Implémentation Mobile — utilise audioplayers
Future<void> playBellStartPlatform() async {
  try {
    await _bellPlayer.stop();
    await _bellPlayer.play(AssetSource('sounds/bell_start.mp3'));
  } catch (_) {}
}

Future<void> playBellEndPlatform() async {
  try {
    await _bellPlayer.stop();
    await _bellPlayer.play(AssetSource('sounds/bell_end.mp3'));
  } catch (_) {}
}

Future<void> playBellClickPlatform() async {
  try {
    await _clickPlayer.setVolume(0.4);
    await _clickPlayer.play(AssetSource('sounds/bell_start.mp3'));
  } catch (_) {}
}

Future<void> playBellCorrectPlatform() async {
  try {
    await _clickPlayer.setVolume(0.7);
    await _clickPlayer.play(AssetSource('sounds/bell_start.mp3'));
  } catch (_) {}
}

Future<void> playBellWrongPlatform() async {
  try {
    await _bellPlayer.setVolume(0.5);
    await _bellPlayer.play(AssetSource('sounds/bell_end.mp3'));
  } catch (_) {}
}

Future<void> playBellDashboardPlatform() async {
  try {
    await _bellPlayer.stop();
    await _bellPlayer.play(AssetSource('sounds/bell_start.mp3'));
  } catch (_) {}
}

Future<void> playBellTransitionPlatform() async {
  try {
    await _clickPlayer.setVolume(0.3);
    await _clickPlayer.play(AssetSource('sounds/bell_start.mp3'));
  } catch (_) {}
}

Future<void> playBellApplausePlatform() async {
  try {
    await _bellPlayer.stop();
    await _bellPlayer.play(AssetSource('sounds/bell_end.mp3'));
  } catch (_) {}
}
