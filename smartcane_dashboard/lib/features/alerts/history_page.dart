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
  Map<String, Map<String, dynamic>> usersDict = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() async {
    final data = await ApiService.getAlertsHistory();
    final usersData = await ApiService.getUsers();
    
    final Map<String, Map<String, dynamic>> tempDict = {};
    for (var u in usersData) {
      tempDict[u['user_id']] = u;
    }

    if (mounted) {
      setState(() { 
        alerts = data; 
        usersDict = tempDict;
        _isLoading = false; 
      });
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Historique des Alertes", style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 4),
                  Text("${alerts.length} alertes résolues", style: TextStyle(color: Colors.grey.shade600)),
                ],
              ),
              if (ApiService.isAdmin)
                ElevatedButton.icon(
                  onPressed: () => _confirmClearHistory(context),
                  icon: const Icon(Icons.delete_sweep_rounded, size: 20),
                  label: const Text("Supprimer l'Historique"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.sosRed,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 32),

          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 800),
                child: Column(
                  children: [
                    // Table header
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withOpacity(0.05), 
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.primary.withOpacity(0.1)),
                      ),
                      child: const Row(
                        children: [
                          Expanded(flex: 2, child: Text("Utilisateur", textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13))),
                          Expanded(flex: 1, child: Text("Type", textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13))),
                          Expanded(flex: 1, child: Text("Statut", textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13))),
                          Expanded(flex: 2, child: Text("Résolu par", textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13))),
                          Expanded(flex: 2, child: Text("Date", textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13))),
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
                          final String userFullName = usersDict[a['user_id']] != null 
                              ? "${usersDict[a['user_id']]!['prenom']} ${usersDict[a['user_id']]!['nom']}" 
                              : a["user_id"] ?? "";

                          return Container(
                            margin: const EdgeInsets.only(bottom: 4),
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                            decoration: BoxDecoration(
                              color: Colors.white, 
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade100),
                            ),
                            child: Row(
                              children: [
                                // Utilisateur
                                Expanded(
                                  flex: 2, 
                                  child: Text(userFullName, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14))
                                ),
                                
                                // Type
                                Expanded(
                                  flex: 1,
                                  child: Center(
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: (isSOS ? AppTheme.sosRed : AppTheme.helpOrange).withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(a["type"], 
                                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 11, color: isSOS ? AppTheme.sosRed : AppTheme.helpOrange)),
                                    ),
                                  ),
                                ),

                                // Statut
                                Expanded(
                                  flex: 1,
                                  child: Center(
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(color: AppTheme.normalGreen.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                                      child: const Text("RÉSOLU", 
                                        style: TextStyle(fontWeight: FontWeight.w800, fontSize: 10, color: AppTheme.normalGreen)),
                                    ),
                                  ),
                                ),

                                // Résolu par
                                Expanded(
                                  flex: 2, 
                                  child: Text(a["resolved_by"] ?? "—", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade700, fontSize: 14))
                                ),

                                // Date
                                Expanded(
                                  flex: 2, 
                                  child: Text(a["timestamp"]?.toString().split('T').first ?? "", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade500, fontSize: 13))
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmClearHistory(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Supprimer l'Historique ?", style: TextStyle(fontWeight: FontWeight.w900)),
        content: const Text("Cette action supprimera définitivement toutes les alertes résolues. Cette action est irréversible."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Annuler")),
          ElevatedButton(
            onPressed: () async {
              final success = await ApiService.clearAlertHistory();
              if (success) {
                Navigator.pop(ctx);
                _load();
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Historique supprimé !"), backgroundColor: AppTheme.sosRed));
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.sosRed),
            child: const Text("Confirmer la Suppression"),
          ),
        ],
      ),
    );
  }
}
