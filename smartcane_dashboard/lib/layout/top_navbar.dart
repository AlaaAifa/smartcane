import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../core/api_service.dart';

class TopNavbar extends StatelessWidget {
  final String currentRoute;
  final Function(String) onNavigate;

  const TopNavbar({
    super.key,
    required this.currentRoute,
    required this.onNavigate,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isNarrow = constraints.maxWidth < 1000;
        final bool isVeryNarrow = constraints.maxWidth < 700;

        return Container(
          height: 70,
          width: double.infinity,
          decoration: const BoxDecoration(
            color: AppTheme.sidebarBg,
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 10,
                offset: Offset(0, 2),
              ),
            ],
          ),
          padding: EdgeInsets.symmetric(horizontal: isNarrow ? 12 : 24),
          child: Row(
            children: [
              // Logo & Title
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppTheme.primary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.visibility, color: Colors.white, size: 22),
                  ),
                  if (!isVeryNarrow) ...[
                    const SizedBox(width: 12),
                    const Text(
                      "Smart Cane",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ],
              ),
              
              SizedBox(width: isVeryNarrow ? 16 : 48),
              
              // Navigation Items (Scrollable when narrow)
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildNavItem("Dashboard", Icons.dashboard_rounded, "/dashboard", isNarrow),
                      _buildNavItem("Alertes Live", Icons.notification_important_rounded, "/alerts", isNarrow),
                      _buildNavItem("Historique", Icons.history_rounded, "/history", isNarrow),
                      _buildNavItem("Staff", Icons.badge_rounded, "/staff", isNarrow),
                      
                      // Admin Dropdown
                      if (ApiService.isAdmin)
                        Padding(
                          padding: const EdgeInsets.only(left: 12),
                          child: PopupMenuButton<String>(
                            onSelected: (route) => onNavigate(route),
                            offset: const Offset(0, 45),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            color: AppTheme.sidebarActive,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: (currentRoute == "/add-staff")
                                    ? AppTheme.sidebarActive
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.admin_panel_settings_rounded, color: Colors.white70, size: 20),
                                  if (!isNarrow) ...[
                                    const SizedBox(width: 8),
                                    const Text(
                                      "Admin",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                      ),
                                    ),
                                    const Icon(Icons.arrow_drop_down, color: Colors.white70),
                                  ],
                                ],
                              ),
                            ),
                            itemBuilder: (context) => [
                              _buildDropdownItem(
                                "Ajouter Staff",
                                Icons.admin_panel_settings_rounded,
                                "/add-staff",
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              const SizedBox(width: 16),

              // User Info & Logout
              Row(
                children: [
                  if (!isVeryNarrow)
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          ApiService.staffName ?? "Utilisateur",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          ApiService.role?.toUpperCase() ?? "",
                          style: const TextStyle(
                            color: Colors.white38,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(width: 12),
                  CircleAvatar(
                    backgroundColor: AppTheme.primary,
                    radius: 18,
                    child: Text(
                      (ApiService.staffName ?? "?")[0].toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    icon: const Icon(Icons.logout, color: Colors.white38, size: 20),
                    tooltip: "Déconnexion",
                    onPressed: () {
                      ApiService.logout();
                      onNavigate("/login");
                    },
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildNavItem(String label, IconData icon, String route, bool hideLabel) {
    final isActive = currentRoute == route;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: InkWell(
        onTap: () => onNavigate(route),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isActive ? AppTheme.sidebarActive : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: isActive ? Colors.white : Colors.white54,
                size: 20,
              ),
              if (!hideLabel) ...[
                const SizedBox(width: 10),
                Text(
                  label,
                  style: TextStyle(
                    color: isActive ? Colors.white : Colors.white54,
                    fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  PopupMenuItem<String> _buildDropdownItem(String label, IconData icon, String value) {
    return PopupMenuItem<String>(
      value: value,
      child: Row(
        children: [
          Icon(icon, color: Colors.white70, size: 20),
          const SizedBox(width: 12),
          Text(
            label,
            style: const TextStyle(color: Colors.white, fontSize: 14),
          ),
        ],
      ),
    );
  }
}
