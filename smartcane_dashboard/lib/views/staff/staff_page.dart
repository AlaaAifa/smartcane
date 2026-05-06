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
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final perf = await DashboardService.getPerformance();
    final members = await StaffService.getStaffMembers();
    if (!mounted) {
      return;
    }
    setState(() {
      performanceData = perf;
      staffMembers = members;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final morningStaff = staffMembers.where((s) => s["shift"] == "Journée" || s["shift"] == "matin" || s["shift"] == null).toList();
    final eveningStaff = staffMembers.where((s) => s["shift"] == "Nuit" || s["shift"] == "soir").toList();

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
                  const Text("Équipe Staff", style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 4),
                  Text("${staffMembers.length} membres au total", style: TextStyle(color: Colors.grey.shade600)),
                ],
              ),
              if (BaseService.isAdmin)
                ElevatedButton.icon(
                  onPressed: () => _showAddStaffDialog(context),
                  icon: const Icon(Icons.person_add_alt_1_rounded),
                  label: const Text("Ajouter Staff"),
                ),
            ],
          ),
          const SizedBox(height: 32),
          Expanded(
            child: Row(
              children: [
                // --- MORNING COLUMN ---
                Expanded(
                  child: Column(
                    children: [
                      _buildShiftHeader("SHIFT Journée", Icons.wb_sunny_rounded, Colors.orange),
                      const SizedBox(height: 16),
                      Expanded(
                        child: ListView.builder(
                          itemCount: morningStaff.length,
                          itemBuilder: (context, index) => _buildStaffCard(morningStaff[index]),
                        ),
                      ),
                    ],
                  ),
                ),
                
                // --- VERTICAL DIVIDER ---
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Container(
                    width: 1,
                    color: Colors.grey.shade300,
                  ),
                ),

                // --- EVENING COLUMN ---
                Expanded(
                  child: Column(
                    children: [
                      _buildShiftHeader("SHIFT Nuit", Icons.nightlight_round, Colors.indigo),
                      const SizedBox(height: 16),
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
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Text(title, style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 1.2)),
        ],
      ),
    );
  }

  Widget _buildStaffCard(Map<String, dynamic> staff) {
    final cin = staff["cin"]?.toString() ?? "";
    final perf = Map<String, dynamic>.from(performanceData[cin] ?? {});

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10)],
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: AppTheme.primary.withOpacity(0.1),
                backgroundImage: (staff["photo_url"] != null && staff["photo_url"].toString().startsWith("data:image"))
                    ? MemoryImage(base64Decode(staff["photo_url"].toString().split(',').last))
                    : (staff["photo_url"] != null && staff["photo_url"].toString().isNotEmpty)
                        ? NetworkImage(staff["photo_url"]) as ImageProvider
                        : null,
                child: (staff["photo_url"] == null || staff["photo_url"].toString().isEmpty)
                    ? Text(
                        (staff["nom"]?.toString().isNotEmpty ?? false)
                            ? staff["nom"].toString()[0].toUpperCase()
                            : "?",
                        style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold),
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(staff["nom"]?.toString() ?? "", style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                    Row(
                      children: [
                        Text("${staff["age"] ?? "0"} ans", style: TextStyle(color: AppTheme.primary, fontSize: 11, fontWeight: FontWeight.bold)),
                        const SizedBox(width: 8),
                        Text(staff["email"]?.toString() ?? "", style: TextStyle(color: Colors.grey.shade600, fontSize: 11)),
                      ],
                    ),
                  ],
                ),
              ),
              if (BaseService.isAdmin)
                IconButton(
                  icon: const Icon(Icons.edit_outlined, color: AppTheme.primary, size: 20),
                  onPressed: () => _showEditStaffDialog(context, staff),
                ),
            ],
          ),
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _statItem("Traitées", (perf["alerts_processed"] ?? 0).toString(), Colors.blue),
              _statItem("Résolues", (perf["alerts_resolved"] ?? 0).toString(), Colors.green),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: color)),
        Text(label, style: const TextStyle(fontSize: 9, color: Colors.grey, fontWeight: FontWeight.bold)),
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
    
    String rawShift = staff['shift']?.toString() ?? "Journée";
    String shift = "Journée";
    if (rawShift == "Nuit" || rawShift == "soir") {
      shift = "Nuit";
    }

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text("Modifier Staff", style: TextStyle(fontWeight: FontWeight.w900)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildPhotoPicker(context, setDialogState, photoUrl, (newUrl) => photoUrl = newUrl),
                const SizedBox(height: 16),
                _buildField("Nom", name, Icons.person),
                _buildField("Email", email, Icons.email),
                _buildField("Âge", age, Icons.cake, isNumber: true),
                _buildField("Téléphone", phone, Icons.phone, isPhone: true),
                _buildField("Adresse", address, Icons.home),
                _buildField("Nouveau mot de passe", password, Icons.lock, obscure: true),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: shift,
                  decoration: const InputDecoration(labelText: "Shift", prefixIcon: Icon(Icons.access_time)),
                  items: const [
                    DropdownMenuItem(value: "Journée", child: Text("Journée")),
                    DropdownMenuItem(value: "Nuit", child: Text("Nuit")),
                  ],
                  onChanged: (val) => setDialogState(() => shift = val ?? "Journée"),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Annuler")),
            ElevatedButton(
              onPressed: () async {
                final updated = {
                  "staff_id": staff['cin'],
                  "name": name.text,
                  "email": email.text,
                  "age": age.text,
                  "phone": _formatPhoneForBackend(phone.text),
                  "address": address.text,
                  "password": password.text,
                  "shift": shift,
                  "photo_url": photoUrl,
                };
                final res = await StaffService.updateStaff(updated);
                if (!mounted) return;
                
                if (res["success"] == true) {
                  Navigator.pop(ctx);
                  _loadData();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(res["error"] ?? "Erreur lors de la mise à jour"),
                    backgroundColor: Colors.red,
                  ));
                }
              },
              child: const Text("Mettre à jour"),
            ),
          ],
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
    String? photoUrl;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text("Ajouter Staff", style: TextStyle(fontWeight: FontWeight.w900)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildPhotoPicker(context, setDialogState, photoUrl, (newUrl) => photoUrl = newUrl),
                const SizedBox(height: 16),
                _buildField("CIN", cin, Icons.fingerprint),
                _buildField("Nom", name, Icons.person),
                _buildField("Email", email, Icons.email),
                _buildField("Âge", age, Icons.cake, isNumber: true),
                _buildField("Mot de passe", password, Icons.lock, obscure: true),
                _buildField("Téléphone", phone, Icons.phone, isPhone: true),
                _buildField("Adresse", address, Icons.home),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: shift,
                  decoration: const InputDecoration(labelText: "Shift", prefixIcon: Icon(Icons.access_time)),
                  items: const [
                    DropdownMenuItem(value: "Journée", child: Text("Journée")),
                    DropdownMenuItem(value: "Nuit", child: Text("Nuit")),
                  ],
                  onChanged: (val) => setDialogState(() => shift = val ?? "Journée"),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Annuler")),
            ElevatedButton(
              onPressed: () async {
                final newStaff = {
                  "staff_id": cin.text,
                  "name": name.text,
                  "email": email.text,
                  "age": age.text,
                  "password": password.text,
                  "phone": _formatPhoneForBackend(phone.text),
                  "address": address.text,
                  "shift": shift,
                  "photo_url": photoUrl,
                };
                final res = await StaffService.addStaff(newStaff);
                if (!mounted) return;
                
                if (res["success"] == true) {
                  Navigator.pop(ctx);
                  _loadData();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(res["error"] ?? "Erreur lors de l'ajout"),
                    backgroundColor: Colors.red,
                  ));
                }
              },
              child: const Text("Enregistrer"),
            ),
          ],
        ),
      ),
    );
  }

  // Normalise an existing phone value → returns only the 8-digit part
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

  Widget _buildField(String label, TextEditingController controller, IconData icon, {bool obscure = false, bool isNumber = false, bool isPhone = false}) {
    if (isPhone && controller.text.isNotEmpty) {
      final normalized = _normalizePhoneDigits(controller.text);
      if (controller.text != normalized) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (controller.text != normalized) controller.text = normalized;
        });
      }
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        keyboardType: isPhone || isNumber ? TextInputType.number : TextInputType.text,
        inputFormatters: isPhone
            ? [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(8),
              ]
            : null,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: isPhone ? null : Icon(icon, size: 20),
          prefix: isPhone
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, size: 20, color: Colors.grey),
                    const SizedBox(width: 6),
                    Text(
                      '+216 ',
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ],
                )
              : null,
          hintText: isPhone ? '12 345 678' : null,
        ),
      ),
    );
  }

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
              setDialogState(() {
                onSelected(base64Image);
              });
            }
          },
          child: Stack(
            children: [
              CircleAvatar(
                radius: 50,
                backgroundColor: AppTheme.primary.withOpacity(0.1),
                backgroundImage: (currentUrl != null && currentUrl.startsWith("data:image"))
                    ? MemoryImage(base64Decode(currentUrl.split(',').last))
                    : (currentUrl != null && currentUrl.isNotEmpty)
                        ? NetworkImage(currentUrl) as ImageProvider
                        : null,
                child: (currentUrl == null || currentUrl.isEmpty)
                    ? const Icon(Icons.add_a_photo, size: 30, color: AppTheme.primary)
                    : null,
              ),
              if (currentUrl != null && currentUrl.isNotEmpty)
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(color: AppTheme.primary, shape: BoxShape.circle),
                    child: const Icon(Icons.edit, size: 14, color: Colors.white),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          currentUrl == null ? "Cliquez pour ajouter une photo" : "Changer la photo",
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
