import 'package:flutter/material.dart';

import 'package:flutter/services.dart';

import 'dart:convert';

import '../theme.dart';

import '../../services/services.dart';

import 'rental_contract_page.dart';



class CaneRentalsPage extends StatefulWidget {

  const CaneRentalsPage({super.key});



  @override

  State<CaneRentalsPage> createState() => _CaneRentalsPageState();

}



class _CaneRentalsPageState extends State<CaneRentalsPage> {

  final _formKey = GlobalKey<FormState>();

  final _fullNameController = TextEditingController();

  final _birthDateController = TextEditingController();

  DateTime? _selectedBirthDate;

  int? _calculatedAge;

  

  final _cinController = TextEditingController();

  final _emailController = TextEditingController();

  final _phoneController = TextEditingController();

  final _streetController = TextEditingController(); 

  final _cityController = TextEditingController();

  final _postalCodeController = TextEditingController();

  final _countryController = TextEditingController();

  final _healthNotesController = TextEditingController();



  // Structured Medical Info

  final Map<String, bool> _pathologies = {

    "Diabète": false,

    "Hypertension": false,

    "Maladie cardiaque": false,

    "Épilepsie": false,

    "Troubles de l’équilibre / Vertiges": false,

    "Difficulté de mobilité": false,

    "Baisse auditive": false,

    "Allergies médicamenteuses": false,

    "Aucune pathologie connue": false,

    "Autre": false,

  };

  final _allergyDetailController = TextEditingController();

  final _otherPathologyController = TextEditingController();

  String _selectedBloodGroup = "Inconnu";

  final List<String> _bloodGroups = ["A+", "A-", "B+", "B-", "AB+", "AB-", "O+", "O-", "Inconnu"];

  final _medicalObservationsController = TextEditingController();



  // Emergency Contact

  final _emergencyNameController = TextEditingController();

  final _emergencyPhoneController = TextEditingController();

  final _emergencyRelationController = TextEditingController();



  // Rental Contract

  final _startDateController = TextEditingController();

  final _endDateController = TextEditingController();

  DateTime _rentalStartDate = DateTime.now();

  DateTime _rentalEndDate = DateTime.now().add(const Duration(days: 30));

  final _internalNotesController = TextEditingController();



  bool _formationNecessaire = false;



  // Device

  final _simNumberController = TextEditingController();



  String _selectedVersion = "Smart Pro V2";

  final List<String> _versions = ["Smart Pro V2", "Smart Pro V3", "Smart Lite"];

  bool _isSubmitting = false;

  int _currentStep = 0; // 0: Selection, 1: Details, 2-7: Wizard



  // Rental price / month per version

  final Map<String, int> _monthlyPrices = {

    "Smart Lite": 150,

    "Smart Pro V2": 250,

    "Smart Pro V3": 350,

  };



  int get _monthlyRate => _monthlyPrices[_selectedVersion] ?? 0;



  int get _rentalDurationMonths {

    return _calculateMonths(_rentalStartDate, _rentalEndDate);

  }



  int get _totalRentalPrice => _rentalDurationMonths * _monthlyRate;



  int _calculateMonths(DateTime start, DateTime end) {

    if (end.isBefore(start)) return 0;

    int months = (end.year - start.year) * 12 + end.month - start.month;

    if (end.day > start.day) months++;

    return months == 0 && end.isAfter(start) ? 1 : months;

  }



  // Payment

  bool _isPaymentConfirmed = false;

  String _paymentMethod = "Espèces";



  @override

  void dispose() {

    _fullNameController.dispose();

    _birthDateController.dispose();

    _cinController.dispose();

    _emailController.dispose();

    _phoneController.dispose();

    _streetController.dispose();

    _cityController.dispose();

    _postalCodeController.dispose();

    _countryController.dispose();

    _healthNotesController.dispose();

    _allergyDetailController.dispose();

    _otherPathologyController.dispose();

    _medicalObservationsController.dispose();

    _emergencyNameController.dispose();

    _emergencyPhoneController.dispose();

    _emergencyRelationController.dispose();

    _startDateController.dispose();

    _endDateController.dispose();

    _internalNotesController.dispose();

    _simNumberController.dispose();

    super.dispose();

  }



  @override

  void initState() {

    super.initState();

    _startDateController.text = "${_rentalStartDate.day}/${_rentalStartDate.month}/${_rentalStartDate.year}";

    _endDateController.text = "${_rentalEndDate.day}/${_rentalEndDate.month}/${_rentalEndDate.year}";

  }



