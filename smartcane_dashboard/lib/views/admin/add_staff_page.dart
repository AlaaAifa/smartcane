import 'package:flutter/material.dart';
import '../../services/services.dart';

class AddStaffPage extends StatefulWidget {
  const AddStaffPage({super.key});

  @override
  State<AddStaffPage> createState() => _AddStaffPageState();
}

class _AddStaffPageState extends State<AddStaffPage> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  String _role = "staff";
  String _shift = "matin";
  bool _isLoading = false;

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final staff = {
      "staff_id": "staff_${DateTime.now().millisecondsSinceEpoch}",
      "name": _name.text,
      "email": _email.text,
      "password": _password.text,
      "role": _role,
      "shift": _shift,
    };

    final result = await StaffService.addStaff(staff);
    setState(() => _isLoading = false);

    if (result["success"] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Compte créé avec succès !"), backgroundColor: Colors.green),
      );
      _formKey.currentState!.reset();
      setState(() {
        _role = "staff";
        _shift = "matin";
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Erreur"), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Ajouter Staff / Admin", style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900)),
          const SizedBox(height: 4),
          Text("Créer un nouveau compte opérateur", style: TextStyle(color: Colors.grey.shade600)),
          const SizedBox(height: 32),

          Container(
            width: 500,
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Nom complet", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  const SizedBox(height: 6),
                  TextFormField(controller: _name, validator: (v) => v!.isEmpty ? "Requis" : null),
                  const SizedBox(height: 20),

                  const Text("Email", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  const SizedBox(height: 6),
                  TextFormField(controller: _email, validator: (v) => v!.isEmpty ? "Requis" : null),
                  const SizedBox(height: 20),

                  const Text("Mot de passe", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  const SizedBox(height: 6),
                  TextFormField(controller: _password, obscureText: true, validator: (v) => v!.isEmpty ? "Requis" : null),
                  const SizedBox(height: 20),

                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("Rôle", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                            const SizedBox(height: 6),
                            DropdownButtonFormField<String>(
                              value: _role,
                              items: const [
                                DropdownMenuItem(value: "staff", child: Text("Personnel")),
                                DropdownMenuItem(value: "admin", child: Text("Administrateur")),
                              ],
                              onChanged: (val) => setState(() => _role = val ?? "staff"),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("Shift", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                            const SizedBox(height: 6),
                            DropdownButtonFormField<String>(
                              value: _shift,
                              items: const [
                                DropdownMenuItem(value: "matin", child: Text("Matin")),
                                DropdownMenuItem(value: "soir", child: Text("Soir")),
                              ],
                              onChanged: (val) => setState(() => _shift = val ?? "matin"),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _submit,
                      child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text("CRÉER LE COMPTE"),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
