import 'dart:convert';
import 'package:http/http.dart' as http;
import 'base_service.dart';

class AlertService {
  static Future<List<Map<String, dynamic>>> getActiveAlerts() async {
    try {
      final res = await http.get(Uri.parse("${BaseService.baseUrl}/alerts"), headers: BaseService.headers);
      if (res.statusCode == 200) {
        final alerts = List<Map<String, dynamic>>.from(jsonDecode(res.body));
        return alerts.where((alert) => (alert["status"] ?? "active") == "active").toList();
      }
    } catch (e) {
      print("Active alerts error: $e");
    }
    return [];
  }

  static Future<List<Map<String, dynamic>>> getAlertsHistory() async {
    try {
      final res = await http.get(Uri.parse("${BaseService.baseUrl}/alerts"), headers: BaseService.headers);
      if (res.statusCode == 200) {
        final alerts = List<Map<String, dynamic>>.from(jsonDecode(res.body));
        return alerts.where((alert) => alert["status"] == "resolved").toList();
      }
    } catch (e) {
      print("History error: $e");
    }
    return [];
  }

  static Future<bool> clearAlertHistory() async {
    try {
      final history = await getAlertsHistory();
      var success = true;
      for (final alert in history) {
        final alertId = alert["alert_id"]?.toString();
        if (alertId == null) {
          continue;
        }
        success = await deleteAlert(alertId) && success;
      }
      return success;
    } catch (e) {
      print("Clear history error: $e");
    }
    return false;
  }

  static Future<bool> deleteAlert(String alertId) async {
    try {
      final res = await http.delete(Uri.parse("${BaseService.baseUrl}/alerts/$alertId"), headers: BaseService.headers);
      return res.statusCode == 200;
    } catch (e) {
      print("Delete alert error: $e");
    }
    return false;
  }

  static Future<bool> resolveAlert(String alertId) async {
    try {
      final res = await http.put(
        Uri.parse("${BaseService.baseUrl}/alerts/$alertId"),
        headers: BaseService.headers,
        body: jsonEncode({
          "status": "resolved",
          "resolved_by": BaseService.staffId,
        }),
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
        Uri.parse("${BaseService.baseUrl}/alerts/$alertId"),
        headers: BaseService.headers,
        body: jsonEncode({
          "status": "active",
          "resolved_by": null,
          "resolved_at": null,
          "taken_by": null,
        }),
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
        Uri.parse("${BaseService.baseUrl}/alerts/$alertId"),
        headers: BaseService.headers,
        body: jsonEncode({
          "taken_by": BaseService.staffId,
        }),
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
        Uri.parse("${BaseService.baseUrl}/alerts/$alertId"),
        headers: BaseService.headers,
        body: jsonEncode({
          "taken_by": null,
        }),
      );
      return res.statusCode == 200;
    } catch (e) {
      print("Release error: $e");
    }
    return false;
  }

  static Future<bool> triggerAlert(Map<String, dynamic> data) async {
    try {
      final res = await http.post(Uri.parse("${BaseService.baseUrl}/alerts"), headers: BaseService.headers, body: jsonEncode(data));
      return res.statusCode == 201;
    } catch (e) {
      print("Trigger alert error: $e");
    }
    return false;
  }
}
