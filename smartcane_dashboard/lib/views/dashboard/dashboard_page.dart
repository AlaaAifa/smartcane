import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
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
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Informations", style: TextStyle(fontSize: 14, color: Colors.grey, fontWeight: FontWeight.normal)),
                Text(_displayName(user), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 22)),
              ],
            ),
            IconButton(
              icon: const Icon(Icons.edit, color: AppTheme.primary),
              onPressed: () {
                Navigator.pop(ctx);
                _editUser(user);
              },
            ),
          ],
        ),
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
              _detailRow("Etat de sante", AppTheme.formatHealthInfo(user["etat_de_sante"]?.toString())),
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

  void _editUser(Map<String, dynamic> user) {
    final cin = user["cin"]?.toString() ?? "";
    final nomController = TextEditingController(text: user["nom"]?.toString() ?? "");
    final emailController = TextEditingController(text: user["email"]?.toString() ?? "");
    final phoneController = TextEditingController(text: _normalizePhoneDigits(user["numero_de_telephone"]?.toString() ?? ""));
    final contactController = TextEditingController(text: _normalizePhoneDigits(user["contact_familial"]?.toString() ?? ""));
    final ageController = TextEditingController(text: user["age"]?.toString() ?? "");
    final adresseController = TextEditingController(text: user["adresse"]?.toString() ?? "");
    final simController = TextEditingController(text: _normalizePhoneDigits(user["sim_de_la_canne"]?.toString() ?? ""));

    // Parse medical data
    Map<String, dynamic> medicalData = {};
    try {
      String rawHealth = user["etat_de_sante"]?.toString() ?? "";
      if (rawHealth.startsWith('{')) {
        medicalData = jsonDecode(rawHealth);
      } else {
        medicalData = {"observations": rawHealth};
      }
    } catch (e) {
      medicalData = {"observations": user["etat_de_sante"]?.toString() ?? ""};
    }

    final List<String> availablePathologies = [
      "Diabète", "Hypertension", "Maladie cardiaque", "Épilepsie", 
      "Troubles de l’équilibre / Vertiges", "Difficulté de mobilité", 
      "Baisse auditive", "Allergies médicamenteuses", 
      "Aucune pathologie connue", "Autre"
    ];

    Map<String, bool> pathologies = {
      for (var p in availablePathologies) p: (medicalData["pathologies"] as List?)?.contains(p) ?? false
    };
    
    final allergyCtrl = TextEditingController(text: medicalData["allergie_detail"]?.toString() ?? "");
    final otherCtrl = TextEditingController(text: medicalData["autre_detail"]?.toString() ?? "");
    final obsCtrl = TextEditingController(text: medicalData["observations"]?.toString() ?? "");
    String bloodGroup = medicalData["groupe_sanguin"]?.toString() ?? "Inconnu";
    final List<String> bloodGroups = ["A+", "A-", "B+", "B-", "AB+", "AB-", "O+", "O-", "Inconnu"];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text("Modifier ${_displayName(user)}", style: const TextStyle(fontWeight: FontWeight.w900)),
          content: SizedBox(
            width: 600,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Informations Générales", style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primary)),
                  const SizedBox(height: 16),
                  _buildEditField("Nom", nomController),
                  _buildEditField("Email", emailController),
                  _buildEditField("Telephone", phoneController, isPhone: true),
                  _buildEditField("Contact familial", contactController, isPhone: true),
                  Row(
                    children: [
                      Expanded(child: _buildEditField("Age", ageController, isNumber: true)),
                      const SizedBox(width: 16),
                      Expanded(child: _buildEditField("SIM associee", simController, isPhone: true)),
                    ],
                  ),
                  _buildEditField("Adresse", adresseController),
                  
                  const Divider(height: 32),
                  const Text("Informations Médicales", style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primary)),
                  const SizedBox(height: 16),
                  
                  const Text("Pathologies :", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: availablePathologies.map((p) => FilterChip(
                      label: Text(p, style: const TextStyle(fontSize: 12)),
                      selected: pathologies[p]!,
                      onSelected: (val) => setDialogState(() {
                        if (p == "Aucune pathologie connue" && val) {
                          pathologies.updateAll((key, value) => false);
                        } else if (val) {
                          pathologies["Aucune pathologie connue"] = false;
                        }
                        pathologies[p] = val;
                      }),
                    )).toList(),
                  ),
                  if (pathologies["Allergies médicamenteuses"]!) ...[
                    const SizedBox(height: 12),
                    _buildEditField("Préciser le(s) médicament(s)", allergyCtrl),
                  ],
                  if (pathologies["Autre"]!) ...[
                    const SizedBox(height: 12),
                    _buildEditField("Préciser l'autre pathologie", otherCtrl),
                  ],
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Text("Groupe sanguin : ", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                      const SizedBox(width: 12),
                      DropdownButton<String>(
                        value: bloodGroup,
                        items: bloodGroups.map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
                        onChanged: (val) => setDialogState(() => bloodGroup = val!),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildEditField("Observations complémentaires", obsCtrl, isMultiline: true),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Annuler")),
            ElevatedButton(
              onPressed: () async {
                final newMedicalJson = jsonEncode({
                  "pathologies": pathologies.entries.where((e) => e.value).map((e) => e.key).toList(),
                  "allergie_detail": allergyCtrl.text.trim(),
                  "autre_detail": otherCtrl.text.trim(),
                  "groupe_sanguin": bloodGroup,
                  "observations": obsCtrl.text.trim(),
                });

                final updateData = {
                  "nom": nomController.text.trim(),
                  "email": emailController.text.trim(),
                  "numero_de_telephone": _formatPhoneForBackend(phoneController.text.trim()),
                  "contact_familial": _formatPhoneForBackend(contactController.text.trim()),
                  "age": int.tryParse(ageController.text) ?? user["age"],
                  "adresse": adresseController.text.trim(),
                  "sim_de_la_canne": _formatPhoneForBackend(simController.text.trim()),
                  "etat_de_sante": newMedicalJson,
                };

                final res = await UserService.updateUser(cin, updateData);
                if (res["success"]) {
                  if (mounted) {
                    Navigator.pop(ctx);
                    _loadData();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Utilisateur mis à jour avec succès"), backgroundColor: AppTheme.normalGreen),
                    );
                  }
                } else {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Erreur: ${res["error"]}"), backgroundColor: AppTheme.sosRed),
                    );
                  }
                }
              },
              child: const Text("Sauvegarder", style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  static String _normalizePhoneDigits(String raw) {
    String cleaned = raw.trim();
    if (cleaned.startsWith('+216')) cleaned = cleaned.substring(4);
    else if (cleaned.startsWith('00216')) cleaned = cleaned.substring(5);
    else if (cleaned.startsWith('216') && cleaned.length > 3) cleaned = cleaned.substring(3);
    cleaned = cleaned.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleaned.length > 8) cleaned = cleaned.substring(0, 8);
    return cleaned;
  }

  static String _formatPhoneForBackend(String eightDigits) {
    final digits = eightDigits.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) return '';
    return '+216$digits';
  }

  Widget _buildEditField(String label, TextEditingController controller, {bool isNumber = false, bool isMultiline = false, bool isPhone = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: controller,
        maxLines: isMultiline ? 3 : 1,
        keyboardType: (isNumber || isPhone) ? TextInputType.number : (isMultiline ? TextInputType.multiline : TextInputType.text),
        inputFormatters: isPhone ? [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(8)] : null,
        decoration: InputDecoration(
          labelText: label,
          isDense: true,
          border: const OutlineInputBorder(),
          prefix: isPhone ? const Text('+216 ') : null,
        ),
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
                _statCard("Clients", _subscribers.length.toString(), Icons.people_alt_rounded, AppTheme.primary),
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
