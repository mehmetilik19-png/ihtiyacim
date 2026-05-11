import 'package:cloud_firestore/cloud_firestore.dart';
import 'order_model.dart';

class OrderRepository {
  OrderRepository({FirebaseFirestore? db})
      : _db = db ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  // Firestore collection paths
  CollectionReference<Map<String, dynamic>> get _orders =>
      _db.collection('orders').withConverter<Map<String, dynamic>>(
        fromFirestore: (s, _) => (s.data() ?? <String, dynamic>{}),
        toFirestore: (m, _) => m,
      );

  CollectionReference<Map<String, dynamic>> _userOrders(String uid) =>
      _db.collection('user_orders').doc(uid).collection('orders');

  CollectionReference<Map<String, dynamic>> _events(String orderId) =>
      _db.collection('order_events').doc(orderId).collection('events');

  CollectionReference<Map<String, dynamic>> _messages(String orderId) =>
      _db.collection('messages').doc(orderId).collection('items');

  CollectionReference<Map<String, dynamic>> _notifications(String uid) =>
      _db.collection('notifications').doc(uid).collection('items');

  int _now() => DateTime.now().millisecondsSinceEpoch;

  /// ✅ Kullanıcı sipariş oluşturur (Firestore)
  Future<String> createOrder({
    required String buyerId,
    required String buyerEmail,
    required List<OrderItem> items,
    required ShippingAddress address,
    required double grandTotal,

    /// Hediyelik ürünlerde müşteri foto linkleri
    Map<String, String>? customerPhotosByProductId,
  }) async {
    if (address.phone.trim().isEmpty) {
      throw Exception('Telefon numarası zorunlu.');
    }

    final now = _now();
    final doc = _orders.doc(); // auto id
    final orderId = doc.id;

    final order = OrderModel(
      orderId: orderId,
      buyerId: buyerId,
      buyerEmail: buyerEmail,
      items: items,
      address: address,
      grandTotal: grandTotal,
      status: OrderStatus.created,
      createdAt: now,
      updatedAt: now,
    );

    final data = order.toMap();

    if (customerPhotosByProductId != null &&
        customerPhotosByProductId.isNotEmpty) {
      data['customerPhotos'] = customerPhotosByProductId;
    }

    final batch = _db.batch();

    // orders/{orderId}
    batch.set(doc, data);

    // user_orders/{uid}/orders/{orderId}
    batch.set(_userOrders(buyerId).doc(orderId), {
      'orderId': orderId,
      'createdAt': now,
      'updatedAt': now,
    });

    // event: created
    batch.set(_events(orderId).doc(), {
      'type': 'created',
      'message': 'Sipariş alındı',
      'createdAt': now,
    });

    // system message
    batch.set(_messages(orderId).doc(), {
      'from': 'system',
      'text': 'Sipariş alındı. Hazırlık başlayınca haber vereceğiz.',
      'createdAt': now,
      'system': true,
    });

    await batch.commit();
    return orderId;
  }

