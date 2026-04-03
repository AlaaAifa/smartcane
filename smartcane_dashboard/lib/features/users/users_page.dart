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
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("Détails: ${user['prenom']} ${user['nom']}", style: const TextStyle(fontWeight: FontWeight.bold)),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _detailRow(Icons.email, "Email", user["email"]),
              _detailRow(Icons.phone, "Téléphone", user["phone_number_malvoyant"]),
              _detailRow(Icons.family_restroom, "Téléphone Famille", user["phone_number_famille"]),
              const Divider(height: 30),
              _detailRow(Icons.settings_cell, "Cane ID (Code)", user["cane_details"]?["serial_number"] ?? "N/A"),
              _detailRow(Icons.wifi, "Connecté", (user["is_online"] ?? false) ? "Oui" : "Non"),
              _detailRow(Icons.warning, "Statut", user["status"]),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Fermer"))
        ],
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
