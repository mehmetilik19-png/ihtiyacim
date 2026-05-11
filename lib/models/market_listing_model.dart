class MarketListingModel {
  final String id;
  final String title;
  final int price;
  final String condition; // "1el" | "2el"

  final String categoryMain;
  final String categorySub;
  final String brand;

  final String categoryId;
  final String categoryPath;
  final Map<String, dynamic> attrs;

  final String city;
  final int createdAt;
  final List<String> photoUrls;

  // Hediyelik / kişiye özel (opsiyonel)
  final bool isGift;
  final String? designId;
  final String? giftColor;
  final String? customerPhotoUrl;

  const MarketListingModel({
    required this.id,
    required this.title,
    required this.price,
    required this.condition,
    required this.categoryMain,
    required this.categorySub,
    required this.brand,
    required this.categoryId,
    required this.categoryPath,
    required this.attrs,
    required this.city,
    required this.createdAt,
    required this.photoUrls,
    this.isGift = false,
    this.designId,
    this.giftColor,
    this.customerPhotoUrl,
  });

  MarketListingModel copyWith({
    String? customerPhotoUrl,
    String? giftColor,
  }) {
    return MarketListingModel(
      id: id,
      title: title,
      price: price,
      condition: condition,
      categoryMain: categoryMain,
      categorySub: categorySub,
      brand: brand,
      categoryId: categoryId,
      categoryPath: categoryPath,
      attrs: attrs,
      city: city,
      createdAt: createdAt,
      photoUrls: photoUrls,
      isGift: isGift,
      designId: designId,
      giftColor: giftColor ?? this.giftColor,
      customerPhotoUrl: customerPhotoUrl ?? this.customerPhotoUrl,
    );
  }

  factory MarketListingModel.fromMap(String id, Map<dynamic, dynamic> map) {
    String _s(dynamic v) => (v ?? '').toString().trim();

    // Foto alanları farklı isimlerle gelebilir
    dynamic rawPhotos = map['photoUrls'];
    rawPhotos ??= map['photos'];
    rawPhotos ??= map['images'];

    final photos = (rawPhotos is List)
        ? rawPhotos.map((e) => e.toString()).where((e) => e.trim().isNotEmpty).toList()
        : <String>[];

    final rawAttrs = map['attrs'];

    // Başlık bazı kayıtlarda title yerine name gelebilir
    String t = _s(map['title']);
    if (t.isEmpty) t = _s(map['name']);
    if (t.isEmpty) t = _s(map['productName']);
    if (t.isEmpty) t = 'İlan';

    // Şehir alanı farklı isimle gelebilir
    String c = _s(map['city']);
    if (c.isEmpty) c = _s(map['il']);
    if (c.isEmpty) c = _s(map['location']);

    return MarketListingModel(
      id: id,
      title: t,
      price: (map['price'] ?? 0) is int
          ? map['price'] as int
          : int.tryParse((map['price'] ?? '0').toString()) ?? 0,
      condition: _s(map['condition']).isEmpty ? '2el' : _s(map['condition']),
      categoryMain: _s(map['categoryMain']),
      categorySub: _s(map['categorySub']),
      brand: _s(map['brand']),
      categoryId: _s(map['categoryId']),
      categoryPath: _s(map['categoryPath']),
      attrs: (rawAttrs is Map) ? Map<String, dynamic>.from(rawAttrs) : <String, dynamic>{},
      city: c,
      createdAt: (map['createdAt'] ?? 0) is int
          ? map['createdAt'] as int
          : int.tryParse((map['createdAt'] ?? '0').toString()) ?? 0,
      photoUrls: photos,
      isGift: map['isGift'] == true,
      designId: map['designId']?.toString(),
      giftColor: map['giftColor']?.toString(),
      customerPhotoUrl: map['customerPhotoUrl']?.toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'price': price,
      'condition': condition,
      'categoryMain': categoryMain,
      'categorySub': categorySub,
      'brand': brand,
      'categoryId': categoryId,
      'categoryPath': categoryPath,
      'attrs': attrs,
      'city': city,
      'createdAt': createdAt,
      'photoUrls': photoUrls,
      'isGift': isGift,
      if (designId != null) 'designId': designId,
      if (giftColor != null) 'giftColor': giftColor,
      if (customerPhotoUrl != null) 'customerPhotoUrl': customerPhotoUrl,
    };
  }
}