import 'dart:convert';
import 'package:http/http.dart' as http;
import 'base_service.dart';

class AuthService {
  static Future<Map<String, dynamic>?> login(String email, String password) async {
    try {
      final res = await http.post(
        Uri.parse("${BaseService.baseUrl}/auth/login"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"email": email, "password": password}),
      ).timeout(const Duration(seconds: 10));
      
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        BaseService.token = data["token"];
        BaseService.role = data["role"];
        BaseService.staffName = data["name"];
        BaseService.staffId = data["staff_id"];
        return data;
      } else if (res.statusCode == 401) {
        return {"error": "Email ou mot de passe incorrect"};
      } else {
        return {"error": "Erreur serveur (${res.statusCode})"};
      }
    } catch (e) {
      return {"error": "Impossible de contacter le serveur. Vérifiez que le backend est lancé."};
    }
  }

  static Future<bool> requestPasswordReset(String email) async {
    try {
      final res = await http.post(
        Uri.parse("${BaseService.baseUrl}/auth/request-reset"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"email": email}),
      );
      return res.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> verifyOtp(String email, String code) async {
    try {
      final res = await http.post(
        Uri.parse("${BaseService.baseUrl}/auth/verify-otp"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"email": email, "code": code}),
      );
      return res.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> resetPassword(String email, String code, String newPassword) async {
    try {
      final res = await http.post(
        Uri.parse("${BaseService.baseUrl}/auth/reset-password"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "email": email,
          "code": code,
          "new_password": newPassword,
        }),
      );
      return res.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}
