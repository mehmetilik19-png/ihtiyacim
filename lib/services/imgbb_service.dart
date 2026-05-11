import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;

class ImgbbService {
  // BURAYA kendi key'in:
  static const String _apiKey = '0faf5f066f8efad06d3d6ca7bc8773c4';

  Future<String> uploadBytes(Uint8List bytes) async {
    final uri = Uri.parse('https://api.imgbb.com/1/upload?key=$_apiKey');

    final res = await http.post(
      uri,
      body: {'image': base64Encode(bytes)},
    );

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('ImgBB upload failed: ${res.statusCode} ${res.body}');
    }

    final json = jsonDecode(res.body) as Map<String, dynamic>;
    final data = (json['data'] as Map?) ?? {};
    final url = (data['url'] ?? data['display_url'] ?? '').toString();

    if (url.isEmpty) throw Exception('ImgBB response url empty');
    return url;
  }
}