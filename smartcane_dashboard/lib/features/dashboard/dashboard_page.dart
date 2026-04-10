import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../core/api_service.dart';

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
  String _selectedFilter = "tous"; // tous, abonnés, loueurs

  // Controllers for detailed user info (Admin updates)
  final _prenomController = TextEditingController();
  final _nomController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneMalvoyantController = TextEditingController();
  final _phoneFamilleController = TextEditingController();
  final _caneIdController = TextEditingController();
  final _cityController = TextEditingController();
  final _streetController = TextEditingController();
  final _postalCodeController = TextEditingController();
  final _bloodGroupController = TextEditingController();
  final _medicalConditionController = TextEditingController();
  final _medicalNotesController = TextEditingController();
  final _emergencyNameController = TextEditingController();
  final _emergencyRelationController = TextEditingController();
  final _emergencyPhoneController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() async {
    final s = await ApiService.getStats();
    final u = await ApiService.getUsers();
    final r = await ApiService.getActiveRentals();
    final a = await ApiService.getActiveAlerts();
    final h = await ApiService.getAlertsHistory();
    
    if (mounted) {
      setState(() { 
        stats = s; 
        users = u;
        activeRentals = r;
        activeAlerts = a;
        historyAlerts = h;
        _isLoading = false; 
      });
    }
  }

  // --- Segmentation Helpers ---
  List<Map<String, dynamic>> get _subscribers {
    final renterIds = activeRentals.map((r) => (r['user_id'] ?? r['id'])?.toString()).toSet();
    return users.where((u) {
      final uid = (u['user_id'] ?? u['id'])?.toString();
      return uid != null && !renterIds.contains(uid);
    }).toList();
  }

  List<Map<String, dynamic>> get _renters {
    final renterIds = activeRentals.map((r) => (r['user_id'] ?? r['id'])?.toString()).toSet();
    return users.where((u) {
      final uid = (u['user_id'] ?? u['id'])?.toString();
      return uid != null && renterIds.contains(uid);
    }).toList();
  }

  int get _onlineSubscribersCount => _subscribers.where((u) => u['is_online'] == true).length;
  int get _onlineRentersCount => _renters.where((u) => u['is_online'] == true).length;

  List<Map<String, dynamic>> get _filteredUsers {
    if (_selectedFilter == "abonnés") return _subscribers;
    if (_selectedFilter == "loueurs") return _renters;
    return users;
  }

  void _updateAge() {
    // Logic removed as it is now in AddUserPage
  }

  // Helper to count active and resolved alerts for a user
  Map<String, int> _getUserAlertStats(String userId) {
    int activeCount = activeAlerts.where((a) => a['user_id'] == userId).length;
    int historyCount = historyAlerts.where((a) => a['user_id'] == userId).length;
    return {"active": activeCount, "resolved": historyCount};
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: AppTheme.sosRed,
    ));
  }

  // --- Detailed View & Admin Updates ---

  Widget _buildField(String label, TextEditingController controller, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          decoration: InputDecoration(
            prefixIcon: Icon(icon, size: 20),
            hintText: label,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
      ],
    );
  }

  void _showUserDetails(BuildContext context, Map<String, dynamic> user) {
    bool isAdmin = ApiService.isAdmin;
    final String userId = (user["user_id"] ?? user["id"] ?? "N/A").toString();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("${user['prenom']} ${user['nom']}", style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 24)),
                Text("ID: ${user['user_id']}", style: const TextStyle(color: Colors.grey, fontSize: 13)),
              ],
            ),
            if (isAdmin)
               PopupMenuButton<String>(
                onSelected: (val) {
                  if (val == 'personal') _showEditPersonalInfoDialog(ctx, user);
                  if (val == 'address') _showAddAddressDialog(ctx, user);
                  if (val == 'medical') _showAddMedicalDialog(ctx, user);
                  if (val == 'emergency') _showAddEmergencyDialog(ctx, user);
                },
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: AppTheme.primary, shape: BoxShape.circle),
                  child: const Icon(Icons.edit, color: Colors.white),
                ),
                itemBuilder: (context) => [
                  const PopupMenuItem(value: 'personal', child: Row(children: [Icon(Icons.edit, size: 18, color: AppTheme.primary), SizedBox(width: 8), Text("Infos Personnelles")])),
                  const PopupMenuItem(value: 'address', child: Row(children: [Icon(Icons.location_on, size: 18, color: AppTheme.primary), SizedBox(width: 8), Text("Adresse")])),
                  const PopupMenuItem(value: 'medical', child: Row(children: [Icon(Icons.medical_services, size: 18, color: AppTheme.primary), SizedBox(width: 8), Text("Dossier Médical")])),
                  const PopupMenuItem(value: 'emergency', child: Row(children: [Icon(Icons.emergency, size: 18, color: AppTheme.primary), SizedBox(width: 8), Text("Contact d'Urgence")])),
                ],
              ),
          ],
        ),
        content: SizedBox(
          width: 700,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Divider(),
                const SizedBox(height: 16),
                
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Left Column: Basic & Cane
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _sectionTitle("Informations de contact"),
                          _infoRow(Icons.email, "Email", user['email']?.toString() ?? 'Non renseigné'),
                          _infoRow(Icons.phone, "Tél Malvoyant", user['phone_number_malvoyant']?.toString() ?? user['phone']?.toString() ?? 'N/A'),
                          _infoRow(Icons.family_restroom, "Tél Famille", user['phone_number_famille']?.toString() ?? 'N/A'),
                          
                          const SizedBox(height: 24),
                          _sectionTitle("Infos Système"),
                          _infoRow(Icons.fingerprint, "User ID", userId),
                          _infoRow(Icons.cake, "Âge", user['age']?.toString() ?? 'N/A'),
                          
                          const SizedBox(height: 24),
                          _sectionTitle("Canne Inteligente"),
                          _infoRow(Icons.vpn_key, "Serial Number", user['cane_details']?['serial_number']?.toString() ?? 'N/A'),
                          _infoRow(Icons.sim_card, "Numéro SIM (4G)", user['cane_details']?['sim_number']?.toString() ?? 'N/A'),
                          _infoRow(Icons.system_update, "Version", user['cane_details']?['firmware_version']?.toString() ?? 'N/A'),
                        ],
                      ),
                    ),
                    const SizedBox(width: 32),
                    
                    // Right Column: Address & Medical
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _sectionTitle("Résidence"),
                          if (user['address'] != null && user['address'] is Map)
                             Text("${user['address']['street'] ?? 'Rue inconnue'}, ${user['address']['city'] ?? 'Ville inconnue'} (${user['address']['postal_code'] ?? 'CP'})", 
                               style: TextStyle(color: Colors.grey.shade800, fontSize: 14))
                          else if (user['address'] is String)
                             Text(user['address'], style: TextStyle(color: Colors.grey.shade800, fontSize: 14))
                          else 
                             const Text("Aucune adresse renseignée", style: TextStyle(color: Colors.grey, fontSize: 14, fontStyle: FontStyle.italic)),
                          
                          const SizedBox(height: 24),
                          _sectionTitle("Éat de Santé"),
                          if (user['medical_info'] != null && user['medical_info'] is Map) ...[
                             _infoRow(Icons.bloodtype, "Groupe Sanguin", user['medical_info']['blood_group']?.toString() ?? "Non renseigné"),
                             _infoRow(Icons.healing, "Condition", user['medical_info']['condition']?.toString() ?? "Non renseignée"),
                             if (user['medical_info']['notes'] != null)
                               Padding(
                                 padding: const EdgeInsets.only(top: 8),
                                 child: Text("Notes: ${user['medical_info']['notes']}", style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                               ),
                          ] else if (user['health_notes'] != null)
                             Text("Notes: ${user['health_notes']}", style: TextStyle(color: Colors.grey.shade600, fontSize: 14))
                          else 
                             const Text("Aucun dossier médical", style: TextStyle(color: Colors.grey, fontSize: 14, fontStyle: FontStyle.italic)),
                          
                          const SizedBox(height: 24),
                          const SizedBox(height: 24),
                          _sectionTitle("Contacts d'urgence"),
                          Builder(builder: (context) {
                            final List<dynamic> emergency = [];
                            if (user['emergency_contacts'] is List) emergency.addAll(user['emergency_contacts']);
                            if (user['medical_info'] != null && user['medical_info']['emergency_contacts'] is List) {
                              emergency.addAll(user['medical_info']['emergency_contacts']);
                            }
                            if (emergency.isEmpty) {
                              return const Text("Aucun contact additionnel", style: TextStyle(color: Colors.grey, fontSize: 14, fontStyle: FontStyle.italic));
                            }
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: emergency.map((e) {
                                if (e is! Map) return const SizedBox();
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: Text("• ${e['name']} (${e['relation']}): ${e['phone']}", style: const TextStyle(fontSize: 13)),
                                );
                              }).toList(),
                            );
                          }),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Fermer"),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(title.toUpperCase(), style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1.2)),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey),
          const SizedBox(width: 12),
          Text("$label : ", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          Expanded(child: Text(value, style: TextStyle(color: Colors.grey.shade800, fontSize: 14))),
        ],
      ),
    );
  }

  // --- Admin Dialogs ---

  void _showEditPersonalInfoDialog(BuildContext parentCtx, Map<String, dynamic> user) {
    _prenomController.text = user['prenom'] ?? "";
    _nomController.text = user['nom'] ?? "";
    _emailController.text = user['email'] ?? "";
    _phoneMalvoyantController.text = user['phone_number_malvoyant'] ?? "";
    _phoneFamilleController.text = user['phone_number_famille'] ?? "";
    _caneIdController.text = user['cane_details']?['serial_number'] ?? "";

    showDialog(
      context: parentCtx,
      builder: (ctx) => AlertDialog(
        title: const Text("Modifier Infos Personnelles"),
        content: SizedBox(
          width: 500,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(child: _buildField("Prénom", _prenomController, Icons.person_outline)),
                    const SizedBox(width: 16),
                    Expanded(child: _buildField("Nom", _nomController, Icons.person_outline)),
                  ],
                ),
                const SizedBox(height: 16),
                _buildField("Email", _emailController, Icons.email_outlined),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(child: _buildField("Tél. Utilisateur", _phoneMalvoyantController, Icons.phone_android_rounded)),
                    const SizedBox(width: 16),
                    Expanded(child: _buildField("Tél. Famille", _phoneFamilleController, Icons.family_restroom)),
                  ],
                ),
                const SizedBox(height: 16),
                _buildField("Cane ID / Code d'activation", _caneIdController, Icons.vpn_key_outlined),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Annuler")),
          ElevatedButton(
            onPressed: () {
              user['prenom'] = _prenomController.text.trim();
              user['nom'] = _nomController.text.trim();
              user['email'] = _emailController.text.trim();
              user['phone_number_malvoyant'] = _phoneMalvoyantController.text.trim();
              user['phone_number_famille'] = _phoneFamilleController.text.trim();
              user['cane_details'] = {
                "serial_number": _caneIdController.text.trim(),
                "firmware_version": user['cane_details']?['firmware_version'] ?? "1.0.0"
              };
              _submitUserUpdate(parentCtx, ctx, user);
            },
            child: const Text("Enregistrer"),
          ),
        ],
      ),
    );
  }

  void _showAddAddressDialog(BuildContext parentCtx, Map<String, dynamic> user) {
    if (user['address'] != null) {
      _cityController.text = user['address']['city'] ?? "";
      _streetController.text = user['address']['street'] ?? "";
      _postalCodeController.text = user['address']['postal_code'] ?? "";
    } else {
      _cityController.clear();
      _streetController.clear();
      _postalCodeController.clear();
    }

    showDialog(
      context: parentCtx,
      builder: (ctx) => AlertDialog(
        title: Text(user['address'] != null ? "Modifier l'Adresse" : "Ajouter une Adresse"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildField("Ville", _cityController, Icons.location_city),
            const SizedBox(height: 16),
            _buildField("Rue / Quartier", _streetController, Icons.streetview),
            const SizedBox(height: 16),
            _buildField("Code Postal", _postalCodeController, Icons.map_outlined),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Annuler")),
          ElevatedButton(
            onPressed: () {
              user['address'] = {
                "city": _cityController.text.trim(),
                "street": _streetController.text.trim(),
                "postal_code": _postalCodeController.text.trim(),
              };
              _submitUserUpdate(parentCtx, ctx, user);
            },
            child: const Text("Enregistrer"),
          ),
        ],
      ),
    );
  }

  void _showAddMedicalDialog(BuildContext parentCtx, Map<String, dynamic> user) {
     if (user['medical_info'] != null) {
       _bloodGroupController.text = user['medical_info']['blood_group'] ?? "";
       _medicalConditionController.text = user['medical_info']['condition'] ?? "";
       _medicalNotesController.text = user['medical_info']['notes'] ?? "";
     } else {
       _bloodGroupController.clear();
       _medicalConditionController.clear();
       _medicalNotesController.clear();
     }

     showDialog(
      context: parentCtx,
      builder: (ctx) => AlertDialog(
        title: Text(user['medical_info'] != null ? "Modifier le Dossier Médical" : "Nouveau Dossier Médical"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildField("Groupe Sanguin", _bloodGroupController, Icons.bloodtype),
            const SizedBox(height: 16),
            _buildField("Pathologie / Condition", _medicalConditionController, Icons.healing),
            const SizedBox(height: 16),
            _buildField("Notes médicales", _medicalNotesController, Icons.notes),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Annuler")),
          ElevatedButton(
            onPressed: () {
               user['medical_info'] = {
                 "blood_group": _bloodGroupController.text.trim(),
                 "condition": _medicalConditionController.text.trim(),
                 "notes": _medicalNotesController.text.trim(),
               };
               _submitUserUpdate(parentCtx, ctx, user);
            },
            child: const Text("Enregistrer"),
          ),
        ],
      ),
    );
  }

  void _showAddEmergencyDialog(BuildContext parentCtx, Map<String, dynamic> user) {
     _emergencyNameController.clear();
     _emergencyRelationController.clear();
     _emergencyPhoneController.clear();

     showDialog(
      context: parentCtx,
      builder: (ctx) => AlertDialog(
        title: const Text("Nouveau Contact d'Urgence"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildField("Nom & Prénom", _emergencyNameController, Icons.person_outline),
            const SizedBox(height: 16),
            _buildField("Relation", _emergencyRelationController, Icons.link),
            const SizedBox(height: 16),
            _buildField("Numéro de Téléphone", _emergencyPhoneController, Icons.phone),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Annuler")),
          ElevatedButton(
            onPressed: () {
               List<dynamic> contacts = (user['emergency_contacts'] is List) 
                   ? List.from(user['emergency_contacts']) 
                   : [];
               contacts.add({
                 "name": _emergencyNameController.text.trim(),
                 "relation": _emergencyRelationController.text.trim(),
                 "phone": _emergencyPhoneController.text.trim(),
               });
               user['emergency_contacts'] = contacts;
               _submitUserUpdate(parentCtx, ctx, user);
            },
            child: const Text("Enregistrer"),
          ),
        ],
      ),
    );
  }

  void _submitUserUpdate(BuildContext parentCtx, BuildContext dialogCtx, Map<String, dynamic> user) async {
    final success = await ApiService.updateUser(user);
    if (success) {
      Navigator.pop(dialogCtx); // Close sub-dialog
      Navigator.pop(parentCtx); // Close main details view to refresh
      _loadData(); // Refresh list
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text("Dossier utilisateur mis à jour !"), 
        backgroundColor: AppTheme.normalGreen));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          Text("Vue d'ensemble et Suivi, ${ApiService.staffName ?? 'Staff'} 👋",
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900)),
          const SizedBox(height: 4),
          Text("Suivi en temps réel des utilisateurs du centre", style: TextStyle(color: Colors.grey.shade600, fontSize: 15)),
          const SizedBox(height: 32),

          // 2 Summary cards
          Row(
            children: [
              _statCard(
                label: "Abonnés", 
                total: "${_subscribers.length}", 
                online: "$_onlineSubscribersCount",
                icon: Icons.people_alt_rounded, 
                color: AppTheme.primary,
              ),
              const SizedBox(width: 24),
              _statCard(
                label: "Loueurs", 
                total: "${_renters.length}", 
                online: "$_onlineRentersCount",
                icon: Icons.supervised_user_circle_rounded, 
                color: AppTheme.normalGreen,
              ),
            ],
          ),
          const SizedBox(height: 40),

          const SizedBox(height: 40),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("SUIVI TEMPS RÉEL", style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: 1.2)),
              const SizedBox(), // Placeholder for the removed button
            ],
          ),
          const SizedBox(height: 24),
          
          // Filter Bar
          _buildFilterBar(),
          
          const SizedBox(height: 16),
          
          _filteredUsers.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.person_off_rounded, size: 64, color: Colors.grey.shade300),
                      const SizedBox(height: 16),
                      Text("Aucun utilisateur dans cette catégorie", style: TextStyle(color: Colors.grey.shade500, fontSize: 16)),
                    ],
                  ),
                )
              : ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.only(bottom: 40),
                  itemCount: _filteredUsers.length,
                  itemBuilder: (context, index) => _buildUserCard(_filteredUsers[index]),
                ),
        ],
      ),
    ),
  );
}

  Widget _buildFilterBar() {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _filterTab("Tous", "tous", Icons.all_inclusive_rounded),
          _filterTab("Abonnés", "abonnés", Icons.star_outline_rounded),
          _filterTab("Loueurs", "loueurs", Icons.vpn_key_outlined),
        ],
      ),
    );
  }

  Widget _filterTab(String label, String value, IconData icon) {
    bool isSelected = _selectedFilter == value;
    return GestureDetector(
      onTap: () => setState(() => _selectedFilter = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          boxShadow: isSelected ? [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4, offset: const Offset(0, 2))] : [],
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: isSelected ? AppTheme.primary : Colors.grey.shade600),
            const SizedBox(width: 8),
            Text(label, style: TextStyle(color: isSelected ? AppTheme.primary : Colors.grey.shade600, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
          ],
        ),
      ),
    );
  }

  Widget _buildUserCard(Map<String, dynamic> user) {
    final String userId = (user["user_id"] ?? user["id"] ?? "").toString();
    final renterIds = activeRentals.map((r) => (r['user_id'] ?? r['id'])?.toString()).toSet();
    final bool isRenter = renterIds.contains(userId);
    
    // Safety check for names (sometimes prenom/nom are separate, sometimes merged in 'prenom' or 'name')
    String prenom = user["prenom"] ?? "";
    String nom = user["nom"] ?? "";
    if (prenom.isEmpty && user["name"] != null) prenom = user["name"];
    
    final String fullName = prenom.contains(nom) || nom.isEmpty ? prenom : "$prenom $nom";
    
    final bool isOnline = user["is_online"] == true;
    final String statusState = user["status"]?.toString() ?? "normal";
    
    final bool isSOS = statusState == "SOS";
    final bool isHELP = statusState == "HELP";

    final alertStats = _getUserAlertStats(userId);
    
    Color cardOutline = Colors.transparent;
    if (isSOS) cardOutline = AppTheme.sosRed.withOpacity(0.5);
    else if (isHELP) cardOutline = AppTheme.helpOrange.withOpacity(0.5);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cardOutline),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 15,
            offset: const Offset(0, 6),
          )
        ]
      ),
      child: Column(
        children: [
          Row(
            children: [
              Stack(
                children: [
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: AppTheme.primary.withOpacity(0.1),
                    child: Text(prenom.isNotEmpty ? prenom[0].toUpperCase() : "?", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppTheme.primary)),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: isOnline ? AppTheme.normalGreen : Colors.grey.shade400,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2.5),
                        boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 2)],
                      ),
                    ),
                  )
                ],
              ),
              const SizedBox(width: 20),
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(fullName, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: isRenter ? AppTheme.normalGreen.withOpacity(0.1) : AppTheme.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            isRenter ? "LOCATION " : "ABONNÉ",
                            style: TextStyle(
                              color: isRenter ? AppTheme.normalGreen : AppTheme.primary,
                              fontWeight: FontWeight.w900,
                              fontSize: 10,
                              letterSpacing: 0.5
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(Icons.wifi, size: 14, color: isOnline ? AppTheme.normalGreen : Colors.grey),
                        const SizedBox(width: 6),
                        Text(isOnline ? "Connecté maintenant" : "Hors ligne", style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                      ],
                    ),
                  ],
                ),
              ),
              
              const Spacer(),
              
              if (isSOS || isHELP)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSOS ? AppTheme.sosRed : AppTheme.helpOrange,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(isSOS ? Icons.warning_rounded : Icons.help_rounded, color: Colors.white, size: 18),
                      const SizedBox(width: 8),
                      Text(isSOS ? "URGENCE SOS" : "AIDE REQUISE", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 11)),
                    ],
                  ),
                ),
                
              const SizedBox(width: 24),
              
              Row(
                children: [
                  _miniStat("${alertStats['active']}", "Alertes actives", AppTheme.sosRed),
                  const SizedBox(width: 24),
                  _miniStat("${alertStats['resolved']}", "Historique", Colors.blueGrey),
                ],
              ),
              
              const SizedBox(width: 32),
              
              ElevatedButton(
                onPressed: () => _showUserDetails(context, user),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text("PROFIL", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _miniStat(String value, String label, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: color)),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _statCard({
    required String label, 
    required String total, 
    required String online, 
    required IconData icon, 
    required Color color
  }) {
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
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: color, size: 36),
            ),
            const SizedBox(width: 20),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min, // Ensure it stays tight
              children: [
                Text(total, style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: color, height: 1.1)),
                Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(color: AppTheme.normalGreen, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 6),
                    Text("$online en ligne", style: TextStyle(color: Colors.grey.shade600, fontSize: 12, fontWeight: FontWeight.bold)),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
