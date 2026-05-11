import 'dart:convert';
import 'package:http/http.dart' as http;

import '../models/nobetci_eczane_model.dart';

class NosyApiPharmacyService {
  // Base URL dokümanda böyle geçiyor 1
  static const String _base = 'https://www.nosyapi.com/apiv2/service';

  // ✅ Senin API Key’in:
  static const String apiKey =
      'JB7MBKhstjvSFoyi9s7rCQYvRfYddrNOb3ymDwRSjmxwRNXbGEu1RStZrzwm';

  Future<List<NobetciEczaneModel>> getNearby({
    required double latitude,
    required double longitude,
  }) async {
    // Konuma göre endpoint: pharmacies-on-duty/locations 2
    final uri = Uri.parse(
      '$_base/pharmacies-on-duty/locations'
          '?latitude=$latitude&longitude=$longitude&apiKey=$apiKey',
    );

    final res = await http.get(uri);
    if (res.statusCode != 200) {
      throw Exception('HTTP ${res.statusCode}: ${res.body}');
    }

    final json = jsonDecode(res.body) as Map<String, dynamic>;
    if (json['status'] != 'success') {
      throw Exception(json['messageTR'] ?? json['message'] ?? 'API hata');
    }

    final data = (json['data'] as List?) ?? const [];
    return data
        .map((e) => NobetciEczaneModel.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }
}