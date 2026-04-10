import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../core/api_service.dart';

class UsersPage extends StatefulWidget {
  final Function(String)? onNavigate;
  const UsersPage({super.key, this.onNavigate});

  @override
  State<UsersPage> createState() => _UsersPageState();
}

class _UsersPageState extends State<UsersPage> {
  List<Map<String, dynamic>> users = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  void _loadUsers() async {
    final data = await ApiService.getUsers();
    setState(() { users = data; _isLoading = false; });
  }

  Color _statusColor(String status) {
    switch (status) {
      case "SOS": return AppTheme.sosRed;
      case "HELP": return AppTheme.helpOrange;
      default: return AppTheme.normalGreen;
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
                  const Text("Utilisateurs", style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 4),
                  Text("${users.length} utilisateurs enregistrés", style: TextStyle(color: Colors.grey.shade600)),
                ],
              ),
              ElevatedButton.icon(
                onPressed: () {
                  if (widget.onNavigate != null) {
                    widget.onNavigate!("/add-user");
                  }
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  backgroundColor: AppTheme.primary,
                ),
                icon: const Icon(Icons.person_add),
                label: const Text("Ajouter Utilisateur"),
              )
            ],
          ),
          const SizedBox(height: 24),

          // Table header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(color: AppTheme.primary.withOpacity(0.05), borderRadius: BorderRadius.circular(12)),
            child: const Row(
              children: [
                Expanded(flex: 2, child: Text("Nom Complet", style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13))),
                Expanded(flex: 2, child: Text("Email", style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13))),
                Expanded(flex: 2, child: Text("Téléphone", style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13))),
                Expanded(flex: 1, child: Text("Statut", style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13))),
                SizedBox(width: 100), // Actions column width
              ],
            ),
          ),
          const SizedBox(height: 8),

          Expanded(
            child: ListView.builder(
              itemCount: users.length,
              itemBuilder: (context, index) {
                final u = users[index];
                final status = u["status"] ?? "normal";
                return Container(
                  margin: const EdgeInsets.only(bottom: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: AppTheme.primary.withOpacity(0.1),
                              radius: 18,
                              child: Text("${(u['prenom'] ?? '?')[0]}${(u['nom'] ?? '?')[0]}",
                                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: AppTheme.primary)),
                            ),
                            const SizedBox(width: 12),
                            Text("${u['prenom']} ${u['nom']}", style: const TextStyle(fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                      Expanded(flex: 2, child: Text(u["email"] ?? "", style: TextStyle(color: Colors.grey.shade600, fontSize: 13))),
                      Expanded(flex: 2, child: Text(u["phone_number_malvoyant"] ?? "", style: TextStyle(color: Colors.grey.shade600, fontSize: 13))),
                      Expanded(
                        flex: 1,
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: _statusColor(status).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(status.toUpperCase(),
                              textAlign: TextAlign.center,
                              style: TextStyle(color: _statusColor(status), fontWeight: FontWeight.w700, fontSize: 12)),
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 100,
                        child: TextButton(
                          onPressed: () => _showUserDetails(context, u),
                          child: const Text("Voir détails", style: TextStyle(fontSize: 12)),
                        ),
                      )
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

  void _showUserDetails(BuildContext context, Map<String, dynamic> user) {
    bool isEditing = false;
    final bool canEdit = ApiService.isAdmin;
    
    // Extract nested data with safe defaults
    final address = user["address"] ?? {};
    final medical = user["medical_info"] ?? {};
    final contacts = user["emergency_contacts"] as List? ?? [];
    final contact = contacts.isNotEmpty ? contacts[0] : {};

    // Controllers for editing
    final prenomCtrl = TextEditingController(text: user["prenom"] ?? "");
    final nomCtrl = TextEditingController(text: user["nom"] ?? "");
    final emailCtrl = TextEditingController(text: user["email"] ?? "");
    final phoneCtrl = TextEditingController(text: user["phone_number_malvoyant"] ?? "");
    final phoneFamilleCtrl = TextEditingController(text: user["phone_number_famille"] ?? "");
    final caneIdCtrl = TextEditingController(text: user["cane_details"]?["serial_number"] ?? "");
    
    final streetCtrl = TextEditingController(text: address["street"] ?? "");
    final cityCtrl = TextEditingController(text: address["city"] ?? "");
    final postalCtrl = TextEditingController(text: address["postal_code"] ?? "");
    final conditionCtrl = TextEditingController(text: medical["condition"] ?? "");
    final medicalNotesCtrl = TextEditingController(text: medical["notes"] ?? "");
    final contactNameCtrl = TextEditingController(text: contact["name"] ?? "");
    final contactPhoneCtrl = TextEditingController(text: contact["phone"] ?? "");

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(isEditing ? "Modifier Profil" : "Détails: ${user['prenom']} ${user['nom']}", style: const TextStyle(fontWeight: FontWeight.bold)),
                if (canEdit && !isEditing)
                  IconButton(
                    icon: const Icon(Icons.edit, color: AppTheme.primary),
                    onPressed: () => setDialogState(() => isEditing = true),
                    tooltip: "Modifier",
                  ),
              ],
            ),
            content: SizedBox(
              width: 500,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (isEditing) ...[
                       Row(
                        children: [
                          Expanded(child: _editField("Prénom", prenomCtrl)),
                          const SizedBox(width: 8),
                          Expanded(child: _editField("Nom", nomCtrl)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      _editField("Email", emailCtrl),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(child: _editField("Tél. Malvoyant", phoneCtrl)),
                          const SizedBox(width: 8),
                          Expanded(child: _editField("Tél. Famille", phoneFamilleCtrl)),
                        ],
                      ),
                      const SizedBox(height: 8),
                    ] else ...[
                      _detailRow(Icons.email, "Email", user["email"]),
                      _detailRow(Icons.phone, "Téléphone", user["phone_number_malvoyant"]),
                      _detailRow(Icons.family_restroom, "Téléphone Famille", user["phone_number_famille"]),
                    ],
                    const Divider(height: 30),
                    
                    const Text("ADRESSE", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11, color: Colors.blueGrey)),
                    const SizedBox(height: 8),
                    if (isEditing) ...[
                      _editField("Rue", streetCtrl),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(child: _editField("Ville", cityCtrl)),
                          const SizedBox(width: 8),
                          Expanded(child: _editField("Code Postal", postalCtrl)),
                        ],
                      ),
                    ] else ...[
                      _detailRow(Icons.location_on, "Adresse", "${address['street'] ?? ''} ${address['city'] ?? ''} ${address['postal_code'] ?? ''}".trim().isEmpty ? "Non spécifiée" : "${address['street'] ?? ''}, ${address['city'] ?? ''} ${address['postal_code'] ?? ''}"),
                    ],

                    const Divider(height: 30),
                    const Text("SANTÉ", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11, color: Colors.blueGrey)),
                    const SizedBox(height: 8),
                    if (isEditing) ...[
                      _editField("Condition", conditionCtrl),
                      const SizedBox(height: 8),
                      _editField("Notes Médicales", medicalNotesCtrl),
                    ] else ...[
                      _detailRow(Icons.health_and_safety, "État de santé", medical["condition"]),
                      _detailRow(Icons.notes, "Notes", medical["notes"]),
                    ],

                    const Divider(height: 30),
                    const Text("CONTACT D'URGENCE", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11, color: Colors.blueGrey)),
                    const SizedBox(height: 8),
                    if (isEditing) ...[
                      _editField("Nom", contactNameCtrl),
                      const SizedBox(height: 8),
                      _editField("Téléphone", contactPhoneCtrl),
                    ] else ...[
                      _detailRow(Icons.emergency, "Contact", contact["name"]),
                      _detailRow(Icons.phone_android, "Tél. Urgence", contact["phone"]),
                    ],
                    
                    const Divider(height: 30),
                    if (isEditing) ...[
                      _editField("Cane ID", caneIdCtrl),
                    ] else ...[
                      _detailRow(Icons.settings_cell, "Cane ID", user["cane_details"]?["serial_number"] ?? "N/A"),
                      _detailRow(Icons.wifi, "Connecté", (user["is_online"] ?? false) ? "Oui" : "Non"),
                    ],
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx), 
                child: Text(isEditing ? "ANNULER" : "FERMER", style: TextStyle(color: isEditing ? Colors.red : Colors.grey))
              ),
              if (isEditing)
                ElevatedButton(
                  onPressed: () async {
                    final updatedUser = Map<String, dynamic>.from(user);
                    updatedUser["prenom"] = prenomCtrl.text.trim();
                    updatedUser["nom"] = nomCtrl.text.trim();
                    updatedUser["email"] = emailCtrl.text.trim();
                    updatedUser["phone_number_malvoyant"] = phoneCtrl.text.trim();
                    updatedUser["phone_number_famille"] = phoneFamilleCtrl.text.trim();
                    updatedUser["cane_details"] = {
                      "serial_number": caneIdCtrl.text.trim(),
                      "firmware_version": user["cane_details"]?["firmware_version"] ?? "1.0.0"
                    };

                    updatedUser["address"] = {
                      "street": streetCtrl.text.trim(),
                      "city": cityCtrl.text.trim(),
                      "postal_code": postalCtrl.text.trim()
                    };
                    updatedUser["medical_info"] = {
                      "condition": conditionCtrl.text.trim(),
                      "notes": medicalNotesCtrl.text.trim(),
                      "blood_group": medical["blood_group"] ?? "O+"
                    };
                    updatedUser["emergency_contacts"] = [
                      {
                        "name": contactNameCtrl.text.trim(),
                        "phone": contactPhoneCtrl.text.trim(),
                        "relation": contact["relation"] ?? "Urgence"
                      }
                    ];

                    final success = await ApiService.updateUser(updatedUser);
                    if (success) {
                      Navigator.pop(ctx);
                      _loadUsers();
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Profil mis à jour !"), backgroundColor: Colors.green));
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Échec de la mise à jour"), backgroundColor: Colors.red));
                    }
                  },
                  child: const Text("ENREGISTRER"),
                ),
            ],
          );
        }
      ),
    );
  }

  Widget _editField(String label, TextEditingController ctrl) {
    return TextField(
      controller: ctrl,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontSize: 12),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey.shade600),
          const SizedBox(width: 12),
          Text("$label : ", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey.shade700)),
          Expanded(child: Text("${value ?? 'Non spécifié'}"))
        ],
      ),
    );
  }
}
