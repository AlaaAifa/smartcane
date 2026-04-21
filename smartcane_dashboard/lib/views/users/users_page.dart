import 'package:flutter/material.dart';
import '../theme.dart';
import '../../services/services.dart';

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

  Future<void> _loadUsers() async {
    final data = await UserService.getUsers();
    if (!mounted) {
      return;
    }
    setState(() {
      users = data.where((user) => user["role"] == "client").toList();
      _isLoading = false;
    });
  }

  String _displayName(Map<String, dynamic> user) => user["nom"]?.toString() ?? user["cin"]?.toString() ?? "Client";

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

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
                  const Text("Clients", style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 4),
                  Text("${users.length} clients enregistres", style: TextStyle(color: Colors.grey.shade600)),
                ],
              ),
              ElevatedButton.icon(
                onPressed: () => widget.onNavigate?.call("/add-user"),
                icon: const Icon(Icons.person_add),
                label: const Text("Ajouter"),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: ListView.builder(
              itemCount: users.length,
              itemBuilder: (context, index) {
                final user = users[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: AppTheme.primary.withOpacity(0.1),
                        child: Text(
                          _displayName(user).isNotEmpty ? _displayName(user)[0].toUpperCase() : "?",
                          style: const TextStyle(fontWeight: FontWeight.w800, color: AppTheme.primary),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_displayName(user), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                            const SizedBox(height: 4),
                            Text(user["email"]?.toString() ?? "Aucun email", style: TextStyle(color: Colors.grey.shade600)),
                          ],
                        ),
                      ),
                      SizedBox(
                        width: 180,
                        child: Text(
                          user["numero_de_telephone"]?.toString() ?? "N/A",
                          style: TextStyle(color: Colors.grey.shade700),
                        ),
                      ),
                      const SizedBox(width: 12),
                      TextButton(
                        onPressed: () => _showUserDetails(user),
                        child: const Text("Voir details"),
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

  void _showUserDetails(Map<String, dynamic> user) {
    final nameCtrl = TextEditingController(text: user["nom"]?.toString() ?? "");
    final emailCtrl = TextEditingController(text: user["email"]?.toString() ?? "");
    final phoneCtrl = TextEditingController(text: user["numero_de_telephone"]?.toString() ?? "");
    final familyCtrl = TextEditingController(text: user["contact_familial"]?.toString() ?? "");
    final addressCtrl = TextEditingController(text: user["adresse"]?.toString() ?? "");
    final healthCtrl = TextEditingController(text: user["etat_de_sante"]?.toString() ?? "");
    final simCtrl = TextEditingController(text: user["sim_de_la_canne"]?.toString() ?? "");
    bool isEditing = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(isEditing ? "Modifier client" : _displayName(user), style: const TextStyle(fontWeight: FontWeight.w900)),
              IconButton(
                onPressed: () => setDialogState(() => isEditing = !isEditing),
                icon: Icon(isEditing ? Icons.close : Icons.edit, color: AppTheme.primary),
              ),
            ],
          ),
          content: SizedBox(
            width: 560,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _fieldOrText("CIN", user["cin"]?.toString() ?? "N/A", null, false),
                  _fieldOrText("Nom", user["nom"]?.toString() ?? "N/A", nameCtrl, isEditing),
                  _fieldOrText("Email", user["email"]?.toString() ?? "N/A", emailCtrl, isEditing),
                  _fieldOrText("Telephone", user["numero_de_telephone"]?.toString() ?? "N/A", phoneCtrl, isEditing),
                  _fieldOrText("Contact familial", user["contact_familial"]?.toString() ?? "N/A", familyCtrl, isEditing),
                  _fieldOrText("Adresse", user["adresse"]?.toString() ?? "N/A", addressCtrl, isEditing),
                  _fieldOrText("Etat de sante", user["etat_de_sante"]?.toString() ?? "N/A", healthCtrl, isEditing),
                  _fieldOrText("SIM canne", user["sim_de_la_canne"]?.toString() ?? "N/A", simCtrl, isEditing),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Fermer")),
            if (isEditing)
              ElevatedButton(
                onPressed: () async {
                  final result = await UserService.updateUser(
                    user["cin"].toString(),
                    {
                      "nom": nameCtrl.text.trim(),
                      "email": emailCtrl.text.trim(),
                      "numero_de_telephone": phoneCtrl.text.trim(),
                      "contact_familial": familyCtrl.text.trim(),
                      "adresse": addressCtrl.text.trim(),
                      "etat_de_sante": healthCtrl.text.trim(),
                      "sim_de_la_canne": simCtrl.text.trim(),
                    },
                  );

                  if (!mounted) {
                    return;
                  }

                  if (result["success"]) {
                    Navigator.pop(ctx);
                    _loadUsers();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Client mis a jour"), backgroundColor: AppTheme.normalGreen),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Echec: ${result["error"] ?? "Erreur inconnue"}"), backgroundColor: AppTheme.sosRed),
                    );
                  }
                },
                child: const Text("Enregistrer"),
              ),
          ],
        ),
      ),
    );
  }

  Widget _fieldOrText(
    String label,
    String value,
    TextEditingController? controller,
    bool isEditing,
  ) {
    if (!isEditing || controller == null) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 140,
              child: Text(label, style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.w700)),
            ),
            Expanded(child: Text(value)),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(labelText: label),
      ),
    );
  }
}
