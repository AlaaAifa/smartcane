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

  // Filter states
  final TextEditingController _searchController = TextEditingController();
  String _searchUser = "";
  String _selectedType = "Tous";
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    _loadData();
    _searchController.addListener(() {
      setState(() {
        _searchUser = _searchController.text;
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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

  List<Map<String, dynamic>> get filteredAlerts {
    return alerts.where((alert) {
      // 1. Filter by User Name
      final name = _userName(alert["user_id"]?.toString()).toLowerCase();
      if (_searchUser.isNotEmpty && !name.contains(_searchUser.toLowerCase())) {
        return false;
      }

      // 2. Filter by Type
      if (_selectedType != "Tous" && alert["type"] != _selectedType) {
        return false;
      }

      // 3. Filter by Date
      if (_startDate != null || _endDate != null) {
        final tsStr = alert["timestamp"]?.toString() ?? "";
        try {
          final ts = DateTime.parse(tsStr);
          // Compare only dates (ignoring time) if needed, but here we'll use exact time comparison
          // Actually user usually wants inclusive date range
          if (_startDate != null && ts.isBefore(_startDate!)) {
            return false;
          }
          if (_endDate != null && ts.isAfter(_endDate!.add(const Duration(days: 1)))) {
            return false;
          }
        } catch (_) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  void _resetFilters() {
    setState(() {
      _searchController.clear();
      _searchUser = "";
      _selectedType = "Tous";
      _startDate = null;
      _endDate = null;
    });
  }

  Future<void> _selectDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: (_startDate != null && _endDate != null)
          ? DateTimeRange(start: _startDate!, end: _endDate!)
          : null,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppTheme.primary,
              onPrimary: Colors.white,
              onSurface: Colors.black87,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
    }
  }

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

    final displayAlerts = filteredAlerts;

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
                child: Text("${displayAlerts.length} actives", style: const TextStyle(color: AppTheme.sosRed, fontWeight: FontWeight.w700)),
              ),
              const Spacer(),
              IconButton(onPressed: _loadData, icon: const Icon(Icons.refresh)),
            ],
          ),
          const SizedBox(height: 24),
          _buildFiltersUI(),
          const SizedBox(height: 24),
          Expanded(
            child: displayAlerts.isEmpty
                ? Center(child: Text("Aucune alerte correspondante", style: TextStyle(color: Colors.grey.shade500)))
                : ListView.builder(
                    itemCount: displayAlerts.length,
                    itemBuilder: (context, index) => _buildAlertCard(displayAlerts[index]),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFiltersUI() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          // User search
          Expanded(
            flex: 3,
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: "Rechercher un utilisateur...",
                prefixIcon: const Icon(Icons.search, size: 20),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                filled: true,
                fillColor: Colors.grey.shade50,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Type filter
          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedType,
                  isExpanded: true,
                  icon: const Icon(Icons.filter_list, size: 20),
                  items: ["Tous", "SOS", "HELP"].map((type) {
                    return DropdownMenuItem(value: type, child: Text(type));
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedType = val);
                  },
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Date range filter
          Expanded(
            flex: 3,
            child: InkWell(
              onTap: _selectDateRange,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today, size: 18, color: Colors.grey),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        (_startDate != null && _endDate != null)
                            ? "${_startDate!.day}/${_startDate!.month} - ${_endDate!.day}/${_endDate!.month}"
                            : "Choisir une période",
                        style: const TextStyle(fontSize: 13),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (_startDate != null)
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _startDate = null;
                            _endDate = null;
                          });
                        },
                        child: const Icon(Icons.close, size: 16, color: Colors.grey),
                      ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Reset button
          IconButton(
            onPressed: _resetFilters,
            icon: const Icon(Icons.restart_alt),
            tooltip: "Réinitialiser les filtres",
            color: AppTheme.primary,
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
