import 'dart:convert';
import 'package:http/http.dart' as http;
import 'base_service.dart';

class StaffService {
  static Future<List<Map<String, dynamic>>> getStaffMembers() async {
    try {
      final res = await http.get(Uri.parse("${BaseService.baseUrl}/users"), headers: BaseService.headers);
      if (res.statusCode == 200) {
        final users = List<Map<String, dynamic>>.from(jsonDecode(res.body));
        return users.where((user) => user["role"] == "staff").toList();
      }
    } catch (e) { 
      print("Staff list error: $e"); 
    }
    return [];
  }

  static Future<bool> addStaff(Map<String, dynamic> staff) async {
    try {
      final res = await http.post(Uri.parse("${BaseService.baseUrl}/users"), headers: BaseService.headers, body: jsonEncode({
        "cin": staff["staff_id"],
        "nom": staff["name"],
        "email": staff["email"],
        "age": int.tryParse(staff["age"]?.toString() ?? "0") ?? 0,
        "numero_de_telephone": staff["phone"],
        "adresse": staff["address"],
        "password_login": staff["password"],
        "role": "staff",
        "shift": staff["shift"] ?? "matin",
      }));
      return res.statusCode == 201;
    } catch (e) { 
      print("Add staff error: $e"); 
    }
    return false;
  }

  static Future<bool> updateStaff(Map<String, dynamic> staff) async {
    try {
      final res = await http.put(
        Uri.parse("${BaseService.baseUrl}/users/${staff['staff_id']}"),
        headers: BaseService.headers,
        body: jsonEncode({
          "nom": staff["name"],
          "email": staff["email"],
          "age": int.tryParse(staff["age"]?.toString() ?? "0") ?? 0,
          "numero_de_telephone": staff["phone"],
          "adresse": staff["address"],
          if (staff["password"] != null && staff["password"].toString().isNotEmpty) "password_login": staff["password"],
          "role": "staff",
          if (staff["shift"] != null) "shift": staff["shift"],
        }),
      );
      return res.statusCode == 200;
    } catch (e) { 
      print("Update staff error: $e"); 
    }
    return false;
  }
}
