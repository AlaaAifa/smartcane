import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../core/api_service.dart';

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

  void _loadData() async {
    final perf = await ApiService.getPerformance();
    final members = await ApiService.getStaffMembers();
    if (mounted) {
      setState(() {
        performanceData = perf;
        staffMembers = members;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    // Split staff into morning and evening
    List<Map<String, dynamic>> morningStaff = [];
    List<Map<String, dynamic>> eveningStaff = [];

    performanceData.forEach((staffId, val) {
      final data = Map<String, dynamic>.from(val);
      data['staff_id'] = staffId; // Injects the true ID from the map key
      if (data['shift'] == 'soir') {
        eveningStaff.add(data);
      } else {
        morningStaff.add(data);
      }
    });

    return SingleChildScrollView(
      child: Padding(
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
                    const Text("Équipes du Centre", style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 4),
                    Text("Gestion des membres et suivi des performances", style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
                  ],
                ),
                if (ApiService.isAdmin)
                  ElevatedButton.icon(
                    onPressed: () => _showAddStaffDialog(context),
                    icon: const Icon(Icons.person_add_alt_1_rounded, size: 20),
                    label: const Text("Ajouter Staff"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 32),
  
            LayoutBuilder(
              builder: (context, constraints) {
                final isNarrow = constraints.maxWidth < 900;
                return isNarrow 
                   ? Column(
                      children: [
                        _buildShiftSection(Icons.wb_sunny_rounded, "Équipe du Matin", Colors.orangeAccent, morningStaff),
                        const SizedBox(height: 32),
                        _buildShiftSection(Icons.nights_stay_rounded, "Équipe du Soir", Colors.indigoAccent, eveningStaff),
                      ],
                    )
                   : Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: _buildShiftSection(Icons.wb_sunny_rounded, "Équipe du Matin", Colors.orangeAccent, morningStaff)),
                        const SizedBox(width: 32),
                        Expanded(child: _buildShiftSection(Icons.nights_stay_rounded, "Équipe du Soir", Colors.indigoAccent, eveningStaff)),
                      ],
                    );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShiftSection(IconData icon, String title, Color color, List<Map<String, dynamic>> staffList) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildShiftHeader(icon, title, color),
        const SizedBox(height: 16),
        ...staffList.map((s) => _buildStaffCard(s)).toList(),
      ],
    );
  }

  Widget _buildShiftHeader(IconData icon, String title, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  Widget _buildStaffCard(Map<String, dynamic> staff) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10)]
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(backgroundColor: AppTheme.primary, radius: 18, child: Text((staff['staff_name'] as String)[0].toUpperCase(), style: const TextStyle(color: Colors.white))),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(staff['staff_name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  Text(staff['role'], style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                ],
              ),
              const Spacer(),
              if (ApiService.isAdmin) ...[
                IconButton(
                  icon: const Icon(Icons.edit_outlined, color: Colors.blueAccent, size: 20),
                  onPressed: () {
                    final detail = staffMembers.firstWhere((m) => m['staff_id'] == staff['staff_id'], orElse: () => {});
                    _showEditStaffDialog(context, detail);
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.info_outline_rounded, color: AppTheme.primary, size: 20),
                  onPressed: () {
                    final detail = staffMembers.firstWhere((m) => m['staff_id'] == staff['staff_id'], orElse: () => {});
                    _showStaffDetails(context, detail);
                  },
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _statItem("Traitées", (staff['alerts_processed'] ?? 0).toString(), Colors.blue),
              _statItem("Résolues", (staff['alerts_resolved'] ?? 0).toString(), Colors.green),
              _statItem("En cours", (staff['alerts_pending'] ?? 0).toString(), Colors.orange),
            ],
          )
        ],
      ),
    );
  }

  Widget _statItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: color)),
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
      ],
    );
  }

  void _showStaffDetails(BuildContext context, Map<String, dynamic> staff) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Informations Personnelles", style: TextStyle(fontWeight: FontWeight.w900)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _detailRow(Icons.mail_outline, "Email", staff['email'] ?? "—"),
            _detailRow(Icons.phone_outlined, "Téléphone", staff['phone'] ?? "—"),
            _detailRow(Icons.home_outlined, "Adresse", staff['address'] ?? "—"),
            _detailRow(Icons.work_outline, "Rôle", staff['role'] ?? "—"),
            _detailRow(Icons.access_time, "Shift", staff['shift'] ?? "—"),
          ],
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Fermer"))],
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppTheme.primary),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
              Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
            ],
          ),
        ],
      ),
    );
  }

  void _showEditStaffDialog(BuildContext context, Map<String, dynamic> staff) {
    final _name = TextEditingController(text: staff['name']);
    final _email = TextEditingController(text: staff['email']);
    final _phone = TextEditingController(text: staff['phone']);
    final _address = TextEditingController(text: staff['address']);
    String _role = staff['role'] ?? "staff";
    String _shift = staff['shift'] ?? "matin";

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text("Modifier Profil Staff", style: TextStyle(fontWeight: FontWeight.w900)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildField("Nom", _name, Icons.person),
                _buildField("Email", _email, Icons.email),
                _buildField("Téléphone", _phone, Icons.phone),
                _buildField("Adresse", _address, Icons.home),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _role,
                  items: const [DropdownMenuItem(value: "staff", child: Text("Staff")), DropdownMenuItem(value: "admin", child: Text("Admin"))],
                  onChanged: (v) => setDialogState(() => _role = v!),
                  decoration: const InputDecoration(labelText: "Rôle"),
                ),
                DropdownButtonFormField<String>(
                  value: _shift,
                  items: const [DropdownMenuItem(value: "matin", child: Text("Matin")), DropdownMenuItem(value: "soir", child: Text("Soir"))],
                  onChanged: (v) => setDialogState(() => _shift = v!),
                  decoration: const InputDecoration(labelText: "Shift"),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Annuler")),
            ElevatedButton(
              onPressed: () async {
                final updated = {
                  "staff_id": staff['staff_id'],
                  "name": _name.text,
                  "email": _email.text,
                  "phone": _phone.text,
                  "address": _address.text,
                  "role": _role,
                  "shift": _shift,
                  "password": staff['password'], // Keep original password
                };
                if (await ApiService.updateStaff(updated)) {
                  Navigator.pop(ctx);
                  _loadData();
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Profil mis à jour !"), backgroundColor: AppTheme.normalGreen));
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
    final _name = TextEditingController();
    final _email = TextEditingController();
    final _password = TextEditingController();
    final _phone = TextEditingController();
    final _address = TextEditingController();
    String _role = "staff";
    String _shift = "matin";

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text("Ajouter Staff", style: TextStyle(fontWeight: FontWeight.w900)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildField("Nom", _name, Icons.person),
                _buildField("Email", _email, Icons.email),
                _buildField("Mot de passe", _password, Icons.lock, obscure: true),
                _buildField("Téléphone", _phone, Icons.phone),
                _buildField("Adresse", _address, Icons.home),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _role,
                  items: const [DropdownMenuItem(value: "staff", child: Text("Staff")), DropdownMenuItem(value: "admin", child: Text("Admin"))],
                  onChanged: (v) => setDialogState(() => _role = v!),
                  decoration: const InputDecoration(labelText: "Rôle"),
                ),
                DropdownButtonFormField<String>(
                  value: _shift,
                  items: const [DropdownMenuItem(value: "matin", child: Text("Matin")), DropdownMenuItem(value: "soir", child: Text("Soir"))],
                  onChanged: (v) => setDialogState(() => _shift = v!),
                  decoration: const InputDecoration(labelText: "Shift"),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Annuler")),
            ElevatedButton(
              onPressed: () async {
                final staff = {
                  "staff_id": "staff_${DateTime.now().millisecondsSinceEpoch}",
                  "name": _name.text,
                  "email": _email.text,
                  "password": _password.text,
                  "phone": _phone.text,
                  "address": _address.text,
                  "role": _role,
                  "shift": _shift,
                };
                if (await ApiService.addStaff(staff)) {
                  Navigator.pop(ctx);
                  _loadData();
                }
              },
              child: const Text("Enregistrer"),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildField(String label, TextEditingController controller, IconData icon, {bool obscure = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: obscure,
          decoration: InputDecoration(
            prefixIcon: Icon(icon, size: 20),
            hintText: label,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
      ],
    );
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: AppTheme.sosRed,
    ));
  }
}
