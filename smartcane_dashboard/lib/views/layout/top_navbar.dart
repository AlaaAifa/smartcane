import 'package:flutter/material.dart';

import '../theme.dart';

import '../../services/services.dart';

import '../../models/message_model.dart';

import 'dart:convert';



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

                      "SIRIUS",

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

                      _buildNavItem("Tableau de bord", Icons.dashboard_rounded, "/dashboard", isNarrow),

                      _buildNavItem("Alertes Live", Icons.notification_important_rounded, "/alerts", isNarrow),

                      _buildNavItem("Historique", Icons.history_rounded, "/history", isNarrow),

                      if (BaseService.isAdmin)

                        _buildNavItem("Personnel", Icons.badge_rounded, "/staff", isNarrow),

                      _buildNavItem("Gestion Location", Icons.shopping_cart_rounded, "/rentals", isNarrow),

                      _buildNavItem("Gestion Vente", Icons.person_add_alt_1_rounded, "/add-user", isNarrow),

                      StreamBuilder<List<ClientMessage>>(

                        stream: MessageService.getMessagesStream(),

                        builder: (context, snapshot) {

                          final int unreadCount = (snapshot.data ?? [])

                              .where((m) => m.status == MessageStatus.unread)

                              .length;

                          return _buildNavItem("Messages Clients", Icons.email_rounded, "/messages", isNarrow, badgeCount: unreadCount);

                        }

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

                          BaseService.staffName ?? "Utilisateur",

                          style: const TextStyle(

                            color: Colors.white,

                            fontSize: 13,

                            fontWeight: FontWeight.w600,

                          ),

                        ),

                        Text(

                          BaseService.role?.toUpperCase() ?? "",

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

                    radius: 18,

                    backgroundColor: AppTheme.primary.withOpacity(0.1),

                    backgroundImage: (BaseService.staffPhotoUrl != null && BaseService.staffPhotoUrl!.startsWith("data:image"))

                        ? MemoryImage(base64Decode(BaseService.staffPhotoUrl!.split(',').last))

                        : (BaseService.staffPhotoUrl != null && BaseService.staffPhotoUrl!.isNotEmpty)

                            ? NetworkImage(BaseService.staffPhotoUrl!) as ImageProvider

                            : null,

                    child: (BaseService.staffPhotoUrl == null || BaseService.staffPhotoUrl!.isEmpty)

                        ? Text(

                            (BaseService.staffName ?? "?")[0].toUpperCase(),

                            style: const TextStyle(

                              color: AppTheme.primary,

                              fontWeight: FontWeight.bold,

                              fontSize: 14,

                            ),

                          )

                        : null,

                  ),

                  const SizedBox(width: 4),

                  IconButton(

                    icon: const Icon(Icons.logout, color: Colors.white38, size: 20),

                    tooltip: "Déconnexion",

                    onPressed: () {

                      BaseService.logout();

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



  Widget _buildNavItem(String label, IconData icon, String route, bool hideLabel, {int badgeCount = 0}) {

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

              Stack(

                clipBehavior: Clip.none,

                children: [

                  Icon(

                    icon,

                    color: isActive ? Colors.white : Colors.white54,

                    size: 20,

                  ),

                  if (badgeCount > 0)

                    Positioned(

                      right: -5,

                      top: -5,

                      child: Container(

                        padding: const EdgeInsets.all(4),

                        decoration: const BoxDecoration(

                          color: AppTheme.sosRed,

                          shape: BoxShape.circle,

                        ),

                        constraints: const BoxConstraints(

                          minWidth: 14,

                          minHeight: 14,

                        ),

                        child: Text(

                          badgeCount.toString(),

                          style: const TextStyle(

                            color: Colors.white,

                            fontSize: 8,

                            fontWeight: FontWeight.bold,

                          ),

                          textAlign: TextAlign.center,

                        ),

                      ),

                    ),

                ],

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

