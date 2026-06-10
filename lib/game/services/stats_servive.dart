import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class StatsSnapshot {
  final int totalUsers;
  final int globalMaxCorrect;
  final int myBestCorrect;
  final int myRank; // 1 = birinci
  final String globalLeaderName;

  const StatsSnapshot({
    required this.totalUsers,
    required this.globalMaxCorrect,
    required this.myBestCorrect,
    required this.myRank,
    required this.globalLeaderName,
  });
}

class StatsService {
  final DatabaseReference _db = FirebaseDatabase.instance.ref();

  // paths
  DatabaseReference _usersRef() => _db.child('stats/users');
  DatabaseReference _lbRef() => _db.child('stats/leaderboard'); // {uid: {bestCorrect, name, updatedAt}}
  DatabaseReference _globalRef() => _db.child('stats/global'); // {maxCorrect, leaderUid, leaderName, updatedAt}

  String _uidOrThrow() {
    final u = FirebaseAuth.instance.currentUser;
    if (u == null) throw Exception('Giriş gerekli');
    return u.uid;
  }

  String _name() {
    final u = FirebaseAuth.instance.currentUser;
    final dn = u?.displayName?.trim();
    if (dn != null && dn.isNotEmpty) return dn;
    final email = u?.email?.trim();
    if (email != null && email.isNotEmpty) return email.split('@').first;
    return 'Oyuncu';
  }

  int _now() => DateTime.now().millisecondsSinceEpoch;

  /// Uygulama/oyun açılınca çağır: kullanıcı var say, lastSeen güncelle
  Future<void> pingUser() async {
    final uid = _uidOrThrow();
    final now = _now();
    await _usersRef().child(uid).update({
      'uid': uid,
      'name': _name(),
      'lastSeen': now,
      // createdAt yoksa set et
    });

    final createdSnap = await _usersRef().child(uid).child('createdAt').get();
    if (!createdSnap.exists) {
      await _usersRef().child(uid).child('createdAt').set(now);
    }
  }

  /// Oyun içinde “en iyi doğru” güncelle (sadece yükselirse yazar)
  Future<void> updateBestCorrect(int bestCorrect) async {
    final uid = _uidOrThrow();
    final name = _name();
    final now = _now();

    // leaderboard: bestCorrect max olarak kalsın
    await _lbRef().child(uid).runTransaction((v) {
      final cur = (v is Map) ? Map<dynamic, dynamic>.from(v) : <dynamic, dynamic>{};
      final curBest = (cur['bestCorrect'] as int?) ?? 0;
      if (bestCorrect <= curBest) {
        // yine de isim güncelleyebiliriz
        cur['name'] = name;
        cur['updatedAt'] = now;
        return Transaction.success(cur);
      }
      cur['uid'] = uid;
      cur['name'] = name;
      cur['bestCorrect'] = bestCorrect;
      cur['updatedAt'] = now;
      return Transaction.success(cur);
    });

    // global max: sadece rekor geçildiyse
    await _globalRef().runTransaction((v) {
      final cur = (v is Map) ? Map<dynamic, dynamic>.from(v) : <dynamic, dynamic>{};
      final curMax = (cur['maxCorrect'] as int?) ?? 0;
      if (bestCorrect <= curMax) return Transaction.success(cur);

      cur['maxCorrect'] = bestCorrect;
      cur['leaderUid'] = uid;
      cur['leaderName'] = name;
      cur['updatedAt'] = now;
      return Transaction.success(cur);
    });
  }

  /// Toplam kullanıcı sayısı (stats/users altında kaç UID var)
  Future<int> getTotalUsers() async {
    final snap = await _usersRef().get();
    if (!snap.exists || snap.value == null) return 0;
    if (snap.value is Map) return (snap.value as Map).length;
    return 0;
  }

  Future<int> getGlobalMaxCorrect() async {
    final snap = await _globalRef().child('maxCorrect').get();
    return (snap.value as int?) ?? 0;
  }

  Future<String> getGlobalLeaderName() async {
    final snap = await _globalRef().child('leaderName').get();
    return (snap.value ?? '').toString();
  }

  Future<int> getMyBestCorrect() async {
    final uid = _uidOrThrow();
    final snap = await _lbRef().child(uid).child('bestCorrect').get();
    return (snap.value as int?) ?? 0;
  }

  /// Sıra hesapla: bestCorrect DESC, updatedAt ASC (basit ve yeterli)
  /// Not: Bu küçük kullanıcı sayılarında çok iyi çalışır.
  Future<int> getMyRank() async {
    final uid = _uidOrThrow();


    // bestCorrect'e göre sırala (query ile tümünü çekmek zor olabilir),
    // basit: tamamını alıp localde sırala.
    final snap = await _lbRef().get();
    if (!snap.exists || snap.value == null || snap.value is! Map) return 0;

    final m = Map<dynamic, dynamic>.from(snap.value as Map);

    final rows = <Map<String, dynamic>>[];
    m.forEach((k, v) {
      if (v is Map) {
        final mm = Map<dynamic, dynamic>.from(v);
        rows.add({
          'uid': k.toString(),
          'bestCorrect': (mm['bestCorrect'] as int?) ?? 0,
          'updatedAt': (mm['updatedAt'] as int?) ?? 0,
        });
      }
    });

    rows.sort((a, b) {
      final bc = (b['bestCorrect'] as int).compareTo(a['bestCorrect'] as int);
      if (bc != 0) return bc;
      return (a['updatedAt'] as int).compareTo(b['updatedAt'] as int);
    });

    final idx = rows.indexWhere((r) => r['uid'] == uid);
    if (idx == -1) {
      // hiç leaderboarda yazılmadıysa (0 doğru) -> en sona yakın say
      // ama düzgün görünmesi için 0 döndürmeyelim:
      return rows.isEmpty ? 1 : (rows.length + 1);
    }

    // 1-based rank
    return idx + 1;
  }

  /// Hepsini tek seferde getir (banner için)
  Future<StatsSnapshot> getSnapshot() async {
    // pingUser burada çağırma: çağıran yer kontrol etsin
    final total = await getTotalUsers();
    final gMax = await getGlobalMaxCorrect();
    final gName = await getGlobalLeaderName();
    final myBest = await getMyBestCorrect();
    final myRank = await getMyRank();

    return StatsSnapshot(
      totalUsers: total,
      globalMaxCorrect: gMax,
      myBestCorrect: myBest,
      myRank: myRank,
      globalLeaderName: gName,
    );
  }
}