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
    final r = Random();
    return List.generate(6, (_) => chars[r.nextInt(chars.length)]).join();
  }

  /// Oda oluştur (2 veya 4)
  Future<String> createRoom({required int maxPlayers}) async {
    if (maxPlayers != 2 && maxPlayers != 4) {
      throw Exception('maxPlayers sadece 2 veya 4 olabilir.');
    }

    final uid = _uid();
    final name = _name();

    // benzersiz code bul
    String code = _code6();
    for (int i = 0; i < 6; i++) {
      final snap = await roomRef(code).get();
      if (!snap.exists) break;
      code = _code6();
    }

    final seed = DateTime.now().millisecondsSinceEpoch;
    final now = DateTime.now().millisecondsSinceEpoch;

    await roomRef(code).set({
      'code': code,
      'hostUid': uid,
      'maxPlayers': maxPlayers,
      'status': 'lobby', // lobby | playing | finished
      'seed': seed,
      'pos': 0,
      'createdAt': now,
      'players': {
        uid: {
          'uid': uid,
          'name': name,
          'score': 0,
          'joinedAt': now,
          'answeredPos': -1,
          'lastAnswer': -1,
        }
      },
    });

    return code;
  }

  /// Odaya katıl
  Future<void> joinRoom(String code) async {
    final uid = _uid();
    final name = _name();
    final now = DateTime.now().millisecondsSinceEpoch;

    final ref = roomRef(code);

    await ref.runTransaction((val) {
      if (val == null) return Transaction.abort();

      final m = Map<dynamic, dynamic>.from(val as Map);
      final status = (m['status'] ?? 'lobby').toString();
      final maxPlayers = (m['maxPlayers'] as int?) ?? 2;

      if (status != 'lobby') return Transaction.abort();

      final players = (m['players'] is Map)
          ? Map<dynamic, dynamic>.from(m['players'] as Map)
          : <dynamic, dynamic>{};

      if (!players.containsKey(uid) && players.length >= maxPlayers) {
        return Transaction.abort();
      }

      final existing = (players[uid] is Map)
          ? Map<dynamic, dynamic>.from(players[uid] as Map)
          : <dynamic, dynamic>{};

      players[uid] = {
        'uid': uid,
        'name': name,
        'score': (existing['score'] as int?) ?? 0,
        'joinedAt': (existing['joinedAt'] as int?) ?? now,
        'answeredPos': (existing['answeredPos'] as int?) ?? -1,
        'lastAnswer': (existing['lastAnswer'] as int?) ?? -1,
      };

      m['players'] = players;
      return Transaction.success(m);
    });
  }

  Future<void> leaveRoom(String code) async {
    final uid = _uid();
    final ref = roomRef(code);

    final snap = await ref.get();
    if (!snap.exists) return;

    final m = Map<dynamic, dynamic>.from(snap.value as Map);
    final hostUid = (m['hostUid'] ?? '').toString();

    await ref.child('players/$uid').remove();
    await ref.child('answers/$uid').remove();

    // host çıkarsa oda biter (basit)
    if (hostUid == uid) {
      await ref.update({'status': 'finished'});
    }
  }

  /// Host oyunu başlatır
  Future<void> startGame(String code) async {
    final uid = _uid();
    final ref = roomRef(code);
    final snap = await ref.get();
    if (!snap.exists) throw Exception('Oda yok');

    final m = Map<dynamic, dynamic>.from(snap.value as Map);
    final hostUid = (m['hostUid'] ?? '').toString();
    if (hostUid != uid) throw Exception('Sadece host başlatabilir');

    await ref.update({
      'status': 'playing',
      'pos': 0,
      'startedAt': DateTime.now().millisecondsSinceEpoch,
    });

    // cevapları temizle
    await ref.child('answers').remove();

    // oyuncu answeredPos sıfırla
    final players = (m['players'] is Map)
        ? Map<dynamic, dynamic>.from(m['players'] as Map)
        : <dynamic, dynamic>{};

    for (final k in players.keys) {
      await ref.child('players/$k/answeredPos').set(-1);
      await ref.child('players/$k/lastAnswer').set(-1);
    }
  }

  /// Oyuncu cevap gönderir (pos için 1 kere)
  Future<void> submitAnswer({
    required String code,
    required int pos,
    required int selectedIndex,
  }) async {
    final uid = _uid();
    final ref = roomRef(code);

    final playerAnswered = await ref.child('players/$uid/answeredPos').get();
    final already = (playerAnswered.value as int?) ?? -1;
    if (already == pos) return;

    await ref.child('answers/$pos/$uid').set(selectedIndex);
    await ref.child('players/$uid/answeredPos').set(pos);
    await ref.child('players/$uid/lastAnswer').set(selectedIndex);
  }

  /// Host: herkes cevapladı mı? ise skorları yazıp sonraki soruya geçir
  Future<void> hostAdvanceIfReady({
    required String code,
    required int pos,
    required int correctIndex,
  }) async {
    final uid = _uid();
    final ref = roomRef(code);

    final snap = await ref.get();
    if (!snap.exists) return;

    final m = Map<dynamic, dynamic>.from(snap.value as Map);
    final hostUid = (m['hostUid'] ?? '').toString();
    if (hostUid != uid) return;

    final status = (m['status'] ?? 'lobby').toString();
    if (status != 'playing') return;

    final players = (m['players'] is Map)
        ? Map<dynamic, dynamic>.from(m['players'] as Map)
        : <dynamic, dynamic>{};
    final playerCount = players.length;

    final ansSnap = await ref.child('answers/$pos').get();
    final answers = (ansSnap.value is Map)
        ? Map<dynamic, dynamic>.from(ansSnap.value as Map)
        : <dynamic, dynamic>{};

    if (answers.length < playerCount) return;

    // skor güncelle
    for (final entry in answers.entries) {
      final puid = entry.key.toString();
      final pick = (entry.value as int?) ?? -1;
      if (pick == correctIndex) {
        await ref.child('players/$puid/score').runTransaction((v) {
          final cur = (v as int?) ?? 0;
          return Transaction.success(cur + 1);
        });
      }
    }

    // sonraki soru
    await ref.child('pos').set(pos + 1);

    // bu pos'un cevaplarını temizle
    await ref.child('answers/$pos').remove();

    // herkes tekrar basabilsin
    for (final k in players.keys) {
      await ref.child('players/$k/answeredPos').set(-1);
      await ref.child('players/$k/lastAnswer').set(-1);
    }
  }
}