import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../core/api_service.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  Map<String, dynamic> stats = {};
  List<Map<String, dynamic>> recentAlerts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() async {
    final s = await ApiService.getStats();
    final a = await ApiService.getActiveAlerts();
    setState(() { stats = s; recentAlerts = a; _isLoading = false; });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Bonjour, ${ApiService.staffName ?? 'Utilisateur'} 👋",
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900)),
          const SizedBox(height: 4),
          Text("Vue d'ensemble du système", style: TextStyle(color: Colors.grey.shade600, fontSize: 15)),
          const SizedBox(height: 32),

          // Stat cards
          Row(
            children: [
              _statCard("Utilisateurs", "${stats['total_users'] ?? 0}", Icons.people, AppTheme.primary),
              const SizedBox(width: 20),
              _statCard("Alertes Actives", "${stats['active_alerts'] ?? 0}", Icons.warning_amber_rounded, AppTheme.helpOrange),
              const SizedBox(width: 20),
              _statCard("SOS", "${stats['sos_count'] ?? 0}", Icons.emergency, AppTheme.sosRed),
              const SizedBox(width: 20),
              _statCard("Résolues", "${stats['resolved_count'] ?? 0}", Icons.check_circle, AppTheme.normalGreen),
            ],
          ),
          const SizedBox(height: 40),

          // Recent alerts
          const Text("Alertes Récentes", style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
          const SizedBox(height: 16),
          Expanded(
            child: recentAlerts.isEmpty
              ? Center(child: Text("Aucune alerte active", style: TextStyle(color: Colors.grey.shade400, fontSize: 16)))
              : ListView.builder(
                  itemCount: recentAlerts.length,
                  itemBuilder: (context, index) {
                    final alert = recentAlerts[index];
                    final isSOS = alert["type"] == "SOS";
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: isSOS ? AppTheme.sosRed.withOpacity(0.3) : AppTheme.helpOrange.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: (isSOS ? AppTheme.sosRed : AppTheme.helpOrange).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              isSOS ? Icons.emergency : Icons.help_outline,
                              color: isSOS ? AppTheme.sosRed : AppTheme.helpOrange,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(alert["type"], style: TextStyle(fontWeight: FontWeight.w800, color: isSOS ? AppTheme.sosRed : AppTheme.helpOrange)),
                                Text("User: ${alert['user_id']}", style: TextStyle(color: Colors.grey.shade600)),
                              ],
                            ),
                          ),
                          Text(alert["timestamp"] ?? "", style: TextStyle(color: Colors.grey.shade400, fontSize: 12)),
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

  Widget _statCard(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: color.withOpacity(0.08), blurRadius: 20, offset: const Offset(0, 8))],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value, style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: color)),
                Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
