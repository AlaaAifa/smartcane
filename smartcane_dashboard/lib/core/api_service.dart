import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = "http://127.0.0.1:8000";
  static String? token;
  static String? role;
  static String? staffName;
  static String? staffId;

  static Map<String, String> get _headers => {
    "Content-Type": "application/json",
    if (token != null) "Authorization": "Bearer $token",
  };

  // --- Auth ---
  static Future<Map<String, dynamic>?> login(String email, String password) async {
    try {
      final res = await http.post(
        Uri.parse("$baseUrl/auth/login"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"email": email, "password": password}),
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        token = data["token"];
        role = data["role"];
        staffName = data["name"];
        staffId = data["staff_id"];
        return data;
      }
    } catch (e) {
      print("Login error: $e");
    }
    return null;
  }

  static void logout() {
    token = null;
    role = null;
    staffName = null;
    staffId = null;
  }

  static bool get isAdmin => role == "admin";

  // --- Dashboard ---
  static Future<Map<String, dynamic>> getStats() async {
    try {
      final res = await http.get(Uri.parse("$baseUrl/dashboard/stats"), headers: _headers);
      if (res.statusCode == 200) return jsonDecode(res.body);
    } catch (e) {
      print("Stats error: $e");
    }
    return {"total_users": 0, "active_alerts": 0, "sos_count": 0, "help_count": 0, "resolved_count": 0};
  }

  // --- Users ---
  static Future<List<Map<String, dynamic>>> getUsers() async {
    try {
      final res = await http.get(Uri.parse("$baseUrl/users"), headers: _headers);
      if (res.statusCode == 200) return List<Map<String, dynamic>>.from(jsonDecode(res.body));
    } catch (e) {
      print("Users error: $e");
    }
    return [];
  }

  static Future<bool> addUser(Map<String, dynamic> user) async {
    try {
      final res = await http.post(Uri.parse("$baseUrl/users"), headers: _headers, body: jsonEncode(user));
      return res.statusCode == 200;
    } catch (e) {
      print("Add user error: $e");
    }
    return false;
  }

  static Future<bool> updateUser(Map<String, dynamic> user) async {
    try {
      final res = await http.post(Uri.parse("$baseUrl/users"), headers: _headers, body: jsonEncode(user));
      return res.statusCode == 200;
    } catch (e) {
      print("Update user error: $e");
    }
    return false;
  }

  // --- Alerts ---
  static Future<List<Map<String, dynamic>>> getActiveAlerts() async {
    try {
      final res = await http.get(Uri.parse("$baseUrl/alerts/active"), headers: _headers);
      if (res.statusCode == 200) return List<Map<String, dynamic>>.from(jsonDecode(res.body));
    } catch (e) {
      print("Active alerts error: $e");
    }
    return [];
  }

  static Future<List<Map<String, dynamic>>> getAlertsHistory() async {
    try {
      final res = await http.get(Uri.parse("$baseUrl/alerts/history"), headers: _headers);
      if (res.statusCode == 200) return List<Map<String, dynamic>>.from(jsonDecode(res.body));
    } catch (e) {
      print("History error: $e");
    }
    return [];
  }

  static Future<bool> clearAlertHistory() async {
    try {
      final res = await http.delete(Uri.parse("$baseUrl/alerts/history"), headers: _headers);
      return res.statusCode == 200;
    } catch (e) {
      print("Clear history error: $e");
    }
    return false;
  }

  static Future<bool> resolveAlert(String alertId) async {
    try {
      final res = await http.put(
        Uri.parse("$baseUrl/alerts/$alertId/resolve?staff_id=${staffId ?? 'staff_001'}"),
        headers: _headers,
      );
      return res.statusCode == 200;
    } catch (e) {
      print("Resolve error: $e");
    }
    return false;
  }

  // --- Staff ---
  static Future<List<Map<String, dynamic>>> getStaff() async {
    try {
      final res = await http.get(Uri.parse("$baseUrl/staff"), headers: _headers);
      if (res.statusCode == 200) return List<Map<String, dynamic>>.from(jsonDecode(res.body));
    } catch (e) {
      print("Staff error: $e");
    }
    return [];
  }

  static Future<bool> addStaff(Map<String, dynamic> staff) async {
    try {
      final res = await http.post(Uri.parse("$baseUrl/staff"), headers: _headers, body: jsonEncode(staff));
      return res.statusCode == 200;
    } catch (e) {
      print("Add staff error: $e");
    }
    return false;
  }

  // --- Performance ---
  static Future<Map<String, dynamic>> getPerformance() async {
    try {
      final res = await http.get(Uri.parse("$baseUrl/performance"), headers: _headers);
      if (res.statusCode == 200) return jsonDecode(res.body);
    } catch (e) {
      print("Performance error: $e");
    }
    return {};
  }
}
