import 'dart:convert';
import 'dart:async';
 import 'package:http/http.dart' as http;
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'base_service.dart';
import 'user_service.dart';

class AlertService {
  // Global reference for showing dialogs/snackbars from service if needed
  static GlobalKey<ScaffoldMessengerState>? scaffoldMessengerKey;

  static void _showError(String message) {
    print("❌ ALERT SERVICE ERROR: $message");
    if (scaffoldMessengerKey != null) {
      scaffoldMessengerKey!.currentState?.showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red.shade900),
      );
    }
  }

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
      final res = await http.delete(Uri.parse("${BaseService.baseUrl}/alerts/history/clear"), headers: BaseService.headers);
      bool backendSuccess = res.statusCode == 200;

      try {
        await _archiveRef.remove();
        print("✅ Firebase History cleared");
      } catch (fbe) {
        print("❌ Firebase Clear failed: $fbe");
      }
      
      return backendSuccess;
    } catch (e) {
      print("Clear history error: $e");
    }
    return false;
  }

  static Future<bool> deleteAlert(String alertId, {String? firebaseKey}) async {
    try {
      print("DEBUG: Deleting alert $alertId (Firebase Key: $firebaseKey)");
      
      // 1. Delete from MySQL
      final res = await http.delete(Uri.parse("${BaseService.baseUrl}/alerts/$alertId"), headers: BaseService.headers);
      bool mysqlSuccess = res.statusCode == 200 || res.statusCode == 404;

      if (!mysqlSuccess) {
        _showError("Backend Delete Fail: ${res.statusCode} - ${res.body}");
      }

      // 2. Delete from Firebase (Archive)
      final targetKey = firebaseKey ?? alertId;
      try {
        await _archiveRef.child(targetKey).remove();
        print("DEBUG: Firebase deletion success for $targetKey");
      } catch (fbe) {
        _showError("Firebase Delete Fail: $fbe");
        return false;
      }

      return mysqlSuccess;
    } catch (e) {
      _showError("Delete Critical Error: $e");
    }
    return false;
  }

  static Future<void> _ensureAlertExistsInMySQL(String alertId, Map<String, dynamic>? fullAlertData) async {
    if (fullAlertData == null) return;
    
    try {
      print("DEBUG: Checking MySQL for alert $alertId...");
      final checkRes = await http.get(Uri.parse("${BaseService.baseUrl}/alerts/$alertId"), headers: BaseService.headers);
      
      if (checkRes.statusCode == 404) {
        print("DEBUG: Syncing missing alert $alertId to MySQL...");
        final createPayload = <String, dynamic>{};
        
        createPayload["alert_id"] = alertId;
        createPayload["type"] = fullAlertData["type"]?.toString() ?? "SOS";
        createPayload["latitude"] = double.tryParse(fullAlertData["latitude"]?.toString() ?? "0.0") ?? 0.0;
        createPayload["longitude"] = double.tryParse(fullAlertData["longitude"]?.toString() ?? "0.0") ?? 0.0;
        createPayload["status"] = fullAlertData["status"]?.toString() ?? "active";
        createPayload["cane_status"] = fullAlertData["cane_status"]?.toString() ?? "normal";
        
        final String? userId = fullAlertData["user_id"]?.toString();
        if (userId != null && userId != "unknown" && userId != "UNKNOWN" && userId != "null") {
           createPayload["user_id"] = userId;
        } else {
           createPayload["user_id"] = null;
        }

        final postRes = await http.post(
          Uri.parse("${BaseService.baseUrl}/alerts"),
          headers: BaseService.headers,
          body: jsonEncode(createPayload),
        );
        print("DEBUG: MySQL POST result: ${postRes.statusCode} - ${postRes.body}");
      } else {
        print("DEBUG: Alert $alertId already in MySQL (Status: ${checkRes.statusCode})");
      }
    } catch (e) {
      print("❌ Sync error: $e");
    }
  }


  static Future<bool> resolveAlert(String alertId, {String? firebaseKey, String? startTime, Map<String, dynamic>? fullAlertData}) async {
    try {
      print("DEBUG: resolveAlert START ($alertId)");
      
      final now = DateTime.now();
      final String resolvedAtIso = now.toIso8601String();
      String responseTimeStr = "0s";
      
      if (startTime != null) {
        try {
          final start = DateTime.parse(startTime);
          final diff = now.difference(start);
          final minutes = diff.inMinutes;
          final seconds = diff.inSeconds % 60;
          responseTimeStr = "${minutes}m ${seconds}s";
        } catch (te) {
          print("Error calculating response time: $te");
        }
      }

      await _ensureAlertExistsInMySQL(alertId, fullAlertData);

      // 1. Update Backend (MySQL)
      final resolvePayload = {
        "status": "resolved",
        "resolved_by": BaseService.staffName ?? BaseService.staffId ?? "Staff",
        "resolved_at": resolvedAtIso,
        "response_time": responseTimeStr,
      };

      print("DEBUG: MySQL PUT /alerts/$alertId with payload: $resolvePayload");
      var res = await http.put(
        Uri.parse("${BaseService.baseUrl}/alerts/$alertId"),
        headers: BaseService.headers,
        body: jsonEncode(resolvePayload),
      );
      
      if (res.statusCode != 200) {
        _showError("Backend Fail: ${res.statusCode} - ${res.body}");
        return false;
      }
      print("DEBUG: MySQL Update Success (200)");

      // 2. Update Firebase (Realtime)
      final targetKey = firebaseKey ?? alertId;
      try {
        print("DEBUG: Updating Firebase at /alerts/$targetKey...");
        await _archiveRef.child(targetKey).update({
          "status": "RESOLVED",
          "resolved": true,
          "resolved_at": resolvedAtIso,
          "resolved_by": BaseService.staffName ?? "Staff",
          "response_time": responseTimeStr,
        });
        print("DEBUG: Firebase update success for $targetKey");
      } catch (fbe) {
        _showError("Firebase Fail: $fbe");
        return false;
      }
      
      return true;
    } catch (e) {
      _showError("Resolve Critical Error: $e");
    }
    return false;
  }

  static Future<bool> reactivateAlert(String alertId, {String? firebaseKey, Map<String, dynamic>? fullAlertData}) async {
    try {
      print("DEBUG: Reactivating alert $alertId");
      final reactivatedAtIso = DateTime.now().toIso8601String();

      await _ensureAlertExistsInMySQL(alertId, fullAlertData);

      final res = await http.put(
        Uri.parse("${BaseService.baseUrl}/alerts/$alertId"),
        headers: BaseService.headers,
        body: jsonEncode({
          "status": "active",
          "resolved_by": null,
          "resolved_at": null,
          "taken_by": null,
          "reactivated_by": BaseService.staffName ?? BaseService.staffId ?? "Staff",
          "reactivated_at": reactivatedAtIso,
        }),
      );
      
      if (res.statusCode != 200) {
        _showError("Backend Reactivate Fail: ${res.statusCode}");
        return false;
      }

      final targetKey = firebaseKey ?? alertId;
      try {
        await _archiveRef.child(targetKey).update({
          "status": "active",
          "resolved": false,
          "resolved_at": null,
          "resolved_by": null,
          "reactivated_at": reactivatedAtIso,
          "reactivated_by": BaseService.staffName ?? "Staff",
        });
      } catch (fbe) {
        _showError("Firebase Reactivate Fail: $fbe");
        return false;
      }

      return true;
    } catch (e) {
      _showError("Reactivate Critical Error: $e");
    }
    return false;
  }

  static Future<bool> takeAlert(String alertId, {String? firebaseKey, Map<String, dynamic>? fullAlertData}) async {
    try {
      print("DEBUG: takeAlert START ($alertId)");
      await _ensureAlertExistsInMySQL(alertId, fullAlertData);

      final targetKey = firebaseKey ?? alertId;
      try {
        final ref = (firebaseKey == "active_alert") ? _activeRef : _archiveRef.child(targetKey);
        await ref.update({
          "taken_by": BaseService.staffId,
          "taken_by_name": BaseService.staffName ?? "Staff",
        });
      } catch (fbe) {
        print("❌ Firebase takeAlert failed: $fbe");
      }

      try {
        final res = await http.put(
          Uri.parse("${BaseService.baseUrl}/alerts/$alertId"),
          headers: BaseService.headers,
          body: jsonEncode({"taken_by": BaseService.staffId}),
        );
        print("DEBUG: Backend takeAlert result: ${res.statusCode}");
      } catch (e) {
        print("Backend takeAlert error: $e");
      }

      return true;
    } catch (e) {
      print("Take error: $e");
    }
    return false;
  }

  static Future<bool> releaseAlert(String alertId, {String? firebaseKey}) async {
    try {
      final targetKey = firebaseKey ?? alertId;
      try {
        final ref = (firebaseKey == "active_alert") ? _activeRef : _archiveRef.child(targetKey);
        await ref.update({
          "taken_by": null,
          "taken_by_name": null,
        });
      } catch (fbe) {
        print("❌ Firebase releaseAlert failed: $fbe");
      }

      try {
        await http.put(
          Uri.parse("${BaseService.baseUrl}/alerts/$alertId"),
          headers: BaseService.headers,
          body: jsonEncode({"taken_by": null}),
        );
      } catch (e) {
        print("Backend releaseAlert error: $e");
      }

      return true;
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

  static DatabaseReference get _activeRef => FirebaseDatabase.instance.ref("smartcane/device1/active_alert");
  static DatabaseReference get _archiveRef => FirebaseDatabase.instance.ref("alerts");

  static Stream<List<Map<String, dynamic>>> getAlertsStream() {
    final controller = StreamController<List<Map<String, dynamic>>>();
    List<Map<String, dynamic>> lastActive = [];
    List<Map<String, dynamic>> lastReactivated = [];

    void update() {
      if (!controller.isClosed) {
        final combined = [...lastActive, ...lastReactivated];
        combined.sort((a, b) => (b['timestamp'] ?? "").compareTo(a['timestamp'] ?? ""));
        controller.add(combined);
      }
    }

    final activeSub = _activeRef.onValue.listen((event) {
      final Object? value = event.snapshot.value;
      if (value == null) {
        lastActive = [];
      } else {
        try {
          final raw = Map<dynamic, dynamic>.from(value as Map);
          lastActive = [{
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
            'taken_by': raw['taken_by'],
            'taken_by_name': raw['taken_by_name'],
          }];
        } catch (e) {
          print("❌ Erreur parsing alerte active: $e");
          lastActive = [];
        }
      }
      update();
    });

    final archiveSub = _archiveRef.onValue.listen((event) {
      final Object? value = event.snapshot.value;
      if (value == null) {
        lastReactivated = [];
      } else {
        final List<Map<String, dynamic>> reactivatedList = [];
        final Map<dynamic, dynamic> dataMap = {};

        if (value is Map) dataMap.addAll(value);
        else if (value is List) {
          for (int i = 0; i < value.length; i++) {
            if (value[i] != null) dataMap[i.toString()] = value[i];
          }
        }

        dataMap.forEach((key, val) {
          if (val is Map) {
            final raw = Map<dynamic, dynamic>.from(val);
            if (raw['status'] == 'active' || raw['resolved'] == false || raw['resolved']?.toString() == 'false') {
              final userMap = raw['user'];
              String userName = "Inconnu";
              if (userMap is Map) userName = userMap['name']?.toString() ?? "Inconnu";

              reactivatedList.add({
                'alert_id': raw['alert_id']?.toString() ?? key.toString(),
                'firebase_key': key.toString(),
                'user_id': raw['user_id']?.toString() ?? raw['user']?['cin']?.toString() ?? "unknown",
                'user_name': userName,
                'type': raw['type']?.toString() ?? "SOS",
                'latitude': double.tryParse((raw['latitude'] ?? raw['lat'])?.toString() ?? "0.0") ?? 0.0,
                'longitude': double.tryParse((raw['longitude'] ?? raw['lon'])?.toString() ?? "0.0") ?? 0.0,
                'timestamp': raw['reactivated_at']?.toString() ?? raw['timestamp']?.toString() ?? DateTime.now().toIso8601String(),
                'status': 'active',
                'resolved': false,
                'cane_status': raw['cane_status']?.toString() ?? "RE-ACTIVATED",
                'taken_by': raw['taken_by'],
                'taken_by_name': raw['taken_by_name'],
              });
            }
          }
        });
        lastReactivated = reactivatedList;
      }
      update();
    });

    controller.onCancel = () {
      activeSub.cancel();
      archiveSub.cancel();
    };

    return controller.stream;
  }

  static Future<bool> resolveActiveAlert({Map<String, dynamic>? fullAlertData}) async {
    try {
      print("DEBUG: resolveActiveAlert called");
      final snapshot = await _activeRef.get();
      if (!snapshot.exists) return false;

      final data = Map<String, dynamic>.from(snapshot.value as Map);
      final String alertId = data['id']?.toString() ?? "alert_${DateTime.now().millisecondsSinceEpoch}";
      final String resolvedAtIso = DateTime.now().toIso8601String();
      final String resolvedBy = BaseService.staffName ?? "Staff";

      await _ensureAlertExistsInMySQL(alertId, fullAlertData ?? data);

      print("DEBUG: Updating Backend MySQL for active alert $alertId");
      final res = await http.put(
        Uri.parse("${BaseService.baseUrl}/alerts/$alertId"),
        headers: BaseService.headers,
        body: jsonEncode({
          "status": "resolved",
          "resolved_by": resolvedBy,
          "resolved_at": resolvedAtIso,
        }),
      );

      if (res.statusCode != 200) {
        _showError("Backend Resolve Fail: ${res.statusCode} - ${res.body}");
        return false;
      }

      print("DEBUG: Moving alert to archive in Firebase...");
      data['status'] = 'resolved';
      data['resolved'] = true;
      data['resolved_at'] = resolvedAtIso;
      data['resolved_by'] = resolvedBy;
      data['timestamp'] = resolvedAtIso;

      await _archiveRef.child(alertId).set(data);
      await _activeRef.remove();

      print("✅ Alerte active résolue avec succès.");
      return true;
    } catch (e) {
      _showError("Active Resolve Critical Error: $e");
      return false;
    }
  }

  static Stream<List<Map<String, dynamic>>> getHistoryStream() {
    try {
      return _archiveRef.onValue.map((event) {
        final Object? value = event.snapshot.value;
        if (value == null) return [];

        final List<Map<String, dynamic>> alertsList = [];
        final Map<dynamic, dynamic> dataMap = {};

        if (value is Map) dataMap.addAll(value);
        else if (value is List) {
          for (int i = 0; i < value.length; i++) if (value[i] != null) dataMap[i.toString()] = value[i];
        }

        dataMap.forEach((key, val) {
          try {
            if (val is Map) {
              final rawAlert = Map<dynamic, dynamic>.from(val);
              final bool resolved = rawAlert['resolved'] == true || rawAlert['resolved']?.toString() == 'true';
              if (!resolved) return;

              final String userName = (rawAlert['user'] is Map) ? rawAlert['user']['name']?.toString() ?? "Inconnu" : "Inconnu";
              String timestamp = rawAlert['resolved_at']?.toString() ?? rawAlert['timestamp']?.toString() ?? DateTime.now().toIso8601String();

              alertsList.add({
                'alert_id': rawAlert['alert_id']?.toString() ?? key.toString(),
                'firebase_key': key.toString(),
                'user_id': rawAlert['user_id']?.toString() ?? rawAlert['user']?['cin']?.toString() ?? key.toString(), 
                'user_name': userName,
                'type': rawAlert['type']?.toString() ?? "SOS",
                'latitude': double.tryParse((rawAlert['latitude'] ?? rawAlert['lat'])?.toString() ?? "0.0") ?? 0.0,
                'longitude': double.tryParse((rawAlert['longitude'] ?? rawAlert['lng'] ?? rawAlert['lon'])?.toString() ?? "0.0") ?? 0.0,
                'timestamp': timestamp,
                'status': 'resolved',
                'resolved_by': rawAlert['resolved_by']?.toString() ?? "Staff",
                'response_time': rawAlert['response_time']?.toString() ?? "N/A",
              });
            }
          } catch (e) { print("History item error: $e"); }
        });

        alertsList.sort((a, b) => b['timestamp'].compareTo(a['timestamp']));
        return alertsList;
      });
    } catch (e) {
      return Stream.value([]);
    }
  }
}
