import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:ihtiyacim/game/quiz_repo.dart';
import 'package:ihtiyacim/game/quiz_question.dart';
import 'package:ihtiyacim/pages/online/online_room_service.dart';

class OnlineGamePage extends StatefulWidget {
  final String code;

  const OnlineGamePage({
    super.key,
    required this.code,
  });

  @override
  State<OnlineGamePage> createState() => _OnlineGamePageState();
}

class _OnlineGamePageState extends State<OnlineGamePage> {
  final OnlineRoomService online = OnlineRoomService();
  final QuizRepo repo = QuizRepo();

  StreamSubscription<DatabaseEvent>? roomSub;
  Timer? timer;

  bool ready = false;
  bool locked = false;

  int seed = 42;
  int pos = 0;
  int maxPlayers = 2;
  int remaining = 15;

  String hostUid = '';
  String currentWinnerUid = '';
  String currentWinnerName = '';
  String status = 'lobby';

  bool isHost = false;

  QuizQuestion? question;

  int? lastSelected;
  int? lastCorrect;

  Map<String, dynamic> players = {};

  static const Color bgTop = Color(0xFF06111F);
  static const Color bgBottom = Color(0xFF102A44);
  static const Color cardColor = Color(0xFF14243A);
  static const Color primary = Color(0xFF00D4FF);
  static const Color green = Color(0xFF35F2A2);
  static const Color red = Color(0xFFFF5A6A);
  static const Color yellow = Color(0xFFFFC857);

  @override
  void initState() {
    super.initState();
    _listenRoom();
  }

  @override
  void dispose() {
    roomSub?.cancel();
    timer?.cancel();
    super.dispose();
  }

  String _uid() => FirebaseAuth.instance.currentUser!.uid;

  void _listenRoom() {
    final ref = FirebaseDatabase.instance.ref('online/rooms/${widget.code}');

    roomSub = ref.onValue.listen((event) async {
      final data = event.snapshot.value;
      if (data == null) return;

      final room = Map<dynamic, dynamic>.from(data as Map);

      final newSeed = (room['seed'] as int?) ?? 42;
      final newPos = (room['pos'] as int?) ?? 0;
      final newHostUid = (room['hostUid'] ?? '').toString();
      final newMaxPlayers = (room['maxPlayers'] as int?) ?? 2;
      final newStatus = (room['status'] ?? 'lobby').toString();
      final winnerUid = (room['currentWinnerUid'] ?? '').toString();
      final winnerName = (room['currentWinnerName'] ?? '').toString();

      final newPlayers = (room['players'] is Map)
          ? Map<String, dynamic>.from(
        (room['players'] as Map).map(
              (key, value) => MapEntry(
            key.toString(),
            Map<String, dynamic>.from(value as Map),
          ),
        ),
      )
          : <String, dynamic>{};

      if (newStatus == 'finished') {
        timer?.cancel();

        if (!mounted) return;
        setState(() {
          status = newStatus;
          players = newPlayers;
          currentWinnerUid = winnerUid;
          currentWinnerName = winnerName;
        });

        return;
      }

      if (newStatus != 'playing') {
        if (!mounted) return;
        setState(() {
          status = newStatus;
          players = newPlayers;
        });
        return;
      }

      final uid = _uid();

      if (!ready) {
        seed = newSeed;
        pos = newPos;
        hostUid = newHostUid;
        maxPlayers = newMaxPlayers;
        status = newStatus;
        isHost = hostUid == uid;
        players = newPlayers;
        currentWinnerUid = winnerUid;
        currentWinnerName = winnerName;

        await repo.init(seed: seed);
        question = repo.at(pos);

        _startTimer();

        if (!mounted) return;
        setState(() => ready = true);
        return;
      }

      final posChanged = newPos != pos;

      if (posChanged) {
        pos = newPos;
        question = repo.at(pos);
        locked = false;
        lastSelected = null;
        lastCorrect = null;
        currentWinnerUid = '';
        currentWinnerName = '';
        _startTimer();
      } else {
        currentWinnerUid = winnerUid;
        currentWinnerName = winnerName;

        if (winnerUid.isNotEmpty) {
          locked = true;
          timer?.cancel();
          lastCorrect = question?.correctIndex;
        }
      }

      if (!mounted) return;
      setState(() {
        seed = newSeed;
        hostUid = newHostUid;
        maxPlayers = newMaxPlayers;
        status = newStatus;
        isHost = hostUid == uid;
        players = newPlayers;
      });
    });
  }

