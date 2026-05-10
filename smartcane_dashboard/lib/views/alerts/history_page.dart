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
              surface: Colors.white,
              onSurface: AppTheme.primary,
              secondary: AppTheme.accent,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: AppTheme.primary,
                textStyle: const TextStyle(fontWeight: FontWeight.bold),
              ),
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
      return const Center(child: CircularProgressIndicator(color: AppTheme.primary));
    }

    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: AlertService.getHistoryStream(),
      builder: (context, snapshot) {
        final allHistory = snapshot.data ?? [];
        final displayAlerts = _filterAlerts(allHistory);

        return Padding(
          padding: const EdgeInsets.all(48),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Archive des Alertes", style: Theme.of(context).textTheme.headlineMedium),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(color: AppTheme.primary.withOpacity(0.08), borderRadius: BorderRadius.circular(8)),
                        child: Text("${displayAlerts.length} RÉSULTATS FILTRÉS / ${allHistory.length} TOTAL", style: const TextStyle(color: AppTheme.primary, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1)),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      if (snapshot.connectionState == ConnectionState.waiting)
                        const Padding(
                          padding: EdgeInsets.only(right: 16),
                          child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primary)),
                        ),
                      if (BaseService.isAdmin)
                        AppGradientButton(
                          onTap: () async {
                            final success = await AlertService.clearAlertHistory();
                            if (success && mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text("Historique vidé avec succès"), backgroundColor: AppTheme.sosRed),
                              );
                            }
                          },
                          icon: Icons.delete_sweep_rounded,
                          label: "PURGER L'HISTORIQUE",
                          color: AppTheme.sosRed,
                        ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 48),
              _buildFiltersUI(),
              const SizedBox(height: 32),
              Expanded(
                child: displayAlerts.isEmpty
                    ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.history_rounded, size: 64, color: Colors.grey.withOpacity(0.2)), const SizedBox(height: 16), Text("Aucune alerte trouvée pour ces critères", style: TextStyle(color: Colors.grey.shade500, fontWeight: FontWeight.w600))]))
                    : ListView.builder(
                        itemCount: displayAlerts.length,
                        itemBuilder: (context, index) {
                          final alert = displayAlerts[index];
                          final isSOS = alert["type"] == "SOS";
                          final color = isSOS ? AppTheme.sosRed : AppTheme.accent;
                          final allowed = _isReactivationAllowed(alert["timestamp"]);
                          
                          final String currentStaff = (BaseService.staffName ?? "Staff").trim().toLowerCase();
                          final String resolverStaff = (alert["resolved_by"] ?? "Staff").toString().trim().toLowerCase();
                          final bool isResolver = currentStaff == resolverStaff;
                          final bool isAdmin = BaseService.isAdmin;
                          final bool canReactivate = allowed && (isResolver || isAdmin);

                          return Container(
                            margin: const EdgeInsets.only(bottom: 20),
                            padding: const EdgeInsets.all(24),
                            decoration: AppTheme.glassCard(),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  decoration: BoxDecoration(color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(10), border: Border.all(color: color.withOpacity(0.1))),
                                  child: Text(alert["type"]?.toString() ?? "", style: TextStyle(color: color, fontWeight: FontWeight.w900, letterSpacing: 1, fontSize: 13)),
                                ),
                                const SizedBox(width: 32),
                                Expanded(
                                  flex: 3,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(alert["user_name"]?.toString() ?? _userName(alert["user_id"]?.toString()), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17, color: AppTheme.primary)),
                                      const SizedBox(height: 6),
                                      Row(
                                        children: [
                                          const Icon(Icons.location_on_rounded, size: 14, color: Color(0xFF94A3B8)),
                                          const SizedBox(width: 6),
                                          Text("${alert['latitude']}, ${alert['longitude']}", style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12, fontWeight: FontWeight.w600)),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                Expanded(
                                  flex: 3,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          const Icon(Icons.verified_user_rounded, size: 16, color: Color(0xFF64748B)),
                                          const SizedBox(width: 8),
                                          Text(alert["resolved_by"]?.toString() ?? "-", style: const TextStyle(color: AppTheme.primary, fontSize: 14, fontWeight: FontWeight.w800)),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Row(
                                        children: [
                                          const Icon(Icons.timer_rounded, size: 16, color: AppTheme.neonGreen),
                                          const SizedBox(width: 8),
                                          Text("RÉPONSE: ${alert["response_time"]?.toString() ?? "-"}", style: const TextStyle(color: AppTheme.neonGreen, fontSize: 12, fontWeight: FontWeight.w900)),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(alert["timestamp"]?.toString() ?? "", style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12, fontWeight: FontWeight.w600)),
                                      const SizedBox(height: 8),
                                      if (allowed && !isResolver && !isAdmin)
                                        const Text("🔒 AGENT DIFFÉRENT", style: TextStyle(color: AppTheme.accent, fontSize: 10, fontWeight: FontWeight.w900)),
                                      if (!allowed)
                                        const Text("• ARCHIVÉ", style: TextStyle(color: Color(0xFFCBD5E1), fontSize: 10, fontWeight: FontWeight.w900)),
                                      if (canReactivate)
                                        const Text("🔓 DISPONIBLE POUR RÉACTIVATION", style: TextStyle(color: AppTheme.neonGreen, fontSize: 10, fontWeight: FontWeight.w900)),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 24),
                                if (canReactivate)
                                  IconButton(
                                    onPressed: () async {
                                      final bool? confirmed = await showDialog<bool>(
                                        context: context,
                                        builder: (ctx) => AlertDialog(
                                          backgroundColor: Colors.white,
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                                          title: const Row(children: [Icon(Icons.refresh_rounded, color: AppTheme.primary, size: 28), SizedBox(width: 16), Text("RÉACTIVATION", style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w900))]),
                                          content: const Text("Voulez-vous réactiver cette alerte ? Elle retournera dans le flux de surveillance actif."),
                                          actions: [
                                            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("ANNULER", style: TextStyle(color: Color(0xFF94A3B8), fontWeight: FontWeight.bold))),
                                            AppGradientButton(onTap: () => Navigator.pop(ctx, true), icon: Icons.check_circle_rounded, label: "RÉACTIVER", color: AppTheme.primary),
                                          ],
                                        ),
                                      );
                                      if (confirmed == true) {
                                        final success = await AlertService.reactivateAlert(alert["alert_id"].toString(), firebaseKey: alert["firebase_key"]);
                                        if (success && mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Alerte réactivée avec succès"), backgroundColor: AppTheme.primary));
                                      }
                                    },
                                    icon: const Icon(Icons.refresh_rounded, color: AppTheme.primary),
                                    tooltip: "Réactiver",
                                  ),
                                if (BaseService.isAdmin)
                                  IconButton(
                                    onPressed: () async {
                                      final bool? confirmed = await showDialog<bool>(
                                        context: context,
                                        builder: (ctx) => AlertDialog(
                                          backgroundColor: Colors.white,
                                          title: const Text("Supprimer l'alerte"),
                                          content: const Text("Voulez-vous vraiment supprimer définitivement cette alerte ?"),
                                          actions: [
                                            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("NON")),
                                            TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("OUI")),
                                          ],
                                        ),
                                      );
                                      if (confirmed == true) {
                                        final success = await AlertService.deleteAlert(alert["alert_id"].toString(), firebaseKey: alert["firebase_key"]);
                                        if (success && mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Alerte supprimée")));
                                      }
                                    },
                                    icon: const Icon(Icons.delete_outline_rounded, color: AppTheme.sosRed),
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
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 20, offset: const Offset(0, 4))],
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: TextField(
              controller: _searchController,
              style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w600),
              decoration: AppTheme.inputDecoration("Rechercher un client...", Icons.search_rounded),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.withOpacity(0.1)),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedType,
                  isExpanded: true,
                  dropdownColor: Colors.white,
                  icon: const Icon(Icons.filter_list_rounded, size: 20, color: AppTheme.primary),
                  style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w700),
                  items: ["Tous", "SOS", "HELP"].map((type) => DropdownMenuItem(value: type, child: Text(type))).toList(),
                  onChanged: (val) => val != null ? setState(() => _selectedType = val) : null,
                ),
              ),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            flex: 3,
            child: InkWell(
              onTap: _selectDateRange,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.withOpacity(0.1)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today_rounded, size: 18, color: AppTheme.primary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        (_startDate != null && _endDate != null)
                            ? "${_startDate!.day}/${_startDate!.month} - ${_endDate!.day}/${_endDate!.month}"
                            : "Période temporelle...",
                        style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w700, fontSize: 13),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (_startDate != null)
                      GestureDetector(
                        onTap: () => setState(() { _startDate = null; _endDate = null; }),
                        child: const Icon(Icons.close_rounded, size: 16, color: Color(0xFF94A3B8)),
                      ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 20),
          Container(
            decoration: BoxDecoration(color: AppTheme.primary.withOpacity(0.05), borderRadius: BorderRadius.circular(12)),
            child: IconButton(
              onPressed: _resetFilters,
              icon: const Icon(Icons.restart_alt_rounded),
              tooltip: "Réinitialiser",
              color: AppTheme.primary,
            ),
          ),
        ],
      ),
    );
  }
}
