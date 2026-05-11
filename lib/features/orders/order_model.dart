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
      qty: (map['qty'] ?? 1) as int,
      imageUrl: map['imageUrl'] as String?,
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
      zip: map['zip'] as String?,
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

enum OrderStatus { created, preparing, shipped, delivered, cancelled }

OrderStatus orderStatusFromString(String s) {
  switch (s) {
    case 'preparing':
      return OrderStatus.preparing;
    case 'shipped':
      return OrderStatus.shipped;
    case 'delivered':
      return OrderStatus.delivered;
    case 'cancelled':
      return OrderStatus.cancelled;
    case 'created':
    default:
      return OrderStatus.created;
  }
}

String orderStatusToString(OrderStatus s) {
  return switch (s) {
    OrderStatus.created => 'created',
    OrderStatus.preparing => 'preparing',
    OrderStatus.shipped => 'shipped',
    OrderStatus.delivered => 'delivered',
    OrderStatus.cancelled => 'cancelled',
  };
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
  });

  factory OrderModel.fromMap(String orderId, Map<dynamic, dynamic> map) {
    final itemsRaw = (map['items'] as List?) ?? [];
    final items = itemsRaw
        .map((e) => OrderItem.fromMap(Map<dynamic, dynamic>.from(e as Map)))
        .toList();

    return OrderModel(
      orderId: orderId,
      buyerId: (map['buyerId'] ?? '').toString(),
      buyerEmail: (map['buyerEmail'] ?? '').toString(),
      items: items,
      address: ShippingAddress.fromMap(Map<dynamic, dynamic>.from(map['address'] as Map)),
      grandTotal: (map['grandTotal'] ?? 0).toDouble(),
      status: orderStatusFromString((map['status'] ?? 'created').toString()),
      trackingCompany: map['trackingCompany'] as String?,
      trackingNo: map['trackingNo'] as String?,
      createdAt: (map['createdAt'] ?? 0) as int,
      updatedAt: (map['updatedAt'] ?? 0) as int,
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
  }..removeWhere((k, v) => v == null);
}
String orderStatusText(dynamic status) {
  final s = status is String ? status : status.toString();

  // enum gelirse: OrderStatus.created gibi
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
    case 'cancelled':
      return 'İptal edildi';
    default:
      return 'Sipariş alındı';
  }
}