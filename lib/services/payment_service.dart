import 'dart:convert';
import 'package:http/http.dart' as http;

class PaymentService {
  static const String baseUrl = "http://192.168.1.4:3000";

  static Future<String> createPayment() async {
    final res = await http.post(
      Uri.parse("$baseUrl/create-payment"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({}),
    );

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      return data["paymentUrl"];
    } else {
      throw Exception("Ödeme linki alınamadı");
    }
  }
}