import 'package:audioplayers/audioplayers.dart';

final AudioPlayer _bellPlayer = AudioPlayer();

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
