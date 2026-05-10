import 'package:flutter/material.dart';
import '../theme.dart';
import '../../services/services.dart';
import '../../models/message_model.dart';
import 'sirius_logo.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Futuristic Sidebar Layout — Focuses only on Navigation now
// ─────────────────────────────────────────────────────────────────────────────
class AppSidebar extends StatefulWidget {
  final String currentRoute;
  final Function(String) onNavigate;

  const AppSidebar({
    super.key,
    required this.currentRoute,
    required this.onNavigate,
  });

  @override
  State<AppSidebar> createState() => _AppSidebarState();
}

class _AppSidebarState extends State<AppSidebar> {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280, // Slightly wider for elegance
      decoration: const BoxDecoration(
        color: AppTheme.sidebarBg,
        boxShadow: [
          BoxShadow(color: Colors.black26, blurRadius: 20, offset: Offset(5, 0)),
        ],
      ),
      child: Column(
        children: [
          const SizedBox(height: 48),
          // Elegant Logo Section
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                const SiriusLogo(size: 32),
                const SizedBox(width: 16),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "SIRIUS",
                      style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                    ),
                    Text(
                      "CENTRE DE CONTRÔLE",
                      style: TextStyle(color: AppTheme.accent, fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 1.5),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 48),
          Expanded(
            child: StreamBuilder<List<ClientMessage>>(
              stream: MessageService.getMessagesStream(),
              builder: (context, snapshot) {
                final int unreadCount = (snapshot.data ?? [])
                    .where((m) => m.status == MessageStatus.unread)
                    .length;
                return _buildNav(unreadCount);
              },
            ),
          ),
          _buildFooter(),
        ],
      ),
    );
  }

  Widget _buildNav(int unreadMessages) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _navItem("Tableau de bord", Icons.grid_view_rounded, "/dashboard"),
          _navItem("Alertes en direct", Icons.notification_important_rounded, "/alerts"),
          _navItem("Historique", Icons.history_rounded, "/history"),
          if (BaseService.isAdmin)
            _navItem("Gestion Personnel", Icons.badge_rounded, "/staff"),
          _navItem("Gestion Locations", Icons.vpn_key_rounded, "/rentals"),
          _navItem("Gestion Vente", Icons.person_add_alt_1_rounded, "/add-user"),
          _navItem("Messages clients", Icons.email_rounded, "/messages", badge: unreadMessages),
        ],
      ),
    );
  }

  Widget _navItem(String label, IconData icon, String route, {int badge = 0}) {
    final isActive = widget.currentRoute == route;
    return _HoverNavItem(
      isActive: isActive,
      label: label,
      icon: icon,
      badge: badge,
      onTap: () => widget.onNavigate(route),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.2),
      ),
      child: _HoverLogout(
        onTap: () {
          BaseService.logout();
          widget.onNavigate("/login");
        },
      ),
    );
  }
}

class _HoverNavItem extends StatefulWidget {
  final bool isActive;
  final String label;
  final IconData icon;
  final int badge;
  final VoidCallback onTap;

  const _HoverNavItem({
    required this.isActive,
    required this.label,
    required this.icon,
    required this.badge,
    required this.onTap,
  });

  @override
  State<_HoverNavItem> createState() => _HoverNavItemState();
}

class _HoverNavItemState extends State<_HoverNavItem> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final Color iconColor = (widget.isActive || _hovered) ? AppTheme.accent : Colors.white.withOpacity(0.4);
    final Color textColor = (widget.isActive || _hovered) ? Colors.white : Colors.white.withOpacity(0.4);

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: widget.isActive ? Colors.white.withOpacity(0.05) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(widget.icon, color: iconColor, size: 22),
                  if (widget.badge > 0)
                    Positioned(
                      right: -8,
                      top: -8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(color: AppTheme.sosRed, shape: BoxShape.circle),
                        child: Text(
                          widget.badge > 9 ? "9+" : widget.badge.toString(),
                          style: const TextStyle(fontSize: 8, color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  widget.label,
                  style: TextStyle(
                    color: textColor,
                    fontWeight: widget.isActive ? FontWeight.w700 : FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
              ),
              if (widget.isActive)
                Container(
                  width: 5,
                  height: 5,
                  decoration: const BoxDecoration(color: AppTheme.accent, shape: BoxShape.circle),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HoverLogout extends StatefulWidget {
  final VoidCallback onTap;
  const _HoverLogout({required this.onTap});
  @override
  State<_HoverLogout> createState() => _HoverLogoutState();
}

class _HoverLogoutState extends State<_HoverLogout> {
  bool _hovered = false;
  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: _hovered ? AppTheme.sosRed.withOpacity(0.1) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _hovered ? AppTheme.sosRed.withOpacity(0.3) : Colors.white12),
          ),
          child: Row(
            children: [
              Icon(Icons.logout_rounded, color: _hovered ? AppTheme.sosRed : Colors.white38, size: 20),
              const SizedBox(width: 12),
              Text(
                "Déconnexion",
                style: TextStyle(
                  color: _hovered ? AppTheme.sosRed : Colors.white38,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
