import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../core/api_service.dart';

class UsersPage extends StatefulWidget {
  const UsersPage({super.key});

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
          const Text("Utilisateurs", style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900)),
          const SizedBox(height: 4),
          Text("${users.length} utilisateurs enregistrés", style: TextStyle(color: Colors.grey.shade600)),
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
}
