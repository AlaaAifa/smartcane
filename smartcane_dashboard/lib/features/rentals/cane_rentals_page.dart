import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../core/api_service.dart';
import 'rental_contract_page.dart';

class CaneRentalsPage extends StatefulWidget {
  const CaneRentalsPage({super.key});

  @override
  State<CaneRentalsPage> createState() => _CaneRentalsPageState();
}

class _CaneRentalsPageState extends State<CaneRentalsPage> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  int? _birthDay;
  int? _birthMonth;
  int? _birthYear;
  int? _calculatedAge;
  
  final _cinController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _healthNotesController = TextEditingController();

  // Emergency Contact
  final _emergencyNameController = TextEditingController();
  final _emergencyPhoneController = TextEditingController();
  final _emergencyRelationController = TextEditingController();

  // Rental Contract
  final _startDateController = TextEditingController();
  final _internalNotesController = TextEditingController();

  bool _formationNecessaire = false;

  // Device
  final _simNumberController = TextEditingController();

  String _selectedVersion = "Smart Pro V2";
  final List<String> _versions = ["Smart Pro V2", "Smart Pro V3", "Smart Lite"];
  bool _isSubmitting = false;

  // Rental price / month per version
  final Map<String, int> _monthlyPrices = {
    "Smart Lite": 150,
    "Smart Pro V2": 250,
    "Smart Pro V3": 350,
  };

  int get _monthlyRate => _monthlyPrices[_selectedVersion] ?? 0;

  int _rentalMonths = 1;
  int get _totalRentalPrice => _rentalMonths * _monthlyRate;

  // Payment
  bool _isPaymentConfirmed = false;
  String _paymentMethod = "Espèces";

  String get _calculatedEndDate {
    final start = _parseDate(_startDateController.text);
    if (start == null) return "--";
    // Add exact months to start date
    final end = DateTime(start.year, start.month + _rentalMonths, start.day);
    return "${end.day.toString().padLeft(2, '0')}/${end.month.toString().padLeft(2, '0')}/${end.year}";
  }

  DateTime? _parseDate(String text) {
    try {
      final parts = text.split('/');
      if (parts.length == 3) {
        return DateTime(int.parse(parts[2]), int.parse(parts[1]), int.parse(parts[0]));
      }
    } catch (_) {}
    return null;
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _cinController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _healthNotesController.dispose();
    _emergencyNameController.dispose();
    _emergencyPhoneController.dispose();
    _emergencyRelationController.dispose();
    _startDateController.dispose();
    _internalNotesController.dispose();
    _simNumberController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context, TextEditingController controller) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppTheme.primary,
              onPrimary: Colors.white,
              onSurface: Colors.black87,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        controller.text = "${picked.day}/${picked.month}/${picked.year}";
      });
    }
  }

  void _updateAge() {
    if (_birthDay == null || _birthMonth == null || _birthYear == null) return;
    
    final now = DateTime.now();
    int age = now.year - _birthYear!;
    
    if (now.month < _birthMonth! || (now.month == _birthMonth! && now.day < _birthDay!)) {
      age--;
    }
    
    setState(() {
      _calculatedAge = age;
    });
  }

  // Generate lists for birth date
  final List<int> _days = List.generate(31, (index) => index + 1);
  final List<int> _months = List.generate(12, (index) => index + 1);
  final List<int> _years = List.generate(100, (index) => DateTime.now().year - index);

  // Helpers for Details Card
  String _getDescriptionForVersion() {
    switch (_selectedVersion) {
      case "Smart Lite":
        return "La Smart Lite est notre canne connectée d'entrée de gamme, parfaite pour les usages quotidiens. Elle embarque une technologie de détection d'obstacles basique, une autonomie prolongée de 48h, et se distingue par son incroyable légèreté (200g).";
      case "Smart Pro V2":
        return "La Smart Pro V2 monte en puissance avec des radars à ultrasons ultra-précis, un retour haptique intelligent qui vibre en fonction de la proximité des obstacles, et une connectivité Bluetooth pour l'accompagner avec notre application mobile.";
      case "Smart Pro V3":
        return "Le fleuron de notre gamme. Équipée d'une caméra gérée par Intelligence Artificielle et de capteurs LiDAR, elle analyse visuellement l'environnement. Avec sa connexion 5G intégrée et son assistance vocale, elle est conçue pour une autonomie totale.";
      default:
        return "";
    }
  }

  String _getPriceForVersion() {
    switch (_selectedVersion) {
      case "Smart Lite": return "150 TND / mois";
      case "Smart Pro V2": return "250 TND / mois";
      case "Smart Pro V3": return "350 TND / mois";
      default: return "";
    }
  }

  List<String> _getFeaturesForVersion() {
    switch (_selectedVersion) {
      case "Smart Lite": return ["Détection d'obstacles (1.5m)", "Autonomie 48h", "Ultra légère"];
      case "Smart Pro V2": return ["Radar à ultrasons (3m)", "Retour haptique", "Bluetooth IoT"];
      case "Smart Pro V3": return ["Caméra IA & LiDAR", "Connexion 5G", "Assistance vocale"];
      default: return [];
    }
  }

  String _getImagePath() {
    switch (_selectedVersion) {
      case "Smart Lite": return "assets/images/smart_lite.png";
      case "Smart Pro V2": return "assets/images/smart_pro_v2.png";
      case "Smart Pro V3": return "assets/images/smart_pro_v3.png";
      default: return "";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 1000;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const SizedBox(width: 20),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "GESTION DE LOCATION",
                            style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.black87),
                          ),
                          Text(
                            "Enregistrement des nouveaux contrats de location",
                            style: TextStyle(color: Colors.grey.withOpacity(0.8), fontSize: 14),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),
                  isWide
                      ? Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(flex: 3, child: _buildFormSection()),
                            const SizedBox(width: 32),
                            Expanded(flex: 2, child: _buildDetailsSection()),
                          ],
                        )
                      : Column(
                          children: [
                            _buildFormSection(),
                            const SizedBox(height: 32),
                            _buildDetailsSection(),
                          ],
                        ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildFormSection() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          )
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
              _buildSectionHeader(Icons.devices_other_outlined, "I. SÉLECTION DU MODÈLE"),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _buildVersionButton("Smart Pro V3", "Caméra IA & LiDAR")),
                  const SizedBox(width: 12),
                  Expanded(child: _buildVersionButton("Smart Pro V2", "Radars & Bluetooth")),
                  const SizedBox(width: 12),
                  Expanded(child: _buildVersionButton("Smart Lite", "Léger & Autonomie")),
                ],
              ),
              const SizedBox(height: 32),
              const Divider(height: 1, color: Colors.black12),
              const SizedBox(height: 32),

              _buildSectionHeader(Icons.person_outline, "II. INFORMATIONS CLIENT"),
              const SizedBox(height: 24),
              
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildFieldLabel("Nom et prénom complet"),
                        _buildTextField(_fullNameController, "Ex: Jean Dupont", Icons.person_outline),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 1,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.primary.withOpacity(0.1)),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text("ÂGE CALCULÉ", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
                          Text(
                            _calculatedAge != null ? "$_calculatedAge ans" : "--",
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppTheme.primary),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              _buildFieldLabel("Date de naissance"),
              Row(
                children: [
                  Expanded(
                    child: _buildDropdownField(
                      "Jour", 
                      _birthDay, 
                      _days, 
                      (val) { setState(() => _birthDay = val); _updateAge(); },
                      (val) => val == null ? "Requis" : null
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildDropdownField(
                      "Mois", 
                      _birthMonth, 
                      _months, 
                      (val) { setState(() => _birthMonth = val); _updateAge(); },
                      (val) => val == null ? "Requis" : null
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: _buildDropdownField(
                      "Année", 
                      _birthYear, 
                      _years, 
                      (val) { setState(() => _birthYear = val); _updateAge(); },
                      (val) => val == null ? "Requis" : null
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildFieldLabel("CIN"),
                        _buildTextField(_cinController, "Numéro carte identité", Icons.badge_outlined, isNumber: true),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildFieldLabel("Téléphone principal"),
                        _buildTextField(_phoneController, "01 23 45 67 89", Icons.phone_outlined, isNumber: true),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              
              _buildFieldLabel("Adresse de résidence"),
              _buildTextField(_addressController, "Rue, Ville, Code Postal", Icons.location_on_outlined),
              const SizedBox(height: 20),

              _buildFieldLabel("Notes de santé / Pathologies"),
              _buildTextField(_healthNotesController, "Ex: Diabète, Difficultés motrices...", Icons.health_and_safety_outlined, isMultiline: true),

              const SizedBox(height: 32),
              const Divider(height: 1, color: Colors.black12),
              const SizedBox(height: 32),

              _buildSectionHeader(Icons.emergency_outlined, "III. CONTACT D'URGENCE"),
              const SizedBox(height: 24),

              _buildFieldLabel("Nom du contact d'urgence"),
              _buildTextField(_emergencyNameController, "Prénom et Nom du proche", Icons.person_search_outlined),
              const SizedBox(height: 20),

              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildFieldLabel("Relation / Lien"),
                        _buildTextField(_emergencyRelationController, "Ex: Fils, Épouse...", Icons.family_restroom_outlined),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildFieldLabel("Numéro de téléphone"),
                        _buildTextField(_emergencyPhoneController, "Numéro permanent", Icons.phone_enabled_outlined, isNumber: true),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 32),
              const Divider(height: 1, color: Colors.black12),
              const SizedBox(height: 32),

              _buildSectionHeader(Icons.calendar_month_outlined, "IV. DÉTAILS DU CONTRAT"),
              const SizedBox(height: 24),

              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildFieldLabel("Date de début"),
                        GestureDetector(
                          onTap: () => _selectDate(context, _startDateController),
                          child: AbsorbPointer(
                            child: _buildTextField(_startDateController, "Choisir...", Icons.calendar_today_outlined),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildFieldLabel("Durée de location"),
                        Row(
                          children: [
                            Expanded(child: _buildDurationButton(1, "1 Mois")),
                            const SizedBox(width: 8),
                            Expanded(child: _buildDurationButton(3, "3 Mois")),
                            const SizedBox(width: 8),
                            Expanded(child: _buildDurationButton(6, "6 Mois")),
                            const SizedBox(width: 8),
                            Expanded(child: _buildDurationButton(12, "1 An")),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.primary.withOpacity(0.1)),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text("DATE DE FIN PRÉVUE", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
                          Text(
                            _calculatedEndDate,
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppTheme.primary),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),
              
              // SIM Number field
              _buildFieldLabel("Numéro SIM (4G) — Identifiant de la Canne"),
              _buildTextField(_simNumberController, "Ex: 216XXXXXXXX", Icons.sim_card_outlined),
              
              const SizedBox(height: 20),

              // Price breakdown card
              if (_rentalMonths > 0)
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withOpacity(0.03),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.primary.withOpacity(0.15)),
                  ),
                  child: Column(
                    children: [
                      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                        const Text("Tarif mensuel", style: TextStyle(color: Colors.grey, fontSize: 13)),
                        Text("$_monthlyRate TND / mois", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      ]),
                      const SizedBox(height: 8),
                      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                        const Text("Durée du contrat", style: TextStyle(color: Colors.grey, fontSize: 13)),
                        Text("$_rentalMonths mois", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      ]),
                      const Divider(height: 20),
                      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                        const Text("TOTAL CONTRAT", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
                        Text("$_totalRentalPrice TND", style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 22, color: AppTheme.primary)),
                      ]),
                    ],
                  ),
                ),

              const SizedBox(height: 32),
              const Divider(height: 1, color: Colors.black12),
              const SizedBox(height: 32),

              _buildSectionHeader(Icons.admin_panel_settings_outlined, "V. ADMINISTRATION & NOTES"),
              const SizedBox(height: 24),

              _buildFieldLabel("Notes internes / Observations staff"),
              _buildTextField(_internalNotesController, "Remarques sur le profil...", Icons.edit_note_outlined, isMultiline: true),
              const SizedBox(height: 24),

              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.primary.withOpacity(0.1)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.school_outlined, color: AppTheme.primary),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Text(
                        "Formation technique nécessaire",
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    ),
                    Switch(
                      value: _formationNecessaire,
                      onChanged: (val) => setState(() => _formationNecessaire = val),
                      activeColor: AppTheme.primary,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 40),

              // --- PAYMENT MODULE ---
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: _isPaymentConfirmed ? AppTheme.normalGreen.withOpacity(0.05) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _isPaymentConfirmed ? AppTheme.normalGreen : Colors.orange.shade300,
                    width: 2,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          _isPaymentConfirmed ? Icons.verified : Icons.payments_rounded,
                          color: _isPaymentConfirmed ? AppTheme.normalGreen : Colors.orange,
                          size: 28,
                        ),
                        const SizedBox(width: 12),
                        const Text("VALIDATION DU PAIEMENT", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                      ],
                    ),
                    const SizedBox(height: 20),
                    if (!_isPaymentConfirmed) ...[
                      // Payment breakdown
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withOpacity(0.04),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppTheme.primary.withOpacity(0.15), width: 1.5),
                        ),
                        child: Column(
                          children: [
                            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                              Text("$_selectedVersion (Canne)", style: const TextStyle(color: Colors.grey, fontSize: 13)),
                              Text("$_monthlyRate TND / mois", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                            ]),
                            const SizedBox(height: 8),
                            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                              const Text("Durée de location", style: TextStyle(color: Colors.grey, fontSize: 13)),
                              Text("$_rentalMonths mois", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                            ]),
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 12),
                              child: Divider(height: 1, color: Colors.black12),
                            ),
                            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                              const Text("TOTAL À PAYER", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
                              Text("$_totalRentalPrice TND", style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 24, color: AppTheme.primary)),
                            ]),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Payment method
                      Row(
                        children: [
                          _buildPaymentRadio("Espèces", Icons.money),
                          const SizedBox(width: 12),
                          _buildPaymentRadio("Carte", Icons.credit_card),
                          const SizedBox(width: 12),
                          _buildPaymentRadio("Virement", Icons.account_balance),
                        ],
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton.icon(
                          onPressed: () => setState(() => _isPaymentConfirmed = true),
                          icon: const Icon(Icons.check_circle_outline),
                          label: const Text("CONFIRMER LA RÉCEPTION DU PAIEMENT", style: TextStyle(fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            foregroundColor: Colors.white,
                            disabledBackgroundColor: Colors.grey.shade300,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                    ] else ...[
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppTheme.normalGreen.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.check_circle, color: AppTheme.normalGreen),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                "PAIEMENT DE $_totalRentalPrice TND REÇU PAR $_paymentMethod",
                                style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.normalGreen),
                              ),
                            ),
                            TextButton(
                              onPressed: () => setState(() => _isPaymentConfirmed = false),
                              child: const Text("Modifier", style: TextStyle(color: Colors.grey)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: (_isPaymentConfirmed && !_isSubmitting) ? _submitRegistration : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isPaymentConfirmed ? AppTheme.primary : Colors.grey,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.check_circle_outline, color: Colors.white, size: 20),
                            const SizedBox(width: 12),
                            Text(
                              _isPaymentConfirmed ? "Enregistrer la Location" : "En Attente de Paiement",
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                          ],
                        ),
                ),
              ),
            ],
          ),
        ),
      );
  }
  Widget _buildDurationButton(int months, String title) {
    bool isSelected = _rentalMonths == months;
    return InkWell(
      onTap: () => setState(() => _rentalMonths = months),
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primary.withOpacity(0.1) : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppTheme.primary : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Text(
          title,
          style: TextStyle(
            color: isSelected ? AppTheme.primary : Colors.black87,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentRadio(String method, IconData icon) {
    bool isSelected = _paymentMethod == method;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _paymentMethod = method),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.primary : Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isSelected ? AppTheme.primary : Colors.grey.shade300),
          ),
          child: Column(
            children: [
              Icon(icon, color: isSelected ? Colors.white : Colors.grey, size: 28),
              const SizedBox(height: 8),
              Text(
                method,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.black87,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVersionButton(String title, String subtitle) {
    bool isSelected = _selectedVersion == title;
    return InkWell(
      onTap: () => setState(() => _selectedVersion = title),
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primary.withOpacity(0.08) : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppTheme.primary : Colors.grey.shade200,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: isSelected ? AppTheme.primary : Colors.grey,
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: isSelected ? AppTheme.primary : Colors.black87,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    fontSize: 16,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: isSelected ? AppTheme.primary.withOpacity(0.7) : Colors.grey,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const Spacer(),
            if (isSelected)
              const Icon(Icons.check_circle, color: AppTheme.primary, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailsSection() {
    final features = _getFeaturesForVersion();

    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
            const Text(
              "Détails du Modèle",
              style: TextStyle(color: AppTheme.primary, fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 24),
            // Espace Photo
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Container(
                height: 220,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Image.asset(
                  _getImagePath(),
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.image_not_supported_outlined, size: 48, color: Colors.grey.shade300),
                        const SizedBox(height: 12),
                        Text(
                          "Photo manquante : ${_getImagePath().split('/').last}", 
                          style: TextStyle(color: Colors.grey.shade400, fontSize: 12)
                        ),
                      ],
                    );
                  },
                  frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
                    if (wasSynchronouslyLoaded) return child;
                    return AnimatedOpacity(
                      opacity: frame == null ? 0 : 1,
                      duration: const Duration(milliseconds: 500),
                      curve: Curves.easeOut,
                      child: child,
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            Text(
              _selectedVersion,
              style: const TextStyle(color: Colors.black87, fontSize: 24, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 6),
            
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.normalGreen.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                _getPriceForVersion(),
                style: const TextStyle(color: AppTheme.normalGreen, fontSize: 13, fontWeight: FontWeight.bold),
              ),
            ),
            
            const SizedBox(height: 24),
            const Text(
              "Description",
              style: TextStyle(color: Colors.black54, fontWeight: FontWeight.bold, fontSize: 13),
            ),
            const SizedBox(height: 8),
            Text(
              _getDescriptionForVersion(),
              style: TextStyle(color: Colors.black87.withOpacity(0.7), fontSize: 14, height: 1.5),
            ),
            
            const SizedBox(height: 24),
            const Text(
              "Fonctionnalités incluses",
              style: TextStyle(color: Colors.black54, fontWeight: FontWeight.bold, fontSize: 13),
            ),
            const SizedBox(height: 12),
            ...features.map((f) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, color: AppTheme.normalGreen, size: 16),
                  const SizedBox(width: 12),
                  Text(f, style: const TextStyle(color: Colors.black87, fontSize: 14)),
                ],
              ),
            )),
          ],
        ),
      );
  }

  Widget _buildFieldLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        label,
        style: const TextStyle(color: Colors.black87, fontSize: 13, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildDropdownField<T>(
    String label, 
    T? value, 
    List<T> items, 
    void Function(T?) onChanged,
    String? Function(T?)? validator,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFieldLabel(label),
        DropdownButtonFormField<T>(
          value: value,
          items: items.map((item) {
            return DropdownMenuItem<T>(
              value: item,
              child: Text(item.toString()),
            );
          }).toList(),
          onChanged: onChanged,
          validator: validator,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.grey.shade50,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppTheme.primary, width: 2),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(IconData icon, String title) {
    return Row(
      children: [
        Icon(icon, color: AppTheme.primary, size: 20),
        const SizedBox(width: 12),
        Text(
          title,
          style: const TextStyle(
            color: AppTheme.primary,
            fontSize: 14,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.1,
          ),
        ),
      ],
    );
  }

  Widget _buildTextField(
    TextEditingController controller, 
    String hint, 
    IconData icon, 
    {bool isNumber = false, bool isMultiline = false}
  ) {
    return TextFormField(
      controller: controller,
      maxLines: isMultiline ? 3 : 1,
      keyboardType: isMultiline 
          ? TextInputType.multiline 
          : (isNumber ? TextInputType.number : TextInputType.text),
      style: const TextStyle(color: Colors.black87, fontSize: 15),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey.shade400),
        prefixIcon: Icon(icon, color: Colors.grey.shade400, size: 20),
        filled: true,
        fillColor: Colors.grey.shade50,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.primary, width: 2),
        ),
      ),
      validator: (value) => value == null || value.isEmpty ? "Champ requis" : null,
    );
  }

  void _submitRegistration() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isSubmitting = true);

    // 1. Collect all data
    final Map<String, dynamic> rentalData = {
      "full_name": _fullNameController.text,
      "birth_date": "$_birthDay/$_birthMonth/$_birthYear",
      "age": _calculatedAge?.toString() ?? "0",
      "cin": _cinController.text,
      "phone": _phoneController.text,
      "address": _addressController.text,
      "health_notes": _healthNotesController.text,
      "emergency_name": _emergencyNameController.text,
      "emergency_phone": _emergencyPhoneController.text,
      "emergency_relation": _emergencyRelationController.text,
      "start_date": _startDateController.text,
      "end_date": _calculatedEndDate,
      "duration_months": _rentalMonths,
      "internal_notes": _internalNotesController.text,
      "model": _selectedVersion,
      "formation_needed": _formationNecessaire,
      "sim_number": _simNumberController.text,
      "total_price": _totalRentalPrice,
      "payment_method": _paymentMethod,
    };

    // 2. Call API
    final bool success = await ApiService.rentCane(rentalData);
    
    if (mounted) {
      if (success) {
        setState(() {
          _isSubmitting = false;
        });

        // 3. Open Contract
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => RentalContractPage(rentalData: rentalData),
          ),
        );
      } else {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Erreur lors de l'enregistrement. Veuillez réessayer."),
          backgroundColor: AppTheme.sosRed,
        ));
      }
    }
  }
}
