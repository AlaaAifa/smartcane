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
    if (!mounted) return;
    setState(() {
      users = data.where((user) => user["role"] == "client").toList();
      _isLoading = false;
    });
  }

  String _displayName(Map<String, dynamic> user) => user["nom"]?.toString() ?? user["cin"]?.toString() ?? "Client";

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppTheme.primary));
    }

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
                  Text("Répertoire des Clients", style: Theme.of(context).textTheme.headlineMedium),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withOpacity(0.08), 
                      borderRadius: BorderRadius.circular(8), 
                    ),
                    child: Text("${users.length} CLIENTS SOUS SURVEILLANCE", style: const TextStyle(color: AppTheme.primary, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1)),
                  ),
                ],
              ),
              AppGradientButton(
                onTap: () => widget.onNavigate?.call("/add-user"),
                icon: Icons.person_add_rounded,
                label: "ENREGISTRER NOUVEAU CLIENT",
                color: AppTheme.primary,
              ),
            ],
          ),
          const SizedBox(height: 48),
          Expanded(
            child: users.isEmpty 
              ? Center(child: Text("Aucun client enregistré", style: TextStyle(color: Colors.grey.shade400, fontWeight: FontWeight.bold)))
              : ListView.builder(
                  itemCount: users.length,
                  itemBuilder: (context, index) {
                    final user = users[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 20),
                      padding: const EdgeInsets.all(24),
                      decoration: AppTheme.glassCard(),
                      child: Row(
                        children: [
                          Container(
                            width: 56, height: 56,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              shape: BoxShape.circle,
                              border: Border.all(color: AppTheme.primary.withOpacity(0.1), width: 2),
                            ),
                            child: Center(
                              child: Text(
                                _displayName(user).isNotEmpty ? _displayName(user)[0].toUpperCase() : "?",
                                style: const TextStyle(fontWeight: FontWeight.w900, color: AppTheme.primary, fontSize: 24),
                              ),
                            ),
                          ),
                          const SizedBox(width: 24),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(_displayName(user), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: AppTheme.primary)),
                                const SizedBox(height: 6),
                                Text(user["email"]?.toString() ?? "Aucune adresse email", style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14, fontWeight: FontWeight.w500)),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(12)),
                            child: Row(
                              children: [
                                const Icon(Icons.phone_rounded, size: 16, color: AppTheme.primary),
                                const SizedBox(width: 12),
                                Text(
                                  user["numero_de_telephone"]?.toString() ?? "Non renseigné",
                                  style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w800, fontSize: 15),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 24),
                          IconButton(
                            onPressed: () => _showUserDetails(user),
                            icon: const Icon(Icons.arrow_forward_ios_rounded, color: Color(0xFFCBD5E1), size: 18),
                            hoverColor: AppTheme.primary.withOpacity(0.05),
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

    bool isEditing = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            width: 750,
            constraints: const BoxConstraints(maxHeight: 850),
            decoration: BoxDecoration(
              color: AppTheme.bgCard,
              borderRadius: BorderRadius.circular(32),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 40)],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _dialogHeader(isEditing ? "MODIFIER LE PROFIL CLIENT" : _displayName(user).toUpperCase(), isEditing ? Icons.edit_note_rounded : Icons.person_rounded, isEditing, () => setDialogState(() => isEditing = !isEditing)),
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(40),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _sectionTitle("COORDONNÉES PERSONNELLES"),
                        const SizedBox(height: 24),
                        _fieldOrText("CIN", user["cin"]?.toString() ?? "Non renseign", null, false),
                        _fieldOrText("Nom Complet", user["nom"]?.toString() ?? "Non renseign", nameCtrl, isEditing, icon: Icons.person_outline_rounded),
                        _fieldOrText("Adresse Email", user["email"]?.toString() ?? "Non renseign", emailCtrl, isEditing, icon: Icons.email_outlined),
                        _fieldOrText("Téléphone Client", user["numero_de_telephone"]?.toString() ?? "Non renseign", phoneCtrl, isEditing, isPhone: true, icon: Icons.phone_android_rounded),
                        _fieldOrText("Contact Familial (SOS)", user["contact_familial"]?.toString() ?? "Non renseign", familyCtrl, isEditing, isPhone: true, icon: Icons.family_restroom_rounded),
                        _fieldOrText("Adresse de Résidence", user["adresse"]?.toString() ?? "Non renseign", addressCtrl, isEditing, icon: Icons.home_outlined),
                        _fieldOrText("SIM de la Canne", user["sim_de_la_canne"]?.toString() ?? "Non renseign", simCtrl, isEditing, isPhone: true, icon: Icons.sim_card_outlined),
                        
                        const Padding(padding: EdgeInsets.symmetric(vertical: 32), child: Divider(height: 1, color: Color(0xFFF1F5F9))),
                        
                        _sectionTitle("DOSSIER MÉDICAL"),
                        const SizedBox(height: 24),
                        
                        if (!isEditing) ...[
                          _buildMedicalSummary(pathologies, allergyCtrl.text, otherCtrl.text, bloodGroup, obsCtrl.text)
                        ] else ...[
                          const Text("PATHOLOGIES DÉTECTÉES", style: TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF64748B), fontSize: 11, letterSpacing: 1)),
                          const SizedBox(height: 16),
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: availablePathologies.map((p) => FilterChip(
                              label: Text(p),
                              labelStyle: TextStyle(color: pathologies[p]! ? Colors.white : AppTheme.primary, fontWeight: FontWeight.bold, fontSize: 13),
                              selected: pathologies[p]!,
                              selectedColor: AppTheme.primary,
                              checkmarkColor: Colors.white,
                              backgroundColor: const Color(0xFFF1F5F9),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              onSelected: (val) => setDialogState(() {
                                if (p == "Aucune pathologie connue" && val) pathologies.updateAll((key, value) => false);
                                else if (val) pathologies["Aucune pathologie connue"] = false;
                                pathologies[p] = val;
                              }),
                            )).toList(),
                          ),
                          if (pathologies["Allergies médicamenteuses"]!) ...[
                            const SizedBox(height: 24),
                            _buildDialogField("Détails des allergies", allergyCtrl, Icons.medication_rounded),
                          ],
                          if (pathologies["Autre"]!) ...[
                            const SizedBox(height: 24),
                            _buildDialogField("Autre pathologie", otherCtrl, Icons.add_moderator_rounded),
                          ],
                          const SizedBox(height: 32),
                          Row(
                            children: [
                              const Text("GROUPE SANGUIN", style: TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF64748B), fontSize: 11, letterSpacing: 1)),
                              const SizedBox(width: 24),
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                  decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.withOpacity(0.1))),
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<String>(
                                      value: bloodGroup,
                                      isExpanded: true,
                                      dropdownColor: Colors.white,
                                      style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w800),
                                      items: bloodGroups.map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
                                      onChanged: (val) => setDialogState(() => bloodGroup = val!),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 32),
                          _buildDialogField("Observations complémentaires", obsCtrl, Icons.notes_rounded, maxLines: 3),
                        ],
                      ],
                    ),
                  ),
                ),
                _dialogActions(ctx, isEditing, () async {
                  final newMedicalJson = jsonEncode({
                    "pathologies": pathologies.entries.where((e) => e.value).map((e) => e.key).toList(),
                    "allergie_detail": allergyCtrl.text.trim(),
                    "autre_detail": otherCtrl.text.trim(),
                    "groupe_sanguin": bloodGroup,
                    "observations": obsCtrl.text.trim(),
                  });

                  final result = await UserService.updateUser(user["cin"].toString(), {
                    "nom": nameCtrl.text.trim(),
                    "email": emailCtrl.text.trim(),
                    "numero_de_telephone": _formatPhoneForBackend(phoneCtrl.text.trim()),
                    "contact_familial": _formatPhoneForBackend(familyCtrl.text.trim()),
                    "adresse": addressCtrl.text.trim(),
                    "etat_de_sante": newMedicalJson,
                    "sim_de_la_canne": _formatPhoneForBackend(simCtrl.text.trim()),
                  });

                  if (!mounted) return;
                  if (result["success"]) {
                    Navigator.pop(ctx);
                    _loadUsers();
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Dossier client mis à jour"), backgroundColor: AppTheme.primary));
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Erreur: ${result["error"]}"), backgroundColor: AppTheme.sosRed));
                  }
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _dialogHeader(String title, IconData icon, bool isEditing, VoidCallback onToggleEdit) => Container(
    padding: const EdgeInsets.all(32),
    decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: const BorderRadius.vertical(top: Radius.circular(32)), border: Border(bottom: BorderSide(color: Colors.grey.withOpacity(0.1)))),
    child: Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: AppTheme.primary.withOpacity(0.08), borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, color: AppTheme.primary),
        ),
        const SizedBox(width: 20),
        Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 20, color: AppTheme.primary, letterSpacing: 0.5))),
        IconButton(
          onPressed: onToggleEdit,
          icon: Icon(isEditing ? Icons.close_rounded : Icons.edit_rounded, color: isEditing ? AppTheme.sosRed : AppTheme.primary),
          tooltip: isEditing ? "Annuler" : "Modifier le profil",
        ),
      ],
    ),
  );

  Widget _dialogActions(BuildContext context, bool isEditing, VoidCallback onSave) => Container(
    padding: const EdgeInsets.all(32),
    decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: const BorderRadius.vertical(bottom: Radius.circular(32)), border: Border(top: BorderSide(color: Colors.grey.withOpacity(0.1)))),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text("FERMER", style: TextStyle(color: Color(0xFF94A3B8), fontWeight: FontWeight.w900))),
        if (isEditing) ...[
          const SizedBox(width: 24),
          AppGradientButton(onTap: onSave, icon: Icons.check_circle_rounded, label: "ENREGISTRER LES MODIFICATIONS", color: AppTheme.primary),
        ],
      ],
    ),
  );

  Widget _sectionTitle(String title) => Row(
    children: [
      Container(width: 4, height: 16, decoration: BoxDecoration(color: AppTheme.primary, borderRadius: BorderRadius.circular(2))),
      const SizedBox(width: 12),
      Text(title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: AppTheme.primary, letterSpacing: 1.5)),
    ],
  );

  Widget _buildDialogField(String label, TextEditingController controller, IconData icon, {int maxLines = 1}) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w600),
      decoration: AppTheme.inputDecoration(label, icon),
    );
  }

  Widget _buildMedicalSummary(Map<String, bool> pathologies, String allergy, String other, String blood, String obs) {
    final activePathologies = pathologies.entries.where((e) => e.value).map((e) => e.key).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _summaryRow("GROUPE SANGUIN", blood),
        const SizedBox(height: 24),
        const Text("PATHOLOGIES SIGNALÉES", style: TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF64748B), fontSize: 11, letterSpacing: 1)),
        const SizedBox(height: 12),
        if (activePathologies.isEmpty) 
          const Text("Aucune pathologie renseignée", style: TextStyle(color: Color(0xFF94A3B8), fontWeight: FontWeight.w600))
        else
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: activePathologies.map((p) {
              String label = p;
              if (p == "Allergies médicamenteuses" && allergy.isNotEmpty) label += " ($allergy)";
              if (p == "Autre" && other.isNotEmpty) label += " ($other)";
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(color: AppTheme.primary.withOpacity(0.05), borderRadius: BorderRadius.circular(10), border: Border.all(color: AppTheme.primary.withOpacity(0.1))),
                child: Text(label, style: const TextStyle(fontSize: 12, color: AppTheme.primary, fontWeight: FontWeight.w800)),
              );
            }).toList(),
          ),
        if (obs.isNotEmpty) ...[
          const SizedBox(height: 24),
          const Text("OBSERVATIONS SPÉCIFIQUES", style: TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF64748B), fontSize: 11, letterSpacing: 1)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(16),
            width: double.infinity,
            decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(12)),
            child: Text(obs, style: const TextStyle(color: AppTheme.primary, fontSize: 14, fontWeight: FontWeight.w500, height: 1.5)),
          ),
        ],
      ],
    );
  }

  Widget _summaryRow(String label, String value) {
    return Row(
      children: [
        Text("$label : ", style: const TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 1)),
        const SizedBox(width: 8),
        Text(value, style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w800, fontSize: 15)),
      ],
    );
  }

  Widget _fieldOrText(String label, String value, TextEditingController? controller, bool isEditing, {bool isPhone = false, IconData icon = Icons.info_outline_rounded}) {
    if (!isEditing || controller == null) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(width: 160, child: Text(label, style: const TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w800, fontSize: 12, letterSpacing: 0.5))),
            Expanded(child: Text(value, style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w700, fontSize: 15))),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: TextField(
        controller: controller,
        style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w600),
        keyboardType: isPhone ? TextInputType.number : TextInputType.text,
        inputFormatters: isPhone ? [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(8)] : null,
        decoration: AppTheme.inputDecoration(label, icon).copyWith(
          prefixText: isPhone ? '+216 ' : null,
          prefixStyle: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  String _normalizePhoneDigits(String raw) {
    String cleaned = raw.trim();
    if (cleaned.startsWith('+216')) cleaned = cleaned.substring(4);
    else if (cleaned.startsWith('00216')) cleaned = cleaned.substring(5);
    else if (cleaned.startsWith('216') && cleaned.length > 3) cleaned = cleaned.substring(3);
    cleaned = cleaned.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleaned.length > 8) cleaned = cleaned.substring(0, 8);
    return cleaned;
  }

  String _formatPhoneForBackend(String eightDigits) {
    final digits = eightDigits.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) return '';
    return '+216$digits';
  }
}
