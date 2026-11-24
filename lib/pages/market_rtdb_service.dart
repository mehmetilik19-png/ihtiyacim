import 'package:firebase_database/firebase_database.dart';

import '../models/market_listing_model.dart';

class MarketRtdbService {
  MarketRtdbService({FirebaseDatabase? db})
      : _db = db ?? FirebaseDatabase.instance;

  final FirebaseDatabase _db;

  DatabaseReference get _ref => _db.ref('market_listings');

  Stream<List<MarketListingModel>> streamListings() {
    return _ref.onValue.map((event) {
      final raw = event.snapshot.value;
      if (raw is! Map) return <MarketListingModel>[];

      final list = <MarketListingModel>[];

      raw.forEach((key, value) {
        if (value is Map) {
          list.add(
            MarketListingModel.fromMap(
              key.toString(),
              Map<dynamic, dynamic>.from(value),
            ),
          );
        }
      });

      list.removeWhere((item) => item.attrs['active'] == false);
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    }).asBroadcastStream();
  }

  Future<String> addListing(MarketListingModel model) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final ref = _ref.push();
    final id = ref.key;

    if (id == null) {
      throw StateError('İlan kimliği oluşturulamadı.');
    }

    final data = model.toMap();
    data['createdAt'] = model.createdAt > 0 ? model.createdAt : now;
    data['updatedAt'] = now;

    await ref.set(data);
    return id;
  }

  Future<void> updateListing(
    String id,
    Map<String, dynamic> patch,
  ) async {
    final data = Map<String, dynamic>.from(patch);
    data['updatedAt'] = DateTime.now().millisecondsSinceEpoch;
    await _ref.child(id).update(data);
  }

  Future<void> deactivateListing(String id) async {
    await updateListing(id, {
      'active': false,
      'attrs/active': false,
    });
  }

  Future<void> deleteListing(String id) async {
    await Future.wait([
      _ref.child(id).remove(),
      _db.ref('market_comments/$id').remove(),
    ]);
  }
}
