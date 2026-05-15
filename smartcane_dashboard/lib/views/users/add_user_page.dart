import 'package:flutter/material.dart';

import 'package:flutter/services.dart';

import 'dart:convert';

import '../../services/services.dart';

import '../theme.dart';

import 'sales_contract_page.dart';



class AddUserPage extends StatefulWidget {

  const AddUserPage({super.key});



  @override

  State<AddUserPage> createState() => _AddUserPageState();

}



class _AddUserPageState extends State<AddUserPage> {

  final _formKey = GlobalKey<FormState>();

  bool _isLoading = false;

  bool _isPaymentConfirmed = false;

  int _currentStep = 0; // 0: Catalog, 1: Details, 2-7: Form Steps



  // --- Identity & Contact (Step 2) ---

  final _fullNameController = TextEditingController();

  final _emailController = TextEditingController();

  final _cinController = TextEditingController();

  final _phoneController = TextEditingController();

  final _birthDateController = TextEditingController();

  DateTime? _selectedBirthDate;

  int? _calculatedAge;



  // --- Address (Step 3) ---

  final _countryController = TextEditingController();

  final _cityController = TextEditingController();

  final _postalCodeController = TextEditingController();

  final _streetController = TextEditingController();



  // --- Emergency Contact (Step 4) ---

  final _emergencyNameController = TextEditingController();

  final _emergencyRelationController = TextEditingController();

  final _emergencyPhoneController = TextEditingController();



  // --- Equipment & Subscription (Step 5) ---

  final _simNumberController = TextEditingController();

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



  String _selectedCaneVersion = "Smart Pro v3";

  final Map<String, int> _canePrices = {

    "Smart Lite": 1200,

    "Smart Pro v2": 1500,

    "Smart Pro v3": 1800,

  };

  

  DateTime _subStartDate = DateTime.now();

  DateTime _subEndDate = DateTime.now().add(const Duration(days: 365));

  final int _pricePerMonth = 20;



  // --- Payment (Step 6) ---

  String _paymentMethod = "Espèces";



  int get _canePrice => _canePrices[_selectedCaneVersion] ?? 0;

  

  int get _subscriptionPrice {

    int months = _calculateMonths(_subStartDate, _subEndDate);

    if (months <= 0) return 0;

    return months * _pricePerMonth;

  }

  

  int get _totalPrice => _canePrice + _subscriptionPrice;



  int _calculateMonths(DateTime start, DateTime end) {

    if (end.isBefore(start)) return 0;

    int months = (end.year - start.year) * 12 + end.month - start.month;

    if (end.day > start.day) months++;

    return months == 0 && end.isAfter(start) ? 1 : months;

  }



  @override

  Widget build(BuildContext context) {

    bool isWizard = _currentStep >= 2;



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

                if (isWizard) ...[

                  const SizedBox(height: 48),

                  _buildStepper(),

                ],

                const SizedBox(height: 48),

                _buildCurrentStepContent(),

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

            Text("Portail d'Enregistrement", style: Theme.of(context).textTheme.headlineMedium),

            const SizedBox(height: 6),

            Text(_getStepSubtitle(), style: const TextStyle(color: Color(0xFF64748B), fontSize: 14, fontWeight: FontWeight.w500)),

          ],

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

      case 5: return "Étape 4 : Équipement et Abonnement";

      case 6: return "Étape 5 : Règlement et Paiement";

      case 7: return "Étape 6 : Récapitulatif et Signature du contrat";

