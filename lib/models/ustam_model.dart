class UstamModel {
  final String id;
  final String title;
  final String job;      // Boyacı, Elektrik vs (chip ile uyumlu)
  final String city;     // Ankara, İzmir
  final String district;
  final String desc;
  final String ownerId;
  final int createdAt;
  final List<String> photoUrls;

  UstamModel({
    required this.id,
    required this.title,
    required this.job,
    required this.city,
    required this.district,
    required this.desc,
    required this.ownerId,
    required this.createdAt,
    required this.photoUrls,
  });

  static String norm(String s) => s.trim().toLowerCase();

  factory UstamModel.fromMap(String id, Map<dynamic, dynamic> map) {
    return UstamModel(
      id: id,
      title: (map['title'] ?? '').toString(),
      job: (map['job'] ?? '').toString(),
      city: (map['city'] ?? '').toString(),
      district: (map['district'] ?? '').toString(),
      desc: (map['desc'] ?? '').toString(),
      ownerId: (map['ownerId'] ?? '').toString(),
      createdAt: (map['createdAt'] ?? 0) as int,
      photoUrls: map['photoUrls'] is List
          ? List<String>.from(map['photoUrls'])
          : [],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'job': job,
      'city': city,
      'district': district,
      'desc': desc,
      'ownerId': ownerId,
      'createdAt': createdAt,
      'photoUrls': photoUrls,
    };
  }
}