import 'dart:convert';
import 'package:http/http.dart' as http;
import 'base_service.dart';

class SubscriptionService {
  static Future<bool> createSubscription(Map<String, dynamic> data) async {
    try {
      final res = await http.post(Uri.parse("${BaseService.baseUrl}/abonnements"), headers: BaseService.headers, body: jsonEncode(data));
      return res.statusCode == 201;
    } catch (e) {
      print("Create subscription error: $e");
    }
    return false;
  }

  static Future<List<Map<String, dynamic>>> getSubscriptions() async {
    try {
      final res = await http.get(Uri.parse("${BaseService.baseUrl}/abonnements"), headers: BaseService.headers);
      if (res.statusCode == 200) return List<Map<String, dynamic>>.from(jsonDecode(res.body));
    } catch (e) {
      print("Get subscriptions error: $e");
    }
    return [];
  }

  static Future<Map<String, dynamic>?> getSubscription(String id) async {
    try {
      final res = await http.get(Uri.parse("${BaseService.baseUrl}/abonnements/$id"), headers: BaseService.headers);
      if (res.statusCode == 200) {
        return jsonDecode(res.body);
      }
    } catch (e) {
      print("Get subscription error: $e");
    }
    return null;
  }

  static Future<bool> updateSubscription(String id, Map<String, dynamic> data) async {
    try {
      final res = await http.put(Uri.parse("${BaseService.baseUrl}/abonnements/$id"), headers: BaseService.headers, body: jsonEncode(data));
      return res.statusCode == 200;
    } catch (e) {
      print("Update subscription error: $e");
    }
    return false;
  }

  static Future<bool> deleteSubscription(String id) async {
    try {
      final res = await http.delete(Uri.parse("${BaseService.baseUrl}/abonnements/$id"), headers: BaseService.headers);
      return res.statusCode == 200;
    } catch (e) {
      print("Delete subscription error: $e");
    }
    return false;
  }
}
