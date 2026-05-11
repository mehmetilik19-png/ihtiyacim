class OrderItem {
  final String productId;
  final String title;
  final double price;
  final int qty;
  final String? imageUrl;

  const OrderItem({
    required this.productId,
    required this.title,
    required this.price,
    required this.qty,
    this.imageUrl,
  });

  factory OrderItem.fromMap(Map<dynamic, dynamic> map) {
    return OrderItem(
      productId: (map['productId'] ?? '').toString(),
      title: (map['title'] ?? '').toString(),
      price: (map['price'] ?? 0).toDouble(),
      qty: (map['qty'] ?? 1) is int
          ? map['qty'] as int
          : int.tryParse((map['qty'] ?? '1').toString()) ?? 1,
      imageUrl: map['imageUrl']?.toString(),
    );
  }

  Map<String, dynamic> toMap() => {
    'productId': productId,
    'title': title,
    'price': price,
    'qty': qty,
    'imageUrl': imageUrl,
  }..removeWhere((k, v) => v == null);
}

class ShippingAddress {
  final String name;
  final String phone;
  final String line1;
  final String city;
  final String district;
  final String? zip;

  const ShippingAddress({
    required this.name,
    required this.phone,
    required this.line1,
    required this.city,
    required this.district,
    this.zip,
  });

  factory ShippingAddress.fromMap(Map<dynamic, dynamic> map) {
    return ShippingAddress(
      name: (map['name'] ?? '').toString(),
      phone: (map['phone'] ?? '').toString(),
      line1: (map['line1'] ?? '').toString(),
      city: (map['city'] ?? '').toString(),
      district: (map['district'] ?? '').toString(),
      zip: map['zip']?.toString(),
    );
  }

  Map<String, dynamic> toMap() => {
    'name': name,
    'phone': phone,
    'line1': line1,
    'city': city,
    'district': district,
    'zip': zip,
  }..removeWhere((k, v) => v == null);
}

enum OrderStatus {
  created,
  preparing,
  shipped,
  delivered,
  returnRequested,
  returnApproved,
  returnRejected,
  returnShipping,
  returnCompleted,
  archived,
  cancelled,
}

OrderStatus orderStatusFromString(String s) {
  switch (s) {
    case 'preparing':
      return OrderStatus.preparing;
    case 'shipped':
      return OrderStatus.shipped;
    case 'delivered':
      return OrderStatus.delivered;
    case 'return_requested':
      return OrderStatus.returnRequested;
    case 'return_approved':
      return OrderStatus.returnApproved;
    case 'return_rejected':
      return OrderStatus.returnRejected;
    case 'return_shipping':
      return OrderStatus.returnShipping;
    case 'return_completed':
      return OrderStatus.returnCompleted;
    case 'archived':
      return OrderStatus.archived;
    case 'cancelled':
      return OrderStatus.cancelled;
    case 'created':
    default:
      return OrderStatus.created;
  }
}

String orderStatusToString(OrderStatus s) {
  switch (s) {
    case OrderStatus.created:
      return 'created';
    case OrderStatus.preparing:
      return 'preparing';
    case OrderStatus.shipped:
      return 'shipped';
    case OrderStatus.delivered:
      return 'delivered';
    case OrderStatus.returnRequested:
      return 'return_requested';
    case OrderStatus.returnApproved:
      return 'return_approved';
    case OrderStatus.returnRejected:
      return 'return_rejected';
    case OrderStatus.returnShipping:
      return 'return_shipping';
    case OrderStatus.returnCompleted:
      return 'return_completed';
    case OrderStatus.archived:
      return 'archived';
    case OrderStatus.cancelled:
      return 'cancelled';
  }
}

class OrderModel {
  final String orderId;
  final String buyerId;
  final String buyerEmail;
  final List<OrderItem> items;
  final ShippingAddress address;
  final double grandTotal;
  final OrderStatus status;

  final String? trackingCompany;
  final String? trackingNo;

  final int createdAt;
  final int updatedAt;

  final int? shippedAt;
  final int? deliveredAt;
  final int? returnDeadline;

  final String? returnReason;
  final int? returnRequestedAt;
  final String? returnAdminNote;
  final int? returnApprovedAt;
  final int? returnRejectedAt;
  final String? returnTrackingCompany;
  final String? returnTrackingNo;
  final int? returnShippingAt;
  final int? returnCompletedAt;

  final bool archived;
  final int? archivedAt;

  const OrderModel({
    required this.orderId,
    required this.buyerId,
    required this.buyerEmail,
    required this.items,
    required this.address,
    required this.grandTotal,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.trackingCompany,
    this.trackingNo,
    this.shippedAt,
    this.deliveredAt,
    this.returnDeadline,
    this.returnReason,
    this.returnRequestedAt,
    this.returnAdminNote,
    this.returnApprovedAt,
    this.returnRejectedAt,
    this.returnTrackingCompany,
    this.returnTrackingNo,
    this.returnShippingAt,
    this.returnCompletedAt,
    this.archived = false,
    this.archivedAt,
  });

