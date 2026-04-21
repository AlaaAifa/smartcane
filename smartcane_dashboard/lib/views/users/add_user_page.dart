import 'package:flutter/material.dart';
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
            padding: const EdgeInsets.all(40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                if (isWizard) ...[
                  const SizedBox(height: 40),
                  _buildStepper(),
                ],
                const SizedBox(height: 40),
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
            padding: const EdgeInsets.only(right: 20),
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, size: 20),
              onPressed: () => setState(() => _currentStep--),
              style: IconButton.styleFrom(
                backgroundColor: Colors.white,
                padding: const EdgeInsets.all(12),
                shadowColor: Colors.black12,
                elevation: 4,
              ),
            ),
          ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "BOUTIQUE SMART CANE",
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.black87),
            ),
            Text(
              _getStepSubtitle(),
              style: TextStyle(color: Colors.grey.withOpacity(0.8), fontSize: 14),
            ),
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
      case 4: return "Étape 3 : Contact d'urgence";
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
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isCurrent ? AppTheme.primary : (isActive ? AppTheme.primary.withOpacity(0.1) : Colors.grey.shade200),
            shape: BoxShape.circle,
            border: Border.all(color: isCurrent ? AppTheme.primary : (isActive ? AppTheme.primary : Colors.transparent)),
          ),
          child: Icon(icon, color: isCurrent ? Colors.white : (isActive ? AppTheme.primary : Colors.grey), size: 20),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
            color: isActive ? Colors.black87 : Colors.grey,
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
          "Quelle version de la Smart Cane souhaitez-vous acquérir ?",
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black54),
        ),
        const SizedBox(height: 32),
        if (isMobile)
          Column(
            children: [
              SizedBox(height: 500, child: _buildVersionCard("Smart Lite", "Légèreté & Simplicité", "ESSENTIEL", Colors.blue, ["48h autonomie", "Ultra légère (200g)", "Détection 1.5m"])),
              const SizedBox(height: 24),
              SizedBox(height: 500, child: _buildVersionCard("Smart Pro v2", "Précision & Bluetooth", "POPULAIRE", Colors.indigo, ["Radar Ultrasons (3m)", "Vibrations haptiques", "Bluetooth App"])),
              const SizedBox(height: 24),
              SizedBox(height: 500, child: _buildVersionCard("Smart Pro v3", "IA & LiDAR Vision", "ÉLITE", Colors.deepPurple, ["IA Vision & LiDAR", "Connexion 5G", "Assistance vocale"])),
            ],
          )
        else
          SizedBox(
            height: 550,
            child: Row(
              children: [
                Expanded(child: _buildVersionCard("Smart Lite", "Légèreté & Simplicité", "ESSENTIEL", Colors.blue, ["48h autonomie", "Ultra légère (200g)", "Détection 1.5m"])),
                const SizedBox(width: 24),
                Expanded(child: _buildVersionCard("Smart Pro v2", "Précision & Bluetooth", "POPULAIRE", Colors.indigo, ["Radar Ultrasons (3m)", "Vibrations haptiques", "Bluetooth App"])),
                const SizedBox(width: 24),
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
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 30, offset: const Offset(0, 15))],
      ),
      child: isWide 
        ? Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 2, child: _buildDetailsImage()),
              const SizedBox(width: 60),
              Expanded(flex: 3, child: _buildDetailsInfo()),
            ],
          )
        : Column(
            children: [
              _buildDetailsImage(),
              const SizedBox(height: 40),
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
        _buildBulletInfo(Icons.headset_mic, "Assistance technique prioritiaire"),
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
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 30, offset: const Offset(0, 15))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(icon, title),
          const SizedBox(height: 32),
          ...children,
          const SizedBox(height: 40),
          _buildNavigationButtons(),
        ],
      ),
    );
  }

  Widget _buildNavigationButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        OutlinedButton.icon(
          onPressed: () => setState(() => _currentStep--),
          icon: const Icon(Icons.arrow_back),
          label: const Text("PRÉCÉDENT"),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        ElevatedButton.icon(
          onPressed: _isLoading ? null : () {
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
              // Surface validation errors
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content: Text("Veuillez corriger les erreurs dans le formulaire."),
                backgroundColor: AppTheme.sosRed,
              ));
            }
          },
          icon: _isLoading 
            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
            : Icon(_currentStep == 7 ? Icons.check_circle : Icons.arrow_forward),
          label: Text(_currentStep == 7 ? (_isLoading ? "ENREGISTREMENT..." : "ENREGISTRER LA VENTE") : "SUIVANT"),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
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
        _buildTextField(_phoneController, "01 23 45 67 89", Icons.phone_outlined, isNumber: true),
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
      title: "III. CONTACT D'URGENCE",
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
                  _buildTextField(_emergencyPhoneController, "Numéro permanent", Icons.phone_enabled_outlined, isNumber: true),
                ],
              ),
            ),
          ],
        ),
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
                  _buildTextField(_simNumberController, "Ex: 216XXXXXXXX", Icons.sim_card_outlined),
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
        const SizedBox(height: 24),
        _buildFieldLabel("Notes de santé / État (Bénéficiaire)"),
        _buildTextField(_healthNotesController, "Ex: Diabète, Difficultés motrices...", Icons.health_and_safety_outlined, isMultiline: true, validator: (v) => null),
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
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        label,
        style: const TextStyle(color: Colors.black87, fontSize: 13, fontWeight: FontWeight.bold),
      ),
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
    {bool isNumber = false, bool isMultiline = false, String? Function(String?)? validator, bool readOnly = false, bool enabled = true}
  ) {
    return TextFormField(
      controller: controller,
      readOnly: readOnly,
      enabled: enabled,
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
      validator: validator ?? ((value) => value == null || value.isEmpty ? "Champ requis" : null),
    );
  }

  void _submitData() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Veuillez remplir tous les champs obligatoires.")));
      return;
    }
    
    // Safety check for critical fields
    if (_cinController.text.isEmpty || _fullNameController.text.isEmpty || _simNumberController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("CIN, Nom et SIM sont obligatoires."), backgroundColor: AppTheme.sosRed));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final String email = _emailController.text.trim().isNotEmpty 
          ? _emailController.text.trim() 
          : "${_cinController.text.trim()}@smartcane.com";

      // Format address properly for backend (String)
      String formattedAddress = "${_streetController.text.trim()}, ${_cityController.text.trim()} ${_postalCodeController.text.trim()}, ${_countryController.text.trim()}".trim();
      if (formattedAddress.startsWith(',')) formattedAddress = formattedAddress.substring(1).trim();

      final flatUserData = {
        "cin": _cinController.text.trim(),
        "nom": _fullNameController.text.trim(),
        "email": email,
        "age": _calculatedAge ?? 0,
        "adresse": formattedAddress,
        "numero_de_telephone": _phoneController.text.trim(),
        "contact_familial": _emergencyPhoneController.text.trim(),
        "etat_de_sante": _healthNotesController.text.trim(),
        "sim_de_la_canne": _simNumberController.text.trim(),
        "role": "client",
      };

      // 1. Try to Add User
      final resAdd = await UserService.addUser(flatUserData);
      bool userSuccess = resAdd["success"];
      String? errorMessage = resAdd["error"];
      
      // 2. If User exists (400) or fails, try Update as fallback
      if (!userSuccess) {
        final resUpdate = await UserService.updateUser(_cinController.text.trim(), {
          "nom": _fullNameController.text.trim(),
          "adresse": formattedAddress,
          "numero_de_telephone": _phoneController.text.trim(),
          "sim_de_la_canne": _simNumberController.text.trim(),
          "etat_de_sante": _healthNotesController.text.trim(),
        });
        userSuccess = resUpdate["success"];
        errorMessage = resUpdate["error"];
      }

      if (userSuccess) {
        // 3. Update Cane status
        await CaneService.updateCane(_simNumberController.text.trim(), {
          "statut": "vendue",
          "version": _selectedCaneVersion,
          "type": "vente"
        });

        // 4. Create Abonnement record for Sales
        await SubscriptionService.createSubscription({
          "sim_de_la_canne": _simNumberController.text.trim(),
          "cin_utilisateur": _cinController.text.trim(),
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
            SnackBar(content: Text("ERREUR: $errorMessage"), backgroundColor: AppTheme.sosRed),
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
      "numero_de_telephone": _phoneController.text.trim(),
      "emergency_name": _emergencyNameController.text.trim(),
      "emergency_phone": _emergencyPhoneController.text.trim(),
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
      "sim_de_la_canne": _simNumberController.text.trim(),
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
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: _isHovered || widget.isSelected ? AppTheme.primary.withOpacity(0.5) : Colors.grey.shade100,
                width: _isHovered || widget.isSelected ? 2 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(_isHovered ? 0.15 : 0.05),
                  blurRadius: _isHovered ? 35 : 15,
                  offset: Offset(0, _isHovered ? 18 : 8),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(19),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(imagePath, fit: BoxFit.cover, alignment: const Alignment(0, -0.5)),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.black.withOpacity(0), Colors.black.withOpacity(0.8)],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(color: widget.badgeColor, borderRadius: BorderRadius.circular(6)),
                          child: Text(widget.badge, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900)),
                        ),
                        const SizedBox(height: 12),
                        Text(widget.title, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.white)),
                        const SizedBox(height: 8),
                        Text(widget.subtitle, maxLines: 2, style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.8))),
                        const SizedBox(height: 16),
                        ...widget.features.map((f) => Row(children: [
                          const Icon(Icons.check_circle_rounded, color: AppTheme.normalGreen, size: 14),
                          const SizedBox(width: 8),
                          Text(f, style: const TextStyle(color: Colors.white, fontSize: 12)),
                        ])),
                      ],
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
