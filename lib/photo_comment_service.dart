import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class PhotoCommentService {
  // 🔧 BURAYA KOY
  static const String imgbbApiKey = 'IMGBB_API_KEYİNİ_BURAYA_YAZ';
  static const String functionUrl =
      'https://us-central1-birnefes-8398.cloudfunctions.net/tarzimAIComment';

  static Future<String> uploadAndGetComment(File imageFile) async {
    // 1️⃣ imgbb upload
    final uploadRequest = http.MultipartRequest(
      'POST',
      Uri.parse('https://api.imgbb.com/1/upload?key=$imgbbApiKey'),
    );

    uploadRequest.files.add(
      await http.MultipartFile.fromPath('image', imageFile.path),
    );

    final uploadResponse = await uploadRequest.send();
    final uploadBody =
    jsonDecode(await uploadResponse.stream.bytesToString());

    if (uploadResponse.statusCode != 200) {
      throw Exception('imgbb upload failed');
    }

    final imageUrl = uploadBody['data']['url'];

    // 2️⃣ Firebase Function çağır
    final response = await http.post(
      Uri.parse(functionUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'imageUrl': imageUrl,
        'note': 'Fotoğrafa göre yorum yap',
      }),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode != 200 || data['ok'] != true) {
      throw Exception(data['error'] ?? 'Yorum alınamadı');
    }

    return data['comment'];
  }
}