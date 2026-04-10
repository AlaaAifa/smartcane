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

  // Filter State
  String? _selectedType;
  DateTimeRange? _selectedRange;
  final TextEditingController _userSearchController = TextEditingController();
  String _userSearchQuery = "";

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
  void dispose() {
    _userSearchController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> _getFilteredHistory() {
    return alerts.where((alert) {
      // User Search Filter
      if (_userSearchQuery.isNotEmpty) {
        final user = usersDict[alert['user_id']];
        final fullName = user != null 
            ? "${user['prenom']} ${user['nom']}".toLowerCase() 
            : alert['user_id'].toString().toLowerCase();
        if (!fullName.contains(_userSearchQuery.toLowerCase())) return false;
      }
      if (_selectedType != null && alert['type'] != _selectedType) return false;
      
      // Date range filter
      if (_selectedRange != null) {
        final alertDateStr = alert['timestamp']?.toString().split('T').first;
        if (alertDateStr == null) return false;
        final alertDate = DateTime.tryParse(alertDateStr);
        if (alertDate == null) return false;
        
        final start = DateTime(_selectedRange!.start.year, _selectedRange!.start.month, _selectedRange!.start.day);
        final end = DateTime(_selectedRange!.end.year, _selectedRange!.end.month, _selectedRange!.end.day, 23, 59, 59);
        
        if (alertDate.isBefore(start) || alertDate.isAfter(end)) return false;
      }
      
      return true;
    }).toList();
  }

  Widget _buildFilterBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Row(
        children: [
          const Icon(Icons.filter_list, color: AppTheme.primary, size: 20),
          const SizedBox(width: 16),
          
          // User Search Bar
          Expanded(
            child: TextField(
              controller: _userSearchController,
              onChanged: (val) => setState(() => _userSearchQuery = val),
              decoration: InputDecoration(
                hintText: "Chercher un utilisateur...",
                hintStyle: const TextStyle(fontSize: 13, color: Colors.grey),
                prefixIcon: const Icon(Icons.search, size: 18, color: AppTheme.primary),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                suffixIcon: _userSearchQuery.isNotEmpty 
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 16),
                      onPressed: () {
                        _userSearchController.clear();
                        setState(() => _userSearchQuery = "");
                      },
                    )
                  : null,
              ),
              style: const TextStyle(fontSize: 13),
            ),
          ),
          
          const VerticalDivider(width: 32),

          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String?>(
                value: _selectedType,
                hint: const Text("Tous les Types", style: TextStyle(fontSize: 13)),
                isExpanded: true,
                items: const [
                  DropdownMenuItem(value: null, child: Text("Tous les Types", style: TextStyle(fontSize: 13))),
                  DropdownMenuItem(value: "SOS", child: Text("SOS Only", style: TextStyle(fontSize: 13, color: AppTheme.sosRed, fontWeight: FontWeight.bold))),
                  DropdownMenuItem(value: "HELP", child: Text("HELP Only", style: TextStyle(fontSize: 13, color: AppTheme.helpOrange, fontWeight: FontWeight.bold))),
                ],
                onChanged: (val) => setState(() => _selectedType = val),
              ),
            ),
          ),
          
          const VerticalDivider(width: 32),
          
          InkWell(
            onTap: () async {
              final picked = await showDateRangePicker(
                context: context,
                initialDateRange: _selectedRange,
                firstDate: DateTime(2023),
                lastDate: DateTime.now().add(const Duration(days: 1)),
                builder: (context, child) => Theme(
                  data: Theme.of(context).copyWith(
                    colorScheme: ColorScheme.light(primary: AppTheme.primary, onPrimary: Colors.white, surface: Colors.white, onSurface: AppTheme.primary),
                  ),
                  child: child!,
                ),
              );
              if (picked != null) setState(() => _selectedRange = picked);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: _selectedRange != null ? AppTheme.primary.withOpacity(0.1) : Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.date_range, size: 16, color: _selectedRange != null ? AppTheme.primary : Colors.grey),
                  const SizedBox(width: 8),
                  Text(
                    _selectedRange != null 
                      ? "${_selectedRange!.start.day}/${_selectedRange!.start.month} - ${_selectedRange!.end.day}/${_selectedRange!.end.month}" 
                      : "Période",
                    style: TextStyle(fontSize: 13, color: _selectedRange != null ? AppTheme.primary : Colors.grey.shade700, fontWeight: FontWeight.w600),
                  ),
                  if (_selectedRange != null) ...[
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => setState(() => _selectedRange = null),
                      child: const Icon(Icons.close, size: 14, color: AppTheme.sosRed),
                    ),
                  ],
                ],
              ),
            ),
          ),
          
          const VerticalDivider(width: 32),

          IconButton(
            onPressed: () => _exportToCSV(_getFilteredHistory()),
            icon: const Icon(Icons.file_download_outlined, color: AppTheme.primary),
            tooltip: "Générer Rapport CSV",
          ),
        ],
      ),
    );
  }

  void _exportToCSV(List<Map<String, dynamic>> filtered) {
    if (filtered.isEmpty) return;
    
    String csv = "ID Alerte,Utilisateur,Type,Statut,Date,Résolu Par\n";
    for (var a in filtered) {
      final user = usersDict[a['user_id']];
      final uName = user != null ? "${user['prenom']} ${user['nom']}" : a['user_id'];
      csv += "${a['alert_id']},$uName,${a['type']},${a['status']},${a['timestamp']},${a['resolved_by_name'] ?? '—'}\n";
    }

    print("CSV Historique Generé:\n$csv");
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Rapport CSV (Historique) généré avec succès !"), backgroundColor: AppTheme.normalGreen),
    );
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
                  Text("${_getFilteredHistory().length} alertes trouvées", style: TextStyle(color: Colors.grey.shade600)),
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
          _buildFilterBar(),

          Expanded(
            child: _getFilteredHistory().isEmpty
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Center(child: Icon(Icons.search_off_rounded, size: 80, color: Colors.grey.shade200)),
                    const SizedBox(height: 16),
                    Text("Aucun résultat ne correspond à vos critères", style: TextStyle(color: Colors.grey.shade400, fontSize: 16)),
                  ],
                )
              : SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SizedBox(
                    width: 1100, // Fixed width for horizontal scroll to resolve Expanded children constraint issues
                    child: Column(
                      children: [
                        // Table header
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withOpacity(0.08), 
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppTheme.primary.withOpacity(0.1)),
                          ),
                          child: Row(
                            children: [
                              const Expanded(flex: 2, child: Text("Utilisateur", textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: AppTheme.primary, letterSpacing: 0.5))),
                              const Expanded(flex: 1, child: Text("Type", textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: AppTheme.primary, letterSpacing: 0.5))),
                              const Expanded(flex: 1, child: Text("Statut", textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: AppTheme.primary, letterSpacing: 0.5))),
                              const Expanded(flex: 2, child: Text("Résolu par", textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: AppTheme.primary, letterSpacing: 0.5))),
                              const Expanded(flex: 2, child: Text("Date", textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: AppTheme.primary, letterSpacing: 0.5))),
                              const SizedBox(width: 120, child: Text("Actions", textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: AppTheme.primary))),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),

                        Expanded(
                          child: ListView.builder(
                            itemCount: _getFilteredHistory().length,
                            itemBuilder: (context, index) {
                              final a = _getFilteredHistory()[index];
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
                                          decoration: BoxDecoration(
                                            color: (a["status"] == "resolved" ? AppTheme.normalGreen : AppTheme.helpOrange).withOpacity(0.1), 
                                            borderRadius: BorderRadius.circular(8)
                                          ),
                                          child: Text(a["status"] == "resolved" ? "RÉSOLU" : "NON", 
                                            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 10, color: a["status"] == "resolved" ? AppTheme.normalGreen : AppTheme.helpOrange)),
                                        ),
                                      ),
                                    ),

                                    // Résolu par
                                    Expanded(
                                      flex: 2, 
                                      child: Text(a["resolved_by_name"] ?? a["resolved_by"] ?? "—", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade700, fontSize: 14))
                                    ),

                                    // Date
                                    Expanded(
                                      flex: 2, 
                                      child: Text(a["timestamp"]?.toString().split('T').first ?? "", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade500, fontSize: 13))
                                    ),

                                    // Actions
                                    SizedBox(
                                      width: 120,
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          // Reactivate (Original resolver OR Admin)
                                          if (ApiService.isAdmin || ApiService.staffId == a['resolved_by'])
                                            IconButton(
                                              icon: const Icon(Icons.refresh, color: AppTheme.primary, size: 20),
                                              onPressed: () => _confirmReactivate(context, a),
                                              tooltip: "Réactiver",
                                            ),
                                          
                                          // Delete (Admin only - remains for maintenance)
                                          if (ApiService.isAdmin)
                                            IconButton(
                                              icon: const Icon(Icons.delete_outline, color: AppTheme.sosRed, size: 20),
                                              onPressed: () => _confirmDeleteAlert(context, a["alert_id"]),
                                              tooltip: "Supprimer",
                                            ),
                                        ],
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
                  ),
                ),
          ),
        ],
      ),
    );
  }

  void _confirmReactivate(BuildContext context, Map<String, dynamic> alert) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Réactiver l'Alerte ?", style: TextStyle(fontWeight: FontWeight.w900)),
        content: const Text("Cette alerte sera renvoyée dans la section 'Alertes Live'. Un log de réactivation sera enregistré."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Annuler")),
          ElevatedButton(
            onPressed: () async {
              final success = await ApiService.reactivateAlert(alert['alert_id']);
              if (success) {
                Navigator.pop(ctx);
                _load();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Alerte réactivée avec succès !"), backgroundColor: AppTheme.primary)
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
            child: const Text("Confirmer"),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteAlert(BuildContext context, String? alertId) {
    if (alertId == null) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Supprimer cette Alerte ?", style: TextStyle(fontWeight: FontWeight.w900)),
        content: const Text("Cette action est irréversible."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Annuler")),
          ElevatedButton(
            onPressed: () async {
              final success = await ApiService.deleteAlert(alertId);
              if (success) {
                Navigator.pop(ctx);
                _load();
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Alerte supprimée !"), backgroundColor: AppTheme.sosRed));
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.sosRed),
            child: const Text("Supprimer"),
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