  Future<void> _selectRentalPeriodDate(BuildContext context, bool isStartDate) async {

    final DateTime? picked = await showDatePicker(

      context: context,

      initialDate: isStartDate ? _rentalStartDate : _rentalEndDate,

      firstDate: isStartDate ? DateTime.now().subtract(const Duration(days: 30)) : _rentalStartDate,

      lastDate: DateTime.now().add(const Duration(days: 3650)),

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

        if (isStartDate) {

          _rentalStartDate = picked;

          _startDateController.text = "${picked.day}/${picked.month}/${picked.year}";

          if (_rentalEndDate.isBefore(_rentalStartDate)) {

            _rentalEndDate = _rentalStartDate.add(const Duration(days: 30));

            _endDateController.text = "${_rentalEndDate.day}/${_rentalEndDate.month}/${_rentalEndDate.year}";

          }

        } else {

          _rentalEndDate = picked;

          _endDateController.text = "${picked.day}/${picked.month}/${picked.year}";

        }

      });

    }

  }



  Future<void> _selectBirthDate(BuildContext context) async {

    final DateTime? picked = await showDatePicker(

      context: context,

      initialDate: _selectedBirthDate ?? DateTime(2000),

      firstDate: DateTime(1900),

      lastDate: DateTime.now(),

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

    if (picked != null && picked != _selectedBirthDate) {

      setState(() {

        _selectedBirthDate = picked;

        _birthDateController.text = "${picked.day}/${picked.month}/${picked.year}";

        _updateAge();

      });

    }

  }



  void _updateAge() {

    if (_selectedBirthDate == null) return;

    

    final now = DateTime.now();

    int age = now.year - _selectedBirthDate!.year;

    

    if (now.month < _selectedBirthDate!.month || (now.month == _selectedBirthDate!.month && now.day < _selectedBirthDate!.day)) {

      age--;

    }

    

    setState(() {

      _calculatedAge = age;

    });

  }



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



  @override

  Widget build(BuildContext context) {

    return Scaffold(

      backgroundColor: Colors.transparent,

      body: Form(

        key: _formKey,

        child: SingleChildScrollView(

          physics: const BouncingScrollPhysics(),

          child: Padding(

            padding: const EdgeInsets.all(48),

            child: Column(

              crossAxisAlignment: CrossAxisAlignment.start,

              children: [

                _buildHeader(),

                if (_currentStep >= 2) ...[

                  const SizedBox(height: 48),

                  _buildStepper(),

                ],

                const SizedBox(height: 48),

                _buildCurrentStepContent(),

                const SizedBox(height: 64),

                _buildWizardControls(),

              ],

            ),

          ),

        ),

      ),

    );

  }



  Widget _buildHeader() {

    return Row(

      children: [

        if (_currentStep > 0)

          Padding(

            padding: const EdgeInsets.only(right: 24),

            child: Container(

              decoration: BoxDecoration(

                color: Colors.white,

                borderRadius: BorderRadius.circular(12),

                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],

              ),

              child: IconButton(

                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: AppTheme.primary),

                onPressed: () => setState(() => _currentStep--),

              ),

            ),

          ),

        const SizedBox(width: 10),

        Column(

          crossAxisAlignment: CrossAxisAlignment.start,

          children: [

            Text("Portail de Location", style: Theme.of(context).textTheme.headlineMedium),

            const SizedBox(height: 6),

            Text(_getStepSubtitle(), style: const TextStyle(color: Color(0xFF64748B), fontSize: 14, fontWeight: FontWeight.w500)),

          ],

        ),

        const Spacer(),

        if (_currentStep > 0)

          TextButton.icon(

            onPressed: () => setState(() => _currentStep = 0),

            icon: const Icon(Icons.restart_alt_rounded, size: 18),

            label: const Text("RÉINITIALISER", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 1)),

            style: TextButton.styleFrom(foregroundColor: AppTheme.sosRed),

          ),

      ],

    );

  }



  String _getStepSubtitle() {

    if (_currentStep == 0) return "Sélectionnez votre modèle de canne";

    if (_currentStep == 1) return "Détails de la configuration sélectionnée";

    

    switch (_currentStep) {

      case 2: return "Étape 1 : Coordonnées du bénéficiaire";

      case 3: return "Étape 2 : Adresse de résidence";

      case 4: return "Étape 3 : Urgence et Santé";

      case 5: return "Étape 4 : Équipement et Période de location";

      case 6: return "Étape 5 : Règlement et Paiement";

      case 7: return "Étape 6 : Récapitulatif et Signature du contrat";

      default: return "";

    }

  }



  Widget _buildStepper() {

    return Container(

      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),

      decoration: BoxDecoration(

        color: Colors.white,

        borderRadius: BorderRadius.circular(24),

        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 20, offset: const Offset(0, 4))],

        border: Border.all(color: Colors.grey.withOpacity(0.1)),

      ),

      child: Row(

        children: [

          _buildStepIndicator(2, "Client", Icons.person_rounded),

          _buildStepLine(2),

          _buildStepIndicator(3, "Adresse", Icons.location_on_rounded),

          _buildStepLine(3),

          _buildStepIndicator(4, "Urgence", Icons.emergency_rounded),

          _buildStepLine(4),

          _buildStepIndicator(5, "Équipement", Icons.settings_input_component_rounded),

          _buildStepLine(5),

          _buildStepIndicator(6, "Paiement", Icons.payments_rounded),

          _buildStepLine(6),

          _buildStepIndicator(7, "Contrat", Icons.description_rounded),

        ],

      ),

    );

  }



  Widget _buildStepIndicator(int step, String label, IconData icon) {

    bool isActive = _currentStep >= step;

    bool isCurrent = _currentStep == step;

    return Column(

      children: [

        AnimatedContainer(

          duration: const Duration(milliseconds: 300),

          padding: const EdgeInsets.all(12),

          decoration: BoxDecoration(

            color: isCurrent ? AppTheme.primary : (isActive ? AppTheme.primary.withOpacity(0.08) : const Color(0xFFF1F5F9)),

            shape: BoxShape.circle,

            boxShadow: isCurrent ? [BoxShadow(color: AppTheme.primary.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4))] : null,

          ),

          child: Icon(icon, color: isCurrent ? Colors.white : (isActive ? AppTheme.primary : const Color(0xFF94A3B8)), size: 18),

        ),

        const SizedBox(height: 10),

        Text(

          label,

          style: TextStyle(

            fontSize: 10,

            fontWeight: isCurrent ? FontWeight.w900 : FontWeight.w700,

            color: isCurrent ? AppTheme.primary : (isActive ? const Color(0xFF475569) : const Color(0xFF94A3B8)),

            letterSpacing: 0.5,

          ),

        )

      ],

    );

  }



  Widget _buildStepLine(int stepAfter) {

    bool isActive = _currentStep > stepAfter;

    return Expanded(

      child: Container(

        height: 2,

        margin: const EdgeInsets.only(left: 10, right: 10, bottom: 20),

        decoration: BoxDecoration(

          color: isActive ? AppTheme.primary.withOpacity(0.2) : const Color(0xFFF1F5F9),

          borderRadius: BorderRadius.circular(1),

        ),

      ),

    );

  }



  Widget _buildCurrentStepContent() {

    switch (_currentStep) {

      case 0: return _buildSelectionStep();

      case 1: return _buildDetailsStep();

      case 2: return _buildStepClientInfo();

      case 3: return _buildStepAddress();

      case 4: return _buildStepEmergencyContact();

      case 5: return _buildStepCaneEquipment();

      case 6: return _buildStepPayment();

      case 7: return _buildStepContractDetails();

      default: return const SizedBox();

    }

  }



  Widget _buildSelectionStep() {

    return Column(

      crossAxisAlignment: CrossAxisAlignment.start,

      children: [

        const Text(

          "Quelle version de la SIRIUS souhaitez-vous louer ?",

          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFF475569), letterSpacing: -0.5),

        ),

        const SizedBox(height: 48),

        SizedBox(

          height: 600,

          child: Row(

            children: [

              Expanded(

                child: _CaneVersionCard(

                  title: "Smart Lite",

                  subtitle: "Légèreté & Simplicité",

                  badge: "ESSENTIEL",

                  badgeColor: Colors.blue,

                  features: const ["48h autonomie", "Ultra légère (200g)", "Détection 1.5m"],

                  isSelected: _selectedVersion == "Smart Lite",

                  onTap: () => setState(() => _selectedVersion = "Smart Lite"),

                ),

              ),

              const SizedBox(width: 32),

              Expanded(

                child: _CaneVersionCard(

                  title: "Smart Pro V2",

                  subtitle: "Précision & Bluetooth",

                  badge: "POPULAIRE",

                  badgeColor: Colors.indigo,

                  features: const ["Radar Ultrasons (3m)", "Vibrations haptiques", "Bluetooth App"],

                  isSelected: _selectedVersion == "Smart Pro V2",

                  onTap: () => setState(() => _selectedVersion = "Smart Pro V2"),

                ),

              ),

              const SizedBox(width: 32),

              Expanded(

                child: _CaneVersionCard(

                  title: "Smart Pro V3",

                  subtitle: "IA & LiDAR Vision",

                  badge: "ÉLITE",

                  badgeColor: Colors.deepPurple,

                  features: const ["IA Vision & LiDAR", "Connexion 5G", "Assistance vocale"],

                  isSelected: _selectedVersion == "Smart Pro V3",

                  onTap: () => setState(() => _selectedVersion = "Smart Pro V3"),

                ),

              ),

            ],

          ),

        ),

        const SizedBox(height: 48),

        Center(

          child: AppGradientButton(

            onTap: () => setState(() => _currentStep = 1),

            label: "VOIR LES DÉTAILS DU MODÈLE",

            icon: Icons.info_outline_rounded,

            color: AppTheme.primary,

          ),

        ),

      ],

    );

  }



  Widget _buildDetailsStep() {

    return Container(

      padding: const EdgeInsets.all(48),

      decoration: BoxDecoration(

        color: Colors.white,

        borderRadius: BorderRadius.circular(32),

        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 40, offset: const Offset(0, 10))],

        border: Border.all(color: Colors.grey.withOpacity(0.1)),

      ),

      child: Row(

        crossAxisAlignment: CrossAxisAlignment.start,

        children: [

          Expanded(flex: 2, child: _buildDetailsImage()),

          const SizedBox(width: 80),

          Expanded(flex: 3, child: _buildDetailsInfo()),

        ],

      ),

    );

  }



  Widget _buildDetailsImage() {

    return Hero(

      tag: 'cane_image_$_selectedVersion',

      child: Center(

        child: Image.asset(

          _selectedVersion == "Smart Lite" ? "assets/images/smart_lite.png" : 

          (_selectedVersion == "Smart Pro V2" ? "assets/images/smart_pro_v2.png" : "assets/images/smart_pro_v3.png"),

          height: 350,

          fit: BoxFit.contain,

        ),

      ),

    );

  }



  Widget _buildDetailsInfo() {

    return Column(

      crossAxisAlignment: CrossAxisAlignment.start,

      children: [

        _buildSectionHeader(Icons.info_outline_rounded, "DÉTAILS DU PRODUIT"),

        const SizedBox(height: 32),

        Text(_selectedVersion, style: const TextStyle(fontSize: 48, fontWeight: FontWeight.w900, color: AppTheme.primary, letterSpacing: -1)),

        const SizedBox(height: 8),

        Text(_getPriceForVersion().toUpperCase(), style: const TextStyle(fontSize: 20, color: AppTheme.primary, fontWeight: FontWeight.w900, letterSpacing: 1)),

        const SizedBox(height: 32),

        Text(

          _getDescriptionForVersion(),

          style: const TextStyle(fontSize: 16, color: Color(0xFF64748B), height: 1.8, fontWeight: FontWeight.w500),

        ),

        const SizedBox(height: 48),

        const Text("CARACTÉRISTIQUES ÉLITE :", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11, color: Color(0xFF94A3B8), letterSpacing: 1.5)),

        const SizedBox(height: 24),

        ..._getFeaturesForVersion().map((f) => Padding(

          padding: const EdgeInsets.only(bottom: 16),

          child: Row(

            children: [

              Container(

                padding: const EdgeInsets.all(4),

                decoration: BoxDecoration(color: AppTheme.primary.withOpacity(0.08), shape: BoxShape.circle),

                child: const Icon(Icons.check_rounded, color: AppTheme.primary, size: 16),

              ),

              const SizedBox(width: 16),

              Text(f, style: const TextStyle(fontSize: 15, color: Color(0xFF475569), fontWeight: FontWeight.w600)),

            ],

          ),

        )),

        const SizedBox(height: 64),

        AppGradientButton(

          onTap: () => setState(() => _currentStep = 2),

          label: "PROCÉDER À LA CONFIGURATION",

          icon: Icons.settings_suggest_rounded,

          color: AppTheme.primary,

        ),

      ],

    );

  }



  Widget _buildStepContainer({required String title, required IconData icon, required List<Widget> children}) {

    return Container(

      padding: const EdgeInsets.all(48),

      decoration: BoxDecoration(

        color: Colors.white,

        borderRadius: BorderRadius.circular(32),

        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 40, offset: const Offset(0, 10))],

        border: Border.all(color: Colors.grey.withOpacity(0.1)),

      ),

      child: Column(

        crossAxisAlignment: CrossAxisAlignment.start,

        children: [

          _buildSectionHeader(icon, title),

          const SizedBox(height: 48),

          ...children,

        ],

      ),

    );

  }



  Widget _buildWizardControls() {

    if (_currentStep < 2) return const SizedBox();

    

    return Row(

      mainAxisAlignment: MainAxisAlignment.spaceBetween,

      children: [

        if (_currentStep > 2)

          TextButton.icon(

            onPressed: () => setState(() => _currentStep--),

            icon: const Icon(Icons.arrow_back_rounded, size: 18),

            label: const Text("PRÉCÉDENT", style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1)),

            style: TextButton.styleFrom(

              foregroundColor: const Color(0xFF64748B),

              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),

            ),

          )

        else

          const SizedBox(),

        AppGradientButton(

          onTap: _isSubmitting ? null : () {

            if (_formKey.currentState!.validate()) {

              if (_currentStep < 7) {

                setState(() => _currentStep++);

              } else {

                _submitRegistration();

              }

            }

          },

          icon: _isSubmitting ? Icons.hourglass_empty_rounded : (_currentStep == 7 ? Icons.check_circle_rounded : Icons.arrow_forward_rounded),

          label: _isSubmitting ? "EN COURS..." : (_currentStep == 7 ? "CONFIRMER & SIGNER" : "ÉTAPE SUIVANTE"),

          color: _currentStep == 7 ? AppTheme.neonGreen : AppTheme.primary,

        ),

      ],

    );

  }



  Widget _buildStepClientInfo() {

    return _buildStepContainer(

      title: "I. COORDONNÉES DU BÉNÉFICIAIRE",

      icon: Icons.person_outline,

      children: [

        Row(

          children: [

            Expanded(

              flex: 2,

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

              flex: 3,

              child: Column(

                crossAxisAlignment: CrossAxisAlignment.start,

                children: [

                  _buildFieldLabel("Nom et prénom complet"),

                  _buildTextField(_fullNameController, "Ex: Jean Dupont", Icons.person_outline),

                ],

              ),

            ),

          ],

        ),

        const SizedBox(height: 24),

        Row(

          crossAxisAlignment: CrossAxisAlignment.end,

          children: [

            Expanded(

              flex: 3,

              child: GestureDetector(

                onTap: () => _selectBirthDate(context),

                child: AbsorbPointer(

                  child: Column(

                    crossAxisAlignment: CrossAxisAlignment.start,

                    children: [

                      _buildFieldLabel("Date de naissance"),

                      _buildTextField(_birthDateController, "Sélectionner...", Icons.calendar_today_outlined),

                    ],

                  ),

                ),

              ),

            ),

            const SizedBox(width: 16),

            Expanded(

              flex: 1,

              child: Container(

                padding: const EdgeInsets.symmetric(vertical: 14),

                decoration: BoxDecoration(

                  color: AppTheme.primary.withOpacity(0.05),

                  borderRadius: BorderRadius.circular(12),

                  border: Border.all(color: AppTheme.primary.withOpacity(0.1)),

                ),

                child: Column(

                  mainAxisSize: MainAxisSize.min,

                  children: [

                    const Text("ÂGE", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),

                    Text(

                      _calculatedAge != null ? "$_calculatedAge" : "--",

                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppTheme.primary),

                    ),

                  ],

                ),

              ),

            ),

          ],

        ),

        const SizedBox(height: 24),

        _buildFieldLabel("Adresse Email"),

        _buildTextField(

          _emailController, 

          "exemple@mail.com", 

          Icons.email_outlined,

          validator: (value) {

            if (value == null || value.isEmpty) return "L'email est requis";

            if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {

              return "Veuillez entrer un email valide";

            }

            return null;

          }

        ),

        const SizedBox(height: 24),

        _buildFieldLabel("Téléphone principal"),

        _buildTextField(_phoneController, "12 345 678", Icons.phone_outlined, isPhone: true),

      ],

    );

  }



  Widget _buildStepAddress() {

    return _buildStepContainer(

      title: "II. ADRESSE",

      icon: Icons.location_on_outlined,

      children: [

        _buildFieldLabel("Pays"),

        _buildTextField(_countryController, "Ex: Tunisie", Icons.public_outlined),

        const SizedBox(height: 24),

        Row(

          children: [

            Expanded(

              flex: 2,

              child: Column(

                crossAxisAlignment: CrossAxisAlignment.start,

                children: [

                  _buildFieldLabel("Ville"),

                  _buildTextField(_cityController, "Ex: Tunis", Icons.location_city_outlined),

                ],

              ),

            ),

            const SizedBox(width: 16),

            Expanded(

              flex: 1,

              child: Column(

                crossAxisAlignment: CrossAxisAlignment.start,

                children: [

                   _buildFieldLabel("Code Postal"),

                  _buildTextField(_postalCodeController, "1002", Icons.map_outlined, isNumber: true),

                ],

              ),

            ),

          ],

        ),

      ],

    );

  }



  Widget _buildStepEmergencyContact() {

    return _buildStepContainer(

      title: "III. URGENCE ET INFORMATIONS MÉDICALES",

      icon: Icons.emergency_outlined,

      children: [

        _buildFieldLabel("Nom du contact d'urgence"),

        _buildTextField(_emergencyNameController, "Prénom et Nom du proche", Icons.person_search_outlined),

        const SizedBox(height: 24),

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

                  _buildTextField(_emergencyPhoneController, "12 345 678", Icons.phone_enabled_outlined, isPhone: true),

                ],

              ),

            ),

          ],

        ),

        const SizedBox(height: 32),

        const Divider(),

        const SizedBox(height: 16),

        _buildSectionHeader(Icons.health_and_safety_outlined, "SANTÉ DU BÉNÉFICIAIRE"),

        const SizedBox(height: 24),

        

        // Pathologies (Grid-like layout)

        _buildFieldLabel("Antécédents / Pathologies (Sélection multiple)"),

        Wrap(

          spacing: 12,

          runSpacing: 8,

          children: _pathologies.keys.map((pathology) {

            return FilterChip(

              label: Text(pathology),

              selected: _pathologies[pathology]!,

              onSelected: (selected) {

                setState(() {

                  if (pathology == "Aucune pathologie connue" && selected) {

                    _pathologies.updateAll((key, value) => false);

                  } else if (selected) {

                    _pathologies["Aucune pathologie connue"] = false;

                  }

                  _pathologies[pathology] = selected;

                });

              },

              selectedColor: AppTheme.primary.withOpacity(0.2),

              checkmarkColor: AppTheme.primary,

              labelStyle: TextStyle(

                color: _pathologies[pathology]! ? AppTheme.primary : Colors.black87,

                fontWeight: _pathologies[pathology]! ? FontWeight.bold : FontWeight.normal,

              ),

            );

          }).toList(),

        ),

        

        const SizedBox(height: 16),

        if (_pathologies["Allergies médicamenteuses"]!) ...[

          _buildFieldLabel("Préciser le(s) médicament(s)"),

          _buildTextField(_allergyDetailController, "Quelles allergies ?", Icons.warning_amber_outlined),

          const SizedBox(height: 16),

        ],

        

        if (_pathologies["Autre"]!) ...[

          _buildFieldLabel("Préciser l'autre pathologie"),

          _buildTextField(_otherPathologyController, "Veuillez préciser...", Icons.add_circle_outline),

          const SizedBox(height: 16),

        ],

        

        const SizedBox(height: 16),

        Row(

          children: [

            Expanded(

              flex: 2,

              child: Column(

                crossAxisAlignment: CrossAxisAlignment.start,

                children: [

                  _buildFieldLabel("Groupe sanguin"),

                  Container(

                    padding: const EdgeInsets.symmetric(horizontal: 16),

                    decoration: BoxDecoration(

                      color: Colors.grey.shade50,

                      borderRadius: BorderRadius.circular(12),

                      border: Border.all(color: Colors.grey.shade200),

                    ),

                    child: DropdownButtonHideUnderline(

                      child: DropdownButton<String>(

                        value: _selectedBloodGroup,

                        isExpanded: true,

                        items: _bloodGroups.map((group) {

                          return DropdownMenuItem(value: group, child: Text(group));

                        }).toList(),

                        onChanged: (val) => setState(() => _selectedBloodGroup = val!),

                      ),

                    ),

                  ),

                ],

              ),

            ),

            const SizedBox(width: 16),

            const Expanded(flex: 3, child: SizedBox()),

          ],

        ),

        

        const SizedBox(height: 24),

        _buildFieldLabel("Observations médicales (optionnel)"),

        _buildTextField(_medicalObservationsController, "Remarques complémentaires...", Icons.note_alt_outlined, isMultiline: true, validator: (v) => null),

      ],

    );

  }



  Widget _buildStepCaneEquipment() {

    final versionController = TextEditingController(text: _selectedVersion);

    

    return _buildStepContainer(

      title: "IV. ÉQUIPEMENT ET PÉRIODE",

      icon: Icons.sensors_outlined,

      children: [

        Row(

          children: [

            Expanded(

              flex: 2,

              child: Column(

                crossAxisAlignment: CrossAxisAlignment.start,

                children: [

                  _buildFieldLabel("Modèle de canne"),

                  _buildTextField(versionController, "", Icons.inventory_2_outlined, readOnly: true, enabled: false),

                ],

              ),

            ),

            const SizedBox(width: 16),

            Expanded(

              flex: 3,

              child: Column(

                crossAxisAlignment: CrossAxisAlignment.start,

                children: [

                  _buildFieldLabel("Numéro SIM (4G) louée"),

                  _buildTextField(_simNumberController, "12 345 678", Icons.sim_card_outlined, isPhone: true),

                ],

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

                  _buildFieldLabel("Date de début de location"),

                  GestureDetector(

                    onTap: () => _selectRentalPeriodDate(context, true),

                    child: AbsorbPointer(

                      child: _buildTextField(_startDateController, "Choisir...", Icons.calendar_today_outlined),

                    ),

                  ),

                ],

              ),

            ),

            const SizedBox(width: 16),

            Expanded(

              child: Column(

                crossAxisAlignment: CrossAxisAlignment.start,

                children: [

                  _buildFieldLabel("Date de fin de location"),

                  GestureDetector(

                    onTap: () => _selectRentalPeriodDate(context, false),

                    child: AbsorbPointer(

                      child: _buildTextField(_endDateController, "Choisir...", Icons.calendar_today_outlined),

                    ),

                  ),

                ],

              ),

            ),

          ],

        ),

      ],

    );

  }



  Widget _buildStepPayment() {

    return _buildStepContainer(

      title: "V. PAIEMENT ET VALIDATION",

      icon: Icons.payments_outlined,

      children: [

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

              const SizedBox(height: 24),

              if (!_isPaymentConfirmed) ...[

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

                    label: const Text("CONFIRMER LE PAIEMENT"),

                    style: ElevatedButton.styleFrom(

                      backgroundColor: Colors.orange,

                      foregroundColor: Colors.white,

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

                          "Paiement de $_totalRentalPrice TND reçu par $_paymentMethod",

                          style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.normalGreen),

                        ),

                      ),

                      IconButton(

                        onPressed: () => setState(() => _isPaymentConfirmed = false),

                        icon: const Icon(Icons.edit, size: 20, color: Colors.grey),

                      ),

                    ],

                  ),

                ),

              ],

            ],

          ),

        ),

        const SizedBox(height: 32),

        _buildFieldLabel("Notes internes / Observations"),

        _buildTextField(_internalNotesController, "Remarques...", Icons.edit_note_outlined, isMultiline: true, validator: (v) => null),

      ],

    );

  }



  Widget _buildStepContractDetails() {

    return _buildStepContainer(

      title: "VI. RÉCAPITULATIF DU CONTRAT",

      icon: Icons.description_outlined,

      children: [

        Container(

          padding: const EdgeInsets.all(24),

          decoration: BoxDecoration(

            color: AppTheme.primary.withOpacity(0.05),

            borderRadius: BorderRadius.circular(16),

            border: Border.all(color: AppTheme.primary.withOpacity(0.1)),

          ),

          child: Column(

            crossAxisAlignment: CrossAxisAlignment.start,

            children: [

              const Text("Détails de la Période", style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primary)),

              const Divider(),

              _infoRow("Date de début", _startDateController.text),

              _infoRow("Date de fin", _endDateController.text),

              _infoRow("Durée totale", "$_rentalDurationMonths mois"),

              const SizedBox(height: 20),

              const Text("Détails Financiers", style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primary)),

              const Divider(),

              _infoRow("Modèle", _selectedVersion),

              _infoRow("Tarif mensuel", "$_monthlyRate TND"),

              const SizedBox(height: 12),

              Row(

                mainAxisAlignment: MainAxisAlignment.spaceBetween,

                children: [

                  const Text("TOTAL DU CONTRAT", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),

                  Text("$_totalRentalPrice TND", style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: AppTheme.primary)),

                ],

              ),

            ],

          ),

        ),

        const SizedBox(height: 24),

        Container(

          padding: const EdgeInsets.all(16),

          decoration: BoxDecoration(

            color: AppTheme.normalGreen.withOpacity(0.1),

            borderRadius: BorderRadius.circular(12),

          ),

          child: Row(

            children: [

              const Icon(Icons.verified, color: AppTheme.normalGreen),

              const SizedBox(width: 12),

              Expanded(

                child: Text(

                  "Paiement de $_totalRentalPrice TND validé par $_paymentMethod",

                  style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.normalGreen),

                ),

              ),

            ],

          ),

        ),

      ],

    );

  }



  Widget _buildVersionCard(String title, String subtitle, String badge, Color color, List<String> features) {

    return _CaneVersionCard(

      title: title,

      subtitle: subtitle,

      badge: badge,

      badgeColor: color,

      features: features,

      isSelected: _selectedVersion == title,

      onTap: () {

        setState(() {

          _selectedVersion = title;

          if (_currentStep == 0) _currentStep = 1;

        });

      },

    );

  }



  Widget _buildPaymentRadio(String method, IconData icon) {

    bool isSelected = _paymentMethod == method;

    return Expanded(

      child: GestureDetector(

        onTap: () => setState(() => _paymentMethod = method),

        child: AnimatedContainer(

          duration: const Duration(milliseconds: 300),

          padding: const EdgeInsets.symmetric(vertical: 24),

          decoration: BoxDecoration(

            color: isSelected ? AppTheme.primary : const Color(0xFFF8FAFC),

            borderRadius: BorderRadius.circular(20),

            border: Border.all(color: isSelected ? AppTheme.primary : const Color(0xFFF1F5F9), width: 2),

            boxShadow: isSelected ? [BoxShadow(color: AppTheme.primary.withOpacity(0.2), blurRadius: 15, offset: const Offset(0, 5))] : null,

          ),

          child: Column(

            children: [

              Icon(icon, color: isSelected ? Colors.white : const Color(0xFF94A3B8), size: 32),

              const SizedBox(height: 12),

              Text(

                method.toUpperCase(),

                style: TextStyle(

                  color: isSelected ? Colors.white : const Color(0xFF475569),

                  fontWeight: FontWeight.w900,

                  fontSize: 12,

                  letterSpacing: 1,

                ),

              ),

            ],

          ),

        ),

      ),

    );

  }



  Widget _buildFieldLabel(String label) {

    return Padding(

      padding: const EdgeInsets.only(bottom: 10, left: 4),

      child: Text(

        label,

        style: const TextStyle(color: Color(0xFF64748B), fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 0.5),

      ),

    );

  }



  Widget _buildSectionHeader(IconData icon, String title) {

    return Row(

      children: [

        Container(

          padding: const EdgeInsets.all(10),

          decoration: BoxDecoration(color: AppTheme.primary.withOpacity(0.08), borderRadius: BorderRadius.circular(10)),

          child: Icon(icon, color: AppTheme.primary, size: 18),

        ),

        const SizedBox(width: 16),

        Text(

          title,

          style: const TextStyle(

            color: AppTheme.primary,

            fontSize: 14,

            fontWeight: FontWeight.w900,

            letterSpacing: 1,

          ),

        ),

      ],

    );

  }



  // Normalise an existing phone/SIM value → returns only the 8-digit part

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



  Widget _buildTextField(

    TextEditingController controller, 

    String hint, 

    IconData icon, 

    {bool isNumber = false, bool isPhone = false, bool isMultiline = false, String? Function(String?)? validator, bool readOnly = false, bool enabled = true}

  ) {

    if (isPhone && controller.text.isNotEmpty) {

      final normalized = _normalizePhoneDigits(controller.text);

      if (controller.text != normalized) {

        WidgetsBinding.instance.addPostFrameCallback((_) {

          if (controller.text != normalized) controller.text = normalized;

        });

      }

    }



    return TextFormField(

      controller: controller,

      readOnly: readOnly,

      enabled: enabled,

      maxLines: isMultiline ? 4 : 1,

      keyboardType: isPhone || isNumber

          ? TextInputType.number

          : (isMultiline ? TextInputType.multiline : TextInputType.text),

      inputFormatters: isPhone

          ? [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(8)]

          : null,

      style: const TextStyle(color: AppTheme.primary, fontSize: 15, fontWeight: FontWeight.w600),

      decoration: AppTheme.inputDecoration(isPhone ? '12 345 678' : hint, icon).copyWith(

        prefixText: isPhone ? '+216 ' : null,

        prefixStyle: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold),

        fillColor: enabled ? const Color(0xFFF8FAFC) : const Color(0xFFF1F5F9),

      ),

      validator: isPhone

          ? (value) {

              if (value == null || value.isEmpty) return 'Numéro requis';

              if (value.replaceAll(RegExp(r'[^0-9]'), '').length != 8) {

                return 'Le numéro doit contenir exactement 8 chiffres';

              }

              return null;

            }

          : (validator ?? ((value) => value == null || value.isEmpty ? 'Champ requis' : null)),

    );

  }



  void _submitRegistration() async {

    if (!_formKey.currentState!.validate()) return;

    

    setState(() => _isSubmitting = true);



    // Encode medical data as JSON

    final medicalInfo = {

      "pathologies": _pathologies.entries.where((e) => e.value).map((e) => e.key).toList(),

      "allergie_detail": _allergyDetailController.text.trim(),

      "autre_detail": _otherPathologyController.text.trim(),

      "groupe_sanguin": _selectedBloodGroup,

      "observations": _medicalObservationsController.text.trim(),

    };

    final String medicalJson = jsonEncode(medicalInfo);



    // 1. Collect all data

    final Map<String, dynamic> rentalData = {

      "full_name": _fullNameController.text,

      "birth_date": _birthDateController.text,

      "age": _calculatedAge?.toString() ?? "0",

      "adresse": "${_streetController.text.trim()}, ${_cityController.text.trim()} ${_postalCodeController.text.trim()}, ${_countryController.text.trim()}".trim(),

      "email": _emailController.text.trim(),

      "telephone": _formatPhoneForBackend(_phoneController.text.trim()),

      "cin": _cinController.text,

      "phone": _formatPhoneForBackend(_phoneController.text.trim()),

      "address": {

        "street": _streetController.text.trim(),

        "city": _cityController.text.trim(),

        "postal_code": _postalCodeController.text.trim(),

        "country": _countryController.text.trim(),

      },

      "health_notes": medicalJson,

      "emergency_name": _emergencyNameController.text,

      "emergency_phone": _formatPhoneForBackend(_emergencyPhoneController.text.trim()),

      "emergency_relation": _emergencyRelationController.text,

      "start_date": _startDateController.text,

      "end_date": _endDateController.text,

      "duration_months": _rentalDurationMonths,

      "internal_notes": _internalNotesController.text,

      "model": _selectedVersion,

      "formation_needed": _formationNecessaire,

      "sim_number": _formatPhoneForBackend(_simNumberController.text.trim()),

      "total_price": _totalRentalPrice,

      "payment_method": _paymentMethod,

    };



    // 2. Call API

    final bool success = await RentalService.rentCane(rentalData);

    

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



  Widget _infoRow(String label, String value) {

    return Padding(

      padding: const EdgeInsets.symmetric(vertical: 8),

      child: Row(

        mainAxisAlignment: MainAxisAlignment.spaceBetween,

        children: [

          Text(label, style: const TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w600, fontSize: 13)),

          Text(value, style: const TextStyle(fontWeight: FontWeight.w800, color: AppTheme.primary, fontSize: 14)),

        ],

      ),

    );

  }

}



