import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../core/api_service.dart';

class StaffPage extends StatefulWidget {
  const StaffPage({super.key});

  @override
  State<StaffPage> createState() => _StaffPageState();
}

class _StaffPageState extends State<StaffPage> {
  Map<String, dynamic> performanceData = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() async {
    final perf = await ApiService.getPerformance();
    if (mounted) {
      setState(() {
        performanceData = perf;
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

    performanceData.forEach((key, val) {
      final data = Map<String, dynamic>.from(val);
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
                    const Text("Équipes du Centre (Staff)", style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 4),
                    Text("Suivi des performances des équipes du Matin et du Soir", style: TextStyle(color: Colors.grey.shade600, fontSize: 15)),
                  ],
                ),
                if (ApiService.isAdmin)
                  ElevatedButton.icon(
                    onPressed: () => _showAddStaffDialog(context),
                    icon: const Icon(Icons.person_add_alt_1_rounded, size: 20),
                    label: const Text("Ajouter Membre"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
                      crossAxisAlignment: CrossAxisAlignment.start, 
                      children: [
                        _buildShiftSection(Icons.wb_sunny_rounded, "Équipe du Matin", Colors.orangeAccent, morningStaff),
                        const SizedBox(height: 40),
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
        staffList.isEmpty 
          ? Center(child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Text("Aucun staff assigné", style: TextStyle(color: Colors.grey.shade400)),
            )) 
          : Column(children: staffList.map((s) => _buildStaffCard(s)).toList()),
      ],
    );
  }

  Widget _buildShiftHeader(IconData icon, String title, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 12),
          Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: color.withOpacity(0.8))),
        ],
      ),
    );
  }

  Widget _buildStaffCard(Map<String, dynamic> staff) {
    int processed = staff['alerts_processed'] ?? 0;
    int resolved = staff['alerts_resolved'] ?? 0;
    int pending = staff['alerts_pending'] ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 15, offset: const Offset(0, 5))
        ]
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: AppTheme.primary,
                radius: 20,
                child: Text((staff['staff_name'] as String)[0].toUpperCase(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(staff['staff_name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  Text("Rôle: ${staff['role']}", style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _statItem("Traitées", processed.toString(), Colors.blueAccent),
              _statItem("Résolues", resolved.toString(), AppTheme.normalGreen),
              _statItem("En attente", pending.toString(), AppTheme.helpOrange),
            ],
          )
        ],
      ),
    );
  }

  Widget _statItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: color)),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 11)),
      ],
    );
  }

  void _showAddStaffDialog(BuildContext context) {
    final _name = TextEditingController();
    final _email = TextEditingController();
    final _password = TextEditingController();
    String _role = "staff";
    String _shift = "matin";

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text("Ajouter un Nouveau Membre", style: TextStyle(fontWeight: FontWeight.w900)),
          content: SizedBox(
            width: 450,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildField("Nom Complet", _name, Icons.person_outline),
                  const SizedBox(height: 16),
                  _buildField("Email", _email, Icons.email_outlined),
                  const SizedBox(height: 16),
                  _buildField("Mot de Passe", _password, Icons.lock_outline, obscure: true),
                  const SizedBox(height: 16),
                  
                  const Text("Rôle", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _role,
                    decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 16)),
                    items: const [
                      DropdownMenuItem(value: "staff", child: Text("Staff")),
                      DropdownMenuItem(value: "admin", child: Text("Admin")),
                    ],
                    onChanged: (val) => setDialogState(() => _role = val ?? "staff"),
                  ),
                  const SizedBox(height: 16),

                  const Text("Shift (Horaire)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _shift,
                    decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 16)),
                    items: const [
                      DropdownMenuItem(value: "matin", child: Text("Matin (Day Shift)")),
                      DropdownMenuItem(value: "soir", child: Text("Soir (Night Shift)")),
                    ],
                    onChanged: (val) => setDialogState(() => _shift = val ?? "matin"),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Annuler")),
            ElevatedButton(
              onPressed: () async {
                final name = _name.text.trim();
                final email = _email.text.trim();
                final pass = _password.text.trim();

                if (name.isEmpty || email.isEmpty || pass.isEmpty) {
                   _showError("Veuillez remplir tous les champs");
                   return;
                }

                // Email Regex
                final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                if (!emailRegex.hasMatch(email)) {
                  _showError("Format d'email invalide");
                  return;
                }

                if (pass.length < 6) {
                  _showError("Le mot de passe doit faire au moins 6 caractères");
                  return;
                }
                
                final staff = {
                  "staff_id": "staff_${DateTime.now().millisecondsSinceEpoch}",
                  "name": name,
                  "email": email,
                  "password": pass,
                  "role": _role,
                  "shift": _shift,
                };

                final success = await ApiService.addStaff(staff);
                if (success) {
                  Navigator.pop(ctx);
                  _loadData(); // Refresh list
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Membre ajouté !"), backgroundColor: AppTheme.normalGreen));
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
