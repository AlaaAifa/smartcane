import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'dart:async';
import 'dart:convert';
import 'views/theme.dart';
import 'services/services.dart';
import 'views/layout/app_sidebar.dart';
import 'views/auth/login_page.dart';
import 'views/dashboard/dashboard_page.dart';
import 'views/users/users_page.dart';
import 'views/users/add_user_page.dart';
import 'views/alerts/alerts_page.dart';
import 'views/alerts/history_page.dart';
import 'views/map/map_page.dart';
import 'views/admin/solved_alerts_page.dart';
import 'views/staff/staff_page.dart';
import 'views/rentals/cane_rentals_page.dart';
import 'views/messages/messages_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: "AIzaSyCyQF1n2S7CYyzqlacSetIXv7_8KZ04hGQ",
        authDomain: "smartcane-97717.firebaseapp.com",
        databaseURL: "https://smartcane-97717-default-rtdb.europe-west1.firebasedatabase.app",
        projectId: "smartcane-97717",
        storageBucket: "smartcane-97717.firebasestorage.app",
        messagingSenderId: "178098479712",
        appId: "1:178098479712:web:5121de6088c7e848f89905",
        measurementId: "G-N56QLD2K56",
      ),
    );
    print("DEBUG: Firebase connecté avec succès !");
  } catch (e) {
    print("DEBUG: Erreur Firebase: $e");
  }
  runApp(const SIRIUSDashboard());
}

class SIRIUSDashboard extends StatelessWidget {
  const SIRIUSDashboard({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SIRIUS Dashboard',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      home: const AppNavigator(),
    );
  }
}

class AppNavigator extends StatefulWidget {
  const AppNavigator({super.key});
  @override
  State<AppNavigator> createState() => _AppNavigatorState();
}

class _AppNavigatorState extends State<AppNavigator> {
  String _currentRoute = "/login";
  List<String> _history = [];
  double? _mapLat;
  double? _mapLon;
  String _mapType = "SOS";

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _navigate(String route) {
    if (route == "/back") {
      if (_history.isNotEmpty) {
        setState(() {
          _currentRoute = _history.removeLast();
        });
      }
      return;
    }
    if (route.startsWith("/map?")) {
      _history.add(_currentRoute);
      final uri = Uri.parse("http://x$route");
      _mapLat = double.tryParse(uri.queryParameters["lat"] ?? "");
      _mapLon = double.tryParse(uri.queryParameters["lon"] ?? "");
      _mapType = uri.queryParameters["type"] ?? "SOS";
      setState(() => _currentRoute = "/map");
      return;
    }
    if (route == "/login") {
      BaseService.logout();
      _history.clear();
    } else {
      _history.add(_currentRoute);
    }
    setState(() => _currentRoute = route);
  }

  Widget _buildPage() {
    switch (_currentRoute) {
      case "/dashboard": return DashboardPage(onNavigate: _navigate);
      case "/users": return UsersPage(onNavigate: _navigate);
      case "/add-user": return const AddUserPage();
      case "/alerts": return AlertsPage(onNavigate: _navigate);
      case "/history": return const HistoryPage();
      case "/staff": return StaffPage();
      case "/rentals": return CaneRentalsPage();
      case "/map": return MapPage(latitude: _mapLat ?? 36.8065, longitude: _mapLon ?? 10.1815, alertType: _mapType, onBack: () => _navigate("/back"));
      case "/solved": return const SolvedAlertsPage();
      case "/messages": return const MessagesPage();
      default: return DashboardPage(onNavigate: _navigate);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_currentRoute == "/login") {
      return LoginPage(onNavigate: _navigate);
    }

    return Scaffold(
      backgroundColor: AppTheme.bgDeep,
      body: Row(
        children: [
          // Sidebar (Full Height) - Optimized with RepaintBoundary
          RepaintBoundary(
            child: AppSidebar(currentRoute: _currentRoute, onNavigate: _navigate),
          ),
          
          // Right Content (Custom Header + Page)
          Expanded(
            child: Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: RepaintBoundary(
                    child: Container(
                      color: AppTheme.bgDeep,
                      child: _buildPage(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final String staffName = BaseService.staffName ?? "Agent";
    final String role = BaseService.role ?? "staff";
    final String? photoUrl = BaseService.staffPhotoUrl;

    return Container(
      height: 80,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: AppTheme.sidebarBg,
        border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.08))),
      ),
      child: Row(
        children: [
          // Centered Title
          const Expanded(
            child: Center(
              child: Text(
                "CENTRE DE CONTRÔLE SIRIUS",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                ),
              ),
            ),
          ),
          
          // Clock - Now isolated to prevent global rebuilds
          const SiriusClock(),
          
          const SizedBox(width: 24),
          
          // Profile anchor (Simplified)
          _buildProfileAnchor(staffName, role, photoUrl),
        ],
      ),
    );
  }

  Widget _buildProfileAnchor(String name, String role, String? url) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(name, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
              Text(
                role.toUpperCase(),
                style: TextStyle(color: AppTheme.cyan.withOpacity(0.8), fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1),
              ),
            ],
          ),
          const SizedBox(width: 14),
          CircleAvatar(
            radius: 18,
            backgroundColor: AppTheme.cyan.withOpacity(0.1),
            backgroundImage: (url != null && url.startsWith("data:image"))
                ? MemoryImage(base64Decode(url.split(',').last))
                : (url != null && url.isNotEmpty)
                    ? NetworkImage(url) as ImageProvider
                    : null,
            child: (url == null || url.isEmpty)
                ? Text(name.isNotEmpty ? name[0].toUpperCase() : "?", style: const TextStyle(color: AppTheme.cyan, fontWeight: FontWeight.bold))
                : null,
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    const days = ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'];
    const months = ['Jan', 'Fév', 'Mar', 'Avr', 'Mai', 'Jun', 'Jul', 'Aoû', 'Sep', 'Oct', 'Nov', 'Déc'];
    return "${days[dt.weekday - 1]} ${dt.day} ${months[dt.month - 1]} ${dt.year}";
  }
}

// ── Isolated Clock Widget for Performance ────────────────────────────────────
class SiriusClock extends StatefulWidget {
  const SiriusClock({super.key});

  @override
  State<SiriusClock> createState() => _SiriusClockState();
}

class _SiriusClockState extends State<SiriusClock> {
  late Timer _timer;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  String _formatDate(DateTime d) {
    final List<String> months = ["Jan", "Fév", "Mar", "Avr", "Mai", "Juin", "Juil", "Août", "Sep", "Oct", "Nov", "Déc"];
    return "${d.day} ${months[d.month - 1]} ${d.year}";
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          "${_now.hour.toString().padLeft(2, '0')}:${_now.minute.toString().padLeft(2, '0')}:${_now.second.toString().padLeft(2, '0')}",
          style: const TextStyle(color: AppTheme.cyan, fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: 1.5),
        ),
        Text(
          _formatDate(_now),
          style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 11, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}
