class EngelsizIsModel {
  final String id;

  /// "is_arayan" | "isci_arayan"
  final String type;

  final String title;        // pozisyon / aranan iş
  final String category;     // meslek kategorisi
  final String city;         // il

  final String desc;         // açıklama
  final String contactName;  // kişi adı
  final String phone;        // iletişim
  final String whatsapp;     // opsiyon

  final int createdAt;

  // ✅ EKLENDİ
  final String ownerId; // ilan sahibi uid
  final String status;  // active / deleted / inactive vs.

  EngelsizIsModel({
    required this.id,
    required this.type,
    required this.title,
    required this.category,
    required this.city,
    required this.desc,
    required this.contactName,
    required this.phone,
    required this.whatsapp,
    required this.createdAt,
    required this.ownerId,
    required this.status,
  });

  factory EngelsizIsModel.fromMap(String id, Map<dynamic, dynamic>? map) {
    final m = map ?? <dynamic, dynamic>{};

    // createdAt güvenli parse
    final rawCreatedAt = m['createdAt'];
    int createdAt;
    if (rawCreatedAt is int) {
      createdAt = rawCreatedAt;
    } else if (rawCreatedAt is num) {
      createdAt = rawCreatedAt.toInt();
    } else {
      createdAt = int.tryParse((rawCreatedAt ?? '0').toString()) ?? 0;
    }

    // ✅ geriye dönük uyumluluk
    final ownerId = (m['ownerId'] ?? m['userId'] ?? '').toString();
    final status = (m['status'] ?? 'active').toString();

    return EngelsizIsModel(
      id: id,
      type: (m['type'] ?? 'isci_arayan').toString(),
      title: (m['title'] ?? '').toString(),
      category: (m['category'] ?? '').toString(),
      city: (m['city'] ?? '').toString(),
      desc: (m['desc'] ?? '').toString(),
      contactName: (m['contactName'] ?? '').toString(),
      phone: (m['phone'] ?? '').toString(),
      whatsapp: (m['whatsapp'] ?? '').toString(),
      createdAt: createdAt,
      ownerId: ownerId,
      status: status,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'type': type,
      'title': title,
      'category': category,
      'city': city,
      'desc': desc,
      'contactName': contactName,
      'phone': phone,
      'whatsapp': whatsapp,
      'createdAt': createdAt,

      // ✅
      'ownerId': ownerId,
      'status': status,
    };
  }

  EngelsizIsModel copyWith({
    String? type,
    String? title,
    String? category,
    String? city,
    String? desc,
    String? contactName,
    String? phone,
    String? whatsapp,
    int? createdAt,
    String? status,
  }) {
    return EngelsizIsModel(
      id: id,
      type: type ?? this.type,
      title: title ?? this.title,
      category: category ?? this.category,
      city: city ?? this.city,
      desc: desc ?? this.desc,
      contactName: contactName ?? this.contactName,
      phone: phone ?? this.phone,
      whatsapp: whatsapp ?? this.whatsapp,
      createdAt: createdAt ?? this.createdAt,
      ownerId: ownerId,
      status: status ?? this.status,
    );
  }
}