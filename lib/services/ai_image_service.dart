import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

class AiImageService {
  // imgbb API KEY
  static const String _apiKey = '0faf5f066f8efad06d3d6ca7bc8773c4';

  /// Tek foto yükler -> image URL döner
  Future<String> uploadToImgbb(File file) async {
    final uri = Uri.parse('https://api.imgbb.com/1/upload?key=$_apiKey');

    final bytes = await file.readAsBytes();
    final base64Image = base64Encode(bytes);

    final res = await http.post(
      uri,
      body: {'image': base64Image},
    );

    if (res.statusCode != 200) {
      throw Exception('imgbb upload failed: ${res.statusCode} ${res.body}');
    }

    final json = jsonDecode(res.body);
    final url = json['data']?['url'] as String?;
    if (url == null || url.isEmpty) {
      throw Exception('imgbb response url missing: ${res.body}');
    }
    return url;
  }

  /// Çoklu foto yükler -> url listesi döner
  Future<List<String>> uploadMultiple(List<File> files) async {
    final urls = <String>[];
    for (final f in files) {
      final url = await uploadToImgbb(f);
      urls.add(url);
    }
    return urls;
  }
}