  void _startTimer() {
    timer?.cancel();

    remaining = 15;

    timer = Timer.periodic(const Duration(seconds: 1), (_) async {
      if (!mounted || locked || status != 'playing') return;

      setState(() => remaining -= 1);

      if (remaining <= 0) {
        timer?.cancel();
        locked = true;

        if (question != null) {
          await online.submitAnswer(
            code: widget.code,
            pos: pos,
            selectedIndex: -1,
            correctIndex: question!.correctIndex,
          );
        }

        if (isHost) {
          await Future.delayed(const Duration(milliseconds: 800));
          await _hostNext();
        }
      }
    });
  }

  Future<void> _hostNext() async {
    if (!isHost || question == null) return;

    await online.hostNextQuestion(
      code: widget.code,
      pos: pos,
      totalQuestions: 10,
    );
  }

  Future<void> _pick(int index) async {
    if (locked || question == null || status != 'playing') return;

    locked = true;
    timer?.cancel();

    lastSelected = index;
    lastCorrect = question!.correctIndex;

    if (mounted) setState(() {});

    final won = await online.submitAnswer(
      code: widget.code,
      pos: pos,
      selectedIndex: index,
      correctIndex: question!.correctIndex,
    );

    if (won) {
      currentWinnerUid = _uid();
      currentWinnerName = 'Sen';
    }

    if (mounted) setState(() {});

    await Future.delayed(const Duration(milliseconds: 1200));

    if (isHost) {
      await _hostNext();
    }
  }

  Color _answerColor(int index) {
    if (!locked) return Colors.white.withOpacity(0.08);

    if (index == lastCorrect) {
      return green.withOpacity(0.20);
    }

    if (lastSelected == index && lastSelected != lastCorrect) {
      return red.withOpacity(0.20);
    }

    return Colors.white.withOpacity(0.06);
  }

  Color _answerBorderColor(int index) {
    if (!locked) return Colors.white.withOpacity(0.10);

    if (index == lastCorrect) return green.withOpacity(0.80);

    if (lastSelected == index && lastSelected != lastCorrect) {
      return red.withOpacity(0.80);
    }

    return Colors.white.withOpacity(0.08);
  }

  List<Map<String, dynamic>> _sortedPlayers() {
    final list = players.values
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();

    list.sort((a, b) {
      final sa = (a['score'] as int?) ?? 0;
      final sb = (b['score'] as int?) ?? 0;
      return sb.compareTo(sa);
    });

    return list;
  }

