import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

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

  static const Color _bg = Color(0xFF0B1020);
  static const Color _card = Color(0xFF1C2233);
  static const Color _softCard = Color(0xFF22283A);
  static const Color _beige = Color(0xFFD8B982);

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

  int? _jackpotQuestion;
  bool _jackpotShown = false;

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

  void _decideJackpotQuestion() {
    final r = Random().nextInt(100);
    _jackpotQuestion = r < 35 ? Random().nextInt(20) + 1 : null;
    _jackpotShown = false;
  }

  Future<void> _boot() async {
    await engine.init();
    await engine.resetRun();
    engine.lastWasCorrect = null;
    engine.lastSelectedIndex = null;
    engine.lastCorrectIndex = null;
    _decideJackpotQuestion();
    _resetQuestionState();
    if (mounted) setState(() => _loading = false);
  }

  void _resetQuestionState() {
    _disabledOptions = {};
    _locked = false;
    _infoText = '20 saniye içinde doğru cevabı bul.';
    _timer?.cancel();
    _remaining = _questionDuration;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      if (!mounted || _locked) return;
      if (_remaining > 0) setState(() => _remaining--);
      if (_remaining <= 0) {
        timer.cancel();
        await _handleTimeout();
      }
    });
    if (mounted) setState(() {});
  }

  Future<void> _maybeShowJackpot() async {
    if (_jackpotShown || _jackpotQuestion == null) return;
    final currentQuestionNumber = engine.pos + 1;
    if (currentQuestionNumber != _jackpotQuestion) return;
    _jackpotShown = true;
    _timer?.cancel();
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const _JackpotDialog(),
    );
  }

  Future<void> _handleTimeout() async {
    if (_locked || engine.isGameOver) return;
    _locked = true;
    _streak = 0;
    await engine.timeout();
    await SfxPlayer.wrong();
    if (!mounted) return;
    setState(() => _infoText = 'Süre doldu.');
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
      if (_streak > _bestStreak) _bestStreak = _streak;
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
    await _maybeShowJackpot();
    await Future.delayed(const Duration(milliseconds: 700));
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

  int _calculateScore() => (engine.totalCorrect * 100) + (_bestStreak * 25);

  Future<Map<String, dynamic>> _saveScoreAndGetRank(int score) async {
    final names = ['Sen', 'Ahmet', 'Zeynep', 'Mehmet', 'Elif', 'Murat', 'Ayşe', 'Kerem', 'Fatma', 'Ali'];
    final players = <Map<String, dynamic>>[];
    final random = Random();
    final myUid = FirebaseAuth.instance.currentUser?.uid ?? 'guest';
    players.add({'uid': myUid, 'name': 'Sen', 'score': score});
    for (int i = 1; i < names.length; i++) {
      players.add({'uid': 'bot_$i', 'name': names[i], 'score': random.nextInt(900) + 50});
    }
    players.sort((a, b) => (b['score'] as int).compareTo(a['score'] as int));
    int myRank = 1;
    for (int i = 0; i < players.length; i++) {
      players[i]['rank'] = i + 1;
      if (players[i]['uid'] == myUid) myRank = i + 1;
    }
    return {'rank': myRank, 'total': players.length, 'players': players};
  }

  Future<void> _showGameOver() async {
    _timer?.cancel();
    final score = _calculateScore();
    final rankData = await _saveScoreAndGetRank(score);
    final newRank = rankData['rank'] ?? 1;
    final totalPlayers = rankData['total'] ?? 1;
    final passed = totalPlayers - newRank;
    final players = List<Map<String, dynamic>>.from(rankData['players'] ?? []);

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        backgroundColor: const Color(0xFF151A2F),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.emoji_events_rounded, color: _beige, size: 46),
                const SizedBox(height: 12),
                const Text('Tur Bitti', style: TextStyle(color: Colors.white, fontSize: 25, fontWeight: FontWeight.w900)),
                const SizedBox(height: 16),
                TweenAnimationBuilder<int>(
                  tween: IntTween(begin: totalPlayers, end: newRank),
                  duration: const Duration(milliseconds: 1800),
                  builder: (context, value, _) => Text('$value. sıra', style: const TextStyle(color: _beige, fontSize: 36, fontWeight: FontWeight.w900)),
                ),
                const SizedBox(height: 8),
                Text('$totalPlayers kişi içinde', style: TextStyle(color: Colors.white.withOpacity(0.65), fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(height: 18),
                _resultRow('Doğru Sayısı', '${engine.totalCorrect}'),
                const SizedBox(height: 8),
                _resultRow('En iyi seri', '$_bestStreak'),
                const SizedBox(height: 8),
                _resultRow('Toplam puan', '$score'),
                const SizedBox(height: 8),
                _resultRow('Geçtiğin kişi', '$passed kişi'),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  constraints: const BoxConstraints(maxHeight: 240),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF22283A),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withOpacity(0.08)),
                  ),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: players.length,
                    itemBuilder: (context, index) {
                      final player = players[index];
                      final isMe = player['uid'] == (FirebaseAuth.instance.currentUser?.uid ?? 'guest');
                      return Container(
                        margin: const EdgeInsets.only(bottom: 6),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        decoration: BoxDecoration(
                          color: isMe ? _beige.withOpacity(0.18) : Colors.white.withOpacity(0.04),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: isMe ? _beige.withOpacity(0.45) : Colors.white.withOpacity(0.05)),
                        ),
                        child: Row(
                          children: [
                            SizedBox(width: 36, child: Text('${player['rank']}.', style: const TextStyle(color: _beige, fontWeight: FontWeight.w900))),
                            Expanded(child: Text('${player['name']}', overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800))),
                            const SizedBox(width: 8),
                            Text('${player['score']}', style: TextStyle(color: Colors.white.withOpacity(0.72), fontWeight: FontWeight.w800)),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () async {
                      Navigator.pop(ctx);
                      if (mounted) setState(() => _loading = true);
                      _timeJoker = 1;
                      _passJoker = 1;
                      _streak = 0;
                      _bestStreak = 0;
                      await engine.resetRun();
                      engine.lastWasCorrect = null;
                      engine.lastSelectedIndex = null;
                      engine.lastCorrectIndex = null;
                      _decideJackpotQuestion();
                      _resetQuestionState();
                      if (mounted) setState(() => _loading = false);
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: _beige, foregroundColor: Colors.black, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                    child: const Text('Yeni Tur Başlat', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton(
                    onPressed: () { Navigator.pop(ctx); Navigator.pop(context); },
                    style: OutlinedButton.styleFrom(foregroundColor: Colors.white, side: BorderSide(color: Colors.white.withOpacity(0.16)), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                    child: const Text('Ana Sayfaya Dön'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _resultRow(String title, String value) {
    return Row(
      children: [
        Expanded(child: Text(title, style: TextStyle(color: Colors.white.withOpacity(0.68), fontSize: 14))),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w800)),
      ],
    );
  }

  Color _optionColor(int index) {
    if (engine.lastWasCorrect == null) return _card;
    final selected = engine.lastSelectedIndex;
    final correct = engine.lastCorrectIndex;
    if (correct == index) return const Color(0xFF1F9D66);
    if (selected == index && selected != correct) return const Color(0xFFC14D5A);
    return _card;
  }

  Color _timerColor() {
    if (_remaining <= 5) return const Color(0xFFFF6B6B);
    if (_remaining <= 10) return const Color(0xFFFFB84D);
    return _beige;
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(backgroundColor: _bg, body: Center(child: CircularProgressIndicator(color: _beige)));
    }

    final q = engine.current;

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
        centerTitle: true,
        title: const Text('Oyun', style: TextStyle(fontWeight: FontWeight.w800)),
        actions: [
          IconButton(tooltip: 'Müziği Kapat', icon: const Icon(Icons.music_off_rounded), onPressed: () => BgmPlayer.stop()),
          IconButton(tooltip: 'Müziği Aç', icon: const Icon(Icons.music_note_rounded), onPressed: () => BgmPlayer.start()),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 6, 14, 12),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(child: _TopMiniCard(icon: Icons.favorite_rounded, title: 'Can', value: '${engine.lives.clamp(0, _maxLives)}/$_maxLives')),
                  const SizedBox(width: 8),
                  Expanded(child: _TopMiniCard(icon: Icons.help_rounded, title: 'Soru', value: '${engine.pos + 1}')),
                  const SizedBox(width: 8),
                  Expanded(child: _TopMiniCard(icon: Icons.local_fire_department_rounded, title: 'Seri', value: '$_streak')),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(18), color: _softCard, border: Border.all(color: Colors.white.withOpacity(0.08))),
                child: Row(
                  children: [
                    Icon(Icons.timer_rounded, color: _timerColor(), size: 18),
                    const SizedBox(width: 8),
                    Expanded(child: ClipRRect(borderRadius: BorderRadius.circular(99), child: LinearProgressIndicator(value: _remaining / _questionDuration, minHeight: 7, backgroundColor: Colors.white.withOpacity(0.08), valueColor: AlwaysStoppedAnimation<Color>(_timerColor())))),
                    const SizedBox(width: 8),
                    Text('$_remaining sn', style: TextStyle(color: _timerColor(), fontSize: 14, fontWeight: FontWeight.w900)),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(13),
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), color: _softCard, border: Border.all(color: Colors.white.withOpacity(0.08))),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(q.category, style: TextStyle(color: _beige.withOpacity(0.85), fontSize: 11, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 6),
                    Text(q.question, maxLines: 3, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900, height: 1.24)),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(15), color: const Color(0xFF191F31), border: Border.all(color: _beige.withOpacity(0.25))),
                child: Text(_infoText, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w700)),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: Column(
                  children: List.generate(q.options.length, (index) {
                    if (_disabledOptions.contains(index)) return const SizedBox.shrink();
                    return Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(bottom: index == q.options.length - 1 ? 0 : 7),
                        child: InkWell(
                          onTap: _locked ? null : () => _handleTap(index),
                          borderRadius: BorderRadius.circular(18),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(borderRadius: BorderRadius.circular(18), color: _optionColor(index), border: Border.all(color: Colors.white.withOpacity(0.08))),
                            child: Row(
                              children: [
                                Container(width: 32, height: 32, alignment: Alignment.center, decoration: BoxDecoration(shape: BoxShape.circle, color: _beige.withOpacity(0.18)), child: Text(['A', 'B', 'C', 'D'][index], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 14))),
                                const SizedBox(width: 10),
                                Expanded(child: Text(q.options[index], maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 13.5, fontWeight: FontWeight.w800, height: 1.20))),
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
                  Expanded(child: _JokerButton(text: '%50', count: engine.jokerFifty, icon: Icons.filter_2_rounded, onTap: _useFifty)),
                  const SizedBox(width: 8),
                  Expanded(child: _JokerButton(text: '+10 sn', count: _timeJoker, icon: Icons.timer_10_rounded, onTap: _useAddTime)),
                  const SizedBox(width: 8),
                  Expanded(child: _JokerButton(text: 'Pas', count: _passJoker, icon: Icons.skip_next_rounded, onTap: _usePass)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TopMiniCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  const _TopMiniCard({required this.icon, required this.title, required this.value});
  @override
  Widget build(BuildContext context) {
    const beige = Color(0xFFD8B982);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), color: const Color(0xFF1C2233), border: Border.all(color: Colors.white.withOpacity(0.08))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: beige, size: 17),
          const SizedBox(height: 5),
          Text(title, style: TextStyle(color: Colors.white.withOpacity(0.62), fontSize: 11, fontWeight: FontWeight.w700)),
          const SizedBox(height: 1),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900)),
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
  const _JokerButton({required this.text, required this.count, required this.icon, required this.onTap});
  @override
  Widget build(BuildContext context) {
    final enabled = count > 0;
    return SizedBox(
      height: 44,
      child: ElevatedButton.icon(
        onPressed: enabled ? onTap : null,
        icon: Icon(icon, size: 16),
        label: Text('$text ($count)', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 11)),
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: enabled ? const Color(0xFFD8B982).withOpacity(0.22) : Colors.white.withOpacity(0.04),
          foregroundColor: Colors.white,
          disabledForegroundColor: Colors.white38,
          disabledBackgroundColor: Colors.white.withOpacity(0.04),
          padding: const EdgeInsets.symmetric(horizontal: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
    );
  }
}

class _JackpotDialog extends StatefulWidget {
  const _JackpotDialog();
  @override
  State<_JackpotDialog> createState() => _JackpotDialogState();
}

class _JackpotDialogState extends State<_JackpotDialog> {
  int? selectedIndex;
  bool opened = false;
  Future<void> _openCard(int index) async {
    if (opened) return;
    setState(() { selectedIndex = index; opened = true; });
    await Future.delayed(const Duration(milliseconds: 900));
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF151A2F),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.card_giftcard_rounded, color: Color(0xFFD8B982), size: 44),
            const SizedBox(height: 10),
            const Text('Jackpot Fırsatı', style: TextStyle(color: Colors.white, fontSize: 23, fontWeight: FontWeight.w900)),
            const SizedBox(height: 6),
            Text(opened ? 'Bu tur ödül çıkmadı.\nBir sonraki turda tekrar dene!' : 'Bir kart seç ve şansını dene.', textAlign: TextAlign.center, style: TextStyle(color: Colors.white.withOpacity(0.70), fontSize: 13.5, fontWeight: FontWeight.w600, height: 1.35)),
            const SizedBox(height: 16),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 16,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 4, mainAxisSpacing: 8, crossAxisSpacing: 8),
              itemBuilder: (context, index) {
                final isSelected = selectedIndex == index;
                return GestureDetector(
                  onTap: () => _openCard(index),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 350),
                    decoration: BoxDecoration(color: isSelected ? const Color(0xFFD8B982) : const Color(0xFF22283A), borderRadius: BorderRadius.circular(14), border: Border.all(color: isSelected ? Colors.white : Colors.white.withOpacity(0.10))),
                    child: Center(child: AnimatedSwitcher(duration: const Duration(milliseconds: 250), child: isSelected ? const Text('BOŞ', key: ValueKey('empty'), style: TextStyle(color: Colors.black, fontSize: 13, fontWeight: FontWeight.w900)) : const Text('?', key: ValueKey('question'), style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900)))),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton(
                onPressed: opened ? () => Navigator.pop(context) : null,
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD8B982), foregroundColor: Colors.black, disabledBackgroundColor: Colors.white.withOpacity(0.08), disabledForegroundColor: Colors.white38, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                child: const Text('Devam Et', style: TextStyle(fontWeight: FontWeight.w900)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
