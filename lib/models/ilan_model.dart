class IlanModel {
  final String id;
  final String title;
  final String category;
  final String city;
  final String desc;
  final int createdAt;
  final List<String> photoUrls;

  // ✅ ilan sahibi
  final String ownerId;

  // ✅ active / inactive / sold / deleted
  final String status;

  // ✅ YENİ: free / swap
  final String tradeType;

  IlanModel({
    required this.id,
    required this.title,
    required this.category,
    required this.city,
    required this.desc,
    required this.createdAt,
    required this.photoUrls,
    required this.ownerId,
    required this.status,
    required this.tradeType,
  });

  factory IlanModel.fromMap(String id, Map<dynamic, dynamic>? map) {
    final m = map ?? <dynamic, dynamic>{};

    final rawPhotos = m['photoUrls'];
    final photos = (rawPhotos is List)
        ? rawPhotos.map((e) => e.toString()).toList()
        : <String>[];

    final rawCreatedAt = m['createdAt'];
    int createdAt;
    if (rawCreatedAt is int) {
      createdAt = rawCreatedAt;
    } else if (rawCreatedAt is num) {
      createdAt = rawCreatedAt.toInt();
    } else {
      createdAt = int.tryParse((rawCreatedAt ?? '0').toString()) ?? 0;
    }

    final ownerId = (m['ownerId'] ?? m['userId'] ?? '').toString();
    final status = (m['status'] ?? 'active').toString();

    // ✅ YENİ: free/swap (eski ilanlarda yoksa free kabul)
    final tradeTypeRaw = (m['tradeType'] ?? m['trade'] ?? 'free').toString().toLowerCase();
    final tradeType = (tradeTypeRaw == 'swap') ? 'swap' : 'free';

    return IlanModel(
      id: id,
      title: (m['title'] ?? '').toString(),
      category: (m['category'] ?? '').toString(),
      city: (m['city'] ?? '').toString(),
      desc: (m['desc'] ?? '').toString(),
      createdAt: createdAt,
      photoUrls: photos,
      ownerId: ownerId,
      status: status,
      tradeType: tradeType,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'category': category,
      'city': city,
      'desc': desc,
      'createdAt': createdAt,
      'photoUrls': photoUrls,
      'ownerId': ownerId,
      'status': status,

      // ✅ YENİ
      'tradeType': tradeType, // free / swap
    };
  }

  IlanModel copyWith({
    String? title,
    String? category,
    String? city,
    String? desc,
    List<String>? photoUrls,
    String? status,
    String? tradeType,
  }) {
    return IlanModel(
      id: id,
      title: title ?? this.title,
      category: category ?? this.category,
      city: city ?? this.city,
      desc: desc ?? this.desc,
      createdAt: createdAt,
      photoUrls: photoUrls ?? this.photoUrls,
      ownerId: ownerId,
      status: status ?? this.status,
      tradeType: tradeType ?? this.tradeType,
    );
  }
}