import 'package:cloud_firestore/cloud_firestore.dart';
import 'order_model.dart';

class OrderRepository {
  OrderRepository({FirebaseFirestore? db})
      : _db = db ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

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

  Future<String> createOrder({
    required String buyerId,
    required String buyerEmail,
    required List<OrderItem> items,
    required ShippingAddress address,
    required double grandTotal,
    Map<String, String>? customerPhotosByProductId,
  }) async {
    if (address.phone.trim().isEmpty) {
      throw Exception('Telefon numarası zorunlu.');
    }

    final now = _now();
    final doc = _orders.doc();
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

    batch.set(doc, data);

    batch.set(_userOrders(buyerId).doc(orderId), {
      'orderId': orderId,
      'createdAt': now,
      'updatedAt': now,
    });

    batch.set(_events(orderId).doc(), {
      'type': 'created',
      'message': 'Sipariş alındı',
      'createdAt': now,
    });

    batch.set(_messages(orderId).doc(), {
      'from': 'system',
      'text': 'Sipariş alındı. Hazırlık başlayınca haber vereceğiz.',
      'createdAt': now,
      'system': true,
    });

    await batch.commit();
    return orderId;
  }

  Stream<List<String>> watchUserOrderIds(String uid) {
    return _userOrders(uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) => d.id).toList());
  }

  Stream<OrderModel?> watchOrder(String orderId) {
    return _orders.doc(orderId).snapshots().map((snap) {
      final v = snap.data();
      if (v == null) return null;
      return OrderModel.fromMap(orderId, v);
    });
  }

  Stream<List<OrderModel>> watchAllOrders({bool includeArchived = false}) {
    return _orders
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) {
      final list =
      snap.docs.map((d) => OrderModel.fromMap(d.id, d.data())).toList();

      if (includeArchived) return list;

      return list.where((o) {
        final raw = o.toMap()['archived'];
        return raw != true;
      }).toList();
    });
  }

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
      'shippedAt': now,
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

  Future<void> adminSetDelivered(String orderId, String buyerId) async {
    final now = _now();
    final returnDeadline =
        DateTime.now().add(const Duration(days: 14)).millisecondsSinceEpoch;

    final batch = _db.batch();

    batch.update(_orders.doc(orderId), {
      'status': 'delivered',
      'deliveredAt': now,
      'returnDeadline': returnDeadline,
      'updatedAt': now,
    });

    batch.set(_events(orderId).doc(), {
      'type': 'delivered',
      'message': 'Teslim edildi. İade süresi 14 gün.',
      'createdAt': now,
    });

    batch.set(_notifications(buyerId).doc(), {
      'title': 'Teslim edildi',
      'body': 'Sipariş #$orderId teslim edildi. İade süresi 14 gün.',
      'createdAt': now,
      'read': false,
      'orderId': orderId,
    });

    batch.set(_messages(orderId).doc(), {
      'from': 'system',
      'text': 'Sipariş teslim edildi. İade talebi için 14 gün süren var.',
      'createdAt': now,
      'system': true,
    });

    await batch.commit();
  }

  Future<void> userRequestReturn({
    required String orderId,
    required String buyerId,
    required String reason,
  }) async {
    final now = _now();

    final snap = await _orders.doc(orderId).get();
    final data = snap.data();

    if (data == null) {
      throw Exception('Sipariş bulunamadı.');
    }

    final deadlineRaw = data['returnDeadline'];
    final deadline = deadlineRaw is int
        ? deadlineRaw
        : int.tryParse((deadlineRaw ?? '0').toString()) ?? 0;

    if (deadline > 0 && now > deadline) {
      throw Exception('İade süresi dolmuş.');
    }

    final batch = _db.batch();

    batch.update(_orders.doc(orderId), {
      'status': 'return_requested',
      'returnReason': reason,
      'returnRequestedAt': now,
      'updatedAt': now,
    });

    batch.set(_events(orderId).doc(), {
      'type': 'return_requested',
      'message': 'İade talebi oluşturuldu: $reason',
      'createdAt': now,
    });

    batch.set(_messages(orderId).doc(), {
      'from': 'system',
      'text': 'İade talebin alındı. Admin inceleyecek.',
      'createdAt': now,
      'system': true,
    });

    await batch.commit();
  }

  Future<void> adminApproveReturn({
    required String orderId,
    required String buyerId,
    String? adminNote,
  }) async {
    final now = _now();
    final batch = _db.batch();

    batch.update(_orders.doc(orderId), {
      'status': 'return_approved',
      'returnAdminNote': adminNote,
      'returnApprovedAt': now,
      'updatedAt': now,
    });

    batch.set(_events(orderId).doc(), {
      'type': 'return_approved',
      'message': 'İade talebi onaylandı',
      'createdAt': now,
    });

    batch.set(_notifications(buyerId).doc(), {
      'title': 'İade talebi onaylandı',
      'body': 'Sipariş #$orderId için iade talebin onaylandı.',
      'createdAt': now,
      'read': false,
      'orderId': orderId,
    });

    batch.set(_messages(orderId).doc(), {
      'from': 'system',
      'text': 'İade talebin onaylandı.',
      'createdAt': now,
      'system': true,
    });

    await batch.commit();
  }

  Future<void> adminRejectReturn({
    required String orderId,
    required String buyerId,
    String? adminNote,
  }) async {
    final now = _now();
    final batch = _db.batch();

    batch.update(_orders.doc(orderId), {
      'status': 'return_rejected',
      'returnAdminNote': adminNote,
      'returnRejectedAt': now,
      'updatedAt': now,
    });

    batch.set(_events(orderId).doc(), {
      'type': 'return_rejected',
      'message': 'İade talebi reddedildi',
      'createdAt': now,
    });

    batch.set(_notifications(buyerId).doc(), {
      'title': 'İade talebi reddedildi',
      'body': 'Sipariş #$orderId için iade talebin reddedildi.',
      'createdAt': now,
      'read': false,
      'orderId': orderId,
    });

    batch.set(_messages(orderId).doc(), {
      'from': 'system',
      'text': 'İade talebin reddedildi.',
      'createdAt': now,
      'system': true,
    });

    await batch.commit();
  }

  Future<void> adminSetReturnShipping({
    required String orderId,
    required String buyerId,
    String? trackingNo,
    String? company,
  }) async {
    final now = _now();
    final batch = _db.batch();

    batch.update(_orders.doc(orderId), {
      'status': 'return_shipping',
      'returnTrackingNo': trackingNo,
      'returnTrackingCompany': company,
      'returnShippingAt': now,
      'updatedAt': now,
    });

    batch.set(_events(orderId).doc(), {
      'type': 'return_shipping',
      'message': 'İade kargoda',
      'createdAt': now,
    });

    batch.set(_messages(orderId).doc(), {
      'from': 'system',
      'text': 'İade kargoda.',
      'createdAt': now,
      'system': true,
    });

    await batch.commit();
  }

  Future<void> adminCompleteReturn({
    required String orderId,
    required String buyerId,
  }) async {
    final now = _now();
    final batch = _db.batch();

    batch.update(_orders.doc(orderId), {
      'status': 'return_completed',
      'returnCompletedAt': now,
      'updatedAt': now,
    });

    batch.set(_events(orderId).doc(), {
      'type': 'return_completed',
      'message': 'İade tamamlandı',
      'createdAt': now,
    });

    batch.set(_notifications(buyerId).doc(), {
      'title': 'İade tamamlandı',
      'body': 'Sipariş #$orderId iade süreci tamamlandı.',
      'createdAt': now,
      'read': false,
      'orderId': orderId,
    });

    batch.set(_messages(orderId).doc(), {
      'from': 'system',
      'text': 'İade süreci tamamlandı.',
      'createdAt': now,
      'system': true,
    });

    await batch.commit();
  }

  Future<void> adminArchiveOrder(String orderId) async {
    final now = _now();

    await _orders.doc(orderId).update({
      'archived': true,
      'archivedAt': now,
      'updatedAt': now,
    });

    await _events(orderId).add({
      'type': 'archived',
      'message': 'Sipariş arşive alındı',
      'createdAt': now,
    });
  }

  Future<void> adminDeleteOrder({
    required String orderId,
    required String buyerId,
  }) async {
    final batch = _db.batch();

    batch.delete(_orders.doc(orderId));
    batch.delete(_userOrders(buyerId).doc(orderId));

    await batch.commit();
  }

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

  Stream<List<Map<String, dynamic>>> watchMessages(String orderId) {
    return _messages(orderId)
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snap) => snap.docs.map((d) => d.data()).toList());
  }
}