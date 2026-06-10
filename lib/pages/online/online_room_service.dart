import 'dart:math';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class OnlineRoomService {
  final DatabaseReference _db = FirebaseDatabase.instance.ref();

  DatabaseReference roomRef(String code) => _db.child('online/rooms/$code');
  DatabaseReference roomsRef() => _db.child('online/rooms');

  String _uid() {
    final u = FirebaseAuth.instance.currentUser;
    if (u == null) throw Exception('Giriş gerekli');
    return u.uid;
  }

  String _name() {
    final u = FirebaseAuth.instance.currentUser;
    final dn = u?.displayName?.trim();
    return (dn != null && dn.isNotEmpty) ? dn : 'Oyuncu';
  }

  String _code6() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final r = Random.secure();
    return List.generate(6, (_) => chars[r.nextInt(chars.length)]).join();
  }

  Future<String> createRoom({int maxPlayers = 4}) async {
    if (maxPlayers < 2) maxPlayers = 2;
    if (maxPlayers > 8) maxPlayers = 8;

    final uid = _uid();
    final name = _name();
    final now = DateTime.now().millisecondsSinceEpoch;

    String code = _code6();

    for (int i = 0; i < 10; i++) {
      final snap = await roomRef(code).get();
      if (!snap.exists) break;
      code = _code6();
    }

    await roomRef(code).set({
      'code': code,
      'hostUid': uid,
      'maxPlayers': maxPlayers,
      'status': 'lobby',
      'seed': now,
      'pos': 0,
      'questionStartedAt': 0,
      'currentWinnerUid': '',
      'currentWinnerName': '',
      'createdAt': now,
      'players': {
        uid: {
          'uid': uid,
          'name': name,
          'score': 0,
          'joinedAt': now,
          'answeredPos': -1,
          'lastAnswer': -1,
          'isReady': true,
        }
      },
    });

    return code;
  }

  Future<void> joinRoom(String rawCode) async {
    final code = rawCode.trim().toUpperCase();
    final uid = _uid();
    final name = _name();
    final now = DateTime.now().millisecondsSinceEpoch;

    await roomRef(code).runTransaction((val) {
      if (val == null) return Transaction.abort();

      final room = Map<dynamic, dynamic>.from(val as Map);
      final status = (room['status'] ?? 'lobby').toString();
      final maxPlayers = (room['maxPlayers'] as int?) ?? 4;

      if (status != 'lobby') return Transaction.abort();

      final players = (room['players'] is Map)
          ? Map<dynamic, dynamic>.from(room['players'] as Map)
          : <dynamic, dynamic>{};

      if (!players.containsKey(uid) && players.length >= maxPlayers) {
        return Transaction.abort();
      }

      final old = (players[uid] is Map)
          ? Map<dynamic, dynamic>.from(players[uid] as Map)
          : <dynamic, dynamic>{};

      players[uid] = {
        'uid': uid,
        'name': name,
        'score': (old['score'] as int?) ?? 0,
        'joinedAt': (old['joinedAt'] as int?) ?? now,
        'answeredPos': -1,
        'lastAnswer': -1,
        'isReady': true,
      };

      room['players'] = players;
      return Transaction.success(room);
    });
  }

  Future<void> leaveRoom(String rawCode) async {
    final code = rawCode.trim().toUpperCase();
    final uid = _uid();
    final ref = roomRef(code);

    final snap = await ref.get();
    if (!snap.exists) return;

    final room = Map<dynamic, dynamic>.from(snap.value as Map);
    final hostUid = (room['hostUid'] ?? '').toString();

    if (hostUid == uid) {
      await ref.update({'status': 'finished'});
      return;
    }

    await ref.child('players/$uid').remove();
  }

  Future<void> startGame(String rawCode) async {
    final code = rawCode.trim().toUpperCase();
    final uid = _uid();
    final ref = roomRef(code);

    final snap = await ref.get();
    if (!snap.exists) throw Exception('Oda yok');

    final room = Map<dynamic, dynamic>.from(snap.value as Map);
    final hostUid = (room['hostUid'] ?? '').toString();

    if (hostUid != uid) {
      throw Exception('Sadece oda sahibi başlatabilir');
    }

    final players = (room['players'] is Map)
        ? Map<dynamic, dynamic>.from(room['players'] as Map)
        : <dynamic, dynamic>{};

    if (players.length < 2) {
      throw Exception('Oyunu başlatmak için en az 2 oyuncu gerekli');
    }

    final now = DateTime.now().millisecondsSinceEpoch;

    await ref.update({
      'status': 'playing',
      'pos': 0,
      'startedAt': now,
      'questionStartedAt': now,
      'currentWinnerUid': '',
      'currentWinnerName': '',
    });

    await ref.child('answers').remove();

    for (final k in players.keys) {
      await ref.child('players/$k/score').set(0);
      await ref.child('players/$k/answeredPos').set(-1);
      await ref.child('players/$k/lastAnswer').set(-1);
    }
  }

  Future<bool> submitAnswer({
    required String code,
    required int pos,
    required int selectedIndex,
    required int correctIndex,
  }) async {
    final roomCode = code.trim().toUpperCase();
    final uid = _uid();
    final name = _name();
    final ref = roomRef(roomCode);

    final playerAnswered = await ref.child('players/$uid/answeredPos').get();
    final already = (playerAnswered.value as int?) ?? -1;
    if (already == pos) return false;

    await ref.child('players/$uid/answeredPos').set(pos);
    await ref.child('players/$uid/lastAnswer').set(selectedIndex);
    await ref.child('answers/$pos/$uid').set({
      'uid': uid,
      'name': name,
      'selectedIndex': selectedIndex,
      'isCorrect': selectedIndex == correctIndex,
      'answeredAt': ServerValue.timestamp,
    });

    if (selectedIndex != correctIndex) return false;

    bool isWinner = false;

    await ref.runTransaction((val) {
      if (val == null) return Transaction.abort();

      final room = Map<dynamic, dynamic>.from(val as Map);
      final status = (room['status'] ?? '').toString();
      final currentPos = (room['pos'] as int?) ?? 0;
      final currentWinnerUid = (room['currentWinnerUid'] ?? '').toString();

      if (status != 'playing') return Transaction.abort();
      if (currentPos != pos) return Transaction.abort();
      if (currentWinnerUid.isNotEmpty) return Transaction.abort();

      room['currentWinnerUid'] = uid;
      room['currentWinnerName'] = name;

      final players = (room['players'] is Map)
          ? Map<dynamic, dynamic>.from(room['players'] as Map)
          : <dynamic, dynamic>{};

      final player = (players[uid] is Map)
          ? Map<dynamic, dynamic>.from(players[uid] as Map)
          : <dynamic, dynamic>{};

      final score = (player['score'] as int?) ?? 0;
      player['score'] = score + 1;
      players[uid] = player;
      room['players'] = players;

      isWinner = true;
      return Transaction.success(room);
    });

    return isWinner;
  }

  Future<void> hostNextQuestion({
    required String code,
    required int pos,
    required int totalQuestions,
  }) async {
    final roomCode = code.trim().toUpperCase();
    final uid = _uid();
    final ref = roomRef(roomCode);

    final snap = await ref.get();
    if (!snap.exists) return;

    final room = Map<dynamic, dynamic>.from(snap.value as Map);
    final hostUid = (room['hostUid'] ?? '').toString();
    final currentPos = (room['pos'] as int?) ?? 0;

    if (hostUid != uid) return;
    if (currentPos != pos) return;

    if (pos + 1 >= totalQuestions) {
      await ref.update({
        'status': 'finished',
        'finishedAt': DateTime.now().millisecondsSinceEpoch,
      });
      return;
    }

    final players = (room['players'] is Map)
        ? Map<dynamic, dynamic>.from(room['players'] as Map)
        : <dynamic, dynamic>{};

    final now = DateTime.now().millisecondsSinceEpoch;

    await ref.update({
      'pos': pos + 1,
      'questionStartedAt': now,
      'currentWinnerUid': '',
      'currentWinnerName': '',
    });

    for (final k in players.keys) {
      await ref.child('players/$k/answeredPos').set(-1);
      await ref.child('players/$k/lastAnswer').set(-1);
    }

    await ref.child('answers/$pos').remove();
  }

  Future<void> finishRoom(String rawCode) async {
    final code = rawCode.trim().toUpperCase();
    final uid = _uid();
    final ref = roomRef(code);

    final snap = await ref.get();
    if (!snap.exists) return;

    final room = Map<dynamic, dynamic>.from(snap.value as Map);
    final hostUid = (room['hostUid'] ?? '').toString();

    if (hostUid != uid) return;

    await ref.update({
      'status': 'finished',
      'finishedAt': DateTime.now().millisecondsSinceEpoch,
    });
  }

  Stream<DatabaseEvent> watchRoom(String rawCode) {
    final code = rawCode.trim().toUpperCase();
    return roomRef(code).onValue;
  }

  Stream<DatabaseEvent> watchRooms() {
    return roomsRef().orderByChild('status').equalTo('lobby').onValue;
  }
}