import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import '../../core/app_paths.dart';
import 'user_profile.dart';

class ProfileRepository {
  ProfileRepository(this._auth, this._db);

  final FirebaseAuth _auth;
  final FirebaseDatabase _db;

  User get currentUser => _auth.currentUser!;

  DatabaseReference _ref(String uid) => _db.ref(AppPaths.userPath(uid));

  Future<UserProfile> getOrCreateMe() async {
    final u = currentUser;
    final r = _ref(u.uid);
    final snap = await r.get();

    if (!snap.exists || snap.value == null) {
      final data = {
        'email': u.email ?? '',
        'fullName': null,
        'phone': null,
        'avatarUrl': null,
        'createdAt': DateTime.now().millisecondsSinceEpoch,
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
      };
      await r.set(data);
      return UserProfile(uid: u.uid, email: u.email ?? '');
    }

    final map = Map<dynamic, dynamic>.from(snap.value as Map);
    return UserProfile.fromMap(u.uid, map);
  }

  Stream<UserProfile> watchMe() {
    final u = currentUser;
    final r = _ref(u.uid);

    return r.onValue.map((event) {
      final val = event.snapshot.value;
      if (val == null) return UserProfile(uid: u.uid, email: u.email ?? '');
      final map = Map<dynamic, dynamic>.from(val as Map);
      return UserProfile.fromMap(u.uid, map);
    });
  }

  Future<void> updateMe(UserProfile p) async {
    await _ref(p.uid).update(p.toUpdateMap());
  }
}