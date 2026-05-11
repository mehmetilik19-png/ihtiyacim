class NobetciEczaneModel {
  final int pharmacyID;
  final String pharmacyName;
  final String address;
  final String city;
  final String district;
  final String? town;
  final String? directions;
  final String? phone;
  final String? phone2;
  final String? dutyStart;
  final String? dutyEnd;
  final double? latitude;
  final double? longitude;
  final double? distanceKm;

  NobetciEczaneModel({
    required this.pharmacyID,
    required this.pharmacyName,
    required this.address,
    required this.city,
    required this.district,
    this.town,
    this.directions,
    this.phone,
    this.phone2,
    this.dutyStart,
    this.dutyEnd,
    this.latitude,
    this.longitude,
    this.distanceKm,
  });

  factory NobetciEczaneModel.fromJson(Map<String, dynamic> j) {
    double? _d(dynamic v) => (v is num) ? v.toDouble() : double.tryParse('${v ?? ''}');
    int _i(dynamic v) => (v is int) ? v : int.tryParse('${v ?? 0}') ?? 0;

    return NobetciEczaneModel(
      pharmacyID: _i(j['pharmacyID']),
      pharmacyName: (j['pharmacyName'] ?? '').toString(),
      address: (j['address'] ?? '').toString(),
      city: (j['city'] ?? '').toString(),
      district: (j['district'] ?? '').toString(),
      town: j['town']?.toString(),
      directions: j['directions']?.toString(),
      phone: j['phone']?.toString(),
      phone2: j['phone2']?.toString(),
      dutyStart: j['pharmacyDutyStart']?.toString(),
      dutyEnd: j['pharmacyDutyEnd']?.toString(),
      latitude: _d(j['latitude']),
      longitude: _d(j['longitude']),
      distanceKm: _d(j['distanceKm']),
    );
  }
}