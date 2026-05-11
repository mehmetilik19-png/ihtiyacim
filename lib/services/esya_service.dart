import 'package:firebase_database/firebase_database.dart';
import '../models/ilan_model.dart';

class EsyaService {
  final DatabaseReference _ref =
  FirebaseDatabase.instance.ref('esya_paylas/items');

  Stream<List<IlanModel>> getEsyalar() {
    return _ref.onValue.map((event) {
      final data = event.snapshot.value;
      if (data == null) return <IlanModel>[];

      final map = Map<dynamic, dynamic>.from(data as Map);
      final list = map.entries.map((e) {
        final itemMap = Map<dynamic, dynamic>.from(e.value as Map);
        return IlanModel.fromMap(e.key.toString(), itemMap);
      }).toList();

      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }
}