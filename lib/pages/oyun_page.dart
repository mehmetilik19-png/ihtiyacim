import 'dart:async';
import 'package:flutter/material.dart';

import 'package:ihtiyacim/game/quiz_engine.dart';
import 'package:ihtiyacim/game/quiz_repo.dart';
import 'package:ihtiyacim/game/quiz_progress_repo.dart' as quiz_progress_repo;

import 'package:ihtiyacim/core/sfx/bgm_player.dart';
import 'package:ihtiyacim/core/sfx/sfx_player.dart';

class OyunPage extends StatefulWidget {
  const OyunPage({super.key});

  @override
  State<OyunPage> createState() => _OyunPageState();
}

class _OyunPageState extends State<OyunPage> {
  late final QuizEngine engine;

  static const int _questionDuration = 20;
  static const int _maxLives = 4;

  bool _loading = true;
  bool _locked = false;

  Timer? _timer;
  int _remaining = _questionDuration;

  Set<int> _disabledOptions = {};

  int _timeJoker = 1;
  int _passJoker = 1;

  int _streak = 0;
  int _bestStreak = 0;

  String _infoText = '20 saniye içinde doğru cevabı bul.';

  @override
  void initState() {
    super.initState();
    BgmPlayer.start();

    engine = QuizEngine(
      QuizRepo(),
      quiz_progress_repo.QuizProgressRepo(),
    );

    _boot();
  }

  @override
  void dispose() {
    _timer?.cancel();
    BgmPlayer.stop();
    super.dispose();
  }

  Future<void> _boot() async {
    await engine.init();
    await engine.resetRun();

    engine.lastWasCorrect = null;
    engine.lastSelectedIndex = null;
    engine.lastCorrectIndex = null;

    _resetQuestionState();

    if (mounted) {
      setState(() => _loading = false);
    }
  }

