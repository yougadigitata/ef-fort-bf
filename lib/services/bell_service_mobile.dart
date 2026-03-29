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
    // Son court de clic via bell_start à faible volume
    await _clickPlayer.setVolume(0.4);
    await _clickPlayer.play(AssetSource('sounds/bell_start.mp3'));
  } catch (_) {}
}
