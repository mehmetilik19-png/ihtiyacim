class GecerkenModel {
  final String id;
  final String title;        // Kısa başlık
  final String role;         // Sürücü / Yolcu
  final String city;         // 81 il
  final String fromWhere;    // Nereden
  final String toWhere;      // Nereye
  final String note;         // Not / açıklama
  final int createdAt;
  final List<String> photoUrls;

  GecerkenModel({
    required this.id,
    required this.title,
    required this.role,
    required this.city,
    required this.fromWhere,
    required this.toWhere,
    required this.note,
    required this.createdAt,
    required this.photoUrls,
  });

  factory GecerkenModel.fromMap(String id, Map<dynamic, dynamic>? map) {
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

    return GecerkenModel(
      id: id,
      title: (m['title'] ?? '').toString(),
      role: (m['role'] ?? 'Yolcu').toString(),
      city: (m['city'] ?? '').toString(),
      fromWhere: (m['fromWhere'] ?? '').toString(),
      toWhere: (m['toWhere'] ?? '').toString(),
      note: (m['note'] ?? '').toString(),
      createdAt: createdAt,
      photoUrls: photos,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'role': role,
      'city': city,
      'fromWhere': fromWhere,
      'toWhere': toWhere,
      'note': note,
      'createdAt': createdAt,
      'photoUrls': photoUrls,
    };
  }
}