  static int _intVal(dynamic v) {
    if (v is int) return v;
    if (v is double) return v.round();
    return int.tryParse((v ?? '0').toString()) ?? 0;
  }

  static int? _nullableInt(dynamic v) {
    if (v == null) return null;
    final i = _intVal(v);
    return i == 0 ? null : i;
  }

  static double _doubleVal(dynamic v) {
    if (v is double) return v;
    if (v is int) return v.toDouble();
    return double.tryParse((v ?? '0').toString()) ?? 0;
  }

  factory OrderModel.fromMap(String orderId, Map<dynamic, dynamic> map) {
    final itemsRaw = (map['items'] as List?) ?? [];
    final items = itemsRaw
        .map((e) => OrderItem.fromMap(Map<dynamic, dynamic>.from(e as Map)))
        .toList();

    final rawAddress = map['address'];
    final addressMap = rawAddress is Map
        ? Map<dynamic, dynamic>.from(rawAddress)
        : <dynamic, dynamic>{};

    return OrderModel(
      orderId: orderId,
      buyerId: (map['buyerId'] ?? '').toString(),
      buyerEmail: (map['buyerEmail'] ?? '').toString(),
      items: items,
      address: ShippingAddress.fromMap(addressMap),
      grandTotal: _doubleVal(map['grandTotal']),
      status: orderStatusFromString((map['status'] ?? 'created').toString()),
      trackingCompany: map['trackingCompany']?.toString(),
      trackingNo: map['trackingNo']?.toString(),
      createdAt: _intVal(map['createdAt']),
      updatedAt: _intVal(map['updatedAt']),
      shippedAt: _nullableInt(map['shippedAt']),
      deliveredAt: _nullableInt(map['deliveredAt']),
      returnDeadline: _nullableInt(map['returnDeadline']),
      returnReason: map['returnReason']?.toString(),
      returnRequestedAt: _nullableInt(map['returnRequestedAt']),
      returnAdminNote: map['returnAdminNote']?.toString(),
      returnApprovedAt: _nullableInt(map['returnApprovedAt']),
      returnRejectedAt: _nullableInt(map['returnRejectedAt']),
      returnTrackingCompany: map['returnTrackingCompany']?.toString(),
      returnTrackingNo: map['returnTrackingNo']?.toString(),
      returnShippingAt: _nullableInt(map['returnShippingAt']),
      returnCompletedAt: _nullableInt(map['returnCompletedAt']),
      archived: map['archived'] == true,
      archivedAt: _nullableInt(map['archivedAt']),
    );
  }

  Map<String, dynamic> toMap() => {
    'orderId': orderId,
    'buyerId': buyerId,
    'buyerEmail': buyerEmail,
    'items': items.map((e) => e.toMap()).toList(),
    'address': address.toMap(),
    'grandTotal': grandTotal,
    'status': orderStatusToString(status),
    'trackingCompany': trackingCompany,
    'trackingNo': trackingNo,
    'createdAt': createdAt,
    'updatedAt': updatedAt,
    'shippedAt': shippedAt,
    'deliveredAt': deliveredAt,
    'returnDeadline': returnDeadline,
    'returnReason': returnReason,
    'returnRequestedAt': returnRequestedAt,
    'returnAdminNote': returnAdminNote,
    'returnApprovedAt': returnApprovedAt,
    'returnRejectedAt': returnRejectedAt,
    'returnTrackingCompany': returnTrackingCompany,
    'returnTrackingNo': returnTrackingNo,
    'returnShippingAt': returnShippingAt,
    'returnCompletedAt': returnCompletedAt,
    'archived': archived,
    'archivedAt': archivedAt,
  }..removeWhere((k, v) => v == null);
}

String orderStatusText(dynamic status) {
  final s = status is String ? status : status.toString();
  final normalized = s.contains('.') ? s.split('.').last : s;

  switch (normalized) {
    case 'created':
      return 'Sipariş alındı';
    case 'preparing':
      return 'Hazırlanıyor';
    case 'shipped':
      return 'Kargoya verildi';
    case 'delivered':
      return 'Teslim edildi';
    case 'returnRequested':
    case 'return_requested':
      return 'İade talebi var';
    case 'returnApproved':
    case 'return_approved':
      return 'İade onaylandı';
    case 'returnRejected':
    case 'return_rejected':
      return 'İade reddedildi';
    case 'returnShipping':
    case 'return_shipping':
      return 'İade kargoda';
    case 'returnCompleted':
    case 'return_completed':
      return 'İade tamamlandı';
    case 'archived':
      return 'Arşiv';
    case 'cancelled':
      return 'İptal edildi';
    default:
      return 'Sipariş alındı';
  }
}