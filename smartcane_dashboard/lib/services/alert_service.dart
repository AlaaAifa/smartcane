import 'dart:convert';
 import 'package:http/http.dart' as http;
import 'package:firebase_database/firebase_database.dart';
import 'base_service.dart';
import 'user_service.dart';

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


  static Future<bool> resolveAlert(String alertId, {String? firebaseKey, String? startTime, Map<String, dynamic>? fullAlertData}) async {
    try {
      print("DEBUG: Resolving alert $alertId (Firebase Key: $firebaseKey)");
      
      final resolvedAt = DateTime.now();
      String responseTimeStr = "0s";
      
      if (startTime != null) {
        try {
          final start = DateTime.parse(startTime);
          final diff = resolvedAt.difference(start);
          final minutes = diff.inMinutes;
          final seconds = diff.inSeconds % 60;
          responseTimeStr = "${minutes}m ${seconds}s";
        } catch (te) {
          print("Error calculating response time: $te");
        }
      }

      // 1. Update Backend (MySQL)
      final resolvePayload = {
        "status": "resolved",
        "resolved_by": BaseService.staffName ?? BaseService.staffId ?? "Staff",
        "resolved_at": resolvedAt.toIso8601String(),
        "response_time": responseTimeStr,
      };

      var res = await http.put(
        Uri.parse("${BaseService.baseUrl}/alerts/$alertId"),
        headers: BaseService.headers,
        body: jsonEncode(resolvePayload),
      );
      
      bool backendSuccess = res.statusCode == 200;

      // Handle 404: If alert doesn't exist in MySQL, create it as resolved
      if (res.statusCode == 404 && fullAlertData != null) {
        print("DEBUG: Alert not in MySQL, creating it as resolved...");
        final createPayload = Map<String, dynamic>.from(fullAlertData);
        
        // --- Integrity Check for Foreign Key ---
        final users = await UserService.getUsers();
        final List<String> validCins = users.map((u) => u["cin"]?.toString() ?? "").toList();
        final String? alertUserId = createPayload["user_id"]?.toString();
        
        if (alertUserId == null || !validCins.contains(alertUserId)) {
          print("⚠️ Warning: User $alertUserId not found in DB. Setting user_id to null for MySQL.");
          createPayload["user_id"] = null;
        }

        createPayload["alert_id"] = alertId;
        createPayload["status"] = "resolved";
        createPayload["resolved_by"] = BaseService.staffName ?? BaseService.staffId ?? "Staff";
        createPayload["resolved_at"] = resolvedAt.toIso8601String();
        createPayload["response_time"] = responseTimeStr;
        
        // Remove unwanted fields for POST schema
        createPayload.remove("firebase_key");
        createPayload.remove("user_name");
        createPayload.remove("user_phone");
        createPayload.remove("user_address");
        createPayload.remove("health_notes");
        createPayload.remove("emergency_phone");
        createPayload.remove("age");
        createPayload.remove("email");
        createPayload.remove("timestamp");
        createPayload.remove("state");
        createPayload.remove("resolved");
        createPayload.remove("caneStatus");

        final createRes = await http.post(
          Uri.parse("${BaseService.baseUrl}/alerts"),
          headers: BaseService.headers,
          body: jsonEncode(createPayload),
        );
        backendSuccess = createRes.statusCode == 201;
        if (!backendSuccess) {
          print("DEBUG: MySQL POST failed: ${createRes.body}");
        }
      }

      if (!backendSuccess) {
        print("DEBUG: Backend resolve failed: ${res.body}");
      }

      // 2. Update Firebase (Realtime)
      final targetKey = firebaseKey ?? alertId;
      try {
        await _alertsRef.child(targetKey).update({
          "status": "RESOLVED",
          "resolved": true,
          "resolved_at": resolvedAt.toIso8601String(),
          "resolved_by": BaseService.staffName ?? "Staff",
          "response_time": responseTimeStr,
        });
        print("DEBUG: Firebase update success for $targetKey");
      } catch (fbe) {
        print("DEBUG: Firebase update failed: $fbe");
      }
      
      return backendSuccess;
    } catch (e) {
      print("Resolve error: $e");
    }
    return false;
  }

  static Future<bool> reactivateAlert(String alertId, {String? firebaseKey}) async {
    try {
      print("DEBUG: Reactivating alert $alertId (Firebase Key: $firebaseKey)");
      final reactivatedAt = DateTime.now();

      // 1. Update Backend (MySQL)
      final res = await http.put(
        Uri.parse("${BaseService.baseUrl}/alerts/$alertId"),
        headers: BaseService.headers,
        body: jsonEncode({
          "status": "active",
          "resolved_by": null,
          "resolved_at": null,
          "taken_by": null,
          "reactivated_by": BaseService.staffName ?? BaseService.staffId ?? "Staff",
          "reactivated_at": reactivatedAt.toIso8601String(),
        }),
      );
      
      bool backendSuccess = res.statusCode == 200;
      if (!backendSuccess) {
        print("DEBUG: Backend reactivate failed: ${res.body}");
      }

      // 2. Update Firebase (Realtime)
      final targetKey = firebaseKey ?? alertId;
      try {
        await _alertsRef.child(targetKey).update({
          "status": "active",
          "resolved": false,
          "resolved_at": null,
          "resolved_by": null,
          "reactivated_at": reactivatedAt.toIso8601String(),
          "reactivated_by": BaseService.staffName ?? "Staff",
        });
        print("DEBUG: Firebase reactivation success for $targetKey");
      } catch (fbe) {
        print("DEBUG: Firebase reactivation failed: $fbe");
      }

      return backendSuccess;
    } catch (e) {
      print("Reactivate error: $e");
    }
    return false;
  }

  static Future<bool> takeAlert(String alertId, {String? firebaseKey}) async {
    try {
      print("DEBUG: Taking alert $alertId (Firebase Key: $firebaseKey)");
      
      // 1. Update Firebase (Primary for Live Alerts)
      final targetKey = firebaseKey ?? alertId;
      bool firebaseSuccess = false;
      try {
        await _alertsRef.child(targetKey).update({
          "taken_by": BaseService.staffId,
          "taken_by_name": BaseService.staffName ?? "Staff",
        });
        firebaseSuccess = true;
      } catch (fbe) {
        print("DEBUG: Firebase takeAlert failed: $fbe");
      }

      // 2. Update Backend (Secondary, ignore 404 for live alerts)
      try {
        final res = await http.put(
          Uri.parse("${BaseService.baseUrl}/alerts/$alertId"),
          headers: BaseService.headers,
          body: jsonEncode({
            "taken_by": BaseService.staffId,
          }),
        );
        if (res.statusCode != 200) {
           print("DEBUG: Backend takeAlert info: ${res.statusCode} - ${res.body}");
        }
      } catch (e) {
        print("Backend takeAlert error: $e");
      }

      return firebaseSuccess;
    } catch (e) {
      print("Take error: $e");
    }
    return false;
  }

  static Future<bool> releaseAlert(String alertId, {String? firebaseKey}) async {
    try {
      print("DEBUG: Releasing alert $alertId (Firebase Key: $firebaseKey)");

      // 1. Update Firebase (Primary for Live Alerts)
      final targetKey = firebaseKey ?? alertId;
      bool firebaseSuccess = false;
      try {
        await _alertsRef.child(targetKey).update({
          "taken_by": null,
          "taken_by_name": null,
        });
        firebaseSuccess = true;
      } catch (fbe) {
        print("DEBUG: Firebase releaseAlert failed: $fbe");
      }

      // 2. Update Backend (Secondary, ignore 404)
      try {
        final res = await http.put(
          Uri.parse("${BaseService.baseUrl}/alerts/$alertId"),
          headers: BaseService.headers,
          body: jsonEncode({
            "taken_by": null,
          }),
        );
        if (res.statusCode != 200) {
           print("DEBUG: Backend releaseAlert info: ${res.statusCode} - ${res.body}");
        }
      } catch (e) {
        print("Backend releaseAlert error: $e");
      }

      return firebaseSuccess;
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

  // --- Firebase Realtime Database ---
  static DatabaseReference get _activeRef => FirebaseDatabase.instance.ref("smartcane/device1/active_alert");
  static DatabaseReference get _archiveRef => FirebaseDatabase.instance.ref("alerts");
  static DatabaseReference get _alertsRef => _archiveRef; // Alias pour compatibilité

  static Stream<List<Map<String, dynamic>>> getAlertsStream() {
    print("DEBUG: Listening to active alert at: ${_activeRef.path}");
    return _activeRef.onValue.map((event) {
      final Object? value = event.snapshot.value;
      
      if (value == null) {
        print("DEBUG: Aucune alerte active trouvée dans Firebase.");
        return [];
      }

      try {
        final raw = Map<dynamic, dynamic>.from(value as Map);
        
        // Conversion au format attendu par le Dashboard
        final alert = {
          'alert_id': raw['id']?.toString() ?? "active",
          'firebase_key': "active_alert",
          'user_id': raw['user']?['cin']?.toString() ?? "unknown",
          'user_name': raw['user']?['name']?.toString() ?? "Inconnu",
          'user_phone': raw['user']?['phone']?.toString() ?? "",
          'type': raw['type']?.toString() ?? "SOS",
          'count': raw['count'] ?? 1,
          'latitude': double.tryParse(raw['latitude']?.toString() ?? "36.8065") ?? 36.8065,
          'longitude': double.tryParse(raw['longitude']?.toString() ?? "10.1815") ?? 10.1815,
          'timestamp': DateTime.fromMillisecondsSinceEpoch(raw['lastUpdatedAt'] ?? DateTime.now().millisecondsSinceEpoch).toIso8601String(),
          'createdAt': DateTime.fromMillisecondsSinceEpoch(raw['createdAt'] ?? DateTime.now().millisecondsSinceEpoch).toIso8601String(),
          'status': 'active',
          'resolved': false,
          'cane_status': raw['caneStatus']?.toString() ?? "NORMAL",
        };

        return [alert];
      } catch (e) {
        print("❌ Erreur parsing alerte active: $e");
        return [];
      }
    });
  }

  static Future<bool> resolveActiveAlert() async {
    try {
      final snapshot = await _activeRef.get();
      if (!snapshot.exists) return false;

      final data = Map<String, dynamic>.from(snapshot.value as Map);
      final String alertId = data['id']?.toString() ?? "alert_${DateTime.now().millisecondsSinceEpoch}";

      // 1. Préparer les données pour l'archive (Utilisation du snake_case pour la cohérence)
      data['status'] = 'resolved';
      data['resolved'] = true;
      data['resolved_at'] = DateTime.now().toIso8601String();
      data['resolved_by'] = BaseService.staffName ?? "Staff";
      data['timestamp'] = data['resolved_at']; // Pour le tri dans l'historique

      // 2. Déplacer vers /alerts/{id}
      await _archiveRef.child(alertId).set(data);

      // 3. Supprimer l'alerte active
      await _activeRef.remove();

      print("✅ Alerte $alertId résolue et archivée.");
      return true;
    } catch (e) {
      print("❌ Erreur lors de la résolution: $e");
      return false;
    }
  }

  static Stream<List<Map<String, dynamic>>> getHistoryStream() {
    print("DEBUG: Listening to Firebase path (History): ${_archiveRef.path}");
    try {
      return _archiveRef.onValue.map((event) {
        final Object? value = event.snapshot.value;
        if (value == null) return [];

        final List<Map<String, dynamic>> alertsList = [];
        final Map<dynamic, dynamic> dataMap = {};

        if (value is Map) {
          dataMap.addAll(value);
        } else if (value is List) {
          for (int i = 0; i < value.length; i++) {
            if (value[i] != null) dataMap[i.toString()] = value[i];
          }
        }

        dataMap.forEach((key, val) {
          try {
            if (val is Map) {
              final rawAlert = Map<dynamic, dynamic>.from(val);

              // Only include resolved alerts for history stream
              final bool resolved = rawAlert['resolved'] == true ||
                  rawAlert['resolved']?.toString() == 'true';
              if (!resolved) return;

              final String type = rawAlert['type']?.toString() ?? "";
              final latVal = rawAlert['latitude'] ?? rawAlert['lat'];
              final lonVal = rawAlert['longitude'] ?? rawAlert['lng'] ?? rawAlert['lon'];
              
              final userMap = rawAlert['user'];
              String userName = "Inconnu";
              if (userMap is Map) {
                userName = userMap['name']?.toString() ?? "Inconnu";
              }

              // Use resolved_at or timestamp
              String timestamp = rawAlert['resolved_at']?.toString() ?? rawAlert['timestamp']?.toString() ?? DateTime.now().toIso8601String();

              final sanitizedAlert = <String, dynamic>{
                'alert_id': rawAlert['alert_id']?.toString() ?? key.toString(),
                'firebase_key': key.toString(),
                'user_id': rawAlert['user_id']?.toString() ?? key.toString(), 
                'user_name': userName,
                'type': type,
                'latitude': double.tryParse(latVal?.toString() ?? "0.0") ?? 0.0,
                'longitude': double.tryParse(lonVal?.toString() ?? "0.0") ?? 0.0,
                'timestamp': timestamp,
                'status': 'resolved',
                'resolved_by': rawAlert['resolved_by']?.toString() ?? "Staff",
                'response_time': rawAlert['response_time']?.toString() ?? "N/A",
              };

              alertsList.add(sanitizedAlert);
            }
          } catch (itemError) {
            print("DEBUG: Error processing history alert ($key): $itemError");
          }
        });

        alertsList.sort((a, b) {
          try {
            return DateTime.parse(b['timestamp'])
                .compareTo(DateTime.parse(a['timestamp']));
          } catch (_) {
            return 0;
          }
        });

        return alertsList;
      });
    } catch (e) {
      print("DEBUG: Firebase History Stream Error: $e");
      return Stream.value([]);
    }
  }
}
