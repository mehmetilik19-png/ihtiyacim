import 'package:shared_preferences/shared_preferences.dart';
import 'quiz_progress_repo.dart';

class DailySpinRepo {
  static const _kLastSpin = 'daily_spin_last_ymd';

  Future<bool> canSpin() async {
    final p = await SharedPreferences.getInstance();
    final last = p.getString(_kLastSpin);
    final now = _ymd(DateTime.now());
    return last != now;
  }

  Future<int> spin() async {
    final p = await SharedPreferences.getInstance();
    final now = _ymd(DateTime.now());
    await p.setString(_kLastSpin, now);

    // ödüller (coin)
    const prizes = [0, 2, 3, 5, 7, 10, 15, 20];
    prizes.shuffle();

    final won = prizes.first;

    final pr = QuizProgressRepo();
    final current = await pr.getCoins();
    await pr.setCoins(current + won);

    return won;
  }

  String _ymd(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}