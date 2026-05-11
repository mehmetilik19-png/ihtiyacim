import 'dart:math';
import 'insight_context.dart';
import 'insight_bank.dart';
import 'insight_policy.dart';

class HumanResponseComposer {
  static String compose({
    required String workResult,
    required InsightContext context,
    required bool workDone,
    required double confidence, // 0..1
    int? seed,
  }) {
    final add = InsightPolicy.shouldAdd(
      workDone: workDone,
      confidence: confidence,
      seed: seed,
    );

    if (!add) return workResult;

    final list = InsightBank.pool[context] ??
        InsightBank.pool[InsightContext.general]!;

    final rnd = Random(seed);
    final insight = list[rnd.nextInt(list.length)];

    return '$workResult\n\n$insight';
  }
}