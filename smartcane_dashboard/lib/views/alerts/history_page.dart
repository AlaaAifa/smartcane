import 'package:flutter/material.dart';
import '../theme.dart';
import '../../services/services.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  List<Map<String, dynamic>> alerts = [];
  Map<String, Map<String, dynamic>> usersDict = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final data = await AlertService.getAlertsHistory();
    final usersData = await UserService.getUsers();

    final tempDict = <String, Map<String, dynamic>>{};
    for (final user in usersData) {
      final cin = user["cin"]?.toString();
      if (cin != null) {
        tempDict[cin] = user;
      }
    }

    if (!mounted) {
      return;
    }

    setState(() {
      alerts = data;
      usersDict = tempDict;
      _isLoading = false;
    });
  }

  String _userName(String? cin) => usersDict[cin]?["nom"]?.toString() ?? cin ?? "Inconnu";

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Historique des alertes", style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 4),
                  Text("${alerts.length} alertes resolues", style: TextStyle(color: Colors.grey.shade600)),
                ],
              ),
              if (BaseService.isAdmin)
                ElevatedButton.icon(
                  onPressed: () async {
                    final success = await AlertService.clearAlertHistory();
                    if (!mounted) {
                      return;
                    }
                    if (success) {
                      _load();
                    }
                  },
                  icon: const Icon(Icons.delete_sweep_rounded),
                  label: const Text("Vider"),
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.sosRed),
                ),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: alerts.isEmpty
                ? Center(child: Text("Aucune alerte resolue", style: TextStyle(color: Colors.grey.shade500)))
                : ListView.builder(
                    itemCount: alerts.length,
                    itemBuilder: (context, index) {
                      final alert = alerts[index];
                      final isSOS = alert["type"] == "SOS";
                      final color = isSOS ? AppTheme.sosRed : AppTheme.helpOrange;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: color.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                alert["type"]?.toString() ?? "",
                                style: TextStyle(color: color, fontWeight: FontWeight.w800),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(child: Text(_userName(alert["user_id"]?.toString()), style: const TextStyle(fontWeight: FontWeight.w700))),
                            Expanded(child: Text(alert["resolved_by"]?.toString() ?? "-", style: TextStyle(color: Colors.grey.shade700))),
                            SizedBox(
                              width: 180,
                              child: Text(alert["timestamp"]?.toString() ?? "", style: TextStyle(color: Colors.grey.shade500)),
                            ),
                            if (BaseService.isAdmin) ...[
                              IconButton(
                                onPressed: () async {
                                  final success = await AlertService.reactivateAlert(alert["alert_id"].toString());
                                  if (!mounted) {
                                    return;
                                  }
                                  if (success) {
                                    _load();
                                  }
                                },
                                icon: const Icon(Icons.refresh, color: AppTheme.primary),
                              ),
                              IconButton(
                                onPressed: () async {
                                  final success = await AlertService.deleteAlert(alert["alert_id"].toString());
                                  if (!mounted) {
                                    return;
                                  }
                                  if (success) {
                                    _load();
                                  }
                                },
                                icon: const Icon(Icons.delete_outline, color: AppTheme.sosRed),
                              ),
                            ],
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
