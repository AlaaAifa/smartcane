import 'dart:convert';
import 'package:http/http.dart' as http;
import 'base_service.dart';
import 'user_service.dart';

class RentalService {
  static Future<List<Map<String, dynamic>>> getActiveRentals() async {
    try {
      final res = await http.get(Uri.parse("${BaseService.baseUrl}/locations"), headers: BaseService.headers);
      if (res.statusCode == 200) return List<Map<String, dynamic>>.from(jsonDecode(res.body));
    } catch (e) {
      print("Rentals error: $e");
    }
    return [];
  }

  static String _formatToIso(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty || dateStr == "--") return "";
    try {
      final parts = dateStr.split('/');
      if (parts.length == 3) {
        // DD/MM/YYYY -> YYYY-MM-DD
        return "${parts[2]}-${parts[1].padLeft(2, '0')}-${parts[0].padLeft(2, '0')}";
      }
    } catch (_) {}
    return dateStr;
  }

  static Future<bool> rentCane(Map<String, dynamic> data) async {
    try {
      // 1. Format Address correctly for backend (String)
      String formattedAddress = "";
      if (data["address"] is Map) {
        final addr = data["address"];
        formattedAddress = "${addr['street'] ?? ''}, ${addr['city'] ?? ''} ${addr['postal_code'] ?? ''}, ${addr['country'] ?? ''}".trim();
        if (formattedAddress.startsWith(',')) formattedAddress = formattedAddress.substring(1).trim();
      } else {
        formattedAddress = data["adresse"]?.toString() ?? "";
      }

      // 2. Create User
      final userRes = await http.post(
        Uri.parse("${BaseService.baseUrl}/users"),
        headers: BaseService.headers,
        body: jsonEncode({
          "cin": data["cin"], 
          "nom": data["full_name"],
          "age": int.tryParse(data["age"]?.toString() ?? "0") ?? 0,
          "adresse": formattedAddress,
          "email": data["email"]?.toString().isNotEmpty == true ? data["email"] : "${data['cin']}@smartcane.com", 
          "numero_de_telephone": data["phone"],
          "contact_familial": data["emergency_phone"],
          "etat_de_sante": data["health_notes"],
          "sim_de_la_canne": data["sim_number"],
          "role": "client",
        }),
      );

      if (userRes.statusCode != 201 && userRes.statusCode != 400) {
        print("User creation failed: ${userRes.body}");
        return false;
      }

      if (userRes.statusCode == 400) {
        final resUpdate = await UserService.updateUser(data["cin"], {
          "nom": data["full_name"],
          "adresse": formattedAddress,
          "numero_de_telephone": data["phone"],
          "sim_de_la_canne": data["sim_number"],
          "etat_de_sante": data["health_notes"],
        });
        if (!resUpdate["success"]) {
           print("Rental User Update failed: ${resUpdate["error"]}");
        }
      }

      // 2. Create Location (Rental)
      final locRes = await http.post(
        Uri.parse("${BaseService.baseUrl}/locations"),
        headers: BaseService.headers,
        body: jsonEncode({
          "sim_de_la_canne": data["sim_number"],
          "cin_utilisateur": data["cin"],
          "date_de_location": _formatToIso(data["start_date"]),
          "date_de_retour": _formatToIso(data["end_date"]),
        }),
      );

      return locRes.statusCode == 201;
    } catch (e) {
      print("Rent cane error: $e");
    }
    return false;
  }

  static Future<Map<String, dynamic>?> getRental(String locationId) async {
    try {
      final res = await http.get(Uri.parse("${BaseService.baseUrl}/locations/$locationId"), headers: BaseService.headers);
      if (res.statusCode == 200) {
        return jsonDecode(res.body);
      }
    } catch (e) {
      print("Get rental error: $e");
    }
    return null;
  }

  static Future<bool> updateRental(String locationId, Map<String, dynamic> data) async {
    try {
      final res = await http.put(Uri.parse("${BaseService.baseUrl}/locations/$locationId"), headers: BaseService.headers, body: jsonEncode(data));
      return res.statusCode == 200;
    } catch (e) {
      print("Update rental error: $e");
    }
    return false;
  }

  static Future<bool> deleteRental(String locationId) async {
    try {
      final res = await http.delete(Uri.parse("${BaseService.baseUrl}/locations/$locationId"), headers: BaseService.headers);
      return res.statusCode == 200;
    } catch (e) {
      print("Delete rental error: $e");
    }
    return false;
  }
}
