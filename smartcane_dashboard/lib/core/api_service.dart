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

  // --- Session Storage (Mocks until backend is ready) ---
  static final List<Map<String, dynamic>> _mockUsers = [
    {"user_id": "user_123", "prenom": "Jean", "nom": "Dupont", "email": "jean@email.com", "phone_number_malvoyant": "+216 22 123 456", "phone_number_famille": "+216 55 123 456", "is_online": true, "sos_active": false, "help_active": false, "alerts_count": 2, "resolved_count": 15, "status": "normal", "birth_date": "15/05/1962", "age": "62"},
    {
      "user_id": "user_456", "prenom": "Marie", "nom": "Curie", "email": "marie@email.com", 
      "phone_number_malvoyant": "+216 98 765 432", 
      "phone_number_famille": "+216 21 888 999",
      "emergency_contacts": [
        {"name": "Pierre Curie", "relation": "Époux", "phone": "+216 50 111 222"}
      ],
      "is_online": true, "sos_active": true, "help_active": false, "alerts_count": 5, "resolved_count": 42, "status": "SOS", "birth_date": "07/11/1867", "age": "57"
    },
    {"user_id": "user_789", "prenom": "Thomas", "nom": "Edison", "email": "thomas@email.com", "phone": "+216 23 000 000", "emergency_phone": "+216 54 111 222", "is_online": false, "sos_active": false, "help_active": true, "alerts_count": 1, "resolved_count": 8, "status": "HELP", "birth_date": "11/02/1847", "age": "84"},
    {"user_id": "user_001", "prenom": "Fatma", "nom": "Zahra", "email": "fatma@email.com", "phone_number_malvoyant": "+216 28 111 111", "is_online": true, "sos_active": false, "help_active": false, "alerts_count": 0, "resolved_count": 5, "status": "normal", "birth_date": "20/06/1955", "age": "68"},
    {"user_id": "user_002", "prenom": "Mohamed", "nom": "Ali", "email": "mohamed@email.com", "phone_number_malvoyant": "+216 99 222 222", "is_online": true, "sos_active": false, "help_active": false, "alerts_count": 3, "resolved_count": 12, "status": "normal", "birth_date": "17/01/1942", "age": "81"},
    {"user_id": "user_003", "prenom": "Ahmed", "nom": "Mansour", "email": "ahmed@email.com", "phone_number_malvoyant": "+216 55 333 333", "is_online": false, "sos_active": false, "help_active": false, "alerts_count": 0, "resolved_count": 2, "status": "normal", "birth_date": "12/03/1970", "age": "54"},
  ];

  static final List<Map<String, dynamic>> _mockRentals = [
    {"cane_id": "CANE_099", "model": "Smart Lite", "user_id": "user_123", "user_name": "Jean Dupont", "start_date": "2024-03-01", "end_date": "2024-06-01", "status": "rented_active"},
    {"cane_id": "CANE_088", "model": "Smart Pro V2", "user_id": "user_456", "user_name": "Marie Curie", "start_date": "2024-04-01", "end_date": "2024-07-01", "status": "rented_active"},
  ];

  // --- Auth ---
  static Future<Map<String, dynamic>?> login(String email, String password) async {
    try {
      print("POST $baseUrl/auth/login with email: $email");
      final res = await http.post(
        Uri.parse("$baseUrl/auth/login"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"email": email, "password": password}),
      ).timeout(const Duration(seconds: 10));
      
      print("Response: ${res.statusCode} - ${res.body}");
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        token = data["token"];
        role = data["role"];
        staffName = data["name"];
        staffId = data["staff_id"];
        return data;
      } else if (res.statusCode == 401) {
        print("Erreur 401: Identifiants incorrects");
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

  static Future<List<Map<String, dynamic>>> getUsers() async {
    if (baseUrl.contains("127.0.0.1")) return _mockUsers;
    try {
      final res = await http.get(Uri.parse("$baseUrl/users"), headers: _headers);
      if (res.statusCode == 200) return List<Map<String, dynamic>>.from(jsonDecode(res.body));
    } catch (e) {
      print("Users error: $e");
    }
    return _mockUsers;
  }

  static Future<bool> addUser(Map<String, dynamic> user) async {
    if (baseUrl.contains("127.0.0.1")) {
      // Create a full user object compatible with the dashboard
      final String newId = "user_${DateTime.now().millisecondsSinceEpoch}";
      _mockUsers.add({
        "user_id": newId,
        "prenom": user["prenom"] ?? "Inconnu",
        "nom": user["nom"] ?? "",
        "email": user["email"] ?? "",
        "phone_number_malvoyant": user["phone_number_malvoyant"] ?? "",
        "phone_number_famille": user["phone_number_famille"] ?? "",
        "is_online": true,
        "sos_active": false,
        "help_active": false,
        "alerts_count": 0,
        "resolved_count": 0,
        "status": "normal",
        "birth_date": user["birth_date"] ?? "N/A",
        "age": user["age"] ?? "0",
        "cane_details": user["cane_details"] ?? {"serial_number": "N/A", "firmware_version": "1.0.0"},
      });
      return true;
    }
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

  static Future<bool> deleteAlert(String alertId) async {
    try {
      final res = await http.delete(Uri.parse("$baseUrl/alerts/$alertId"), headers: _headers);
      return res.statusCode == 200;
    } catch (e) {
      print("Delete alert error: $e");
    }
    return false;
  }

  static Future<bool> resolveAlert(String alertId) async {
    try {
      final res = await http.put(
        Uri.parse("$baseUrl/alerts/$alertId/resolve?staff_id=${staffId ?? 'staff_001'}&staff_name=${staffName ?? 'Staff'}"),
        headers: _headers,
      );
      return res.statusCode == 200;
    } catch (e) {
      print("Resolve error: $e");
    }
    return false;
  }

  static Future<bool> reactivateAlert(String alertId) async {
    try {
      final res = await http.put(
        Uri.parse("$baseUrl/alerts/$alertId/reactivate?staff_id=${staffId ?? 'staff_001'}&staff_name=${staffName ?? 'Staff'}"),
        headers: _headers,
      );
      return res.statusCode == 200;
    } catch (e) {
      print("Reactivate error: $e");
    }
    return false;
  }

  static Future<bool> takeAlert(String alertId) async {
    try {
      final res = await http.put(
        Uri.parse("$baseUrl/alerts/$alertId/take?staff_id=${staffId ?? 'staff_001'}&staff_name=${staffName ?? 'Staff'}"),
        headers: _headers,
      );
      return res.statusCode == 200;
    } catch (e) {
      print("Take error: $e");
    }
    return false;
  }

  static Future<bool> releaseAlert(String alertId) async {
    try {
      final res = await http.put(
        Uri.parse("$baseUrl/alerts/$alertId/release"),
        headers: _headers,
      );
      return res.statusCode == 200;
    } catch (e) {
      print("Release error: $e");
    }
    return false;
  }

  // --- Staff ---
  static Future<List<Map<String, dynamic>>> getStaffMembers() async {
    try {
      final res = await http.get(Uri.parse("$baseUrl/staff"), headers: _headers);
      if (res.statusCode == 200) return List<Map<String, dynamic>>.from(jsonDecode(res.body));
    } catch (e) { print("Staff list error: $e"); }
    return [];
  }

  static Future<bool> addStaff(Map<String, dynamic> staff) async {
    try {
      final res = await http.post(Uri.parse("$baseUrl/staff"), headers: _headers, body: jsonEncode({
        "staff_id": staff["staff_id"],
        "name": staff["name"],
        "email": staff["email"],
        "password": staff["password"],
        "role": staff["role"],
        "shift": staff["shift"],
        "phone": staff["phone"],
        "address": staff["address"],
      }));
      return res.statusCode == 200;
    } catch (e) { print("Add staff error: $e"); }
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

  static Future<bool> updateStaff(Map<String, dynamic> staff) async {
    try {
      final res = await http.put(
        Uri.parse("$baseUrl/staff/${staff['staff_id']}"),
        headers: _headers,
        body: jsonEncode(staff),
      );
      return res.statusCode == 200;
    } catch (e) { print("Update staff error: $e"); }
    return false;
  }

  // --- Rentals ---
  static Future<List<Map<String, dynamic>>> getAvailableCanes() async {
    // Mocking available canes
    return [
      {"cane_id": "CANE_001", "model": "Smart Pro V2", "features": "GPS, Obstacle Detection"},
      {"cane_id": "CANE_002", "model": "Smart Lite", "features": "Obstacle Detection"},
      {"cane_id": "CANE_003", "model": "Smart Pro V2", "features": "GPS, Obstacle Detection, Voice Assistant"},
      {"cane_id": "CANE_004", "model": "Smart Lite", "features": "Obstacle Detection"},
      {"cane_id": "CANE_005", "model": "Smart Pro V3", "features": "5G, LiDAR, AI Navigation"},
      {"cane_id": "CANE_006", "model": "Smart Pro V3", "features": "5G, LiDAR, AI Navigation"},
    ];
  }

  static Future<List<Map<String, dynamic>>> getActiveRentals() async {
    return _mockRentals;
  }

  static Future<bool> rentCane(Map<String, dynamic> data) async {
    try {
      // 1. Generate unique IDs
      final String userId = "user_${DateTime.now().millisecondsSinceEpoch}";
      final String caneId = "CANE_${(100 + _mockRentals.length).toString()}";

      // 2. Add to Users list
      _mockUsers.add({
        "user_id": userId,
        "prenom": data["full_name"],
        "nom": "",
        "phone": data["phone"],
        "is_online": true, 
        "sos_active": false,
        "help_active": false,
        "alerts_count": 0,
        "resolved_count": 0,
        "age": data["age"],
        "address": data["address"],
        "status": "normal",
      });

      // 3. Add to Rentals list
      _mockRentals.add({
        "cane_id": caneId,
        "model": data["model"],
        "user_id": userId,
        "user_name": data["full_name"],
        "start_date": data["start_date"],
        "end_date": data["end_date"],
        "status": "rented_active"
      });

      print("Successfully registered rental for ${data['full_name']} (Cane: $caneId)");
      return true;
    } catch (e) {
      print("Rent cane error: $e");
    }
    return false;
  }

  // --- Password Reset ---
  static Future<bool> requestPasswordReset(String email) async {
    try {
      print("POST $baseUrl/auth/request-reset with email: $email");
      final res = await http.post(
        Uri.parse("$baseUrl/auth/request-reset"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"email": email}),
      ).timeout(const Duration(seconds: 10));
      
      print("Response: ${res.statusCode} - ${res.body}");
      return res.statusCode == 200;
    } catch (e) {
      print("Request password reset error: $e");
    }
    return false;
  }

  static Future<bool> verifyOtp(String email, String code) async {
    try {
      print("POST $baseUrl/auth/verify-otp with email: $email, code: $code");
      final res = await http.post(
        Uri.parse("$baseUrl/auth/verify-otp"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"email": email, "code": code}),
      ).timeout(const Duration(seconds: 10));
      
      print("Response: ${res.statusCode} - ${res.body}");
      return res.statusCode == 200;
    } catch (e) {
      print("Verify OTP error: $e");
    }
    return false;
  }

  static Future<bool> resetPassword(String email, String newPassword) async {
    try {
      print("POST $baseUrl/auth/reset-password for email: $email");
      final res = await http.post(
        Uri.parse("$baseUrl/auth/reset-password"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "email": email,
          "new_password": newPassword,
        }),
      ).timeout(const Duration(seconds: 10));
      
      print("Response: ${res.statusCode} - ${res.body}");
      return res.statusCode == 200;
    } catch (e) {
      print("Reset password error: $e");
    }
    return false;
  }
}
