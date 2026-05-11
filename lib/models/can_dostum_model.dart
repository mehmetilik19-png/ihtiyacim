class CanDostumModel {
  final String id;
  final String title;      // örn: “Golden yavru sahiplendirme”
  final String petType;    // Kedi / Köpek / Kuş / Diğer
  final String city;       // 81 il
  final String desc;       // açıklama
  final int createdAt;
  final List<String> photoUrls;

  CanDostumModel({
    required this.id,
    required this.title,
    required this.petType,
    required this.city,
    required this.desc,
    required this.createdAt,
    required this.photoUrls,
  });

  factory CanDostumModel.fromMap(String id, Map<dynamic, dynamic>? map) {
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

    return CanDostumModel(
      id: id,
      title: (m['title'] ?? '').toString(),
      petType: (m['petType'] ?? 'Diğer').toString(),
      city: (m['city'] ?? '').toString(),
      desc: (m['desc'] ?? '').toString(),
      createdAt: createdAt,
      photoUrls: photos,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'petType': petType,
      'city': city,
      'desc': desc,
      'createdAt': createdAt,
      'photoUrls': photoUrls,
    };
  }
}