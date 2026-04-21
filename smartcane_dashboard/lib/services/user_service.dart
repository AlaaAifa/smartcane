import 'dart:convert';
import 'package:http/http.dart' as http;
import 'base_service.dart';

class UserService {
  static List<Map<String, dynamic>> _lastFetchedUsers = [];

  static Future<List<Map<String, dynamic>>> getUsers() async {
    try {
      final res = await http.get(Uri.parse("${BaseService.baseUrl}/users"), headers: BaseService.headers);
      if (res.statusCode == 200) {
        _lastFetchedUsers = List<Map<String, dynamic>>.from(jsonDecode(res.body));
        return _lastFetchedUsers;
      }
    } catch (e) {
      print("Users error: $e");
    }
    return _lastFetchedUsers;
  }

  static Future<Map<String, dynamic>> addUser(Map<String, dynamic> user) async {
    try {
      final res = await http.post(Uri.parse("${BaseService.baseUrl}/users"), headers: BaseService.headers, body: jsonEncode(user));
      if (res.statusCode == 201) return {"success": true};
      final body = jsonDecode(res.body);
      return {"success": false, "error": body['detail'] ?? "Erreur inconnue"};
    } catch (e) {
      print("Add user error: $e");
      return {"success": false, "error": e.toString()};
    }
  }

  static Future<Map<String, dynamic>> updateUser(String cin, Map<String, dynamic> user) async {
    try {
      final res = await http.put(Uri.parse("${BaseService.baseUrl}/users/$cin"), headers: BaseService.headers, body: jsonEncode(user));
      if (res.statusCode == 200) return {"success": true};
      final body = jsonDecode(res.body);
      return {"success": false, "error": body['detail'] ?? "Erreur inconnue"};
    } catch (e) {
      print("Update user error: $e");
      return {"success": false, "error": e.toString()};
    }
  }

  static Future<Map<String, dynamic>?> getUserByCin(String cin) async {
    try {
      final res = await http.get(Uri.parse("${BaseService.baseUrl}/users/$cin"), headers: BaseService.headers);
      if (res.statusCode == 200) {
        return jsonDecode(res.body);
      }
    } catch (e) {
      print("Get user error: $e");
    }
    return null;
  }

  static Future<bool> deleteUser(String cin) async {
    try {
      final res = await http.delete(Uri.parse("${BaseService.baseUrl}/users/$cin"), headers: BaseService.headers);
      return res.statusCode == 200;
    } catch (e) {
      print("Delete user error: $e");
    }
    return false;
  }
}