      default: return "";

    }

  }



  Widget _buildStepper() {

    return Row(

      children: [

        _buildStepIndicator(2, "Client", Icons.person_outline),

        _buildStepLine(2),

        _buildStepIndicator(3, "Adresse", Icons.location_on_outlined),

        _buildStepLine(3),

        _buildStepIndicator(4, "Urgence", Icons.emergency_outlined),

        _buildStepLine(4),

        _buildStepIndicator(5, "Équipement", Icons.sensors_outlined),

        _buildStepLine(5),

        _buildStepIndicator(6, "Paiement", Icons.payments_outlined),

        _buildStepLine(6),

        _buildStepIndicator(7, "Contrat", Icons.description_outlined),

      ],

    );

  }



  Widget _buildStepIndicator(int step, String label, IconData icon) {

    bool isActive = _currentStep >= step;

    bool isCurrent = _currentStep == step;

    return Column(

      children: [

        AnimatedContainer(

          duration: const Duration(milliseconds: 300),

          padding: const EdgeInsets.all(14),

          decoration: BoxDecoration(

            color: isCurrent ? AppTheme.primary : (isActive ? AppTheme.primary.withOpacity(0.08) : const Color(0xFFF1F5F9)),

            shape: BoxShape.circle,

            border: Border.all(color: isCurrent ? AppTheme.primary : (isActive ? AppTheme.primary.withOpacity(0.2) : Colors.transparent), width: 2),

            boxShadow: isCurrent ? [BoxShadow(color: AppTheme.primary.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 5))] : null,

          ),

          child: Icon(icon, color: isCurrent ? Colors.white : (isActive ? AppTheme.primary : const Color(0xFF94A3B8)), size: 22),

        ),

        const SizedBox(height: 12),

        Text(

          label,

          style: TextStyle(

            fontSize: 11,

            letterSpacing: 0.5,

            fontWeight: isCurrent ? FontWeight.w900 : FontWeight.w700,

            color: isCurrent ? AppTheme.primary : (isActive ? const Color(0xFF475569) : const Color(0xFF94A3B8)),

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

        color: isActive ? AppTheme.primary : Colors.grey.shade200,

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

    final screenWidth = MediaQuery.of(context).size.width;

    bool isMobile = screenWidth < 1200;



    return Column(

      crossAxisAlignment: CrossAxisAlignment.start,

      children: [

        const Text(

          "Quelle version de la SIRIUS souhaitez-vous acquérir ?",

          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFF475569), letterSpacing: -0.5),

        ),

        const SizedBox(height: 48),

        if (isMobile)

          Column(

            children: [

              SizedBox(height: 520, child: _buildVersionCard("Smart Lite", "Légèreté & Simplicité", "ESSENTIEL", Colors.blue, ["48h autonomie", "Ultra légère (200g)", "Détection 1.5m"])),

              const SizedBox(height: 24),

              SizedBox(height: 520, child: _buildVersionCard("Smart Pro v2", "Précision & Bluetooth", "POPULAIRE", Colors.indigo, ["Radar Ultrasons (3m)", "Vibrations haptiques", "Bluetooth App"])),

              const SizedBox(height: 24),

              SizedBox(height: 520, child: _buildVersionCard("Smart Pro v3", "IA & LiDAR Vision", "ÉLITE", Colors.deepPurple, ["IA Vision & LiDAR", "Connexion 5G", "Assistance vocale"])),

            ],

          )

        else

          SizedBox(

            height: 580,

            child: Row(

              children: [

                Expanded(child: _buildVersionCard("Smart Lite", "Légèreté & Simplicité", "ESSENTIEL", Colors.blue, ["48h autonomie", "Ultra légère (200g)", "Détection 1.5m"])),

                const SizedBox(width: 32),

                Expanded(child: _buildVersionCard("Smart Pro v2", "Précision & Bluetooth", "POPULAIRE", Colors.indigo, ["Radar Ultrasons (3m)", "Vibrations haptiques", "Bluetooth App"])),

                const SizedBox(width: 32),

                Expanded(child: _buildVersionCard("Smart Pro v3", "IA & LiDAR Vision", "ÉLITE", Colors.deepPurple, ["IA Vision & LiDAR", "Connexion 5G", "Assistance vocale"])),

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

      isSelected: _selectedCaneVersion == title,

      onTap: () {

        setState(() {

          _selectedCaneVersion = title;

          if (_currentStep == 0) _currentStep = 1;

        });

      },

    );

  }



  Widget _buildDetailsStep() {

    final screenWidth = MediaQuery.of(context).size.width;

    bool isWide = screenWidth > 1000;



    return Container(

      padding: const EdgeInsets.all(48),

      decoration: BoxDecoration(

        color: Colors.white,

        borderRadius: BorderRadius.circular(32),

        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 40, offset: const Offset(0, 10))],

        border: Border.all(color: Colors.grey.withOpacity(0.1)),

      ),

      child: isWide 

        ? Row(

            crossAxisAlignment: CrossAxisAlignment.start,

            children: [

              Expanded(flex: 2, child: _buildDetailsImage()),

              const SizedBox(width: 80),

              Expanded(flex: 3, child: _buildDetailsInfo()),

            ],

          )

        : Column(

            children: [

              _buildDetailsImage(),

              const SizedBox(height: 48),

              _buildDetailsInfo(),

            ],

          ),

    );

  }



  Widget _buildDetailsImage() {

    return Hero(

      tag: 'cane_image_$_selectedCaneVersion',

      child: Center(

        child: Image.asset(

          _selectedCaneVersion.contains("Lite") ? "assets/images/smart_lite.png" : 

          (_selectedCaneVersion.contains("v2") ? "assets/images/smart_pro_v2.png" : "assets/images/smart_pro_v3.png"),

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

        _buildSectionHeader(Icons.info_outline, "DÉTAILS DU PRODUIT"),

        const SizedBox(height: 24),

        Text(_selectedCaneVersion, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900)),

        const SizedBox(height: 4),

        Text("${_canePrices[_selectedCaneVersion]} TND", style: const TextStyle(fontSize: 20, color: AppTheme.primary, fontWeight: FontWeight.bold)),

        const SizedBox(height: 24),

        Text(

          "Équipement de mobilité avancée conçu pour une autonomie totale des personnes malvoyantes.",

          style: TextStyle(fontSize: 16, color: Colors.grey.shade700, height: 1.6),

        ),

        const SizedBox(height: 32),

        const Text("Garanties incluses :", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),

        const SizedBox(height: 16),

        _buildBulletInfo(Icons.verified, "Garantie matériel 2 ans"),

        const SizedBox(height: 12),

        _buildBulletInfo(Icons.headset_mic, "Assistance technique prioritaire"),

        const SizedBox(height: 12),

        _buildBulletInfo(Icons.update, "Mises à jour logicielles à vie"),

        const SizedBox(height: 40),

        SizedBox(

          width: double.infinity,

          height: 60,

          child: ElevatedButton(

            onPressed: () => setState(() => _currentStep = 2),

            style: ElevatedButton.styleFrom(

              backgroundColor: AppTheme.primary,

              foregroundColor: Colors.white,

              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),

              elevation: 4,

            ),

            child: const Text("PROCÉDER À L'ACHAT", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 0.5)),

          ),

        ),

      ],

    );

  }



  Widget _buildBulletInfo(IconData icon, String text) {

    return Row(

      children: [

        Icon(icon, color: AppTheme.normalGreen, size: 20),

        const SizedBox(width: 12),

        Text(text, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),

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

          const SizedBox(height: 40),

          ...children,

          const SizedBox(height: 48),

          _buildNavigationButtons(),

        ],

      ),

    );

  }



  Widget _buildNavigationButtons() {

    return Row(

      mainAxisAlignment: MainAxisAlignment.spaceBetween,

      children: [

        TextButton.icon(

          onPressed: () => setState(() => _currentStep--),

          icon: const Icon(Icons.arrow_back_rounded, size: 18),

          label: const Text("RETOUR", style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1)),

          style: TextButton.styleFrom(

            foregroundColor: const Color(0xFF64748B),

            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),

          ),

        ),

        AppGradientButton(

          onTap: _isLoading ? null : () {

            if (_formKey.currentState!.validate()) {

              if (_currentStep < 6) {

                setState(() => _currentStep++);

              } else if (_currentStep == 6) {

                if (_isPaymentConfirmed) {

                  setState(() => _currentStep++);

                } else {

                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(

                    content: Text("Veuillez confirmer le paiement pour passer au récapitulatif."),

                    backgroundColor: AppTheme.sosRed,

                  ));

                }

              } else {

                _submitData();

              }

            } else {

              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(

                content: Text("Veuillez corriger les erreurs dans le formulaire."),

                backgroundColor: AppTheme.sosRed,

              ));

            }

          },

          icon: _currentStep == 7 ? Icons.check_circle_rounded : Icons.arrow_forward_rounded,

          label: _currentStep == 7 ? (_isLoading ? "VALIDATION..." : "VALIDER LA VENTE") : "ÉTAPE SUIVANTE",

          color: AppTheme.primary,

        ),

      ],

    );

  }



  void _selectBirthDate(BuildContext context) async {

    final DateTime? picked = await showDatePicker(

      context: context,

      initialDate: _selectedBirthDate ?? DateTime.now().subtract(const Duration(days: 365 * 20)),

      firstDate: DateTime(1900),

      lastDate: DateTime.now(),

    );

    if (picked != null) {

      setState(() {

        _selectedBirthDate = picked;

        _birthDateController.text = "${picked.day}/${picked.month}/${picked.year}";

        _calculatedAge = DateTime.now().year - picked.year;

        if (DateTime.now().month < picked.month || (DateTime.now().month == picked.month && DateTime.now().day < picked.day)) {

          _calculatedAge = (_calculatedAge ?? 0) - 1;

        }

      });

    }

  }



  void _selectSubDate(BuildContext context, bool isStart) async {

    final DateTime? picked = await showDatePicker(

      context: context,

      initialDate: isStart ? _subStartDate : _subEndDate,

      firstDate: DateTime.now().subtract(const Duration(days: 365)),

      lastDate: DateTime.now().add(const Duration(days: 365 * 10)),

    );

    if (picked != null) {

      setState(() {

        if (isStart) {

          _subStartDate = picked;

        } else {

          _subEndDate = picked;

        }

      });

    }

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

        _buildTextField(_emailController, "exemple@mail.com", Icons.email_outlined),

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

                    // Reset all others if "None" is selected

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

    final versionController = TextEditingController(text: _selectedCaneVersion);

    return _buildStepContainer(

      title: "IV. ÉQUIPEMENT ET ABONNEMENT",

      icon: Icons.sensors_outlined,

      children: [

        Row(

          children: [

            Expanded(

              flex: 2,

              child: Column(

                crossAxisAlignment: CrossAxisAlignment.start,

                children: [

                  _buildFieldLabel("Modèle sélectionné"),

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

                  _buildFieldLabel("Numéro SIM (4G) associée"),

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

                  _buildFieldLabel("Début d'abonnement"),

                  GestureDetector(

                    onTap: () => _selectSubDate(context, true),

                    child: AbsorbPointer(

                      child: _buildTextField(TextEditingController(text: "${_subStartDate.day}/${_subStartDate.month}/${_subStartDate.year}"), "Choisir...", Icons.calendar_today_outlined),

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

                  _buildFieldLabel("Fin d'abonnement"),

                  GestureDetector(

                    onTap: () => _selectSubDate(context, false),

                    child: AbsorbPointer(

                      child: _buildTextField(TextEditingController(text: "${_subEndDate.day}/${_subEndDate.month}/${_subEndDate.year}"), "Choisir...", Icons.calendar_today_outlined),

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

      title: "V. RÈGLEMENT ET PAIEMENT",

      icon: Icons.payments_outlined,

      children: [

        Container(

          padding: const EdgeInsets.all(24),

          decoration: BoxDecoration(

            color: _isPaymentConfirmed ? AppTheme.normalGreen.withOpacity(0.05) : Colors.white,

            borderRadius: BorderRadius.circular(16),

            border: Border.all(color: _isPaymentConfirmed ? AppTheme.normalGreen : Colors.orange.shade300, width: 2),

          ),

          child: Column(

            crossAxisAlignment: CrossAxisAlignment.start,

            children: [

              Row(

                children: [

                  Icon(_isPaymentConfirmed ? Icons.verified : Icons.payments_rounded, color: _isPaymentConfirmed ? AppTheme.normalGreen : Colors.orange, size: 28),

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

                    label: const Text("CONFIRMER L'ENCAISSEMENT"),

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

                          "Paiement de $_totalPrice TND reçu par $_paymentMethod",

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

              const Text("Détails de la Vente", style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primary)),

              const Divider(),

              _infoRow("Modèle", _selectedCaneVersion),

              _infoRow("Prix Canne", "$_canePrice TND"),

              const SizedBox(height: 12),

              const Text("Détails Abonnement", style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primary)),

              const Divider(),

              _infoRow("Période", "Du ${_subStartDate.day}/${_subStartDate.month}/${_subStartDate.year} au ${_subEndDate.day}/${_subEndDate.month}/${_subEndDate.year}"),

              _infoRow("Durée", "${_calculateMonths(_subStartDate, _subEndDate)} mois"),

              _infoRow("Prix Abonnement", "$_subscriptionPrice TND"),

              const Divider(height: 32),

              Row(

                mainAxisAlignment: MainAxisAlignment.spaceBetween,

                children: [

                  const Text("TOTAL TTC", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),

                  Text("$_totalPrice TND", style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: AppTheme.primary)),

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

                  "Paiement de $_totalPrice TND validé par $_paymentMethod",

                  style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.normalGreen),

                ),

              ),

            ],

          ),

        ),

      ],

    );

  }



  Widget _infoRow(String label, String value) {

    return Padding(

      padding: const EdgeInsets.symmetric(vertical: 4),

      child: Row(

        mainAxisAlignment: MainAxisAlignment.spaceBetween,

        children: [

          Text(label, style: const TextStyle(color: Colors.grey)),

          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),

        ],

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

    // Strip known prefixes: +216, 00216, 216

    String cleaned = raw.trim();

    if (cleaned.startsWith('+216')) cleaned = cleaned.substring(4);

    else if (cleaned.startsWith('00216')) cleaned = cleaned.substring(5);

    else if (cleaned.startsWith('216') && cleaned.length > 3) cleaned = cleaned.substring(3);

    // Keep only digits

    cleaned = cleaned.replaceAll(RegExp(r'[^0-9]'), '');

    // Trim to max 8 digits

    if (cleaned.length > 8) cleaned = cleaned.substring(0, 8);

    return cleaned;

  }



  // Returns the full +216XXXXXXXX value for sending to backend

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

      maxLines: isMultiline ? 3 : 1,

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



  void _submitData() async {

    if (!_formKey.currentState!.validate()) {

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Veuillez remplir tous les champs obligatoires.")));

      return;

    }

    

    // Safety check for critical fields

    if (_cinController.text.trim().isEmpty || _fullNameController.text.trim().isEmpty || _simNumberController.text.trim().isEmpty) {

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("CIN, Nom et SIM sont obligatoires."), backgroundColor: AppTheme.sosRed));

      return;

    }



    setState(() => _isLoading = true);



    try {

      final String cin = _cinController.text.trim();

      final String email = _emailController.text.trim().isNotEmpty 

          ? _emailController.text.trim() 

          : "$cin@smartcane.com";



      // Format address properly for backend (String)

      String formattedAddress = "${_streetController.text.trim()}, ${_cityController.text.trim()} ${_postalCodeController.text.trim()}, ${_countryController.text.trim()}".trim();

      if (formattedAddress.startsWith(',')) formattedAddress = formattedAddress.substring(1).trim();



      // Encode medical data as JSON

      final medicalInfo = {

        "pathologies": _pathologies.entries.where((e) => e.value).map((e) => e.key).toList(),

        "allergie_detail": _allergyDetailController.text.trim(),

        "autre_detail": _otherPathologyController.text.trim(),

        "groupe_sanguin": _selectedBloodGroup,

        "observations": _medicalObservationsController.text.trim(),

      };

      final String medicalJson = jsonEncode(medicalInfo);



      // Check if user already exists

      final existingUser = await UserService.getUserByCin(cin);

      

      bool userSuccess = false;

      String? errorMessage;



      if (existingUser != null) {

        // User exists -> Update

        final resUpdate = await UserService.updateUser(cin, {

          "nom": _fullNameController.text.trim(),

          "adresse": formattedAddress,

          "email": email,

          "age": _calculatedAge ?? 0,

          "numero_de_telephone": _formatPhoneForBackend(_phoneController.text.trim()),

          "contact_familial": _formatPhoneForBackend(_emergencyPhoneController.text.trim()),

          "sim_de_la_canne": _formatPhoneForBackend(_simNumberController.text.trim()),

          "etat_de_sante": medicalJson,

        });

        userSuccess = resUpdate["success"];

        errorMessage = resUpdate["error"];

      } else {

        // User doesn't exist -> Create

        final resAdd = await UserService.addUser({

          "cin": cin,

          "nom": _fullNameController.text.trim(),

          "email": email,

          "age": _calculatedAge ?? 0,

          "adresse": formattedAddress,

          "numero_de_telephone": _formatPhoneForBackend(_phoneController.text.trim()),

          "contact_familial": _formatPhoneForBackend(_emergencyPhoneController.text.trim()),

          "etat_de_sante": medicalJson,

          "sim_de_la_canne": _formatPhoneForBackend(_simNumberController.text.trim()),

          "role": "client",

        });

        userSuccess = resAdd["success"];

        errorMessage = resAdd["error"];

      }



      if (userSuccess) {

        // 3. Update Cane status

        await CaneService.updateCane(_formatPhoneForBackend(_simNumberController.text.trim()), {

          "statut": "vendue",

          "version": _selectedCaneVersion,

          "type": "vente"

        });



        // 4. Create Abonnement record for Sales

        await SubscriptionService.createSubscription({

          "sim_de_la_canne": _formatPhoneForBackend(_simNumberController.text.trim()),

          "cin_utilisateur": cin,

          "type_d_abonnement": _selectedCaneVersion.contains("Lite") ? "essential" : "premium",

          "date_de_fin": "${_subEndDate.year}-${_subEndDate.month.toString().padLeft(2, '0')}-${_subEndDate.day.toString().padLeft(2, '0')}",

        });



        if (mounted) {

          setState(() => _isLoading = false);

          _showFinalContract(); // Success -> Contract

        }

      } else {

        if (mounted) {

          setState(() => _isLoading = false);

          ScaffoldMessenger.of(context).showSnackBar(

            SnackBar(

              content: Text("ERREUR: ${errorMessage ?? 'Une erreur est survenue'}"), 

              backgroundColor: AppTheme.sosRed,

              duration: const Duration(seconds: 5),

            ),

          );

        }

      }

    } catch (e) {

      print("CRITICAL ERROR: $e");

      if (mounted) {

        setState(() => _isLoading = false);

        ScaffoldMessenger.of(context).showSnackBar(

          SnackBar(content: Text("ERREUR CRITIQUE: $e"), backgroundColor: AppTheme.sosRed),

        );

      }

    }

  }



  void _showFinalContract() {

    final saleData = {

      "nom": _fullNameController.text.trim(),

      "cin": _cinController.text.trim(),

      "email": _emailController.text.trim(),

      "numero_de_telephone": _formatPhoneForBackend(_phoneController.text.trim()),

      "emergency_name": _emergencyNameController.text.trim(),

      "emergency_phone": _formatPhoneForBackend(_emergencyPhoneController.text.trim()),

      "emergency_relation": _emergencyRelationController.text.trim(),

      "birth_date": _birthDateController.text,

      "address": {

        "street": _streetController.text.trim(),

        "city": _cityController.text.trim(),

        "postal_code": _postalCodeController.text.trim(),

        "country": _countryController.text.trim(),

      },

      "payment_info": {

        "method": _paymentMethod,

        "total_amount": _totalPrice.toString(),

        "subscription_start": "${_subStartDate.day}/${_subStartDate.month}/${_subStartDate.year}",

        "subscription_end": "${_subEndDate.day}/${_subEndDate.month}/${_subEndDate.year}",

        "subscription_duration_months": _calculateMonths(_subStartDate, _subEndDate).toString(),

        "subscription_price": _subscriptionPrice.toString(),

        "cane_price": _canePrice.toString(),

      },

      "sim_de_la_canne": _formatPhoneForBackend(_simNumberController.text.trim()),

      "version_canne": _selectedCaneVersion,

    };



    Navigator.of(context).push(

      MaterialPageRoute(

        builder: (_) => SalesContractPage(saleData: saleData),

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

    final String title = widget.title.toLowerCase();



    if (title.contains("lite")) imagePath = "assets/images/smart_lite.png";

    else if (title.contains("v2")) imagePath = "assets/images/smart_pro_v2.png";

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

