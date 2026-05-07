import 'package:flutter/material.dart';
import 'dart:async';
import '../theme.dart';
import '../../services/services.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  Map<String, Map<String, dynamic>> usersDict = {};
  bool _isLoading = true;
  Timer? _refreshTimer;

  // Filter states
  final TextEditingController _searchController = TextEditingController();
  String _searchUser = "";
  String _selectedType = "Tous";
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    _loadUsers();
    _searchController.addListener(() {
      setState(() {
        _searchUser = _searchController.text;
      });
    });
    // Refresh UI every minute to update reactivation availability
    _refreshTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadUsers() async {
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
      usersDict = tempDict;
      _isLoading = false;
    });
  }

  String _userName(String? cin) => usersDict[cin]?["nom"]?.toString() ?? cin ?? "Inconnu";

  List<Map<String, dynamic>> _filterAlerts(List<Map<String, dynamic>> alerts) {
    return alerts.where((alert) {
      // 1. Filter by User Name
      final cin = alert["user_id"]?.toString();
      final embeddedName = alert["user_name"]?.toString().toLowerCase() ?? "";
      final dictName = usersDict[cin]?["nom"]?.toString().toLowerCase() ?? "";
      final searchUserLower = _searchUser.toLowerCase();

      if (searchUserLower.isNotEmpty) {
        bool matches = false;
        if (embeddedName.contains(searchUserLower)) matches = true;
        if (dictName.contains(searchUserLower)) matches = true;
        if (cin != null && cin.toLowerCase().contains(searchUserLower)) matches = true;
        
        if (!matches) return false;
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

  bool _isReactivationAllowed(String? timestamp) {
    if (timestamp == null) return false;
    try {
      final resolvedTime = DateTime.parse(timestamp);
      final now = DateTime.now();
      return now.difference(resolvedTime).inMinutes < 5;
    } catch (_) {
      return false;
    }
  }

  int _minutesRemaining(String? timestamp) {
    if (timestamp == null) return 0;
    try {
      final resolvedTime = DateTime.parse(timestamp);
      final now = DateTime.now();
      final diff = 5 - now.difference(resolvedTime).inMinutes;
      return diff > 0 ? diff : 0;
    } catch (_) {
      return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: AlertService.getHistoryStream(),
      builder: (context, snapshot) {
        final allHistory = snapshot.data ?? [];
        final displayAlerts = _filterAlerts(allHistory);

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
                      Text("${displayAlerts.length} alertes filtrées / ${allHistory.length} au total", style: TextStyle(color: Colors.grey.shade600)),
                    ],
                  ),
                  Row(
                    children: [
                      if (snapshot.connectionState == ConnectionState.waiting)
                        const Padding(
                          padding: EdgeInsets.only(right: 16),
                          child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                        ),
                      if (BaseService.isAdmin)
                        ElevatedButton.icon(
                          onPressed: () async {
                            final success = await AlertService.clearAlertHistory();
                            if (success && mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text("Historique vidé avec succès")),
                              );
                            }
                          },
                          icon: const Icon(Icons.delete_sweep_rounded),
                          label: const Text("Vider"),
                          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.sosRed),
                        ),
                    ],
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
                          final allowed = _isReactivationAllowed(alert["timestamp"]);
                          final remaining = _minutesRemaining(alert["timestamp"]);
                          
                          // Nouvelle règle : Seul celui qui a résolu l'alerte peut la réactiver
                          final String currentStaff = (BaseService.staffName ?? "Staff").trim().toLowerCase();
                          final String resolverStaff = (alert["resolved_by"] ?? "Staff").toString().trim().toLowerCase();
                          
                          final bool isResolver = currentStaff == resolverStaff;
                          final bool isAdmin = BaseService.isAdmin; // Les admins peuvent tout réactiver
                          
                          final bool canReactivate = allowed && (isResolver || isAdmin);
                          
                          // Debug (visible dans la console VS Code)
                          if (allowed) {
                            print("DEBUG: Alerte ${alert['alert_id']} - Resolver: '$resolverStaff', Current: '$currentStaff', Match: $isResolver");
                          }

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
                                Expanded(
                                  flex: 2,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        alert["user_name"]?.toString() ?? _userName(alert["user_id"]?.toString()),
                                        style: const TextStyle(fontWeight: FontWeight.w700),
                                      ),
                                      Text(
                                        "Position: ${alert['latitude']}, ${alert['longitude']}",
                                        style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
                                      ),
                                    ],
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "Résolu par: ${alert["resolved_by"]?.toString() ?? "-"}",
                                        style: TextStyle(color: Colors.grey.shade700, fontSize: 13, fontWeight: FontWeight.bold),
                                      ),
                                      Text(
                                        "Réponse: ${alert["response_time"]?.toString() ?? "-"}",
                                        style: TextStyle(color: AppTheme.normalGreen, fontSize: 11, fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(alert["timestamp"]?.toString() ?? "", style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                                      // --- Diagnostic Visuel ---
                                      if (allowed && !isResolver && !isAdmin)
                                        const Text("🔒 Résolu par un autre staff", style: TextStyle(color: Colors.orange, fontSize: 10, fontWeight: FontWeight.bold)),
                                      if (!allowed)
                                        const Text("⌛ Temps de réactivation expiré (>5min)", style: TextStyle(color: Colors.grey, fontSize: 10)),
                                      if (canReactivate)
                                        const Text("🔓 Réactivation possible", style: TextStyle(color: Colors.green, fontSize: 10, fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                ),
                                if (canReactivate)
                                  IconButton(
                                    onPressed: () async {
                                      final bool? confirmed = await showDialog<bool>(
                                        context: context,
                                        builder: (ctx) => AlertDialog(
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                          title: const Row(
                                            children: [
                                              Icon(Icons.refresh, color: AppTheme.primary),
                                              SizedBox(width: 12),
                                              Text("Confirmer la réactivation"),
                                            ],
                                          ),
                                          content: const Text("Êtes-vous sûr de vouloir réactiver cette alerte ? Elle retournera dans les Alertes Live."),
                                          actions: [
                                            TextButton(
                                              onPressed: () => Navigator.pop(ctx, false),
                                              child: Text("ANNULER", style: TextStyle(color: Colors.grey.shade600)),
                                            ),
                                            ElevatedButton(
                                              onPressed: () => Navigator.pop(ctx, true),
                                              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
                                              child: const Text("CONFIRMER"),
                                            ),
                                          ],
                                        ),
                                      );

                                      if (confirmed == true) {
                                        final success = await AlertService.reactivateAlert(
                                          alert["alert_id"].toString(),
                                          firebaseKey: alert["firebase_key"],
                                        );
                                        if (success && mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(
                                              content: Text("Alerte réactivée avec succès"),
                                              backgroundColor: AppTheme.primary,
                                            ),
                                          );
                                        }
                                      }
                                    },
                                    icon: const Icon(Icons.refresh, color: AppTheme.primary),
                                    tooltip: "Réactiver",
                                  ),
                                if (BaseService.isAdmin)
                                  IconButton(
                                    onPressed: () async {
                                      final bool? confirmed = await showDialog<bool>(
                                        context: context,
                                        builder: (ctx) => AlertDialog(
                                          title: const Text("Supprimer l'alerte"),
                                          content: const Text("Voulez-vous vraiment supprimer définitivement cette alerte de l'historique ?"),
                                          actions: [
                                            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("NON")),
                                            TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("OUI")),
                                          ],
                                        ),
                                      );
                                      if (confirmed == true) {
                                        final success = await AlertService.deleteAlert(
                                          alert["alert_id"].toString(),
                                          firebaseKey: alert["firebase_key"],
                                        );
                                        if (success && mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(content: Text("Alerte supprimée")),
                                          );
                                        }
                                      }
                                    },
                                    icon: const Icon(Icons.delete_outline, color: AppTheme.sosRed),
                                    tooltip: "Supprimer",
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
      },
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
