import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../core/api_service.dart';

class AlertsPage extends StatefulWidget {
  final Function(String)? onNavigate;
  const AlertsPage({super.key, this.onNavigate});

  @override
  State<AlertsPage> createState() => _AlertsPageState();
}

class _AlertsPageState extends State<AlertsPage> {
  List<Map<String, dynamic>> alerts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAlerts();
  }

  void _loadAlerts() async {
    final data = await ApiService.getActiveAlerts();
    setState(() { alerts = data; _isLoading = false; });
  }

  void _resolveAlert(String alertId) async {
    final success = await ApiService.resolveAlert(alertId);
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Alerte résolue !"), backgroundColor: Colors.green),
      );
      _loadAlerts();
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
                onPressed: () { setState(() => _isLoading = true); _loadAlerts(); },
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
                                Text("Utilisateur: ${alert['user_id']}", style: TextStyle(color: Colors.grey.shade600)),
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
                            icon: const Icon(Icons.map, size: 18),
                            label: const Text("Carte"),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton.icon(
                            onPressed: () => _resolveAlert(alert["alert_id"]),
                            icon: const Icon(Icons.check, size: 18),
                            label: const Text("Résoudre"),
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
