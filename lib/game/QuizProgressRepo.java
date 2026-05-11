import 'package:shared_preferences/shared_preferences.dart';

class QuizProgressRepo {
  static const _kInited = 'qp_inited';

  // oyun içi
  static const _kRunLives = 'qp_run_lives';
  static const _kRunCoins = 'qp_run_coins';
  static const _kRunPos = 'qp_run_pos';
  static const _kRunCorrect = 'qp_run_correct';

  // rekor
  static const _kBestCorrect = 'qp_best_correct';

  // jokerler
  static const _kJokerFifty = 'qp_joker_fifty';
  static const _kJokerTime = 'qp_joker_time';
  static const _kJokerPass = 'qp_joker_pass';

  late SharedPreferences _sp;

  Future<void> init({required int seed}) async {
    _sp = await SharedPreferences.getInstance();

    final inited = _sp.getBool(_kInited) ?? false;

    if (!inited) {
      await _sp.setBool(_kInited, true);
      await _sp.setInt(_kBestCorrect, 0);
      await resetRun();
    }
  }

  Future<void> resetRun() async {
    await _sp.setInt(_kRunLives, 4);
    await _sp.setInt(_kRunCoins, 0);
    await _sp.setInt(_kRunPos, 0);
    await _sp.setInt(_kRunCorrect, 0);

    await _sp.setInt(_kJokerFifty, 1);
    await _sp.setInt(_kJokerTime, 1);
    await _sp.setInt(_kJokerPass, 1);
  }

  // run
  Future<int> getLives() async => _sp.getInt(_kRunLives) ?? 4;
  Future<int> getCoins() async => _sp.getInt(_kRunCoins) ?? 0;
  Future<int> getPosition() async => _sp.getInt(_kRunPos) ?? 0;
  Future<int> getTotalCorrect() async => _sp.getInt(_kRunCorrect) ?? 0;

  Future<void> setLives(int value) async => _sp.setInt(_kRunLives, value);
  Future<void> setCoins(int value) async => _sp.setInt(_kRunCoins, value);
  Future<void> setPosition(int value) async => _sp.setInt(_kRunPos, value);
  Future<void> setTotalCorrect(int value) async =>
      _sp.setInt(_kRunCorrect, value);

  // rekor
  Future<int> getBestCorrect() async => _sp.getInt(_kBestCorrect) ?? 0;
  Future<void> setBestCorrect(int value) async =>
      _sp.setInt(_kBestCorrect, value);

  // jokerler
  Future<int> getJokerFifty() async => _sp.getInt(_kJokerFifty) ?? 1;
  Future<int> getJokerTime() async => _sp.getInt(_kJokerTime) ?? 1;
  Future<int> getJokerPass() async => _sp.getInt(_kJokerPass) ?? 1;

  Future<void> setJokerFifty(int value) async =>
      _sp.setInt(_kJokerFifty, value);
  Future<void> setJokerTime(int value) async =>
      _sp.setInt(_kJokerTime, value);
  Future<void> setJokerPass(int value) async =>
      _sp.setInt(_kJokerPass, value);

  // eski engine ile uyumluluk
  Future<int> getJokerReveal() async => 0;
  Future<int> getJokerPercent() async => 0;
  Future<int> getBreakTokens() async => 0;

  Future<void> setJokerReveal(int value) async {}
  Future<void> setJokerPercent(int value) async {}
  Future<void> setBreakTokens(int value) async {}
}