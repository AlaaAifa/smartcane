import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../core/api_service.dart';
import 'package:url_launcher/url_launcher.dart';

class AlertsPage extends StatefulWidget {
  final Function(String)? onNavigate;
  const AlertsPage({super.key, this.onNavigate});

  @override
  State<AlertsPage> createState() => _AlertsPageState();
}

class _AlertsPageState extends State<AlertsPage> {
  List<Map<String, dynamic>> alerts = [];
  Map<String, Map<String, dynamic>> usersDict = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() async {
    final alertData = await ApiService.getActiveAlerts();
    final usersData = await ApiService.getUsers();
    
    final Map<String, Map<String, dynamic>> tempDict = {};
    for (var u in usersData) {
      tempDict[u['user_id']] = u;
    }

    if (mounted) {
      setState(() { 
        alerts = alertData; 
        usersDict = tempDict;
        _isLoading = false; 
      });
    }
  }

  void _resolveAlert(String alertId) async {
    final success = await ApiService.resolveAlert(alertId);
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Alerte résolue !"), backgroundColor: Colors.green),
      );
      _loadData();
    }
  }

  void _callNumber(String? number) async {
    if (number == null || number.isEmpty) return;
    final Uri url = Uri.parse("tel:$number");
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text("Alertes Live", style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900)),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: AppTheme.sosRed.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                child: Text("${alerts.length} actives", style: const TextStyle(color: AppTheme.sosRed, fontWeight: FontWeight.w700, fontSize: 13)),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () { setState(() => _isLoading = true); _loadData(); },
              ),
            ],
          ),
          const SizedBox(height: 24),

          Expanded(
            child: alerts.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle, size: 80, color: AppTheme.normalGreen.withOpacity(0.3)),
                      const SizedBox(height: 16),
                      Text("Aucune alerte active", style: TextStyle(color: Colors.grey.shade400, fontSize: 18)),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: alerts.length,
                  itemBuilder: (context, index) {
                    final alert = alerts[index];
                    final isSOS = alert["type"] == "SOS";
                    final color = isSOS ? AppTheme.sosRed : AppTheme.helpOrange;
                    final user = usersDict[alert['user_id']];
                    final userName = user != null ? "${user['prenom']} ${user['nom']}" : alert['user_id'];

                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border(left: BorderSide(color: color, width: 4)),
                        boxShadow: [BoxShadow(color: color.withOpacity(0.06), blurRadius: 12, offset: const Offset(0, 4))],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                            child: Icon(isSOS ? Icons.emergency : Icons.help_outline, color: color, size: 28),
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(alert["type"], style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: color)),
                                const SizedBox(height: 4),
                                Text(userName, style: const TextStyle(fontWeight: FontWeight.bold)),
                                Text("Position: ${alert['latitude']}, ${alert['longitude']}", style: TextStyle(color: Colors.grey.shade400, fontSize: 12)),
                              ],
                            ),
                          ),
                          Text(alert["timestamp"] ?? "", style: TextStyle(color: Colors.grey.shade400, fontSize: 12)),
                          const SizedBox(width: 20),

                          // Actions
                          OutlinedButton.icon(
                            onPressed: () {
                              if (widget.onNavigate != null) {
                                widget.onNavigate!("/map?lat=${alert['latitude']}&lon=${alert['longitude']}&type=${alert['type']}");
                              }
                            },
                            icon: const Icon(Icons.location_on, size: 18),
                            label: const Text("Localiser"),
                          ),
                          const SizedBox(width: 8),
                          
                          // Call Menu
                          PopupMenuButton<String>(
                            onSelected: (value) {
                              if (value == "patient") _callNumber(user?['phone_number_malvoyant']);
                              if (value == "famille") _callNumber(user?['phone_number_famille']);
                            },
                            itemBuilder: (context) => [
                              PopupMenuItem(
                                value: "patient",
                                child: Row(
                                  children: [
                                    const Icon(Icons.person, size: 18, color: AppTheme.primary),
                                    const SizedBox(width: 8),
                                    Text("Client (${user?['phone_number_malvoyant'] ?? 'N/A'})"),
                                  ],
                                ),
                              ),
                              PopupMenuItem(
                                value: "famille",
                                child: Row(
                                  children: [
                                    const Icon(Icons.family_restroom, size: 18, color: AppTheme.primary),
                                    const SizedBox(width: 8),
                                    Text("Famille (${user?['phone_number_famille'] ?? 'N/A'})"),
                                  ],
                                ),
                              ),
                            ],
                            child: OutlinedButton.icon(
                              onPressed: null, // the popup overrides this
                              icon: const Icon(Icons.phone),
                              label: const Text("Appeler"),
                            ),
                          ),
                          
                          const SizedBox(width: 8),
                          ElevatedButton.icon(
                            onPressed: () => _resolveAlert(alert["alert_id"]),
                            icon: const Icon(Icons.check, size: 18),
                            label: const Text("Traiter"),
                            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.normalGreen),
                          ),
                        ],
                      ),
                    );
                  },
                ),
          ),
        ],
      ),
    );
  }
}
