import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:ihtiyacim/game/quiz_repo.dart';
import 'package:ihtiyacim/game/quiz_question.dart';
import 'package:ihtiyacim/pages/online/online_room_service.dart';

class OnlineGamePage extends StatefulWidget {
  final String code;
  const OnlineGamePage({super.key, required this.code});

  @override
  State<OnlineGamePage> createState() => _OnlineGamePageState();
}

class _OnlineGamePageState extends State<OnlineGamePage> {
  final online = OnlineRoomService();
  final roomRef = FirebaseDatabase.instance.ref();

  final repo = QuizRepo();

  bool ready = false;

  int seed = 42;
  int pos = 0;
  int maxPlayers = 2;
  String hostUid = '';
  bool isHost = false;

  QuizQuestion? q;

  bool locked = false;
  int remaining = 15;
  Timer? t;

  int? lastSelected;
  int? lastCorrect;

  @override
  void initState() {
    super.initState();
    _listenRoom();
  }

  @override
  void dispose() {
    t?.cancel();
    super.dispose();
  }

  String _uid() => FirebaseAuth.instance.currentUser!.uid;

  void _startTimer() {
    t?.cancel();
    locked = false;
    lastSelected = null;
    lastCorrect = null;

    remaining = (pos < 10) ? 10 : 15;

    t = Timer.periodic(const Duration(seconds: 1), (_) async {
      if (!mounted || locked) return;
      setState(() => remaining -= 1);
      if (remaining <= 0) {
        t?.cancel();
        locked = true;
        // süre bitti: cevap yok -> -1 gönder (host saymaz)
        await online.submitAnswer(code: widget.code, pos: pos, selectedIndex: -1);
        // host kontrol
        await _hostTryAdvance();
      }
    });
  }

  Future<void> _hostTryAdvance() async {
    if (!isHost || q == null) return;
    await online.hostAdvanceIfReady(
      code: widget.code,
      pos: pos,
      correctIndex: q!.correctIndex,
    );
  }

  void _listenRoom() {
    final ref = FirebaseDatabase.instance.ref('online/rooms/${widget.code}');
    ref.onValue.listen((e) async {
      final data = e.snapshot.value;
      if (data == null) return;

      final m = Map<dynamic, dynamic>.from(data as Map);

      final newSeed = (m['seed'] as int?) ?? 42;
      final newPos = (m['pos'] as int?) ?? 0;
      final newHost = (m['hostUid'] ?? '').toString();
      final newMax = (m['maxPlayers'] as int?) ?? 2;
      final status = (m['status'] ?? 'lobby').toString();

      if (status != 'playing') return;

      final uid = _uid();

      // ilk init
      if (!ready) {
        seed = newSeed;
        hostUid = newHost;
        isHost = (hostUid == uid);
        maxPlayers = newMax;

        await repo.init(seed: seed);
        pos = newPos;
        q = repo.at(pos);

        _startTimer();
        setState(() => ready = true);
        return;
      }

      // pos değiştiyse yeni soru
      if (newPos != pos) {
        pos = newPos;
        q = repo.at(pos);
        _startTimer();
        setState(() {});
      }
    });
  }

  Color _tileColor(int i) {
    if (!locked) return Colors.white;
    if (lastCorrect == i) return const Color(0xFFDDEFE3);
    if (lastSelected == i && lastSelected != lastCorrect) return const Color(0xFFF7D6D6);
    return Colors.white;
  }

  Future<void> _pick(int i) async {
    if (locked || q == null) return;

    locked = true;
    t?.cancel();

    lastSelected = i;
    lastCorrect = q!.correctIndex;
    setState(() {});

    await online.submitAnswer(code: widget.code, pos: pos, selectedIndex: i);

    // biraz göster
    await Future.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;

    // host kontrol edip ilerletir
    await _hostTryAdvance();
  }

  @override
  Widget build(BuildContext context) {
    if (!ready || q == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Online Soru ${pos + 1}'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Center(child: Text(isHost ? 'HOST' : 'OYUNCU', style: const TextStyle(fontWeight: FontWeight.w900))),
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(q!.category, style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 8),
            Text(q!.question, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
            const SizedBox(height: 10),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Süre: $remaining sn'),
                Text('Oda: ${widget.code}', style: const TextStyle(fontWeight: FontWeight.w800)),
              ],
            ),
            const SizedBox(height: 12),

            Expanded(
              child: ListView.separated(
                itemCount: q!.options.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (_, i) => InkWell(
                  onTap: locked ? null : () => _pick(i),
                  borderRadius: BorderRadius.circular(14),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                    decoration: BoxDecoration(
                      color: _tileColor(i),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.black12),
                    ),
                    child: Text(q!.options[i], style: const TextStyle(fontSize: 18)),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 8),

            if (isHost)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () async => _hostTryAdvance(),
                  child: const Text('Host: Kontrol Et / İlerlet'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}