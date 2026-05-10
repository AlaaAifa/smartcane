class BaseService {
  static const String baseUrl = "http://localhost:8000";
  static String? token;
  static String? role;
  static String? staffName;
  static String? staffId;
  static String? staffPhotoUrl;

  static Map<String, String> get headers => {
    "Content-Type": "application/json",
    if (token != null) "Authorization": "Bearer $token",
  };

  static bool get isAdmin => role == "admin";

  static void logout() {
    token = null;
    role = null;
    staffName = null;
    staffId = null;
    staffPhotoUrl = null;
  }
}
