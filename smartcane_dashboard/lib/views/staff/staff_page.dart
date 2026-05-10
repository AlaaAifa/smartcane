import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme.dart';
import '../../services/services.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'dart:typed_data';

class StaffPage extends StatefulWidget {
  const StaffPage({super.key});

  @override
  State<StaffPage> createState() => _StaffPageState();
}

class _StaffPageState extends State<StaffPage> {
  List<Map<String, dynamic>> staffMembers = [];
  Map<String, dynamic> performanceData = {};
  Map<String, Uint8List> _decodedPhotos = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final perf = await DashboardService.getPerformance();
    final members = await StaffService.getStaffMembers();
    if (!mounted) return;
    
    // Cache base64 photos to prevent flickering
    final Map<String, Uint8List> newCache = {};
    for (var s in members) {
      final cin = s["cin"]?.toString() ?? "";
      final photo = s["photo_url"]?.toString() ?? "";
      if (photo.startsWith("data:image")) {
        try {
          newCache[cin] = base64Decode(photo.split(',').last);
        } catch (e) {
          debugPrint("Error decoding photo for $cin: $e");
        }
      }
    }

    setState(() {
      performanceData = perf;
      staffMembers = members;
      _decodedPhotos = newCache;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppTheme.primary));
    }

    final morningStaff = staffMembers.where((s) => s["shift"] == "Journée" || s["shift"] == "matin" || s["shift"] == null).toList();
    final eveningStaff = staffMembers.where((s) => s["shift"] == "Nuit" || s["shift"] == "soir").toList();

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
                  Text("Équipe Opérationnelle", style: Theme.of(context).textTheme.headlineMedium),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppTheme.neonGreen.withOpacity(0.1), 
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text("${staffMembers.length} AGENTS ACTIFS", style: const TextStyle(color: AppTheme.neonGreen, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1)),
                      ),
                      const SizedBox(width: 16),
                      const Text("Surveillance en temps réel activée", style: TextStyle(color: Color(0xFF64748B), fontSize: 13, fontWeight: FontWeight.w500)),
                    ],
                  ),
                ],
              ),
              if (BaseService.isAdmin)
                AppGradientButton(
                  onTap: () => _showAddStaffDialog(context),
                  icon: Icons.person_add_rounded,
                  label: "NOUVEAU MEMBRE STAFF",
                  color: AppTheme.primary,
                ),
            ],
          ),
          const SizedBox(height: 48),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    children: [
                      _buildShiftHeader("Shift Matin / Journée", Icons.wb_sunny_rounded, const Color(0xFFF59E0B)),
                      const SizedBox(height: 24),
                      Expanded(
                        child: ListView.builder(
                          itemCount: morningStaff.length,
                          itemBuilder: (context, index) => _buildStaffCard(morningStaff[index]),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 48),
                Expanded(
                  child: Column(
                    children: [
                      _buildShiftHeader("Shift Soir / Nuit", Icons.nights_stay_rounded, const Color(0xFF6366F1)),
                      const SizedBox(height: 24),
                      Expanded(
                        child: ListView.builder(
                          itemCount: eveningStaff.length,
                          itemBuilder: (context, index) => _buildStaffCard(eveningStaff[index]),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShiftHeader(String title, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.1)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 14),
          Text(title.toUpperCase(), style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 1)),
        ],
      ),
    );
  }

  Widget _buildStaffCard(Map<String, dynamic> staff) {
    final cin = staff["cin"]?.toString() ?? "";
    final perf = Map<String, dynamic>.from(performanceData[cin] ?? {});
    final bool isAdminRole = staff["role"] == "admin";

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(24),
      decoration: AppTheme.glassCard(),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: (isAdminRole ? AppTheme.primary : AppTheme.neonGreen).withOpacity(0.1), width: 3),
                ),
                child: CircleAvatar(
                  key: ValueKey("avatar_$cin"),
                  radius: 32,
                  backgroundColor: const Color(0xFFF1F5F9),
                  backgroundImage: (staff["photo_url"] != null && staff["photo_url"].toString().startsWith("data:image") && _decodedPhotos.containsKey(cin))
                      ? MemoryImage(_decodedPhotos[cin]!)
                      : (staff["photo_url"] != null && staff["photo_url"].toString().isNotEmpty)
                          ? NetworkImage(staff["photo_url"]) as ImageProvider
                          : null,
                  child: (staff["photo_url"] == null || staff["photo_url"].toString().isEmpty)
                      ? Text(
                          (staff["nom"]?.toString().isNotEmpty ?? false)
                              ? staff["nom"].toString()[0].toUpperCase()
                              : "?",
                          style: TextStyle(color: isAdminRole ? AppTheme.primary : AppTheme.neonGreen, fontWeight: FontWeight.w900, fontSize: 24),
                        )
                      : null,
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(staff["nom"]?.toString() ?? "", style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: AppTheme.primary)),
                        if (isAdminRole) ...[
                          const SizedBox(width: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(color: AppTheme.primary.withOpacity(0.08), borderRadius: BorderRadius.circular(6)),
                            child: const Text("ADMINISTRATEUR", style: TextStyle(color: AppTheme.primary, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Text("${staff["age"] ?? "0"} ans", style: const TextStyle(color: Color(0xFF64748B), fontSize: 13, fontWeight: FontWeight.w600)),
                        const SizedBox(width: 12),
                        const Icon(Icons.fiber_manual_record, size: 4, color: Color(0xFFCBD5E1)),
                        const SizedBox(width: 12),
                        Expanded(child: Text(staff["email"]?.toString() ?? "", style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13), overflow: TextOverflow.ellipsis)),
                      ],
                    ),
                  ],
                ),
              ),
              if (BaseService.isAdmin)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit_rounded, color: Color(0xFF94A3B8), size: 20),
                      onPressed: () => _showEditStaffDialog(context, staff),
                      hoverColor: AppTheme.primary.withOpacity(0.05),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded, color: AppTheme.sosRed, size: 20),
                      onPressed: () => _deleteStaff(staff),
                      hoverColor: AppTheme.sosRed.withOpacity(0.05),
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(12)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _statItem("INCIDENTS TRAITÉS", (perf["alerts_processed"] ?? 0).toString(), AppTheme.primary),
                Container(width: 1, height: 24, color: const Color(0xFFE2E8F0)),
                _statItem("ALERTES RÉSOLUES", (perf["alerts_resolved"] ?? 0).toString(), AppTheme.neonGreen),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _deleteStaff(Map<String, dynamic> staff) async {
    final cin = staff["cin"]?.toString() ?? "";
    final name = staff["nom"]?.toString() ?? "ce membre";

    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.bgCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: AppTheme.sosRed.withOpacity(0.3))),
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: AppTheme.sosRed, size: 28),
            const SizedBox(width: 16),
            const Text("CONFIRMER SUPPRESSION", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: 0.5)),
          ],
        ),
        content: Text("Êtes-vous sûr de vouloir supprimer $name (CIN: $cin) ? Cette action est irréversible.", style: TextStyle(color: Colors.white.withOpacity(0.7))),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text("ANNULER", style: TextStyle(color: Colors.white.withOpacity(0.4), fontWeight: FontWeight.bold)),
          ),
          AppGradientButton(
            onTap: () => Navigator.pop(ctx, true),
            icon: Icons.delete_forever_rounded,
            label: "SUPPRIMER",
            color: AppTheme.sosRed,
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final res = await StaffService.deleteStaff(cin);
      if (!mounted) return;
      if (res["success"] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Membre $name supprimé avec succès"), backgroundColor: AppTheme.neonGreen),
        );
        _loadData();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(res["error"] ?? "Erreur lors de la suppression"), backgroundColor: AppTheme.sosRed),
        );
      }
    }
  }

  Widget _statItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 22, color: color, letterSpacing: -0.5)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8), fontWeight: FontWeight.w800, letterSpacing: 0.5)),
      ],
    );
  }

  void _showEditStaffDialog(BuildContext context, Map<String, dynamic> staff) {
    final name = TextEditingController(text: staff['nom']?.toString() ?? "");
    final email = TextEditingController(text: staff['email']?.toString() ?? "");
    final age = TextEditingController(text: staff['age']?.toString() ?? "");
    final phone = TextEditingController(text: _normalizePhoneDigits(staff['numero_de_telephone']?.toString() ?? ""));
    final address = TextEditingController(text: staff['adresse']?.toString() ?? "");
    final password = TextEditingController();
    String? photoUrl = staff['photo_url']?.toString();
    String shift = staff['shift'] == "Nuit" || staff['shift'] == "soir" ? "Nuit" : "Journée";
    String role = staff['role']?.toString() ?? "staff";

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            width: 600,
            decoration: BoxDecoration(
              color: AppTheme.bgCard,
              borderRadius: BorderRadius.circular(32),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 40)],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _dialogHeader("MODIFIER LE PROFIL STAFF", Icons.edit_note_rounded),
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(40),
                    child: Column(
                      children: [
                        _buildPhotoPicker(context, setDialogState, photoUrl, (newUrl) => photoUrl = newUrl),
                        const SizedBox(height: 40),
                        _buildField("Nom complet", name, Icons.person_rounded),
                        _buildField("Adresse Email", email, Icons.email_rounded),
                        _buildField("Âge", age, Icons.cake_rounded, isNumber: true),
                        _buildField("Téléphone Mobile", phone, Icons.phone_rounded, isPhone: true),
                        _buildField("Adresse Résidentielle", address, Icons.home_rounded),
                        _buildField("Réinitialiser le mot de passe", password, Icons.lock_rounded, obscure: true),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(child: _buildDropdown("Affectation Shift", shift, ["Journée", "Nuit"], Icons.schedule_rounded, (val) => setDialogState(() => shift = val!))),
                            const SizedBox(width: 24),
                            Expanded(child: _buildDropdown("Niveau d'Accès", role, ["staff", "admin"], Icons.admin_panel_settings_rounded, (val) => setDialogState(() => role = val!))),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                _dialogActions(ctx, "SAUVEGARDER LES MODIFICATIONS", Icons.check_circle_rounded, AppTheme.primary, () async {
                  final updated = {
                    "staff_id": staff['cin'],
                    "name": name.text,
                    "email": email.text,
                    "age": age.text,
                    "phone": _formatPhoneForBackend(phone.text),
                    "address": address.text,
                    "password": password.text,
                    "shift": shift,
                    "role": role,
                    "photo_url": photoUrl,
                  };
                  final res = await StaffService.updateStaff(updated);
                  if (!mounted) return;
                  if (res["success"] == true) {
                    Navigator.pop(ctx);
                    _loadData();
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res["error"] ?? "Erreur lors de la mise à jour"), backgroundColor: AppTheme.sosRed));
                  }
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showAddStaffDialog(BuildContext context) {
    final cin = TextEditingController();
    final name = TextEditingController();
    final email = TextEditingController();
    final age = TextEditingController();
    final password = TextEditingController();
    final phone = TextEditingController();
    final address = TextEditingController();
    String shift = "Journée";
    String role = "staff";
    String? photoUrl;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            width: 550,
            decoration: BoxDecoration(
              color: AppTheme.bgCard,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _dialogHeader("AJOUTER STAFF", Icons.person_add_alt_1_rounded),
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      children: [
                        _buildPhotoPicker(context, setDialogState, photoUrl, (newUrl) => photoUrl = newUrl),
                        const SizedBox(height: 32),
                        _buildField("CIN", cin, Icons.fingerprint_rounded),
                        _buildField("Nom complet", name, Icons.person_outline_rounded),
                        _buildField("Email", email, Icons.email_outlined),
                        _buildField("Âge", age, Icons.cake_outlined, isNumber: true),
                        _buildField("Mot de passe", password, Icons.lock_outline_rounded, obscure: true),
                        _buildField("Téléphone", phone, Icons.phone_outlined, isPhone: true),
                        _buildField("Adresse", address, Icons.home_outlined),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(child: _buildDropdown("Shift", shift, ["Journée", "Nuit"], Icons.access_time_rounded, (val) => setDialogState(() => shift = val!))),
                            const SizedBox(width: 16),
                            Expanded(child: _buildDropdown("Rôle", role, ["staff", "admin"], Icons.admin_panel_settings_outlined, (val) => setDialogState(() => role = val!))),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                _dialogActions(ctx, "ENREGISTRER", Icons.person_add_rounded, AppTheme.neonGreen, () async {
                  final newStaff = {
                    "staff_id": cin.text,
                    "name": name.text,
                    "email": email.text,
                    "age": age.text,
                    "password": password.text,
                    "phone": _formatPhoneForBackend(phone.text),
                    "address": address.text,
                    "shift": shift,
                    "role": role,
                    "photo_url": photoUrl,
                  };
                  final res = await StaffService.addStaff(newStaff);
                  if (!mounted) return;
                  if (res["success"] == true) {
                    Navigator.pop(ctx);
                    _loadData();
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res["error"] ?? "Erreur lors de l'ajout"), backgroundColor: AppTheme.sosRed));
                  }
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }

  Widget _dialogHeader(String title, IconData icon) => Container(
    padding: const EdgeInsets.all(32),
    decoration: BoxDecoration(
      color: const Color(0xFFF8FAFC), 
      borderRadius: const BorderRadius.vertical(top: Radius.circular(32)), 
      border: Border(bottom: BorderSide(color: Colors.grey.withOpacity(0.1)))
    ),
    child: Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: AppTheme.primary.withOpacity(0.08), borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, color: AppTheme.primary),
        ),
        const SizedBox(width: 20),
        Text(title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 20, color: AppTheme.primary, letterSpacing: 0.5)),
      ],
    ),
  );

  Widget _dialogActions(BuildContext context, String label, IconData icon, Color color, VoidCallback onSave) => Container(
    padding: const EdgeInsets.all(32),
    decoration: BoxDecoration(
      color: const Color(0xFFF8FAFC), 
      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(32)), 
      border: Border(top: BorderSide(color: Colors.grey.withOpacity(0.1)))
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text("ANNULER", style: TextStyle(color: Color(0xFF94A3B8), fontWeight: FontWeight.w900))),
        const SizedBox(width: 24),
        AppGradientButton(onTap: onSave, icon: icon, label: label, color: color),
      ],
    ),
  );

  Widget _buildField(String label, TextEditingController controller, IconData icon, {bool obscure = false, bool isNumber = false, bool isPhone = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        style: const TextStyle(color: AppTheme.primary, fontSize: 15, fontWeight: FontWeight.w600),
        keyboardType: isPhone || isNumber ? TextInputType.number : TextInputType.text,
        inputFormatters: isPhone ? [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(8)] : null,
        decoration: AppTheme.inputDecoration(label, icon).copyWith(
          prefixText: isPhone ? '+216 ' : null,
          prefixStyle: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildDropdown(String label, String value, List<String> items, IconData icon, Function(String?) onChanged) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label.toUpperCase(), style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1)),
      const SizedBox(height: 10),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC), 
          borderRadius: BorderRadius.circular(12), 
          border: Border.all(color: Colors.grey.withOpacity(0.1))
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: value,
            isExpanded: true,
            dropdownColor: Colors.white,
            icon: Icon(Icons.expand_more_rounded, size: 20, color: AppTheme.primary.withOpacity(0.5)),
            style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w700, fontSize: 15),
            items: items.map((i) => DropdownMenuItem(value: i, child: Text(i))).toList(),
            onChanged: onChanged,
          ),
        ),
      ),
    ],
  );

  Widget _buildPhotoPicker(BuildContext context, StateSetter setDialogState, String? currentUrl, Function(String?) onSelected) {
    return Column(
      children: [
        GestureDetector(
          onTap: () async {
            final picker = ImagePicker();
            final XFile? image = await picker.pickImage(source: ImageSource.gallery, maxWidth: 500, maxHeight: 500, imageQuality: 80);
            if (image != null) {
              final bytes = await image.readAsBytes();
              final base64Image = "data:image/png;base64,${base64Encode(bytes)}";
              setDialogState(() => onSelected(base64Image));
            }
          },
          child: Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppTheme.primary.withOpacity(0.1), width: 4),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20)],
                ),
                child: CircleAvatar(
                  radius: 64,
                  backgroundColor: const Color(0xFFF1F5F9),
                  backgroundImage: (currentUrl != null && currentUrl.startsWith("data:image"))
                      ? MemoryImage(base64Decode(currentUrl.split(',').last))
                      : (currentUrl != null && currentUrl.isNotEmpty)
                          ? NetworkImage(currentUrl) as ImageProvider
                          : null,
                  child: (currentUrl == null || currentUrl.isEmpty)
                      ? const Icon(Icons.add_a_photo_rounded, size: 40, color: Color(0xFF94A3B8))
                      : null,
                ),
              ),
              Positioned(
                right: 4, bottom: 4,
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: AppTheme.primary, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 3)),
                  child: const Icon(Icons.camera_alt_rounded, size: 18, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const Text("PHOTO DE PROFIL STAFF", style: TextStyle(fontSize: 10, color: Color(0xFF94A3B8), fontWeight: FontWeight.w900, letterSpacing: 1.5)),
      ],
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
