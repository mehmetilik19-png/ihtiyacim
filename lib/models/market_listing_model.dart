class MarketListingModel {
  final String id;
  final String title;
  final int price;
  final int oldPrice;
  final String ilanCode;
  final String condition;

  final String categoryMain;
  final String categorySub;
  final String brand;

  final String categoryId;
  final String categoryPath;
  final Map<String, dynamic> attrs;

  final String city;
  final int createdAt;
  final List<String> photoUrls;

  final bool isGift;
  final String? designId;
  final String? giftColor;
  final String? customerPhotoUrl;

  const MarketListingModel({
    required this.id,
    required this.title,
    required this.price,
    this.oldPrice = 0,
    this.ilanCode = '',
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

  bool get hasDiscount => oldPrice > price && oldPrice > 0;

  MarketListingModel copyWith({
    String? customerPhotoUrl,
    String? giftColor,
  }) {
    return MarketListingModel(
      id: id,
      title: title,
      price: price,
      oldPrice: oldPrice,
      ilanCode: ilanCode,
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

    int _i(dynamic v) {
      if (v is int) return v;
      if (v is double) return v.round();
      return int.tryParse((v ?? '0').toString()) ?? 0;
    }

    dynamic rawPhotos = map['photoUrls'];
    rawPhotos ??= map['photos'];
    rawPhotos ??= map['images'];

    final photos = (rawPhotos is List)
        ? rawPhotos
        .map((e) => e.toString())
        .where((e) => e.trim().isNotEmpty)
        .toList()
        : <String>[];

    final rawAttrs = map['attrs'];
    final attrs =
    (rawAttrs is Map) ? Map<String, dynamic>.from(rawAttrs) : <String, dynamic>{};

    String t = _s(map['title']);
    if (t.isEmpty) t = _s(map['name']);
    if (t.isEmpty) t = _s(map['productName']);
    if (t.isEmpty) t = 'İlan';

    String c = _s(map['city']);
    if (c.isEmpty) c = _s(map['il']);
    if (c.isEmpty) c = _s(map['location']);

    final oldPrice = _i(
      map['oldPrice'] ??
          attrs['oldPrice'] ??
          map['old_price'] ??
          attrs['old_price'] ??
          map['eskiFiyat'] ??
          attrs['eskiFiyat'],
    );

    String ilanCode = _s(
      map['ilanCode'] ??
          attrs['ilanCode'] ??
          map['listingCode'] ??
          attrs['listingCode'] ??
          map['code'] ??
          attrs['code'],
    );

    if (ilanCode.isEmpty) {
      final cleanId = id.replaceAll(RegExp(r'[^A-Za-z0-9]'), '');
      final short = cleanId.length > 6
          ? cleanId.substring(cleanId.length - 6).toUpperCase()
          : cleanId.toUpperCase();
      ilanCode = 'MKT-$short';
    }

    return MarketListingModel(
      id: id,
      title: t,
      price: _i(map['price']),
      oldPrice: oldPrice,
      ilanCode: ilanCode,
      condition: _s(map['condition']).isEmpty ? '2el' : _s(map['condition']),
      categoryMain: _s(map['categoryMain']),
      categorySub: _s(map['categorySub']),
      brand: _s(map['brand']),
      categoryId: _s(map['categoryId']),
      categoryPath: _s(map['categoryPath']),
      attrs: attrs,
      city: c,
      createdAt: _i(map['createdAt']),
      photoUrls: photos,
      isGift: map['isGift'] == true,
      designId: map['designId']?.toString(),
      giftColor: map['giftColor']?.toString(),
      customerPhotoUrl: map['customerPhotoUrl']?.toString(),
    );
  }

  Map<String, dynamic> toMap() {
    final newAttrs = Map<String, dynamic>.from(attrs);
    newAttrs['oldPrice'] = oldPrice;
    newAttrs['ilanCode'] = ilanCode;

    return {
      'title': title,
      'price': price,
      'oldPrice': oldPrice,
      'ilanCode': ilanCode,
      'condition': condition,
      'categoryMain': categoryMain,
      'categorySub': categorySub,
      'brand': brand,
      'categoryId': categoryId,
      'categoryPath': categoryPath,
      'attrs': newAttrs,
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