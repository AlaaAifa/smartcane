import 'dart:async';
import 'package:flutter/material.dart';
import '../theme.dart';
import '../../services/services.dart';
import '../layout/sirius_logo.dart';
import 'sirius_transition_screen.dart';

enum AuthView { login, forgotEmail, forgotOTP, forgotNewPassword }

class LoginPage extends StatefulWidget {
  final Function(String) onNavigate;
  const LoginPage({super.key, required this.onNavigate});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with SingleTickerProviderStateMixin {
  final _emailController = TextEditingController(text: "aifaalaa97@gmail.com");
  final _passwordController = TextEditingController(text: "123456789");
  final _forgotEmailController = TextEditingController();
  final _otpController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  AuthView _currentView = AuthView.login;
  bool _isLoading = false;
  bool _showSuccessTransition = false;
  bool _obscurePassword = true;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;
  bool _rememberMe = false;
  String? _error;
  String? _successMessage;

  late AnimationController _brandingController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  final FocusNode _emailFocus = FocusNode();
  final FocusNode _passwordFocus = FocusNode();
  final FocusNode _forgotEmailFocus = FocusNode();
  final FocusNode _otpFocus = FocusNode();
  final FocusNode _newPasswordFocus = FocusNode();
  final FocusNode _confirmPasswordFocus = FocusNode();

  Timer? _otpTimer;
  int _secondsRemaining = 600; 

  @override
  void initState() {
    super.initState();
    _brandingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _fadeAnim = CurvedAnimation(parent: _brandingController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.05), end: Offset.zero).animate(
      CurvedAnimation(parent: _brandingController, curve: Curves.easeOutCubic),
    );

    _brandingController.forward();

    _emailFocus.addListener(() => setState(() {}));
    _passwordFocus.addListener(() => setState(() {}));
    _forgotEmailFocus.addListener(() => setState(() {}));
    _otpFocus.addListener(() => setState(() {}));
    _newPasswordFocus.addListener(() => setState(() {}));
    _confirmPasswordFocus.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _brandingController.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    _forgotEmailFocus.dispose();
    _otpFocus.dispose();
    _newPasswordFocus.dispose();
    _confirmPasswordFocus.dispose();
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
      setState(() => _showSuccessTransition = true);
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
    final rawCode = _otpController.text.trim();
    final normalizedCode = rawCode.replaceAll(' ', '');
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
    final success = await AuthService.resetPassword(email, normalizedCode, newPass);
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
      setState(() => _error = "Échec de la réinitialisation. Le code est peut-être expiré ou vous tentez de modifier un compte protégé.");
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_showSuccessTransition) {
      return SiriusTransitionScreen(
        onFinished: () => widget.onNavigate("/dashboard"),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF070c18),
      body: Row(
        children: [
          // Left Column: Branding
          Expanded(
            flex: 10,
            child: Container(
              decoration: const BoxDecoration(
                color: Color(0xFF080e1c),
                border: Border(right: BorderSide(color: Color(0x12FFFFFF), width: 0.5)),
              ),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // Decorative Circles
                  Positioned(
                    top: -60,
                    left: -60,
                    child: Container(
                      width: 280,
                      height: 280,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFA028).withOpacity(0.06),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: -30,
                    right: -30,
                    child: Container(
                      width: 180,
                      height: 180,
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E8CFF).withOpacity(0.06),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  // Content
                  FadeTransition(
                    opacity: _fadeAnim,
                    child: SlideTransition(
                      position: _slideAnim,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Logo & Brand Name
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const SiriusLogo(size: 56),
                              const SizedBox(width: 24),
                              const Text(
                                "SIRIUS",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 48,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 12,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            "L'ÉTOILE QUI NE VOUS QUITTE JAMAIS",
                            style: TextStyle(
                              color: const Color(0xFFF5A623).withOpacity(0.95),
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 4,
                            ),
                          ),
                          const SizedBox(height: 80),
                          // Slogan
                          const Column(
                            children: [
                              Text(
                                "Sous l'étoile Sirius,",
                                style: TextStyle(color: Color(0xFFFFFFFF), fontSize: 26, fontWeight: FontWeight.w800),
                              ),
                              Text(
                                "chaque pas est sûr.",
                                style: TextStyle(color: Color(0xFFF5A623), fontSize: 26, fontWeight: FontWeight.w800),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          const SizedBox(
                            width: 380,
                            child: Text(
                              "Surveillance temps réel des malvoyants — cannes connectées, alertes GPS et SOS instantanés.",
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Color(0xFF64748B), fontSize: 15, height: 1.6),
                            ),
                          ),
                          const SizedBox(height: 80),
                          // Bottom Pills
                          Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  _buildPill(Icons.location_on_rounded, "GPS Live", const Color(0xFF4FB3FF), const Color(0xFF1E8CFF)),
                                  const SizedBox(width: 16),
                                  _buildPill(Icons.notifications_active_rounded, "Alertes SOS", const Color(0xFFF5A623), const Color(0xFFF5A623)),
                                ],
                              ),
                              const SizedBox(height: 16),
                              _buildPill(Icons.access_time_filled_rounded, "24 / 7", const Color(0xFFFFD84A), const Color(0xFFFFDC50)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Right Column: Form
          Expanded(
            flex: 11,
            child: Center(
              child: Container(
                width: 420,
                padding: const EdgeInsets.all(40),
                decoration: BoxDecoration(
                  color: const Color(0xFF0c1424),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: Colors.white.withOpacity(0.07), width: 0.5),
                ),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: Column(
                    key: ValueKey(_currentView),
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _currentView == AuthView.login ? "Connexion" : 
                        _currentView == AuthView.forgotEmail ? "Mot de passe oublié" :
                        _currentView == AuthView.forgotOTP ? "Vérification" : "Nouveau mot de passe",
                        style: const TextStyle(color: Color(0xFFFFFFFF), fontSize: 19, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _currentView == AuthView.login ? "Accédez au tableau de bord de surveillance SIRIUS" :
                        _currentView == AuthView.forgotEmail ? "Entrez votre email pour recevoir un code" :
                        _currentView == AuthView.forgotOTP ? "Entrez le code envoyé à votre adresse e-mail" : "Définissez votre nouveau mot de passe sécurisé",
                        style: const TextStyle(color: Color(0xFF3A567A), fontSize: 12),
                      ),
                      const SizedBox(height: 24),
                      
                      if (_error != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          margin: const EdgeInsets.only(bottom: 20),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.red.withOpacity(0.3)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.error_outline, color: Colors.red, size: 18),
                              const SizedBox(width: 12),
                              Expanded(child: Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 12))),
                            ],
                          ),
                        ),

                      if (_successMessage != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          margin: const EdgeInsets.only(bottom: 20),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.green.withOpacity(0.3)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.check_circle_outline, color: Colors.green, size: 18),
                              const SizedBox(width: 12),
                              Expanded(child: Text(_successMessage!, style: const TextStyle(color: Colors.green, fontSize: 12))),
                            ],
                          ),
                        ),

                      if (_currentView == AuthView.login) ...[
                        _buildLabel("IDENTIFIANT"),
                        const SizedBox(height: 8),
                        _buildTextField(
                          controller: _emailController,
                          hint: "Votre email ou ID",
                          icon: Icons.person_rounded,
                          color: const Color(0xFF4fb3ff),
                          focusNode: _emailFocus,
                        ),
                        const SizedBox(height: 20),
                        _buildLabel("MOT DE PASSE"),
                        const SizedBox(height: 8),
                        _buildTextField(
                          controller: _passwordController,
                          hint: "Votre mot de passe",
                          icon: Icons.lock_rounded,
                          color: const Color(0xFF4fb3ff),
                          isPassword: true,
                          obscureText: _obscurePassword,
                          onToggleVisibility: () => setState(() => _obscurePassword = !_obscurePassword),
                          focusNode: _passwordFocus,
                        ),
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: () => setState(() {
                                _currentView = AuthView.forgotEmail;
                                _error = null;
                                _successMessage = null;
                              }),
                              child: const Text(
                                "Mot de passe oublié ?",
                                style: TextStyle(color: Color(0xFF4fb3ff), fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        _HoverScaleButton(
                          onTap: _isLoading ? null : _login,
                          child: _buildSubmitButton("SE CONNECTER"),
                        ),
                      ],

                      if (_currentView == AuthView.forgotEmail) ...[
                        _buildLabel("EMAIL DE RÉCUPÉRATION"),
                        const SizedBox(height: 8),
                        _buildTextField(
                          controller: _forgotEmailController,
                          hint: "votre@email.com",
                          icon: Icons.email_rounded,
                          color: const Color(0xFF4fb3ff),
                          focusNode: _forgotEmailFocus,
                        ),
                        const SizedBox(height: 32),
                        _HoverScaleButton(
                          onTap: _isLoading ? null : _requestResetEmail,
                          child: _buildSubmitButton("ENVOYER LE CODE"),
                        ),
                      ],

                      if (_currentView == AuthView.forgotOTP) ...[
                        _buildLabel("CODE DE VÉRIFICATION"),
                        const SizedBox(height: 8),
                        _buildTextField(
                          controller: _otpController,
                          hint: "6 chiffres",
                          icon: Icons.pin_rounded,
                          color: const Color(0xFF4fb3ff),
                          focusNode: _otpFocus,
                        ),
                        const SizedBox(height: 32),
                        _HoverScaleButton(
                          onTap: _isLoading ? null : _verifyCode,
                          child: _buildSubmitButton("VÉRIFIER LE CODE"),
                        ),
                      ],

                      if (_currentView == AuthView.forgotNewPassword) ...[
                        _buildLabel("NOUVEAU MOT DE PASSE"),
                        const SizedBox(height: 8),
                        _buildTextField(
                          controller: _newPasswordController,
                          hint: "Minimum 8 caractères",
                          icon: Icons.lock_rounded,
                          color: const Color(0xFF4fb3ff),
                          isPassword: true,
                          obscureText: _obscureNewPassword,
                          onToggleVisibility: () => setState(() => _obscureNewPassword = !_obscureNewPassword),
                          focusNode: _newPasswordFocus,
                        ),
                        const SizedBox(height: 20),
                        _buildLabel("CONFIRMATION"),
                        const SizedBox(height: 8),
                        _buildTextField(
                          controller: _confirmPasswordController,
                          hint: "Répétez le mot de passe",
                          icon: Icons.lock_clock_rounded,
                          color: const Color(0xFF4fb3ff),
                          isPassword: true,
                          obscureText: _obscureConfirmPassword,
                          onToggleVisibility: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                          focusNode: _confirmPasswordFocus,
                        ),
                        const SizedBox(height: 32),
                        _HoverScaleButton(
                          onTap: _isLoading ? null : _resetPasswordFinal,
                          child: _buildSubmitButton("RÉINITIALISER"),
                        ),
                      ],

                      if (_currentView != AuthView.login) ...[
                        const SizedBox(height: 16),
                        Center(
                          child: TextButton(
                            onPressed: () => setState(() {
                              _currentView = AuthView.login;
                              _error = null;
                              _successMessage = null;
                            }),
                            child: const Text(
                              "Retour à la connexion",
                              style: TextStyle(color: Color(0xFF3A567A), fontSize: 13),
                            ),
                          ),
                        ),
                      ],

                      const SizedBox(height: 40),
                      // Footer
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _PulsingDot(),
                          const SizedBox(width: 12),
                          const Text(
                            "Système SIRIUS opérationnel",
                            style: TextStyle(color: Color(0xFF1E3050), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1),
                          ),
                        ],
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

  Widget _buildSubmitButton(String label) {
    return Container(
      width: double.infinity,
      height: 52,
      decoration: BoxDecoration(
        color: const Color(0xFFf5a623),
        borderRadius: BorderRadius.circular(11),
      ),
      alignment: Alignment.center,
      child: _isLoading 
        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Color(0xFF07100a), strokeWidth: 2))
        : Text(
            label,
            style: const TextStyle(color: Color(0xFF07100a), fontWeight: FontWeight.bold, letterSpacing: 2.5),
          ),
    );
  }

  Widget _buildPill(IconData icon, String label, Color textColor, Color baseColor) {
    double opacity = 0.12;
    if (label == "Alertes SOS") opacity = 0.10;
    if (label == "24 / 7") opacity = 0.08;

    return Container(
      width: 150,
      padding: const EdgeInsets.symmetric(vertical: 8),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: baseColor.withOpacity(opacity),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: baseColor.withOpacity(opacity == 0.08 ? 0.15 : 0.2)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: textColor, size: 14),
          const SizedBox(width: 10),
          Text(
            label,
            style: TextStyle(
              color: textColor,
              fontSize: 13,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: Color(0xFF4FB3FF),
        fontSize: 10.5,
        fontWeight: FontWeight.w600,
        letterSpacing: 2,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    required Color color,
    required FocusNode focusNode,
    bool isPassword = false,
    bool? obscureText,
    VoidCallback? onToggleVisibility,
  }) {
    final bool hasFocus = focusNode.hasFocus;
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(11),
        border: Border.all(
          color: hasFocus ? const Color(0xFFf5a623).withOpacity(0.5) : Colors.black.withOpacity(0.08),
          width: 1,
        ),
        boxShadow: hasFocus ? [
          BoxShadow(
            color: const Color(0xFFf5a623).withOpacity(0.07),
            spreadRadius: 3,
            blurRadius: 0,
          )
        ] : [],
      ),
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        obscureText: obscureText ?? false,
        style: const TextStyle(color: Colors.black, fontSize: 14),
        cursorColor: const Color(0xFFf5a623),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 14),
          prefixIcon: Icon(icon, color: color, size: 18),
          suffixIcon: isPassword 
            ? IconButton(
                icon: Icon(obscureText! ? Icons.visibility_off_rounded : Icons.visibility_rounded, color: color, size: 18),
                onPressed: onToggleVisibility,
              )
            : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        ),
      ),
    );
  }
}

