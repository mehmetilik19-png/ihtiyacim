import 'dart:math';
import 'package:flutter/material.dart';

import 'quiz_repo.dart';
import 'quiz_progress_repo.dart';
import 'quiz_question.dart';

class QuizEngine {
  final QuizRepo repo;
  final QuizProgressRepo progress;

  late int lives;
  late int coins;

  // bu tur
  late int pos;
  late int totalCorrect;

  // kalıcı
  late int seasonCorrect;
  late int questionCursor;
  late int bestCorrect;

  late int jokerFifty;

  int jokerReveal = 0;
  int jokerPercent = 0;
  int breakTokens = 0;
  bool breakEarnedHappened = false;

  bool timerEnabled = true;
  int timeLimitSeconds = 20;

  bool? lastWasCorrect;
  int? lastSelectedIndex;
  int? lastCorrectIndex;

  late QuizQuestion current;

  String milestoneMessage = '';

  QuizEngine(this.repo, this.progress);

  int get level => (seasonCorrect ~/ 5) + 1;
  double get progressPercent => (seasonCorrect / 100).clamp(0, 1);
  bool get isGameOver => lives <= 0;

  String get currentLeagueName {
    if (seasonCorrect >= 150) return 'Efsane Lig';
    if (seasonCorrect >= 100) return 'Elmas Lig';
    if (seasonCorrect >= 70) return 'Altın Lig';
    if (seasonCorrect >= 40) return 'Gümüş Lig';
    if (seasonCorrect >= 20) return 'Bronz Lig';
    return 'Başlangıç Ligi';
  }

  String get nextLeagueName {
    if (seasonCorrect < 20) return 'Bronz Lig';
    if (seasonCorrect < 40) return 'Gümüş Lig';
    if (seasonCorrect < 70) return 'Altın Lig';
    if (seasonCorrect < 100) return 'Elmas Lig';
    if (seasonCorrect < 150) return 'Efsane Lig';
    return 'Zirve';
  }

  int get questionsToNextLeague {
    if (seasonCorrect < 20) return 20 - seasonCorrect;
    if (seasonCorrect < 40) return 40 - seasonCorrect;
    if (seasonCorrect < 70) return 70 - seasonCorrect;
    if (seasonCorrect < 100) return 100 - seasonCorrect;
    if (seasonCorrect < 150) return 150 - seasonCorrect;
    return 0;
  }

  int get currentRank {
    final base = 50 - (seasonCorrect ~/ 2);
    return base.clamp(1, 50);
  }

  Color get leagueColor {
    if (seasonCorrect >= 150) return const Color(0xFFB06CFF);
    if (seasonCorrect >= 100) return const Color(0xFF59D7FF);
    if (seasonCorrect >= 70) return const Color(0xFFFFC857);
    if (seasonCorrect >= 40) return const Color(0xFFC0C7D1);
    if (seasonCorrect >= 20) return const Color(0xFFCD7F32);
    return const Color(0xFF7A869A);
  }

  double get leagueProgress {
    if (seasonCorrect < 20) return (seasonCorrect / 20).clamp(0, 1);
    if (seasonCorrect < 40) return ((seasonCorrect - 20) / 20).clamp(0, 1);
    if (seasonCorrect < 70) return ((seasonCorrect - 40) / 30).clamp(0, 1);
    if (seasonCorrect < 100) return ((seasonCorrect - 70) / 30).clamp(0, 1);
    if (seasonCorrect < 150) return ((seasonCorrect - 100) / 50).clamp(0, 1);
    return 1;
  }

  Future<void> init() async {
    final seed = DateTime.now().millisecondsSinceEpoch;

    await progress.init(seed: seed);
    await repo.init(seed: seed);

    lives = await progress.getLives();
    coins = await progress.getCoins();
    pos = await progress.getPosition();
    totalCorrect = await progress.getTotalCorrect();

    seasonCorrect = await progress.getSeasonCorrect();
    questionCursor = await progress.getQuestionCursor();
    bestCorrect = await progress.getBestCorrect();

    jokerFifty = await progress.getJokerFifty();

    if (lives <= 0) {
      lives = 4;
      await progress.setLives(lives);
    }

    current = repo.at(questionCursor);

    lastWasCorrect = null;
    lastSelectedIndex = null;
    lastCorrectIndex = null;
  }

  Future<void> answer(int selected) async {
    lastSelectedIndex = selected;
    lastCorrectIndex = current.correctIndex;

    final correct = selected == current.correctIndex;
    lastWasCorrect = correct;

    if (correct) {
      totalCorrect++;
      seasonCorrect++;
      coins++;

      if (totalCorrect > bestCorrect) {
        bestCorrect = totalCorrect;
        await progress.setBestCorrect(bestCorrect);
      }

      milestoneMessage = _milestoneText(seasonCorrect);

      await progress.setTotalCorrect(totalCorrect);
      await progress.setSeasonCorrect(seasonCorrect);
      await progress.setCoins(coins);
    } else {
      lives--;
      await progress.setLives(lives);
    }
  }

  String _milestoneText(int v) {
    if (v == 5) return 'İyi başladın';
    if (v == 10) return 'Çok iyi gidiyorsun';
    if (v == 20) return 'Bronz Lig açıldı';
    if (v == 40) return 'Gümüş Lig açıldı';
    if (v == 70) return 'Altın Lig açıldı';
    if (v == 100) return 'Elmas Lig açıldı';
    if (v == 150) return 'Efsane Lig açıldı';
    return '';
  }

  Future<void> advance() async {
    pos++;
    questionCursor++;

    await progress.setPosition(pos);
    await progress.setQuestionCursor(questionCursor);

    current = repo.at(questionCursor);

    lastWasCorrect = null;
    lastSelectedIndex = null;
    lastCorrectIndex = null;

    timeLimitSeconds = 20;
  }

  Future<void> timeout() async {
    lastWasCorrect = false;
    lastSelectedIndex = null;
    lastCorrectIndex = current.correctIndex;

    lives--;
    await progress.setLives(lives);
  }

  Future<void> resetRun() async {
    await progress.resetRun();

    lives = await progress.getLives();
    coins = await progress.getCoins();
    pos = await progress.getPosition();
    totalCorrect = await progress.getTotalCorrect();

    seasonCorrect = await progress.getSeasonCorrect();
    questionCursor = await progress.getQuestionCursor();
    bestCorrect = await progress.getBestCorrect();

    jokerFifty = await progress.getJokerFifty();

    jokerReveal = 0;
    jokerPercent = 0;
    breakTokens = 0;
    breakEarnedHappened = false;

    current = repo.at(questionCursor);

    timeLimitSeconds = 20;
    timerEnabled = true;

    lastWasCorrect = null;
    lastSelectedIndex = null;
    lastCorrectIndex = null;
    milestoneMessage = '';
  }

  Future<List<int>?> useFifty() async {
    if (jokerFifty <= 0) return null;

    jokerFifty--;
    await progress.setJokerFifty(jokerFifty);

    final wrongs = List.generate(current.options.length, (i) => i)
      ..remove(current.correctIndex);

    wrongs.shuffle(Random());

    return wrongs.take(2).toList();
  }

  Future<int?> useReveal() async {
    return null;
  }

  Future<List<int>> usePercentFixed() async {
    final len = current.options.length;
    final base = 100 ~/ len;
    final p = List<int>.filled(len, base);
    p[0] += 100 - p.reduce((a, b) => a + b);
    return p;
  }

  Future<bool> useBreakToken() async {
    return false;
  }
}