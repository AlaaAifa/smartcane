import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../core/api_service.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  List<Map<String, dynamic>> alerts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() async {
    final data = await ApiService.getAlertsHistory();
    setState(() { alerts = data; _isLoading = false; });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Historique des Alertes", style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900)),
          const SizedBox(height: 4),
          Text("${alerts.length} alertes résolues", style: TextStyle(color: Colors.grey.shade600)),
          const SizedBox(height: 24),

          // Table header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(color: AppTheme.primary.withOpacity(0.05), borderRadius: BorderRadius.circular(12)),
            child: const Row(
              children: [
                Expanded(flex: 1, child: Text("Type", style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13))),
                Expanded(flex: 2, child: Text("Utilisateur", style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13))),
                Expanded(flex: 2, child: Text("Date", style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13))),
                Expanded(flex: 2, child: Text("Résolu par", style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13))),
                Expanded(flex: 1, child: Text("Statut", style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13))),
              ],
            ),
          ),
          const SizedBox(height: 8),

          Expanded(
            child: ListView.builder(
              itemCount: alerts.length,
              itemBuilder: (context, index) {
                final a = alerts[index];
                final isSOS = a["type"] == "SOS";
                return Container(
                  margin: const EdgeInsets.only(bottom: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 1,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: (isSOS ? AppTheme.sosRed : AppTheme.helpOrange).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(a["type"], textAlign: TextAlign.center,
                            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: isSOS ? AppTheme.sosRed : AppTheme.helpOrange)),
                        ),
                      ),
                      Expanded(flex: 2, child: Text(a["user_id"] ?? "", style: TextStyle(color: Colors.grey.shade700))),
                      Expanded(flex: 2, child: Text(a["timestamp"] ?? "", style: TextStyle(color: Colors.grey.shade500, fontSize: 13))),
                      Expanded(flex: 2, child: Text(a["resolved_by"] ?? "—", style: TextStyle(color: Colors.grey.shade700))),
                      Expanded(
                        flex: 1,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(color: AppTheme.normalGreen.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                          child: const Text("RÉSOLU", textAlign: TextAlign.center,
                            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: AppTheme.normalGreen)),
                        ),
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