  @override
  Widget build(BuildContext context) {
    if (!ready || question == null) {
      return const Scaffold(
        backgroundColor: bgTop,
        body: Center(
          child: CircularProgressIndicator(color: primary),
        ),
      );
    }

    if (status == 'finished') {
      return _buildFinished();
    }

    return Scaffold(
      backgroundColor: bgTop,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [bgTop, bgBottom],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTopBar(),
                const SizedBox(height: 18),
                _buildScoreBar(),
                const SizedBox(height: 18),
                _buildQuestionCard(),
                const SizedBox(height: 16),
                _buildAnswers(),
                const SizedBox(height: 16),
                _buildWinnerBox(),
                const SizedBox(height: 16),
                if (isHost)
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: OutlinedButton(
                      onPressed: _hostNext,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: primary,
                        side: BorderSide(color: primary.withOpacity(0.55)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text(
                        'Sonraki Soru',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Row(
      children: [
        InkWell(
          onTap: () => Navigator.pop(context),
          borderRadius: BorderRadius.circular(14),
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withOpacity(0.10)),
            ),
            child: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: Colors.white,
              size: 18,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            'Oda ${widget.code}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 21,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isHost
                ? yellow.withOpacity(0.16)
                : primary.withOpacity(0.14),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            isHost ? 'HOST' : 'OYUNCU',
            style: TextStyle(
              color: isHost ? yellow : primary,
              fontWeight: FontWeight.w900,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildScoreBar() {
    final list = _sortedPlayers();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: cardColor.withOpacity(0.82),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.timer_rounded, color: primary, size: 22),
              const SizedBox(width: 8),
              Text(
                '$remaining sn',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                ),
              ),
              const Spacer(),
              Text(
                'Soru ${pos + 1}/10',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.70),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: list.map((p) {
              final name = (p['name'] ?? 'Oyuncu').toString();
              final score = (p['score'] as int?) ?? 0;
              final uid = (p['uid'] ?? '').toString();

              return Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                decoration: BoxDecoration(
                  color: uid == _uid()
                      ? primary.withOpacity(0.16)
                      : Colors.white.withOpacity(0.07),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: uid == _uid()
                        ? primary.withOpacity(0.35)
                        : Colors.white.withOpacity(0.08),
                  ),
                ),
                child: Text(
                  '$name  $score',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor.withOpacity(0.90),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.09)),
        boxShadow: [
          BoxShadow(
            color: primary.withOpacity(0.08),
            blurRadius: 28,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            question!.category,
            style: TextStyle(
              color: primary.withOpacity(0.95),
              fontWeight: FontWeight.w900,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            question!.question,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              height: 1.35,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnswers() {
    return Column(
      children: List.generate(question!.options.length, (index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: InkWell(
            onTap: locked ? null : () => _pick(index),
            borderRadius: BorderRadius.circular(18),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 17),
              decoration: BoxDecoration(
                color: _answerColor(index),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: _answerBorderColor(index)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      String.fromCharCode(65 + index),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      question!.options[index],
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        height: 1.3,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildWinnerBox() {
    if (currentWinnerName.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.055),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white.withOpacity(0.07)),
        ),
        child: Text(
          locked
              ? 'Cevabın alındı. İlk doğru cevap bekleniyor.'
              : 'İlk doğru cevaplayan bu sorunun puanını alır.',
          style: TextStyle(
            color: Colors.white.withOpacity(0.68),
            fontWeight: FontWeight.w700,
          ),
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: green.withOpacity(0.14),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: green.withOpacity(0.40)),
      ),
      child: Row(
        children: [
          const Icon(Icons.flash_on_rounded, color: green),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'İlk doğru cevap: $currentWinnerName',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFinished() {
    final list = _sortedPlayers();

    return Scaffold(
      backgroundColor: bgTop,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [bgTop, bgBottom],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Oyun Bitti',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Oda ${widget.code} sonucu',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.65),
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 24),
                Expanded(
                  child: ListView.separated(
                    itemCount: list.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (_, i) {
                      final p = list[i];
                      final name = (p['name'] ?? 'Oyuncu').toString();
                      final score = (p['score'] as int?) ?? 0;

                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.075),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.08),
                          ),
                        ),
                        child: Row(
                          children: [
                            Text(
                              '${i + 1}.',
                              style: TextStyle(
                                color: i == 0 ? yellow : Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Text(
                                name,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 17,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            Text(
                              '$score puan',
                              style: const TextStyle(
                                color: primary,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primary,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(17),
                      ),
                    ),
                    child: const Text(
                      'Menüye Dön',
                      style: TextStyle(fontWeight: FontWeight.w900),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}