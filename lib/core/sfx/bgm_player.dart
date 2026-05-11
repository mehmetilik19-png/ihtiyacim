
import 'package:audioplayers/audioplayers.dart';

class BgmPlayer {
  static final AudioPlayer _player = AudioPlayer();
  static bool _started = false;

  static Future<void> start() async {
    if (_started) return; // tekrar tekrar başlatmasın
    _started = true;

    await _player.setReleaseMode(ReleaseMode.loop);
    await _player.setVolume(0.35);
    await _player.play(AssetSource('bgm/loop.mp3'));
  }

  static Future<void> stop() async {
    _started = false;
    await _player.stop();
  }

  /// 🔉 SFX çalarken müziği kıs
  static Future<void> duck() async {
    await _player.setVolume(0.12);
  }

  /// 🔊 SFX bitince eski haline getir
  static Future<void> unduck() async {
    await _player.setVolume(0.35);
  }
}