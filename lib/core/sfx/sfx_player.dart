
import 'package:audioplayers/audioplayers.dart';
import 'bgm_player.dart';

class SfxPlayer {
  static final AudioPlayer _sfx = AudioPlayer();

  static Future<void> correct() async {
    await BgmPlayer.duck(); // 🔉 BGM kıs
    await _sfx.play(AssetSource('sfx/correct.mp3'));
    _sfx.onPlayerComplete.listen((_) {
      BgmPlayer.unduck(); // 🔊 geri aç
    });
  }

  static Future<void> wrong() async {
    await BgmPlayer.duck();
    await _sfx.play(AssetSource('sfx/wrong.mp3'));
    _sfx.onPlayerComplete.listen((_) {
      BgmPlayer.unduck();
    });
  }
}