import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
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
    final phoneCtrl = TextEditingController(text: _normalizePhoneDigits(user["numero_de_telephone"]?.toString() ?? ""));
    final familyCtrl = TextEditingController(text: _normalizePhoneDigits(user["contact_familial"]?.toString() ?? ""));
    final addressCtrl = TextEditingController(text: user["adresse"]?.toString() ?? "");
    final simCtrl = TextEditingController(text: _normalizePhoneDigits(user["sim_de_la_canne"]?.toString() ?? ""));
    
    // Parse structured health info
    Map<String, dynamic> medicalData = {};
    try {
      String rawHealth = user["etat_de_sante"]?.toString() ?? "";
      if (rawHealth.startsWith('{')) {
        medicalData = jsonDecode(rawHealth);
      } else {
        // Fallback for old text notes
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
            width: 600,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _fieldOrText("CIN", user["cin"]?.toString() ?? "N/A", null, false),
                  _fieldOrText("Nom", user["nom"]?.toString() ?? "N/A", nameCtrl, isEditing),
                  _fieldOrText("Email", user["email"]?.toString() ?? "N/A", emailCtrl, isEditing),
                  _fieldOrText("Telephone", user["numero_de_telephone"]?.toString() ?? "N/A", phoneCtrl, isEditing, isPhone: true),
                  _fieldOrText("Contact familial", user["contact_familial"]?.toString() ?? "N/A", familyCtrl, isEditing, isPhone: true),
                  _fieldOrText("Adresse", user["adresse"]?.toString() ?? "N/A", addressCtrl, isEditing),
                  _fieldOrText("SIM canne", user["sim_de_la_canne"]?.toString() ?? "N/A", simCtrl, isEditing, isPhone: true),
                  
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Divider(),
                  ),
                  
                  const Text("Informations Médicales", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.primary)),
                  const SizedBox(height: 12),
                  
                  if (!isEditing) ...[
                    _buildMedicalSummary(pathologies, allergyCtrl.text, otherCtrl.text, bloodGroup, obsCtrl.text)
                  ] else ...[
                    const Text("Pathologies :", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
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
                      TextField(controller: allergyCtrl, decoration: const InputDecoration(labelText: "Préciser le(s) médicament(s)", isDense: true)),
                    ],
                    if (pathologies["Autre"]!) ...[
                      const SizedBox(height: 12),
                      TextField(controller: otherCtrl, decoration: const InputDecoration(labelText: "Préciser l'autre pathologie", isDense: true)),
                    ],
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Text("Groupe sanguin : ", style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(width: 12),
                        DropdownButton<String>(
                          value: bloodGroup,
                          items: bloodGroups.map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
                          onChanged: (val) => setDialogState(() => bloodGroup = val!),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(controller: obsCtrl, maxLines: 2, decoration: const InputDecoration(labelText: "Observations complémentaires")),
                  ],
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Fermer")),
            if (isEditing)
              ElevatedButton(
                onPressed: () async {
                  // Encode medical info
                  final newMedicalJson = jsonEncode({
                    "pathologies": pathologies.entries.where((e) => e.value).map((e) => e.key).toList(),
                    "allergie_detail": allergyCtrl.text.trim(),
                    "autre_detail": otherCtrl.text.trim(),
                    "groupe_sanguin": bloodGroup,
                    "observations": obsCtrl.text.trim(),
                  });

                  final result = await UserService.updateUser(
                    user["cin"].toString(),
                    {
                      "nom": nameCtrl.text.trim(),
                      "email": emailCtrl.text.trim(),
                      "numero_de_telephone": _formatPhoneForBackend(phoneCtrl.text.trim()),
                      "contact_familial": _formatPhoneForBackend(familyCtrl.text.trim()),
                      "adresse": addressCtrl.text.trim(),
                      "etat_de_sante": newMedicalJson,
                      "sim_de_la_canne": _formatPhoneForBackend(simCtrl.text.trim()),
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

  Widget _buildMedicalSummary(Map<String, bool> pathologies, String allergy, String other, String blood, String obs) {
    final activePathologies = pathologies.entries.where((e) => e.value).map((e) => e.key).toList();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _summaryRow("Groupe sanguin", blood),
        const SizedBox(height: 8),
        const Text("Pathologies :", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
        if (activePathologies.isEmpty) 
          const Text("Non spécifié")
        else
          Wrap(
            spacing: 4,
            children: activePathologies.map((p) {
              String label = p;
              if (p == "Allergies médicamenteuses" && allergy.isNotEmpty) label += " ($allergy)";
              if (p == "Autre" && other.isNotEmpty) label += " ($other)";
              return Chip(
                label: Text(label, style: const TextStyle(fontSize: 11)),
                backgroundColor: AppTheme.primary.withOpacity(0.1),
                padding: EdgeInsets.zero,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              );
            }).toList(),
          ),
        if (obs.isNotEmpty) ...[
          const SizedBox(height: 12),
          const Text("Observations :", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
          Text(obs),
        ],
      ],
    );
  }

  Widget _summaryRow(String label, String value) {
    return Row(
      children: [
        Text("$label : ", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }

  // Normalise an existing phone/SIM value → returns only the 8-digit part
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

  Widget _fieldOrText(
    String label,
    String value,
    TextEditingController? controller,
    bool isEditing, {
    bool isPhone = false,
  }) {
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
        keyboardType: isPhone ? TextInputType.number : TextInputType.text,
        inputFormatters: isPhone
            ? [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(8),
              ]
            : null,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: isPhone ? null : null,
          prefix: isPhone
              ? Text(
                  '+216 ',
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                )
              : null,
          hintText: isPhone ? '12 345 678' : null,
        ),
      ),
    );
  }
}
