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

      list.removeWhere((x) => x.attrs['active'] == false);
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      return list;
    });
  }

  Future<String> addListing(MarketListingModel model) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final ref = _ref.push();
    final id = ref.key!;

    final data = model.toMap();
    data['createdAt'] = data['createdAt'] ?? now;
    data['updatedAt'] = now;

    await ref.set(data);
    return id;
  }

  Future<void> updateListing(String id, Map<String, dynamic> patch) async {
    patch['updatedAt'] = DateTime.now().millisecondsSinceEpoch;
    await _ref.child(id).update(patch);
  }

  Future<void> deactivateListing(String id) async {
    await updateListing(id, {
      'active': false,
      'attrs/active': false,
    });
  }

  Future<void> deleteListing(String id) async {
    await _ref.child(id).remove();
    await _db.ref('market_comments/$id').remove();
  }
}