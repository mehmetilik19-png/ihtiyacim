import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class ImageHostService {
  ImageHostService({required this.apiKey});
  final String apiKey;

  Future<String> uploadImage(File file) async {
    final bytes = await file.readAsBytes();
    final base64Image = base64Encode(bytes);

    final uri = Uri.parse('https://api.imgbb.com/1/upload?key=$apiKey');
    final res = await http.post(uri, body: {
      'image': base64Image,
    });

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('imgbb upload failed: ${res.statusCode}');
    }

    final json = jsonDecode(res.body) as Map<String, dynamic>;
    return json['data']['url'];
  }
}