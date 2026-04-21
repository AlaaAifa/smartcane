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

  // Filter states
  final TextEditingController _searchController = TextEditingController();
  String _searchUser = "";
  String _selectedType = "Tous";
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    _load();
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Historique des alertes", style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 4),
                  Text("${displayAlerts.length} alertes filtrées / ${alerts.length} au total", style: TextStyle(color: Colors.grey.shade600)),
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
          _buildFiltersUI(),
          const SizedBox(height: 24),
          Expanded(
            child: displayAlerts.isEmpty
                ? Center(child: Text("Aucune alerte correspondante", style: TextStyle(color: Colors.grey.shade500)))
                : ListView.builder(
                    itemCount: displayAlerts.length,
                    itemBuilder: (context, index) {
                      final alert = displayAlerts[index];
                      final isSOS = alert["type"] == "SOS";
                      final color = isSOS ? AppTheme.sosRed : AppTheme.helpOrange;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 2))
                          ],
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
                                tooltip: "Réactiver",
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
                                tooltip: "Supprimer",
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
}
