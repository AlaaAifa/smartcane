import 'package:flutter/material.dart';
import '../../core/api_service.dart';

class AddUserPage extends StatefulWidget {
  const AddUserPage({super.key});

  @override
  State<AddUserPage> createState() => _AddUserPageState();
}

class _AddUserPageState extends State<AddUserPage> {
  final _formKey = GlobalKey<FormState>();
  final _nom = TextEditingController();
  final _prenom = TextEditingController();
  final _email = TextEditingController();
  final _phoneMalvoyant = TextEditingController();
  final _phoneFamille = TextEditingController();
  final _caneId = TextEditingController();
  bool _isLoading = false;

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final user = {
      "user_id": "user_${DateTime.now().millisecondsSinceEpoch}",
      "nom": _nom.text,
      "prenom": _prenom.text,
      "email": _email.text,
      "phone_number_malvoyant": _phoneMalvoyant.text,
      "phone_number_famille": _phoneFamille.text,
      "birthday": "1990-01-01",
      "status": "normal",
    };

    final success = await ApiService.addUser(user);
    setState(() => _isLoading = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Utilisateur ajouté avec succès !"), backgroundColor: Colors.green),
      );
      _formKey.currentState!.reset();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Erreur lors de l'ajout"), backgroundColor: Colors.red),
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
          const Text("Ajouter un Utilisateur", style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900)),
          const SizedBox(height: 4),
          Text("Enregistrer un nouveau malvoyant", style: TextStyle(color: Colors.grey.shade600)),
          const SizedBox(height: 32),

          Expanded(
            child: Container(
              width: 600,
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(child: _field("Nom", _nom)),
                          const SizedBox(width: 16),
                          Expanded(child: _field("Prénom", _prenom)),
                        ],
                      ),
                      const SizedBox(height: 20),
                      _field("Email", _email),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(child: _field("Téléphone Malvoyant", _phoneMalvoyant)),
                          const SizedBox(width: 16),
                          Expanded(child: _field("Téléphone Famille", _phoneFamille)),
                        ],
                      ),
                      const SizedBox(height: 20),
                      _field("ID Canne (Serial)", _caneId),
                      const SizedBox(height: 32),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _submit,
                          child: _isLoading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text("ENREGISTRER"),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _field(String label, TextEditingController ctrl) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
        const SizedBox(height: 6),
        TextFormField(
          controller: ctrl,
          validator: (val) => val == null || val.isEmpty ? "Champ requis" : null,
        ),
      ],
    );
  }
}
