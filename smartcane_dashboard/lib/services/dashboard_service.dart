import 'dart:convert';
import 'package:http/http.dart' as http;
import 'base_service.dart';

class DashboardService {
  static Future<Map<String, dynamic>> getStats() async {
    try {
      final usersRes = await http.get(Uri.parse("${BaseService.baseUrl}/users"), headers: BaseService.headers);
      final alertsRes = await http.get(Uri.parse("${BaseService.baseUrl}/alerts"), headers: BaseService.headers);

      final users = usersRes.statusCode == 200
          ? List<Map<String, dynamic>>.from(jsonDecode(usersRes.body))
          : <Map<String, dynamic>>[];
      final alerts = alertsRes.statusCode == 200
          ? List<Map<String, dynamic>>.from(jsonDecode(alertsRes.body))
          : <Map<String, dynamic>>[];

      final activeAlerts = alerts.where((a) => (a["status"] ?? "active") == "active").toList();
      final resolvedAlerts = alerts.where((a) => a["status"] == "resolved").toList();

      return {
        "total_users": users.length,
        "active_alerts": activeAlerts.length,
        "sos_count": activeAlerts.where((a) => a["type"] == "SOS").length,
        "help_count": activeAlerts.where((a) => a["type"] == "HELP").length,
        "resolved_count": resolvedAlerts.length,
      };
    } catch (e) {
      print("Stats error: $e");
    }
    return {"total_users": 0, "active_alerts": 0, "sos_count": 0, "help_count": 0, "resolved_count": 0};
  }

  static Future<Map<String, dynamic>> getPerformance() async {
    try {
      final usersRes = await http.get(Uri.parse("${BaseService.baseUrl}/users"), headers: BaseService.headers);
      final alertsRes = await http.get(Uri.parse("${BaseService.baseUrl}/alerts"), headers: BaseService.headers);
      if (usersRes.statusCode != 200 || alertsRes.statusCode != 200) {
        return {};
      }

      final users = List<Map<String, dynamic>>.from(jsonDecode(usersRes.body));
      final alerts = List<Map<String, dynamic>>.from(jsonDecode(alertsRes.body));
      final staffUsers = users.where((u) => u["role"] == "staff").toList();

      final Map<String, dynamic> performance = {};
      for (final staff in staffUsers) {
        final cin = staff["cin"]?.toString() ?? "";
        final resolved = alerts.where((a) => a["resolved_by"]?.toString() == cin).length;
        final taken = alerts.where((a) => a["taken_by"]?.toString() == cin).length;

        performance[cin] = {
          "staff_name": staff["nom"] ?? cin,
          "role": staff["role"] ?? "staff",
          "shift": "matin",
          "alerts_processed": taken,
          "alerts_resolved": resolved,
          "alerts_pending": taken - resolved < 0 ? 0 : taken - resolved,
        };
      }

      return performance;
    } catch (e) {
      print("Performance error: $e");
    }
    return {};
  }
}