  void _resetQuestionState() {
    _disabledOptions = {};
    _locked = false;
    _infoText = '20 saniye içinde doğru cevabı bul.';

    _timer?.cancel();
    _remaining = _questionDuration;

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      if (!mounted || _locked) return;

      if (_remaining > 0) {
        setState(() => _remaining--);
      }

      if (_remaining <= 0) {
        timer.cancel();
        await _handleTimeout();
      }
    });

    if (mounted) setState(() {});
  }

  Future<void> _handleTimeout() async {
    if (_locked || engine.isGameOver) return;

    _locked = true;
    _streak = 0;

    await engine.timeout();
    await SfxPlayer.wrong();

    if (!mounted) return;

    setState(() {
      _infoText = 'Süre doldu.';
    });

    await Future.delayed(const Duration(milliseconds: 850));
    if (!mounted) return;

    if (engine.isGameOver || engine.lives <= 0) {
      await _showGameOver();
      return;
    }

    await engine.advance();
    _resetQuestionState();
  }

  Future<void> _handleTap(int index) async {
    if (_locked || engine.isGameOver) return;
    if (_disabledOptions.contains(index)) return;

    _locked = true;
    _timer?.cancel();

    await engine.answer(index);

    if (engine.lastWasCorrect == true) {
      _streak++;
      if (_streak > _bestStreak) {
        _bestStreak = _streak;
      }

      await SfxPlayer.correct();

      if (_streak == 5) {
        engine.jokerFifty++;
        _infoText = '5 doğru seri yaptın. +1 %50 kazandın!';
      } else if (_streak >= 3) {
        _infoText = '$_streak doğru seri yaptın!';
      } else {
        _infoText = 'Doğru cevap!';
      }
    } else {
      _streak = 0;
      await SfxPlayer.wrong();
      _infoText = 'Yanlış cevap.';
    }

    if (!mounted) return;
    setState(() {});

    await Future.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;

    if (engine.isGameOver || engine.lives <= 0) {
      await _showGameOver();
      return;
    }

    await engine.advance();
    _resetQuestionState();
  }

  Future<void> _useFifty() async {
    if (_locked || engine.jokerFifty <= 0) return;

    final removed = await engine.useFifty();
    if (!mounted) return;
    if (removed == null || removed.isEmpty) return;

    setState(() {
      _disabledOptions = removed.toSet();
      _infoText = '%50 kullanıldı.';
    });
  }

  void _useAddTime() {
    if (_locked || _timeJoker <= 0) return;

    setState(() {
      _timeJoker--;
      _remaining += 10;
      _infoText = '+10 saniye eklendi.';
    });
  }

  Future<void> _usePass() async {
    if (_locked || _passJoker <= 0) return;

    _locked = true;
    _timer?.cancel();

    setState(() {
      _passJoker--;
      _streak = 0;
      _infoText = 'Soru pas geçildi.';
    });

    await Future.delayed(const Duration(milliseconds: 350));
    if (!mounted) return;

    await engine.advance();
    _resetQuestionState();
  }

  Future<void> _showGameOver() async {
    _timer?.cancel();

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        backgroundColor: const Color(0xFF151A2F),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.emoji_events_rounded,
                color: Color(0xFF53D8FB),
                size: 42,
              ),
              const SizedBox(height: 12),
              const Text(
                'Tur Bitti',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 14),
              _resultRow('Bu tur doğru', '${engine.totalCorrect}'),
              const SizedBox(height: 8),
              _resultRow('Toplam doğru', '${engine.seasonCorrect}'),
              const SizedBox(height: 8),
              _resultRow('En yüksek seri', '$_bestStreak'),
              const SizedBox(height: 8),
              _resultRow('Lig', engine.currentLeagueName),
              const SizedBox(height: 8),
              _resultRow('Sıralama', '${engine.currentRank} / 50'),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () async {
                    Navigator.pop(ctx);

                    if (mounted) {
                      setState(() => _loading = true);
                    }

                    _timeJoker = 1;
                    _passJoker = 1;
                    _streak = 0;
                    _bestStreak = 0;

                    await engine.resetRun();

                    engine.lastWasCorrect = null;
                    engine.lastSelectedIndex = null;
                    engine.lastCorrectIndex = null;

                    _resetQuestionState();

                    if (mounted) {
                      setState(() => _loading = false);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF5B6CFF),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'Yeni Tur Başlat',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    Navigator.pop(context);
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: BorderSide(
                      color: Colors.white.withOpacity(0.16),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text('Ana Sayfaya Dön'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _resultRow(String title, String value) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              color: Colors.white.withOpacity(0.68),
              fontSize: 14,
            ),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Color _optionColor(int index) {
    if (engine.lastWasCorrect == null) {
      return Colors.white.withOpacity(0.08);
    }

    final selected = engine.lastSelectedIndex;
    final correct = engine.lastCorrectIndex;

    if (correct == index) return const Color(0xFF1F9D66);
    if (selected == index && selected != correct) {
      return const Color(0xFFC14D5A);
    }
    return Colors.white.withOpacity(0.08);
  }

  Color _timerColor() {
    if (_remaining <= 5) return const Color(0xFFFF6B6B);
    if (_remaining <= 10) return const Color(0xFFFFB84D);
    return const Color(0xFF4DD8FF);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: Color(0xFF0B1020),
        body: Center(
          child: CircularProgressIndicator(
            color: Color(0xFF5B6CFF),
          ),
        ),
      );
    }

    final q = engine.current;

    return Scaffold(
      backgroundColor: const Color(0xFF0B1020),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
        centerTitle: true,
        title: const Text(
          'Oyun',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            tooltip: 'Müziği Kapat',
            icon: const Icon(Icons.music_off_rounded),
            onPressed: () => BgmPlayer.stop(),
          ),
          IconButton(
            tooltip: 'Müziği Aç',
            icon: const Icon(Icons.music_note_rounded),
            onPressed: () => BgmPlayer.start(),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 6, 14, 12),
          child: Column(
            children: [
              _LeagueCard(engine: engine),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _TopMiniCard(
                      icon: Icons.favorite_rounded,
                      title: 'Can',
                      value: '${engine.lives.clamp(0, _maxLives)}/$_maxLives',
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _TopMiniCard(
                      icon: Icons.help_rounded,
                      title: 'Soru',
                      value: '${engine.pos + 1}',
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _TopMiniCard(
                      icon: Icons.local_fire_department_rounded,
                      title: 'Seri',
                      value: '$_streak',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  color: Colors.white.withOpacity(0.08),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.10),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.timer_rounded, color: _timerColor(), size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(99),
                        child: LinearProgressIndicator(
                          value: _remaining / _questionDuration,
                          minHeight: 7,
                          backgroundColor: Colors.white.withOpacity(0.08),
                          valueColor: AlwaysStoppedAnimation<Color>(_timerColor()),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '$_remaining sn',
                      style: TextStyle(
                        color: _timerColor(),
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: Colors.white.withOpacity(0.08),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.10),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      q.category,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.60),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      q.question,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        height: 1.28,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                  color: const Color(0xFF182241),
                  border: Border.all(
                    color: const Color(0xFF2A3A6A),
                  ),
                ),
                child: Text(
                  _infoText,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: Column(
                  children: List.generate(q.options.length, (index) {
                    if (_disabledOptions.contains(index)) {
                      return const SizedBox.shrink();
                    }

                    return Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(
                          bottom: index == q.options.length - 1 ? 0 : 8,
                        ),
                        child: InkWell(
                          onTap: _locked ? null : () => _handleTap(index),
                          borderRadius: BorderRadius.circular(18),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(18),
                              color: _optionColor(index),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.10),
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 34,
                                  height: 34,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.white.withOpacity(0.10),
                                  ),
                                  child: Text(
                                    ['A', 'B', 'C', 'D'][index],
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 15,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    q.options[index],
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      height: 1.25,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _JokerButton(
                      text: '%50',
                      count: engine.jokerFifty,
                      icon: Icons.filter_2_rounded,
                      onTap: _useFifty,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _JokerButton(
                      text: '+10 sn',
                      count: _timeJoker,
                      icon: Icons.timer_10_rounded,
                      onTap: _useAddTime,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _JokerButton(
                      text: 'Pas',
                      count: _passJoker,
                      icon: Icons.skip_next_rounded,
                      onTap: _usePass,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LeagueCard extends StatelessWidget {
  final QuizEngine engine;

  const _LeagueCard({required this.engine});

  @override
  Widget build(BuildContext context) {
    final nextLeague = engine.nextLeagueName;
    final needed = engine.questionsToNextLeague;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.white.withOpacity(0.07),
        border: Border.all(
          color: Colors.white.withOpacity(0.08),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  color: engine.leagueColor.withOpacity(0.18),
                ),
                child: Text(
                  engine.currentLeagueName,
                  style: TextStyle(
                    color: engine.leagueColor,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                'Sıra ${engine.currentRank}/50',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.80),
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Toplam doğru: ${engine.seasonCorrect}',
            style: TextStyle(
              color: Colors.white.withOpacity(0.78),
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'İlk 10 kişi üst lige çıkar',
            style: TextStyle(
              color: Colors.white.withOpacity(0.68),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: engine.leagueProgress,
              minHeight: 6,
              backgroundColor: Colors.white.withOpacity(0.08),
              valueColor: AlwaysStoppedAnimation(engine.leagueColor),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            needed <= 0
                ? 'Üst lige çıkmaya hazırsın: $nextLeague'
                : '$nextLeague için $needed soru daha gerekiyor',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _TopMiniCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _TopMiniCard({
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white.withOpacity(0.06),
        border: Border.all(
          color: Colors.white.withOpacity(0.08),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.white70, size: 17),
          const SizedBox(height: 6),
          Text(
            title,
            style: TextStyle(
              color: Colors.white.withOpacity(0.62),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _JokerButton extends StatelessWidget {
  final String text;
  final int count;
  final IconData icon;
  final VoidCallback onTap;

  const _JokerButton({
    required this.text,
    required this.count,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = count > 0;

    return SizedBox(
      height: 46,
      child: ElevatedButton.icon(
        onPressed: enabled ? onTap : null,
        icon: Icon(icon, size: 16),
        label: Text(
          '$text ($count)',
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 11,
          ),
        ),
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: enabled
              ? Colors.white.withOpacity(0.10)
              : Colors.white.withOpacity(0.04),
          foregroundColor: Colors.white,
          disabledForegroundColor: Colors.white38,
          disabledBackgroundColor: Colors.white.withOpacity(0.04),
          padding: const EdgeInsets.symmetric(horizontal: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }
}