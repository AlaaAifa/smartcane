import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme.dart';
import '../../services/services.dart';

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

  Future<void> _loadData() async {
    final alertData = await AlertService.getActiveAlerts();
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
      alerts = alertData;
      usersDict = tempDict;
      _isLoading = false;
    });
  }

  String _userName(String? cin) => usersDict[cin]?["nom"]?.toString() ?? cin ?? "Inconnu";

  Future<void> _callNumber(String? number) async {
    if (number == null || number.isEmpty) {
      return;
    }
    final url = Uri.parse("tel:$number");
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }

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
            children: [
              const Text("Alertes Live", style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900)),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: AppTheme.sosRed.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                child: Text("${alerts.length} actives", style: const TextStyle(color: AppTheme.sosRed, fontWeight: FontWeight.w700)),
              ),
              const Spacer(),
              IconButton(onPressed: _loadData, icon: const Icon(Icons.refresh)),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: alerts.isEmpty
                ? Center(child: Text("Aucune alerte active", style: TextStyle(color: Colors.grey.shade500)))
                : ListView.builder(
                    itemCount: alerts.length,
                    itemBuilder: (context, index) => _buildAlertCard(alerts[index]),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlertCard(Map<String, dynamic> alert) {
    final isSOS = alert["type"] == "SOS";
    final color = isSOS ? AppTheme.sosRed : AppTheme.helpOrange;
    final cin = alert["user_id"]?.toString();
    final user = usersDict[cin];

    return GestureDetector(
      onTap: () => _showAlertDetails(alert, user),
      child: Container(
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
                  Text(alert["type"]?.toString() ?? "", style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: color)),
                  const SizedBox(height: 4),
                  Text(_userName(cin), style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text(
                    "Position: ${alert['latitude']}, ${alert['longitude']}",
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                  ),
                ],
              ),
            ),
            Text(alert["timestamp"]?.toString() ?? "", style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  void _showAlertDetails(Map<String, dynamic> alert, Map<String, dynamic>? user) {
    final isSOS = alert["type"] == "SOS";
    final color = isSOS ? AppTheme.sosRed : AppTheme.helpOrange;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: EdgeInsets.zero,
        content: SizedBox(
          width: 600,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.notification_important, color: Colors.white),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text("Alerte ${alert['type']}", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 20)),
                    ),
                    IconButton(onPressed: () => Navigator.pop(ctx), icon: const Icon(Icons.close, color: Colors.white)),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _detail("Utilisateur", _userName(alert["user_id"]?.toString())),
                    _detail("CIN", alert["user_id"]?.toString() ?? "N/A"),
                    _detail("Email", user?["email"]?.toString() ?? "N/A"),
                    _detail("Telephone", user?["numero_de_telephone"]?.toString() ?? "N/A"),
                    _detail("Contact familial", user?["contact_familial"]?.toString() ?? "N/A"),
                    _detail("Etat de sante", user?["etat_de_sante"]?.toString() ?? "N/A"),
                    _detail("Coordonnees", "${alert['latitude']}, ${alert['longitude']}"),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.pop(ctx);
                              widget.onNavigate?.call(
                                "/map?lat=${alert['latitude']}&lon=${alert['longitude']}&type=${alert['type']}",
                              );
                            },
                            icon: const Icon(Icons.map),
                            label: const Text("Localiser"),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _callNumber(user?["numero_de_telephone"]?.toString()),
                            icon: const Icon(Icons.phone),
                            label: const Text("Appeler"),
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              final success = await AlertService.resolveAlert(alert["alert_id"].toString());
                              if (!mounted) {
                                return;
                              }
                              if (success) {
                                Navigator.pop(ctx);
                                _loadData();
                              }
                            },
                            icon: const Icon(Icons.check_circle),
                            label: const Text("Resoudre"),
                            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.normalGreen),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              final success = await AlertService.releaseAlert(alert["alert_id"].toString());
                              if (!mounted) {
                                return;
                              }
                              if (success) {
                                Navigator.pop(ctx);
                                _loadData();
                              }
                            },
                            icon: const Icon(Icons.undo),
                            label: const Text("Liberer"),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _detail(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 140, child: Text(label, style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.w700))),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