  /// ✅ Kullanıcı siparişlerim: orderId listesi
  Stream<List<String>> watchUserOrderIds(String uid) {
    return _userOrders(uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) => d.id).toList());
  }

  /// ✅ Tek sipariş dinle
  Stream<OrderModel?> watchOrder(String orderId) {
    return _orders.doc(orderId).snapshots().map((snap) {
      final v = snap.data();
      if (v == null) return null;
      return OrderModel.fromMap(orderId, v);
    });
  }

  /// ✅ Admin: tüm siparişler
  Stream<List<OrderModel>> watchAllOrders() {
    return _orders
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) {
      return snap.docs.map((d) => OrderModel.fromMap(d.id, d.data())).toList();
    });
  }

  /// ✅ Sipariş eventleri
  Stream<List<Map<String, dynamic>>> watchEvents(String orderId) {
    return _events(orderId)
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snap) {
      return snap.docs.map((d) {
        final m = d.data();
        return {
          'type': (m['type'] ?? '').toString(),
          'message': (m['message'] ?? '').toString(),
          'createdAt': (m['createdAt'] ?? 0) is int
              ? (m['createdAt'] as int)
              : int.tryParse((m['createdAt'] ?? '0').toString()) ?? 0,
        };
      }).toList();
    });
  }

  /// ✅ Admin durum: hazırlanıyor
  Future<void> adminSetPreparing(String orderId, String buyerId) async {
    final now = _now();
    final batch = _db.batch();

    batch.update(_orders.doc(orderId), {
      'status': 'preparing',
      'updatedAt': now,
    });

    batch.set(_events(orderId).doc(), {
      'type': 'preparing',
      'message': 'Sipariş hazırlanıyor',
      'createdAt': now,
    });

    batch.set(_notifications(buyerId).doc(), {
      'title': 'Sipariş hazırlanıyor',
      'body': 'Sipariş #$orderId hazırlanıyor.',
      'createdAt': now,
      'read': false,
      'orderId': orderId,
    });

    batch.set(_messages(orderId).doc(), {
      'from': 'system',
      'text': 'Sipariş hazırlanıyor.',
      'createdAt': now,
      'system': true,
    });

    await batch.commit();
  }

  /// ✅ Admin durum: kargoda
  Future<void> adminSetShipped({
    required String orderId,
    required String buyerId,
    required String trackingNo,
    String? company,
  }) async {
    final now = _now();
    final batch = _db.batch();

    batch.update(_orders.doc(orderId), {
      'status': 'shipped',
      'trackingNo': trackingNo,
      'trackingCompany': company,
      'updatedAt': now,
    });

    final msg = (company == null || company.trim().isEmpty)
        ? 'Kargoya verildi. Takip no: $trackingNo'
        : 'Kargoya verildi ($company). Takip no: $trackingNo';

    batch.set(_events(orderId).doc(), {
      'type': 'shipped',
      'message': msg,
      'createdAt': now,
    });

    batch.set(_notifications(buyerId).doc(), {
      'title': 'Kargon yola çıktı',
      'body': 'Sipariş #$orderId - Takip no: $trackingNo',
      'createdAt': now,
      'read': false,
      'orderId': orderId,
    });

    batch.set(_messages(orderId).doc(), {
      'from': 'system',
      'text': msg,
      'createdAt': now,
      'system': true,
    });

    await batch.commit();
  }

  /// ✅ Admin durum: teslim
  Future<void> adminSetDelivered(String orderId, String buyerId) async {
    final now = _now();
    final batch = _db.batch();

    batch.update(_orders.doc(orderId), {
      'status': 'delivered',
      'updatedAt': now,
    });

    batch.set(_events(orderId).doc(), {
      'type': 'delivered',
      'message': 'Teslim edildi',
      'createdAt': now,
    });

    batch.set(_notifications(buyerId).doc(), {
      'title': 'Teslim edildi',
      'body': 'Sipariş #$orderId teslim edildi.',
      'createdAt': now,
      'read': false,
      'orderId': orderId,
    });

    batch.set(_messages(orderId).doc(), {
      'from': 'system',
      'text': 'Sipariş teslim edildi.',
      'createdAt': now,
      'system': true,
    });

    await batch.commit();
  }

  /// ✅ Kullanıcı mesaj yazar (order chat)
  Future<void> sendUserMessage({
    required String orderId,
    required String fromUid,
    required String text,
  }) async {
    final now = _now();
    await _messages(orderId).add({
      'from': fromUid,
      'text': text,
      'createdAt': now,
      'system': false,
    });
  }

  /// ✅ Sipariş mesajlarını dinle
  Stream<List<Map<String, dynamic>>> watchMessages(String orderId) {
    return _messages(orderId)
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snap) => snap.docs.map((d) => d.data()).toList());
  }
}