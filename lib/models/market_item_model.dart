class MarketItemModel {
  final String id;
  final String title;
  final int price; // TL
  final String imageUrl;
  final String category; // mobilya, ev-dekor, hirdavat...
  final String tag; // 1.el, 2.el vb.
  final String brand; // opsiyonel
  final int createdAt;

  // 🔥 HEDİYELİK / TASARIM (OPSİYONEL)
  final bool isGift;              // hediyelik tasarım kartı mı?
  final String? designId;         // D010 vb.
  final String? giftType;         // sehpa / saat / ucgen
  final String? giftColor;        // seçilen renk
  final String? customerPhotoUrl; // müşterinin yüklediği foto (sepette/checkout'ta dolabilir)

  const MarketItemModel({
    required this.id,
    required this.title,
    required this.price,
    required this.imageUrl,
    required this.category,
    required this.tag,
    required this.brand,
    required this.createdAt,

    // hediyelik
    this.isGift = false,
    this.designId,
    this.giftType,
    this.giftColor,
    this.customerPhotoUrl,
  });

  factory MarketItemModel.fromMap(String id, Map<dynamic, dynamic> map) {
    return MarketItemModel(
      id: id,
      title: (map['title'] ?? '').toString(),
      price: (map['price'] ?? 0) is int
          ? map['price'] as int
          : int.tryParse((map['price'] ?? '0').toString()) ?? 0,
      imageUrl: (map['imageUrl'] ?? '').toString(),
      category: (map['category'] ?? '').toString(),
      tag: (map['tag'] ?? '').toString(),
      brand: (map['brand'] ?? '').toString(),
      createdAt: (map['createdAt'] ?? 0) is int
          ? map['createdAt'] as int
          : int.tryParse((map['createdAt'] ?? '0').toString()) ?? 0,

      // hediyelik (yoksa false / null)
      isGift: map['isGift'] == true,
      designId: map['designId']?.toString(),
      giftType: map['giftType']?.toString(),
      giftColor: map['giftColor']?.toString(),
      customerPhotoUrl: map['customerPhotoUrl']?.toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'price': price,
      'imageUrl': imageUrl,
      'category': category,
      'tag': tag,
      'brand': brand,
      'createdAt': createdAt,

      // hediyelik
      'isGift': isGift,
      if (designId != null) 'designId': designId,
      if (giftType != null) 'giftType': giftType,
      if (giftColor != null) 'giftColor': giftColor,
      if (customerPhotoUrl != null) 'customerPhotoUrl': customerPhotoUrl,
    };
  }

  /// 🔧 Sepete eklerken seçilen foto/renk geldiyse bu şekilde güncellemek kolay olsun
  MarketItemModel copyWith({
    String? giftColor,
    String? customerPhotoUrl,
  }) {
    return MarketItemModel(
      id: id,
      title: title,
      price: price,
      imageUrl: imageUrl,
      category: category,
      tag: tag,
      brand: brand,
      createdAt: createdAt,
      isGift: isGift,
      designId: designId,
      giftType: giftType,
      giftColor: giftColor ?? this.giftColor,
      customerPhotoUrl: customerPhotoUrl ?? this.customerPhotoUrl,
    );
  }
}