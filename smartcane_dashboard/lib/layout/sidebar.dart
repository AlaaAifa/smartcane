import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../core/api_service.dart';

class Sidebar extends StatelessWidget {
  final String currentRoute;
  final Function(String) onNavigate;

  const Sidebar({super.key, required this.currentRoute, required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 260,
      color: AppTheme.sidebarBg,
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.visibility, color: Colors.white, size: 28),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    "Smart Cane",
                    style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ),
          ),
          const Divider(color: Colors.white12, height: 1),
          const SizedBox(height: 12),

          // Menu Items
          _buildItem(Icons.dashboard_rounded, "Dashboard", "/dashboard"),
          _buildItem(Icons.people_alt_rounded, "Utilisateurs", "/users"),
          _buildItem(Icons.person_add_alt_1_rounded, "Ajouter Utilisateur", "/add-user"),
          _buildItem(Icons.notification_important_rounded, "Alertes Live", "/alerts"),
          _buildItem(Icons.history_rounded, "Historique", "/history"),

          // Admin-only items
          if (ApiService.isAdmin) ...[
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 24, 20, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text("ADMIN", style: TextStyle(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.5)),
              ),
            ),
            _buildItem(Icons.check_circle_outline_rounded, "Alertes Résolues", "/solved"),
            _buildItem(Icons.admin_panel_settings_rounded, "Ajouter Staff", "/add-staff"),
          ],

          const Spacer(),

          // User info + Logout
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppTheme.primary,
                  radius: 18,
                  child: Text(
                    (ApiService.staffName ?? "?")[0].toUpperCase(),
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ApiService.staffName ?? "Utilisateur",
                        style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        ApiService.role?.toUpperCase() ?? "",
                        style: const TextStyle(color: Colors.white38, fontSize: 11),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.logout, color: Colors.white38, size: 20),
                  onPressed: () {
                    ApiService.logout();
                    onNavigate("/login");
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItem(IconData icon, String label, String route) {
    final isActive = currentRoute == route;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => onNavigate(route),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isActive ? AppTheme.sidebarActive : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(icon, color: isActive ? Colors.white : Colors.white54, size: 22),
                const SizedBox(width: 14),
                Text(
                  label,
                  style: TextStyle(
                    color: isActive ? Colors.white : Colors.white54,
                    fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
