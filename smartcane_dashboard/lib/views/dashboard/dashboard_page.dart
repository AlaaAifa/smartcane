import 'package:flutter/material.dart';
import '../theme.dart';
import '../../services/services.dart';

class DashboardPage extends StatefulWidget {
  final Function(String) onNavigate;
  const DashboardPage({super.key, required this.onNavigate});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  Map<String, dynamic> stats = {};
  List<Map<String, dynamic>> users = [];
  List<Map<String, dynamic>> activeRentals = [];
  List<Map<String, dynamic>> activeAlerts = [];
  List<Map<String, dynamic>> historyAlerts = [];
  bool _isLoading = true;
  String _selectedFilter = "tous";

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final s = await DashboardService.getStats();
    final u = await UserService.getUsers();
    final r = await RentalService.getActiveRentals();
    final a = await AlertService.getActiveAlerts();
    final h = await AlertService.getAlertsHistory();

    if (!mounted) {
      return;
    }

    setState(() {
      stats = s;
      users = u.where((user) => user["role"] == "client").toList();
      activeRentals = r;
      activeAlerts = a;
      historyAlerts = h;
      _isLoading = false;
    });
  }

  Set<String> get _renterIds => activeRentals
      .where((rental) => rental["date_de_retour"] == null)
      .map((rental) => rental["cin_utilisateur"]?.toString() ?? "")
      .where((cin) => cin.isNotEmpty)
      .toSet();

  List<Map<String, dynamic>> get _subscribers =>
      users.where((user) => !_renterIds.contains(user["cin"]?.toString() ?? "")).toList();

  List<Map<String, dynamic>> get _renters =>
      users.where((user) => _renterIds.contains(user["cin"]?.toString() ?? "")).toList();

  List<Map<String, dynamic>> get _filteredUsers {
    switch (_selectedFilter) {
      case "abonnes":
        return _subscribers;
      case "loueurs":
        return _renters;
      default:
        return users;
    }
  }

  String _displayName(Map<String, dynamic> user) => (user["nom"]?.toString().trim().isNotEmpty ?? false)
      ? user["nom"].toString()
      : (user["cin"]?.toString() ?? "Utilisateur");

  int _activeAlertCountForUser(String cin) =>
      activeAlerts.where((alert) => alert["user_id"]?.toString() == cin).length;

  int _historyAlertCountForUser(String cin) =>
      historyAlerts.where((alert) => alert["user_id"]?.toString() == cin).length;

  void _showUserDetails(Map<String, dynamic> user) {
    final cin = user["cin"]?.toString() ?? "";
    final isRenter = _renterIds.contains(cin);
    final userRentals =
        activeRentals.where((rental) => rental["cin_utilisateur"]?.toString() == cin).toList();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(_displayName(user), style: const TextStyle(fontWeight: FontWeight.w900)),
        content: SizedBox(
          width: 560,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _detailRow("CIN", cin),
              _detailRow("Email", user["email"]?.toString() ?? "N/A"),
              _detailRow("Telephone", user["numero_de_telephone"]?.toString() ?? "N/A"),
              _detailRow("Contact familial", user["contact_familial"]?.toString() ?? "N/A"),
              _detailRow("Age", user["age"]?.toString() ?? "N/A"),
              _detailRow("Adresse", user["adresse"]?.toString() ?? "N/A"),
              _detailRow("Etat de sante", user["etat_de_sante"]?.toString() ?? "N/A"),
              _detailRow("SIM associee", user["sim_de_la_canne"]?.toString() ?? "N/A"),
              _detailRow("Statut", isRenter ? "Location" : "Abonnement/Vente"),
              if (userRentals.isNotEmpty)
                _detailRow(
                  "Retour prevu",
                  userRentals.first["date_de_retour"]?.toString() ?? "Non defini",
                ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Fermer")),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(label, style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.w600)),
          ),
          Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Vue d'ensemble, ${BaseService.staffName ?? 'Staff'}",
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 4),
            Text(
              "Suivi des clients, locations et alertes selon le backend courant",
              style: TextStyle(color: Colors.grey.shade600, fontSize: 15),
            ),
            const SizedBox(height: 32),
            Row(
              children: [
                _statCard("Clients", users.length.toString(), Icons.people_alt_rounded, AppTheme.primary),
                const SizedBox(width: 24),
                _statCard("Locations actives", _renters.length.toString(), Icons.vpn_key_rounded, AppTheme.normalGreen),
                const SizedBox(width: 24),
                _statCard("Alertes actives", activeAlerts.length.toString(), Icons.notification_important_rounded, AppTheme.sosRed),
              ],
            ),
            const SizedBox(height: 40),
            Wrap(
              spacing: 12,
              children: [
                _filterChip("Tous", "tous"),
                _filterChip("Abonnes", "abonnes"),
                _filterChip("Loueurs", "loueurs"),
              ],
            ),
            const SizedBox(height: 20),
            if (_filteredUsers.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(40),
                  child: Text("Aucun utilisateur a afficher", style: TextStyle(color: Colors.grey.shade500)),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _filteredUsers.length,
                itemBuilder: (context, index) => _buildUserCard(_filteredUsers[index]),
              ),
          ],
        ),
      ),
    );
  }

  Widget _filterChip(String label, String value) {
    final isSelected = _selectedFilter == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => setState(() => _selectedFilter = value),
      selectedColor: AppTheme.primary.withOpacity(0.15),
      labelStyle: TextStyle(
        color: isSelected ? AppTheme.primary : Colors.grey.shade700,
        fontWeight: FontWeight.w700,
      ),
    );
  }

  Widget _buildUserCard(Map<String, dynamic> user) {
    final cin = user["cin"]?.toString() ?? "";
    final isRenter = _renterIds.contains(cin);
    final activeCount = _activeAlertCountForUser(cin);
    final historyCount = _historyAlertCountForUser(cin);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: AppTheme.primary.withOpacity(0.1),
            child: Text(
              _displayName(user).isNotEmpty ? _displayName(user)[0].toUpperCase() : "?",
              style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primary),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_displayName(user), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
                const SizedBox(height: 4),
                Text(user["email"]?.toString() ?? "Aucun email", style: TextStyle(color: Colors.grey.shade600)),
                const SizedBox(height: 6),
                Text(
                  isRenter ? "Location en cours" : "Client sans location active",
                  style: TextStyle(
                    color: isRenter ? AppTheme.normalGreen : AppTheme.primary,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          _miniStat(activeCount.toString(), "Actives", AppTheme.sosRed),
          const SizedBox(width: 20),
          _miniStat(historyCount.toString(), "Resolues", Colors.blueGrey),
          const SizedBox(width: 24),
          ElevatedButton(
            onPressed: () => _showUserDetails(user),
            child: const Text("Profil", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _miniStat(String value, String label, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: color)),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 11)),
      ],
    );
  }

  Widget _statCard(String label, String total, IconData icon, Color color) {
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
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 18),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(total, style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900, color: color)),
                Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