class _HoverScaleButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  const _HoverScaleButton({required this.child, this.onTap});

  @override
  State<_HoverScaleButton> createState() => _HoverScaleButtonState();
}

class _HoverScaleButtonState extends State<_HoverScaleButton> {
  bool _hovered = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        onTap: widget.onTap,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 150),
          opacity: _hovered ? 0.9 : 1.0,
          child: AnimatedScale(
            duration: const Duration(milliseconds: 100),
            scale: _pressed ? 0.98 : 1.0,
            child: widget.child,
          ),
        ),
      ),
    );
  }
}

class _HoverOverlayButton extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  const _HoverOverlayButton({required this.child, required this.onTap});

  @override
  State<_HoverOverlayButton> createState() => _HoverOverlayButtonState();
}

class _HoverOverlayButtonState extends State<_HoverOverlayButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: _hovered ? const Color(0xFF4fb3ff).withOpacity(0.03) : Colors.transparent,
            borderRadius: BorderRadius.circular(11),
          ),
          child: widget.child,
        ),
      ),
    );
  }
}

class _PulsingDot extends StatefulWidget {
  const _PulsingDot();

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 2500))..repeat(reverse: true);
    _opacity = TweenSequence([
      TweenSequenceItem(tween: Tween<double>(begin: 1.0, end: 0.2), weight: 50),
      TweenSequenceItem(tween: Tween<double>(begin: 0.2, end: 1.0), weight: 50),
    ]).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _opacity,
      builder: (context, child) {
        return Opacity(
          opacity: _opacity.value,
          child: Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(color: Color(0xFFffd84a), shape: BoxShape.circle),
          ),
        );
      },
    );
  }
}


