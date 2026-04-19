import 'dart:convert';
import 'package:http/http.dart' as http;
import 'base_service.dart';

class CaneService {
  static Future<List<Map<String, dynamic>>> getAvailableCanes() async {
    try {
      final res = await http.get(Uri.parse("${BaseService.baseUrl}/cannes"), headers: BaseService.headers);
      if (res.statusCode == 200) return List<Map<String, dynamic>>.from(jsonDecode(res.body));
    } catch (e) {
      print("Get canes error: $e");
    }
    return [];
  }

  static Future<bool> registerCane(Map<String, dynamic> data) async {
    try {
      final res = await http.post(Uri.parse("${BaseService.baseUrl}/cannes"), headers: BaseService.headers, body: jsonEncode(data));
      return res.statusCode == 201;
    } catch (e) {
      print("Register cane error: $e");
    }
    return false;
  }

  static Future<Map<String, dynamic>?> getCane(String simNumber) async {
    try {
      final res = await http.get(Uri.parse("${BaseService.baseUrl}/cannes/$simNumber"), headers: BaseService.headers);
      if (res.statusCode == 200) {
        return jsonDecode(res.body);
      }
    } catch (e) {
      print("Get cane error: $e");
    }
    return null;
  }

  static Future<bool> deleteCane(String simNumber) async {
    try {
      final res = await http.delete(Uri.parse("${BaseService.baseUrl}/cannes/$simNumber"), headers: BaseService.headers);
      return res.statusCode == 200;
    } catch (e) {
      print("Delete cane error: $e");
    }
    return false;
  }

  static Future<bool> updateCane(String simNumber, Map<String, dynamic> data) async {
    try {
      final res = await http.put(
        Uri.parse("${BaseService.baseUrl}/cannes/$simNumber"),
        headers: BaseService.headers,
        body: jsonEncode(data),
      );
      return res.statusCode == 200;
    } catch (e) {
      print("Update cane error: $e");
    }
    return false;
  }
}
