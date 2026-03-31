import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/user_model.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nomController = TextEditingController();
  final TextEditingController _prenomController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneMalvoyantController = TextEditingController();
  final TextEditingController _phoneFamilleController = TextEditingController();
  
  bool _isLoading = false;

  void _register() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      
      final newUser = UserModel(
        userId: "user_${DateTime.now().millisecondsSinceEpoch}",
        nom: _nomController.text,
        prenom: _prenomController.text,
        birthday: "1990-01-01", // Simplify for demo
        email: _emailController.text,
        phoneNumberMalvoyant: _phoneMalvoyantController.text,
        phoneNumberFamille: _phoneFamilleController.text,
      );

      bool success = await ApiService.registerUser(newUser);
      
      setState(() => _isLoading = false);
      
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Compte créé avec succès !")));
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Erreur lors de la création du compte")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text("Créer un compte", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Container(
        height: double.infinity,
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/bg.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Card(
                color: Colors.white.withOpacity(0.9),
                elevation: 8,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextFormField(
                          controller: _nomController,
                          decoration: const InputDecoration(labelText: "Nom"),
                          validator: (val) => val!.isEmpty ? "Champ requis" : null,
                        ),
                        TextFormField(
                          controller: _prenomController,
                          decoration: const InputDecoration(labelText: "Prénom"),
                          validator: (val) => val!.isEmpty ? "Champ requis" : null,
                        ),
                        TextFormField(
                          controller: _emailController,
                          decoration: const InputDecoration(labelText: "Email"),
                          validator: (val) => val!.isEmpty ? "Champ requis" : null,
                        ),
                        TextFormField(
                          controller: _phoneMalvoyantController,
                          decoration: const InputDecoration(labelText: "Téléphone Malvoyant"),
                          keyboardType: TextInputType.phone,
                          validator: (val) => val!.isEmpty ? "Champ requis" : null,
                        ),
                        TextFormField(
                          controller: _phoneFamilleController,
                          decoration: const InputDecoration(labelText: "Téléphone Famille"),
                          keyboardType: TextInputType.phone,
                          validator: (val) => val!.isEmpty ? "Champ requis" : null,
                        ),
                        const SizedBox(height: 30),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _register,
                            child: _isLoading 
                              ? const CircularProgressIndicator()
                              : const Text("S'ENREGISTRER"),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
