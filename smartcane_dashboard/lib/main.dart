import 'package:flutter/material.dart';
import 'core/theme.dart';
import 'core/api_service.dart';
import 'layout/top_navbar.dart';
import 'features/auth/login_page.dart';
import 'features/dashboard/dashboard_page.dart';
import 'features/users/users_page.dart';
import 'features/users/add_user_page.dart';
import 'features/alerts/alerts_page.dart';
import 'features/alerts/history_page.dart';
import 'features/map/map_page.dart';
import 'features/admin/solved_alerts_page.dart';
import 'features/staff/staff_page.dart';
import 'features/rentals/cane_rentals_page.dart';

void main() {
  runApp(const SmartCaneDashboard());
}

class SmartCaneDashboard extends StatelessWidget {
  const SmartCaneDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Cane Dashboard',
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

  void _navigate(String route) {
    if (route == "/back") {
      if (_history.isNotEmpty) {
        setState(() {
          _currentRoute = _history.removeLast();
        });
      }
      return;
    }

    // Handle map route with parameters
    if (route.startsWith("/map?")) {
      _history.add(_currentRoute);
      final uri = Uri.parse("http://x$route");
      _mapLat = double.tryParse(uri.queryParameters["lat"] ?? "");
      _mapLon = double.tryParse(uri.queryParameters["lon"] ?? "");
      _mapType = uri.queryParameters["type"] ?? "SOS";
      setState(() => _currentRoute = "/map");
      return;
    }

    // If logging out, clear token
    if (route == "/login") {
      ApiService.logout();
      _history.clear();
    } else {
      _history.add(_currentRoute);
    }

    setState(() => _currentRoute = route);
  }

  Widget _buildPage() {
    switch (_currentRoute) {
      case "/dashboard":
        return DashboardPage(onNavigate: _navigate);
      case "/users":
        return UsersPage(onNavigate: _navigate);
      case "/add-user":
        return const AddUserPage();
      case "/alerts":
        return AlertsPage(onNavigate: _navigate);
      case "/history":
        return const HistoryPage();
      case "/staff":
        return StaffPage();
      case "/rentals":
        return CaneRentalsPage();
      case "/map":
        return MapPage(
          latitude: _mapLat ?? 36.8065,
          longitude: _mapLon ?? 10.1815,
          alertType: _mapType,
          onBack: () => _navigate("/back"),
        );
      case "/solved":
        return const SolvedAlertsPage();

      default:
        return DashboardPage(onNavigate: _navigate);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show login page without sidebar
    if (_currentRoute == "/login") {
      return LoginPage(onNavigate: _navigate);
    }

    // Show top navigation bar layout with content below it
    return Scaffold(
      body: Column(
        children: [
          TopNavbar(currentRoute: _currentRoute, onNavigate: _navigate),
          Expanded(
            child: Container(
              width: double.infinity,
              color: AppTheme.background,
              child: _buildPage(),
            ),
          ),
        ],
      ),
    );
  }
}
