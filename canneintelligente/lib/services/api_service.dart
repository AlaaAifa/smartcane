import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/user_model.dart';

class ApiService {
  // Use 10.0.2.2 to access localhost from Android emulator
  // Use 127.0.0.1 for iOS simulator or Windows desktop
  static const String baseUrl = "http://127.0.0.1:8000";

  static Future<UserModel?> getUser(String userId) async {
    try {
      final response = await http.get(Uri.parse("$baseUrl/users/$userId"));
      if (response.statusCode == 200) {
        return UserModel.fromJson(jsonDecode(response.body));
      }
    } catch (e) {
      print("Error fetching user: $e");
    }
    return null;
  }

  static Future<bool> sendAlert(String userId, String type, double lat, double lon) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/alerts"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "user_id": userId,
          "type": type,
          "latitude": lat,
          "longitude": lon,
          "timestamp": DateTime.now().toIso8601String(),
        }),
      );
      return response.statusCode == 200;
    } catch (e) {
      print("Error sending alert: $e");
      return false;
    }
  }

  static Future<bool> registerUser(UserModel user) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/users"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(user.toJson()),
      );
      return response.statusCode == 200;
    } catch (e) {
      print("Error registering user: $e");
      return false;
    }
  }
}
