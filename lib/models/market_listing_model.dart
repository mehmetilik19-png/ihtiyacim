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
    String? title,
    int? price,
    int? oldPrice,
    String? ilanCode,
    String? condition,
    String? categoryMain,
    String? categorySub,
    String? brand,
    String? categoryId,
    String? categoryPath,
    Map<String, dynamic>? attrs,
    String? city,
    int? createdAt,
    List<String>? photoUrls,
    bool? isGift,
    String? designId,
    String? giftColor,
    String? customerPhotoUrl,
  }) {
    return MarketListingModel(
      id: id,
      title: title ?? this.title,
      price: price ?? this.price,
      oldPrice: oldPrice ?? this.oldPrice,
      ilanCode: ilanCode ?? this.ilanCode,
      condition: condition ?? this.condition,
      categoryMain: categoryMain ?? this.categoryMain,
      categorySub: categorySub ?? this.categorySub,
      brand: brand ?? this.brand,
      categoryId: categoryId ?? this.categoryId,
      categoryPath: categoryPath ?? this.categoryPath,
      attrs: attrs ?? this.attrs,
      city: city ?? this.city,
      createdAt: createdAt ?? this.createdAt,
      photoUrls: photoUrls ?? this.photoUrls,
      isGift: isGift ?? this.isGift,
      designId: designId ?? this.designId,
      giftColor: giftColor ?? this.giftColor,
      customerPhotoUrl: customerPhotoUrl ?? this.customerPhotoUrl,
    );
  }

  factory MarketListingModel.fromMap(String id, Map<dynamic, dynamic> map) {
    String s(dynamic value) => (value ?? '').toString().trim();

    int i(dynamic value) {
      if (value is int) return value;
      if (value is double) return value.round();
      return int.tryParse((value ?? '0').toString()) ?? 0;
    }

    dynamic rawPhotos = map['photoUrls'] ?? map['photos'] ?? map['images'];
    final photos = <String>[];

    if (rawPhotos is List) {
      photos.addAll(
        rawPhotos
            .map((e) => e?.toString().trim() ?? '')
            .where((e) => e.isNotEmpty),
      );
    } else if (rawPhotos is Map) {
      photos.addAll(
        rawPhotos.values
            .map((e) => e?.toString().trim() ?? '')
            .where((e) => e.isNotEmpty),
      );
    }

    final rawAttrs = map['attrs'];
    final attrs = rawAttrs is Map
        ? Map<String, dynamic>.from(rawAttrs)
        : <String, dynamic>{};

    String title = s(map['title']);
    if (title.isEmpty) title = s(map['name']);
    if (title.isEmpty) title = s(map['productName']);
    if (title.isEmpty) title = 'İlan';

    String city = s(map['city']);
    if (city.isEmpty) city = s(map['il']);
    if (city.isEmpty) city = s(map['location']);

    final oldPrice = i(
      map['oldPrice'] ??
          attrs['oldPrice'] ??
          map['old_price'] ??
          attrs['old_price'] ??
          map['eskiFiyat'] ??
          attrs['eskiFiyat'],
    );

    String ilanCode = s(
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
      title: title,
      price: i(map['price']),
      oldPrice: oldPrice,
      ilanCode: ilanCode,
      condition: s(map['condition']).isEmpty ? '2el' : s(map['condition']),
      categoryMain: s(map['categoryMain']),
      categorySub: s(map['categorySub']),
      brand: s(map['brand']),
      categoryId: s(map['categoryId']),
      categoryPath: s(map['categoryPath']),
      attrs: attrs,
      city: city,
      createdAt: i(map['createdAt']),
      photoUrls: photos.toSet().toList(),
      isGift: map['isGift'] == true,
      designId: map['designId']?.toString(),
      giftColor: map['giftColor']?.toString(),
      customerPhotoUrl: map['customerPhotoUrl']?.toString(),
    );
  }

  Map<String, dynamic> toMap() {
    final newAttrs = Map<String, dynamic>.from(attrs)
      ..['oldPrice'] = oldPrice
      ..['ilanCode'] = ilanCode;

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
