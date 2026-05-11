class UserProfile {
  final String uid;
  final String email;
  final String? fullName;
  final String? phone;
  final String? avatarUrl;

  const UserProfile({
    required this.uid,
    required this.email,
    this.fullName,
    this.phone,
    this.avatarUrl,
  });

  factory UserProfile.fromMap(String uid, Map<dynamic, dynamic> map) {
    return UserProfile(
      uid: uid,
      email: (map['email'] ?? '') as String,
      fullName: map['fullName'] as String?,
      phone: map['phone'] as String?,
      avatarUrl: map['avatarUrl'] as String?,
    );
  }

  Map<String, dynamic> toUpdateMap() {
    return {
      'email': email,
      'fullName': fullName,
      'phone': phone,
      'avatarUrl': avatarUrl,
      'updatedAt': DateTime.now().millisecondsSinceEpoch,
    };
  }

  UserProfile copyWith({String? fullName, String? phone, String? avatarUrl}) {
    return UserProfile(
      uid: uid,
      email: email,
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      avatarUrl: avatarUrl ?? this.avatarUrl,
    );
  }
}