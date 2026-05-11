import 'dart:math';

class InsightPolicy {
  /// workDone: iş gerçekten yapıldı mı
  /// confidence: 0..1 (ne kadar emin)
  /// baseRate: ortalama ekleme oranı
  static bool shouldAdd({
    required bool workDone,
    required double confidence,
    double baseRate = 0.35,
    int? seed,
  }) {
    if (!workDone) return false;
    if (confidence < 0.55) return false;

    final rnd = Random(seed);
    final p = (baseRate + (confidence - 0.55)).clamp(0.0, 0.75);
    return rnd.nextDouble() < p;
  }
}