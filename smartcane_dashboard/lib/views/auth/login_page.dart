import 'dart:async';
import 'package:flutter/material.dart';
import '../theme.dart';
import '../../services/services.dart';

enum AuthView { login, forgotEmail, forgotOTP, forgotNewPassword }

class LoginPage extends StatefulWidget {
  final Function(String) onNavigate;
  const LoginPage({super.key, required this.onNavigate});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController(text: "aifaalaa97@gmail.com");
  final _passwordController = TextEditingController(text: "123456789");
  final _forgotEmailController = TextEditingController();
  final _otpController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  AuthView _currentView = AuthView.login;
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;
  String? _error;
  String? _successMessage;

  Timer? _otpTimer;
  int _secondsRemaining = 600; // 10 minutes

  @override
  void dispose() {
    _otpTimer?.cancel();
    _emailController.dispose();
    _passwordController.dispose();
    _forgotEmailController.dispose();
    _otpController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _startOtpTimer() {
    _otpTimer?.cancel();
    setState(() => _secondsRemaining = 600);
    _otpTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        setState(() => _secondsRemaining--);
      } else {
        timer.cancel();
      }
    });
  }

  String _formatTime(int seconds) {
    final mins = (seconds / 60).floor();
    final secs = seconds % 60;
    return "${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}";
  }

  void _login() async {
    setState(() { _isLoading = true; _error = null; });

    final result = await AuthService.login(
      _emailController.text.trim(),
      _passwordController.text.trim(),
    );

    setState(() => _isLoading = false);

    if (result != null && !result.containsKey("error")) {
      widget.onNavigate("/dashboard");
    } else {
      setState(() => _error = result?["error"] ?? "Une erreur inconnue est survenue");
    }
  }

  bool _validatePassword(String password) {
    if (password.length < 8) return false;
    if (!password.contains(RegExp(r'[A-Z]'))) return false;
    if (!password.contains(RegExp(r'[0-9]'))) return false;
    if (!password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) return false;
    return true;
  }

  void _requestResetEmail() async {
    final email = _forgotEmailController.text.trim();

    if (email.isEmpty || !email.contains("@")) {
      setState(() => _error = "Veuillez entrer une adresse e-mail valide");
      return;
    }

    setState(() { _isLoading = true; _error = null; });
    final success = await AuthService.requestPasswordReset(email);
    setState(() => _isLoading = false);

    if (success) {
      setState(() {
        _currentView = AuthView.forgotOTP;
        _successMessage = "Un code de vérification a été généré pour $email";
        _startOtpTimer();
      });
    } else {
      setState(() => _error = "Impossible de contacter le serveur ou email incorrect.");
    }
  }

  void _verifyCode() async {
    final email = _forgotEmailController.text.trim();
    final code = _otpController.text.trim();

    if (code.isEmpty || code.length < 6) {
      setState(() => _error = "Veuillez entrer le code de vérification à 6 chiffres");
      return;
    }

    // Remove spaces and normalize the code
    final normalizedCode = code.replaceAll(' ', '');
    
    setState(() { _isLoading = true; _error = null; });
    final success = await AuthService.verifyOtp(email, normalizedCode);
    setState(() => _isLoading = false);

    if (success) {
      _otpTimer?.cancel();
      setState(() {
        _currentView = AuthView.forgotNewPassword;
        _successMessage = "Code vérifié avec succès. Définissez votre nouveau mot de passe.";
        _error = null;
      });
    } else {
      setState(() => _error = "Code incorrect. Vérifiez votre e-mail et entrez le code numérique à 6 chiffres.");
    }
  }

  void _resetPasswordFinal() async {
    final email = _forgotEmailController.text.trim();
    final newPass = _newPasswordController.text.trim();
    final confirmPass = _confirmPasswordController.text.trim();

    if (!_validatePassword(newPass)) {
      setState(() => _error = "Le mot de passe doit contenir au moins 8 caractères, une majuscule, un chiffre et un symbole.");
      return;
    }

    if (newPass != confirmPass) {
      setState(() => _error = "Les mots de passe ne correspondent pas.");
      return;
    }

    setState(() { _isLoading = true; _error = null; });
    final success = await AuthService.resetPassword(email, newPass);
    setState(() => _isLoading = false);

    if (success) {
      setState(() {
        _currentView = AuthView.login;
        _successMessage = "Mot de passe réinitialisé avec succès ! Connectez-vous maintenant.";
        _error = null;
        _otpController.clear();
        _forgotEmailController.clear();
        _newPasswordController.clear();
        _confirmPasswordController.clear();
      });
    } else {
      setState(() => _error = "Une erreur est survenue lors de la réinitialisation.");
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

          // Right panel - form (Dynamic based on state)
          Expanded(
            child: Center(
              child: SizedBox(
                width: 400,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: _buildCurrentForm(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentForm() {
    switch (_currentView) {
      case AuthView.login:
        return _buildLoginForm();
      case AuthView.forgotEmail:
        return _buildForgotEmailForm();
      case AuthView.forgotOTP:
        return _buildForgotOTPForm();
      case AuthView.forgotNewPassword:
        return _buildForgotNewPasswordForm();
    }
  }

  Widget _buildLoginForm() {
    return Column(
      key: const ValueKey("login_form"),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Connexion", style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900)),
        const SizedBox(height: 8),
        Text("Accédez au tableau de bord", style: TextStyle(color: Colors.grey.shade600, fontSize: 16)),
        
        if (_successMessage != null) ...[
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(8)),
            child: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.green, size: 20),
                const SizedBox(width: 12),
                Expanded(child: Text(_successMessage!, style: TextStyle(color: Colors.green.shade800, fontSize: 13))),
              ],
            ),
          ),
        ],

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
          obscureText: _obscurePassword,
          decoration: InputDecoration(
            hintText: "••••••••",
            prefixIcon: const Icon(Icons.lock_outline),
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword ? Icons.visibility_off : Icons.visibility,
                color: Colors.grey,
              ),
              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
            ),
          ),
          onSubmitted: (_) => _login(),
        ),
        
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () => setState(() {
              _currentView = AuthView.forgotEmail;
              _error = null;
              _successMessage = null;
            }),
            child: const Text("Mot de passe oublié ?", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          ),
        ),

        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 12),
            child: Text(_error!, style: const TextStyle(color: AppTheme.sosRed, fontSize: 13)),
          ),

        const SizedBox(height: 20),
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
    );
  }

  Widget _buildForgotEmailForm() {
    return Column(
      key: const ValueKey("forgot_email_form"),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        IconButton(
          onPressed: () => setState(() => _currentView = AuthView.login),
          icon: const Icon(Icons.arrow_back),
          padding: EdgeInsets.zero,
          alignment: Alignment.centerLeft,
        ),
        const SizedBox(height: 20),
        const Text("Réinitialisation", style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900)),
        const SizedBox(height: 8),
        Text("Entrez votre email personnel pour recevoir un code", style: TextStyle(color: Colors.grey.shade600, fontSize: 16)),
        const SizedBox(height: 40),

        const Text("Email Personnel", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
        const SizedBox(height: 8),
        TextField(
          controller: _forgotEmailController,
          decoration: const InputDecoration(
            hintText: "exemple@gmail.com",
            prefixIcon: Icon(Icons.email_outlined),
          ),
        ),

        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(top: 16, bottom: 4),
            child: Text(_error!, style: const TextStyle(color: AppTheme.sosRed, fontSize: 13)),
          ),

        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _requestResetEmail,
            child: _isLoading
              ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : const Text("ENVOYER LE CODE", style: TextStyle(letterSpacing: 1)),
          ),
        ),
      ],
    );
  }

  Widget _buildForgotOTPForm() {
    return Column(
      key: const ValueKey("forgot_otp_form"),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        IconButton(
          onPressed: () => setState(() => _currentView = AuthView.forgotEmail),
          icon: const Icon(Icons.arrow_back),
          padding: EdgeInsets.zero,
          alignment: Alignment.centerLeft,
        ),
        const SizedBox(height: 20),
        const Text("Vérification", style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900)),
        const SizedBox(height: 8),
        Text("Entrez le code numérique à 6 chiffres envoyé sur votre e-mail", style: TextStyle(color: Colors.grey.shade600, fontSize: 16)),
        
        if (_successMessage != null) ...[
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: AppTheme.sidebarBg.withOpacity(0.05), borderRadius: BorderRadius.circular(8)),
            child: Text(_successMessage!, style: const TextStyle(color: AppTheme.sidebarBg, fontSize: 13)),
          ),
        ],

        const SizedBox(height: 40),

        const Text("Code de vérification", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
        const SizedBox(height: 8),
        TextField(
          controller: _otpController,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 8),
          decoration: const InputDecoration(
            hintText: "••••••",
            contentPadding: EdgeInsets.symmetric(vertical: 16),
          ),
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 16),
        Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.timer_outlined, size: 16, color: _secondsRemaining < 60 ? AppTheme.sosRed : Colors.grey),
              const SizedBox(width: 8),
              Text(
                "Le code expire dans: ${_formatTime(_secondsRemaining)}",
                style: TextStyle(
                  color: _secondsRemaining < 60 ? AppTheme.sosRed : Colors.grey.shade600,
                  fontWeight: _secondsRemaining < 60 ? FontWeight.bold : FontWeight.normal,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),

        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(top: 16, bottom: 4),
            child: Text(_error!, style: const TextStyle(color: AppTheme.sosRed, fontSize: 13)),
          ),

        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _verifyCode,
            child: _isLoading
              ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : const Text("VÉRIFIER LE CODE", style: TextStyle(letterSpacing: 1)),
          ),
        ),
        const SizedBox(height: 16),
        Center(
          child: TextButton(
            onPressed: () => _requestResetEmail(),
            child: const Text("Renvoyer le code", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          ),
        ),
      ],
    );
  }

  Widget _buildForgotNewPasswordForm() {
    return Column(
      key: const ValueKey("forgot_new_pass_form"),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Nouveau mot de passe", style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900)),
        const SizedBox(height: 8),
        Text("Sécurisez votre compte avec un nouveau mot de passe", style: TextStyle(color: Colors.grey.shade600, fontSize: 16)),
        const SizedBox(height: 40),

        const Text("Nouveau mot de passe", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
        const SizedBox(height: 8),
        TextField(
          controller: _newPasswordController,
          obscureText: _obscureNewPassword,
          decoration: InputDecoration(
            hintText: "••••••••",
            prefixIcon: const Icon(Icons.lock_reset_outlined),
            suffixIcon: IconButton(
              icon: Icon(
                _obscureNewPassword ? Icons.visibility_off : Icons.visibility,
                color: Colors.grey,
              ),
              onPressed: () => setState(() => _obscureNewPassword = !_obscureNewPassword),
            ),
          ),
        ),
        const SizedBox(height: 20),

        const Text("Confirmer le mot de passe", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
        const SizedBox(height: 8),
        TextField(
          controller: _confirmPasswordController,
          obscureText: _obscureConfirmPassword,
          decoration: InputDecoration(
            hintText: "••••••••",
            prefixIcon: const Icon(Icons.check_circle_outline),
            suffixIcon: IconButton(
              icon: Icon(
                _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
                color: Colors.grey,
              ),
              onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          "Doit contenir 8+ caractères, majuscule, chiffre et symbole.",
          style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
        ),

        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(top: 16, bottom: 4),
            child: Text(_error!, style: const TextStyle(color: AppTheme.sosRed, fontSize: 13)),
          ),

        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _resetPasswordFinal,
            child: _isLoading
              ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : const Text("RÉINITIALISER", style: TextStyle(letterSpacing: 1)),
          ),
        ),
      ],
    );
  }
}
