import 'package:firebase_database/firebase_database.dart';
import 'package:uuid/uuid.dart';
import '../models/engelsiz_is_model.dart';

class EngelsizIsRtdbService {
  final _ref = FirebaseDatabase.instance.ref('engelsiz_is/listings');
  final _uuid = const Uuid();

  Stream<List<EngelsizIsModel>> streamAll() {
    return _ref.onValue.map((event) {
      final val = event.snapshot.value;
      if (val == null) return <EngelsizIsModel>[];

      final map = Map<dynamic, dynamic>.from(val as Map);
      final list = <EngelsizIsModel>[];

      map.forEach((key, value) {
        if (value is Map) {
          list.add(EngelsizIsModel.fromMap(
            key.toString(),
            Map<dynamic, dynamic>.from(value),
          ));
        }
      });

      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  Future<void> add(EngelsizIsModel model) async {
    final id = model.id.isEmpty ? _uuid.v4() : model.id;
    await _ref.child(id).set(model.toMap());
  }
}