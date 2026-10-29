import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../core/constants.dart';

/// Sends the photo to YOUR server. The AI key never lives in the app.
class FoodAi {
  static Future<List> analyze(File image) async {
    final res = await http.post(Uri.parse('${AppConfig.apiBase}/analyze'),
      headers: {'content-type': 'application/json', 'x-app-token': AppConfig.appToken},
      body: jsonEncode({'image': base64Encode(await image.readAsBytes())})).timeout(const Duration(seconds: 60));
    if (res.statusCode != 200) throw Exception('Server error ${res.statusCode}');
    return jsonDecode(res.body)['items'] as List;
  }
}