class _CaneVersionCard extends StatefulWidget {

  final String title;

  final String subtitle;

  final String badge;

  final Color badgeColor;

  final List<String> features;

  final bool isSelected;

  final VoidCallback onTap;



  const _CaneVersionCard({

    required this.title,

    required this.subtitle,

    required this.badge,

    required this.badgeColor,

    required this.features,

    required this.isSelected,

    required this.onTap,

  });



  @override

  State<_CaneVersionCard> createState() => _CaneVersionCardState();

}



class _CaneVersionCardState extends State<_CaneVersionCard> {

  bool _isHovered = false;



  @override

  Widget build(BuildContext context) {

    String imagePath = "";

    if (widget.title.contains("Lite")) imagePath = "assets/images/smart_lite.png";

    else if (widget.title.contains("V2")) imagePath = "assets/images/smart_pro_v2.png";

    else imagePath = "assets/images/smart_pro_v3.png";



    return MouseRegion(

      onEnter: (_) => setState(() => _isHovered = true),

      onExit: (_) => setState(() => _isHovered = false),

      cursor: SystemMouseCursors.click,

      child: GestureDetector(

        onTap: widget.onTap,

        child: AnimatedScale(

          duration: const Duration(milliseconds: 300),

          scale: _isHovered ? 1.02 : 1.0,

          child: AnimatedContainer(

            duration: const Duration(milliseconds: 300),

            curve: Curves.easeOut,

            transform: Matrix4.identity()..translate(0.0, _isHovered ? -8.0 : 0.0),

            decoration: BoxDecoration(

              color: Colors.white,

              borderRadius: BorderRadius.circular(24),

              border: Border.all(

                color: widget.isSelected ? AppTheme.primary : (_isHovered ? AppTheme.primary.withOpacity(0.3) : Colors.grey.withOpacity(0.1)),

                width: widget.isSelected ? 3 : 1.5,

              ),

              boxShadow: [

                BoxShadow(

                  color: Colors.black.withOpacity(_isHovered ? 0.08 : 0.03),

                  blurRadius: _isHovered ? 40 : 20,

                  offset: Offset(0, _isHovered ? 20 : 10),

                ),

              ],

            ),

            child: ClipRRect(

              borderRadius: BorderRadius.circular(22),

              child: Stack(

                fit: StackFit.expand,

                children: [

                  Image.asset(imagePath, fit: BoxFit.cover, alignment: const Alignment(0, -0.5)),

                  Container(

                    decoration: BoxDecoration(

                      gradient: LinearGradient(

                        begin: Alignment.topCenter,

                        end: Alignment.bottomCenter,

                        colors: [Colors.black.withOpacity(0), Colors.black.withOpacity(0.85)],

                        stops: const [0.4, 1.0],

                      ),

                    ),

                  ),

                  Padding(

                    padding: const EdgeInsets.all(32),

                    child: Column(

                      crossAxisAlignment: CrossAxisAlignment.start,

                      mainAxisAlignment: MainAxisAlignment.end,

                      children: [

                        Container(

                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),

                          decoration: BoxDecoration(color: widget.badgeColor, borderRadius: BorderRadius.circular(8)),

                          child: Text(widget.badge, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1)),

                        ),

                        const SizedBox(height: 16),

                        Text(widget.title, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: -0.5)),

                        const SizedBox(height: 8),

                        Text(widget.subtitle, maxLines: 2, style: TextStyle(fontSize: 15, color: Colors.white.withOpacity(0.7), fontWeight: FontWeight.w500)),

                        const SizedBox(height: 24),

                        ...widget.features.map((f) => Padding(

                          padding: const EdgeInsets.only(bottom: 8),

                          child: Row(children: [

                            const Icon(Icons.check_circle_rounded, color: AppTheme.neonGreen, size: 16),

                            const SizedBox(width: 10),

                            Text(f, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),

                          ]),

                        )),

                      ],

                    ),

                  ),

                  if (widget.isSelected)

                    Positioned(

                      top: 20, right: 20,

                      child: Container(

                        padding: const EdgeInsets.all(8),

                        decoration: const BoxDecoration(color: AppTheme.primary, shape: BoxShape.circle),

                        child: const Icon(Icons.check_rounded, color: Colors.white, size: 20),

                      ),

                    ),

                ],

              ),

            ),

          ),

        ),

      ),

    );

  }

}

