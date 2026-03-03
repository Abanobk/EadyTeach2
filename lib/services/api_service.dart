import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  // ضع رابط الموقع المنشور هنا بعد النشر
  static const String baseUrl = 'https://easytechapp-n8wz4sb5.manus.space';
  static const String trpcUrl = '$baseUrl/api/trpc';

  static Future<String?> _getCookie() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('session_cookie');
  }

  static Future<void> _saveCookie(String cookie) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('session_cookie', cookie);
  }

  static Future<void> clearCookie() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('session_cookie');
  }

  static Map<String, String> _headers({String? cookie}) {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (cookie != null) {
      headers['Cookie'] = cookie;
    }
    return headers;
  }

  /// tRPC Query (GET)
  static Future<Map<String, dynamic>> query(
    String procedure, {
    Map<String, dynamic>? input,
  }) async {
    final cookie = await _getCookie();
    String url = '$trpcUrl/$procedure';
    if (input != null) {
      final encoded = Uri.encodeComponent(jsonEncode({'0': input}));
      url += '?batch=1&input=$encoded';
    } else {
      url += '?batch=1';
    }

    final response = await http.get(
      Uri.parse(url),
      headers: _headers(cookie: cookie),
    );

    // Save cookie if returned
    final setCookie = response.headers['set-cookie'];
    if (setCookie != null) {
      await _saveCookie(setCookie);
    }

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      if (data.isNotEmpty && data[0]['result'] != null) {
        return {'data': data[0]['result']['data'], 'success': true};
      }
      if (data.isNotEmpty && data[0]['error'] != null) {
        throw Exception(data[0]['error']['message'] ?? 'Unknown error');
      }
    }
    throw Exception('Request failed: ${response.statusCode}');
  }

  /// tRPC Mutation (POST)
  static Future<Map<String, dynamic>> mutate(
    String procedure, {
    Map<String, dynamic>? input,
  }) async {
    final cookie = await _getCookie();
    final url = '$trpcUrl/$procedure?batch=1';

    final body = jsonEncode({'0': input ?? {}});

    final response = await http.post(
      Uri.parse(url),
      headers: _headers(cookie: cookie),
      body: body,
    );

    // Save cookie if returned
    final setCookie = response.headers['set-cookie'];
    if (setCookie != null) {
      await _saveCookie(setCookie);
    }

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      if (data.isNotEmpty && data[0]['result'] != null) {
        return {'data': data[0]['result']['data'], 'success': true};
      }
      if (data.isNotEmpty && data[0]['error'] != null) {
        final msg = data[0]['error']['message'] ?? 'Unknown error';
        throw Exception(msg);
      }
    }
    throw Exception('Request failed: ${response.statusCode}');
  }
}
