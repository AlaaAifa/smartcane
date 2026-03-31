import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../core/api_service.dart';

class LoginPage extends StatefulWidget {
  final Function(String) onNavigate;
  const LoginPage({super.key, required this.onNavigate});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController(text: "admin@smartcane.com");
  final _passwordController = TextEditingController(text: "admin123");
  bool _isLoading = false;
  String? _error;

  void _login() async {
    setState(() { _isLoading = true; _error = null; });

    final result = await ApiService.login(
      _emailController.text.trim(),
      _passwordController.text.trim(),
    );

    setState(() => _isLoading = false);

    if (result != null) {
      widget.onNavigate("/dashboard");
    } else {
      setState(() => _error = "Email ou mot de passe incorrect");
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Row(
        children: [
          // Left panel - branding
          Container(
            width: size.width * 0.45,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppTheme.sidebarBg, AppTheme.primary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.visibility, color: Colors.white, size: 80),
                  ),
                  const SizedBox(height: 32),
                  const Text(
                    "Smart Cane",
                    style: TextStyle(color: Colors.white, fontSize: 42, fontWeight: FontWeight.w900, letterSpacing: 1),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "Centre de Surveillance",
                    style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 18),
                  ),
                ],
              ),
            ),
          ),

          // Right panel - login form
          Expanded(
            child: Center(
              child: SizedBox(
                width: 400,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Connexion", style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 8),
                    Text("Accédez au tableau de bord", style: TextStyle(color: Colors.grey.shade600, fontSize: 16)),
                    const SizedBox(height: 40),

                    const Text("Email", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                        hintText: "admin@smartcane.com",
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                    ),
                    const SizedBox(height: 20),

                    const Text("Mot de passe", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        hintText: "••••••••",
                        prefixIcon: Icon(Icons.lock_outline),
                      ),
                      onSubmitted: (_) => _login(),
                    ),
                    const SizedBox(height: 12),

                    if (_error != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Text(_error!, style: const TextStyle(color: AppTheme.sosRed, fontSize: 13)),
                      ),

                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _login,
                        child: _isLoading
                          ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Text("SE CONNECTER", style: TextStyle(letterSpacing: 1)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
