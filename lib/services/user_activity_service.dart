import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class UserActiveService {
  UserActiveService._();
  static final UserActiveService instance = UserActiveService._();

  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  DatabaseReference _base(String uid) =>
      FirebaseDatabase.instance.ref('user_activity/$uid');

  // ---------------- FAVORITES ----------------

  DatabaseReference _favRef(String uid, String module, String itemId) =>
      _base(uid).child('favorites/$module/$itemId');

  Stream<bool> watchFavorite({
    required String module,
    required String itemId,
  }) {
    final uid = _uid;
    if (uid == null) return Stream.value(false);
    return _favRef(uid, module, itemId).onValue.map((e) => e.snapshot.value != null);
  }

  Future<void> toggleFavorite({
    required String module,
    required String itemId,
    required Map<String, dynamic> payload,
  }) async {
    final uid = _uid;
    if (uid == null) return;

    final ref = _favRef(uid, module, itemId);
    final snap = await ref.get();

    if (snap.value == null) {
      await ref.set({
        ...payload,
        'module': module,
        'itemId': itemId,
        'savedAt': ServerValue.timestamp,
      });
    } else {
      await ref.remove();
    }
  }

  Stream<List<Map<String, dynamic>>> streamFavorites({int limit = 60}) {
    final uid = _uid;
    if (uid == null) return Stream.value(const []);
    final ref = _base(uid).child('favorites');

    return ref.onValue.map((e) {
      final v = e.snapshot.value;
      if (v == null) return <Map<String, dynamic>>[];

      final root = Map<dynamic, dynamic>.from(v as Map);
      final list = <Map<String, dynamic>>[];

      root.forEach((mod, items) {
        if (items is Map) {
          final mm = Map<dynamic, dynamic>.from(items);
          mm.forEach((id, data) {
            if (data is Map) {
              final m = Map<String, dynamic>.from(data);
              m['module'] = mod.toString();
              m['itemId'] = id.toString();
              list.add(m);
            }
          });
        }
      });

      list.sort((a, b) => _toInt(b['savedAt']).compareTo(_toInt(a['savedAt'])));
      if (list.length > limit) return list.take(limit).toList();
      return list;
    });
  }

  // ---------------- RECENT ----------------

  DatabaseReference _recentRef(String uid, String module, String itemId) =>
      _base(uid).child('recent/$module/$itemId');

  Future<void> addRecent({
    required String module,
    required String itemId,
    required Map<String, dynamic> payload,
  }) async {
    final uid = _uid;
    if (uid == null) return;

    await _recentRef(uid, module, itemId).set({
      ...payload,
      'module': module,
      'itemId': itemId,
      'viewedAt': ServerValue.timestamp,
    });
  }

  Stream<List<Map<String, dynamic>>> streamRecent({int limit = 60}) {
    final uid = _uid;
    if (uid == null) return Stream.value(const []);
    final ref = _base(uid).child('recent');

    return ref.onValue.map((e) {
      final v = e.snapshot.value;
      if (v == null) return <Map<String, dynamic>>[];

      final root = Map<dynamic, dynamic>.from(v as Map);
      final list = <Map<String, dynamic>>[];

      root.forEach((mod, items) {
        if (items is Map) {
          final mm = Map<dynamic, dynamic>.from(items);
          mm.forEach((id, data) {
            if (data is Map) {
              final m = Map<String, dynamic>.from(data);
              m['module'] = mod.toString();
              m['itemId'] = id.toString();
              list.add(m);
            }
          });
        }
      });

      list.sort((a, b) => _toInt(b['viewedAt']).compareTo(_toInt(a['viewedAt'])));
      if (list.length > limit) return list.take(limit).toList();
      return list;
    });
  }

  static int _toInt(dynamic v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse((v ?? '0').toString()) ?? 0;
  }
}