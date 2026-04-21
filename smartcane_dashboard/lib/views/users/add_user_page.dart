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
  int _currentStep = 0; // 0: Catalog, 1: Insight, 2: Checkout

  // --- Identity & Contact ---
  final _nomController = TextEditingController();
  final _prenomController = TextEditingController();
  final _emailController = TextEditingController();
  final _cinController = TextEditingController();
  final _phoneMalvoyantController = TextEditingController();
  final _phoneFamilleController = TextEditingController();
  final _birthDateController = TextEditingController();
  DateTime? _selectedBirthDate;
  int? _calculatedAge;

  // --- Billing & Commerce ---
  final _cityController = TextEditingController();
  final _streetController = TextEditingController();
  final _postalCodeController = TextEditingController();
  String _paymentMethod = "Espèces";
  final _amountController = TextEditingController(text: "1500");
  String _warrantyPeriod = "2 Ans";

  // --- Medical & Security ---
  String _bloodGroup = "Inconnu";
  final _medicalConditionsController = TextEditingController();
  final List<Map<String, String>> _emergencyContacts = [];
  final _eContactNameController = TextEditingController();
  final _eContactPhoneController = TextEditingController();
  final _eContactRelationController = TextEditingController();

  // --- Device & Versions ---
  final _simNumberController = TextEditingController();
  String _selectedCaneVersion = "Smart Pro v3";
  final Map<String, int> _canePrices = {
    "Smart Lite": 1200,
    "Smart Pro v2": 1500,
    "Smart Pro v3": 1800,
  };
  String _voiceLanguage = "Français";
  double _voiceSpeed = 1.0;
  
  // --- Subscription ---
  String _subscriptionPeriod = "1 An";
  final Map<String, int> _subscriptionPrices = {
    "Sans Abonnement": 0,
    "1 An": 200,
    "2 Ans": 350,
    "3 Ans": 480,
  };

  int get _canePrice => _canePrices[_selectedCaneVersion] ?? 0;
  int get _subscriptionPrice => _subscriptionPrices[_subscriptionPeriod] ?? 0;
  int get _totalPrice => _canePrice + _subscriptionPrice;

  void _updateTotalPrice() {
    _amountController.text = _totalPrice.toString();
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
    if (now.month < _selectedBirthDate!.month || (now.month == _selectedBirthDate!.month && now.day < _selectedBirthDate!.day)) age--;
    setState(() => _calculatedAge = age);
  }

  void _addEmergencyContact() {
    if (_eContactNameController.text.isEmpty || _eContactPhoneController.text.isEmpty) return;
    setState(() {
      _emergencyContacts.add({
        "name": _eContactNameController.text.trim(),
        "phone": _eContactPhoneController.text.trim(),
        "relation": _eContactRelationController.text.trim(),
      });
      _eContactNameController.clear();
      _eContactPhoneController.clear();
      _eContactRelationController.clear();
    });
  }

  void _submitData() async {
    if (!_isPaymentConfirmed) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Veuillez confirmer l'encaissement du paiement d'abord."), backgroundColor: AppTheme.sosRed),
      );
      return;
    }

    setState(() => _isLoading = true);

    final flatUserData = {
      "cin": _cinController.text.trim(),
      "nom": "${_prenomController.text.trim()} ${_nomController.text.trim()}",
      "email": _emailController.text.trim(),
      "age": _calculatedAge ?? 0,
      "adresse": "${_streetController.text.trim()}, ${_cityController.text.trim()} ${_postalCodeController.text.trim()}",
      "numero_de_telephone": _phoneMalvoyantController.text.trim(),
      "contact_familial": _phoneFamilleController.text.trim(),
      "etat_de_sante": _medicalConditionsController.text.trim(),
      "sim_de_la_canne": _simNumberController.text.trim(),
      "role": "client",
    };

    final success = await UserService.addUser(flatUserData);

    if (success) {
      // update cane status to 'vendue'
      await CaneService.updateCane(_simNumberController.text.trim(), {
        "statut": "vendue",
        "version": _selectedCaneVersion,
        "type": "vente"
      });
    }

    if (mounted) {
      setState(() => _isLoading = false);
      if (success) {
        _showConfirmationDialog();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Erreur lors de l'enregistrement"), backgroundColor: AppTheme.sosRed),
        );
      }
    }
  }

  void _showConfirmationDialog() {
    final saleData = {
      "nom": "${_prenomController.text.trim()} ${_nomController.text.trim()}".trim(),
      "cin": _cinController.text.trim(),
      "email": _emailController.text.trim(),
      "numero_de_telephone": _phoneMalvoyantController.text.trim(),
      "contact_familial": _phoneFamilleController.text.trim(),
      "birth_date": _birthDateController.text.isNotEmpty ? _birthDateController.text : "N/A",
      "adresse": "${_streetController.text.trim()}, ${_cityController.text.trim()} ${_postalCodeController.text.trim()}".trim(),
      "payment_info": {
        "method": _paymentMethod,
        "amount": _amountController.text.trim(),
        "warranty": _warrantyPeriod,
        "subscription_period": _subscriptionPeriod,
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
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent, // Parent provides background
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 40),
              _buildStepper(),
              const SizedBox(height: 40),
              _buildCurrentStepContent(),
            ],
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
              "Vente et configuration des équipements",
              style: TextStyle(color: Colors.grey.withOpacity(0.8), fontSize: 14),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStepper() {
    return Row(
      children: [
        _buildStepIndicator(0, "Catalogue", Icons.shopping_bag_outlined),
        _buildStepLine(0),
        _buildStepIndicator(1, "Détails", Icons.auto_awesome_outlined),
        _buildStepLine(1),
        _buildStepIndicator(2, "Paiement", Icons.shopping_cart_checkout_outlined),
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
      case 0: return _buildCatalog();
      case 1: return _buildProductInsight();
      case 2: return _buildCheckoutForm();
      default: return const SizedBox();
    }
  }

  Widget _buildCatalog() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 3,
      childAspectRatio: 0.8,
      crossAxisSpacing: 30,
      children: [
        _buildProductCard("Smart Lite", "1200", "LÉGER & COMPACT", Icons.bolt, "Compact", Colors.blue),
        _buildProductCard("Smart Pro v2", "1500", "L'ÉQUILIBRE PARFAIT", Icons.location_on, "Populaire", Colors.orange),
        _buildProductCard("Smart Pro v3", "1800", "IA & LiDAR INTÉGRÉS", Icons.graphic_eq, "Élite", Colors.purple),
      ],
    );
  }

  Widget _buildProductCard(String title, String price, String tagline, IconData icon, String badge, Color color) {
    bool isSelected = _selectedCaneVersion == title;
    return InkWell(
      onTap: () {
        setState(() {
          _selectedCaneVersion = title;
          _currentStep = 1;
          _updateTotalPrice();
        });
      },
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: isSelected ? AppTheme.primary : Colors.transparent, width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 30,
              offset: const Offset(0, 15),
            )
          ],
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(badge.toUpperCase(), style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: color.withOpacity(0.05),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 54),
            ),
            const SizedBox(height: 32),
            Text(title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.black87)),
            const SizedBox(height: 8),
            Text(tagline, style: TextStyle(color: Colors.grey.withOpacity(0.7), fontSize: 12, letterSpacing: 1.1)),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(price, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: AppTheme.primary)),
                const Padding(
                  padding: EdgeInsets.only(bottom: 6, left: 4),
                  child: Text("TND", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.primary)),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: isSelected ? AppTheme.primary : AppTheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: Text(
                  "DÉCOUVRIR",
                  style: TextStyle(
                    color: isSelected ? Colors.white : AppTheme.primary,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.1,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductInsight() {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 40, offset: const Offset(0, 20))
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppTheme.normalGreen.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle_rounded, color: AppTheme.normalGreen, size: 16),
                      SizedBox(width: 8),
                      Text("EN STOCK - PRÊT À L'EXPÉDITION", style: TextStyle(color: AppTheme.normalGreen, fontWeight: FontWeight.bold, fontSize: 11)),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  _selectedCaneVersion,
                  style: const TextStyle(fontSize: 48, fontWeight: FontWeight.w900, color: Colors.black87),
                ),
                const SizedBox(height: 20),
                Text(
                  _getDetailedDescription(),
                  style: TextStyle(fontSize: 18, color: Colors.grey.shade600, height: 1.6),
                ),
                const SizedBox(height: 40),
                const Text("TECHNOLOGIES EMBARQUÉES", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 1.2)),
                const SizedBox(height: 20),
                Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: _getSpecifications().map((spec) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.black.withOpacity(0.05)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.verified_user_outlined, color: AppTheme.primary, size: 20),
                        const SizedBox(width: 12),
                        Text(spec, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      ],
                    ),
                  )).toList(),
                ),
              ],
            ),
          ),
          const SizedBox(width: 60),
          Expanded(
            flex: 1,
            child: Container(
              padding: const EdgeInsets.all(40),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(32),
                border: Border.all(color: Colors.black.withOpacity(0.03)),
              ),
              child: Column(
                children: [
                  const Text("TOTAL PRODUIT", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        _canePrice.toString(),
                        style: const TextStyle(fontSize: 56, fontWeight: FontWeight.w900, color: AppTheme.primary),
                      ),
                      const Padding(
                        padding: EdgeInsets.only(bottom: 10, left: 6),
                        child: Text("TND", style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primary, fontSize: 16)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),
                  const Divider(),
                  const SizedBox(height: 40),
                  _buildFeatureLine(Icons.verified, "Garantie 2 ans incluse"),
                  const SizedBox(height: 16),
                  _buildFeatureLine(Icons.headset_mic, "Assistance VIP 24/7"),
                  const SizedBox(height: 16),
                  _buildFeatureLine(Icons.update, "Mises à jour à vie"),
                  const SizedBox(height: 60),
                  SizedBox(
                    width: double.infinity,
                    height: 64,
                    child: ElevatedButton(
                      onPressed: () => setState(() => _currentStep = 2),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        elevation: 8,
                        shadowColor: AppTheme.primary.withOpacity(0.4),
                      ),
                      child: const Text("PROCÉDER À L'ACHAT", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16)),
                    ),
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureLine(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: AppTheme.normalGreen, size: 22),
        const SizedBox(width: 16),
        Text(text, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
      ],
    );
  }

  String _getDetailedDescription() {
    switch (_selectedCaneVersion) {
      case "Smart Lite": return "La Smart Lite est l'outil idéal pour une mobilité urbaine simple. Concentrée sur l'essentiel, elle offre une détection fiable des obstacles tout en restant la plus légère du marché.";
      case "Smart Pro v2": return "Notre modèle le plus équilibré. Elle combine une détection ultrasonique longue portée avec une connexion Bluetooth fluide vers votre smartphone pour une navigation GPS vocale.";
      case "Smart Pro v3": return "Le fleuron technologique. Une véritable extension de vos sens grâce à sa caméra IA qui reconnaît les objets et son capteur LiDAR pour une cartographie 3D de l'espace.";
      default: return "";
    }
  }

  List<String> _getSpecifications() {
    switch (_selectedCaneVersion) {
      case "Smart Lite": return ["Détection ultrason", "Batterie 7 jours", "Poids 180g"];
      case "Smart Pro v2": return ["Alertes Haptiques", "Connectivité BT 5.0", "GPS Vocal"];
      case "Smart Pro v3": return ["Reconnaissance IA", "Mapping LiDAR", "Connectivité 5G"];
      default: return [];
    }
  }

  Widget _buildCheckoutForm() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 2,
                child: Column(
                  children: [
                    _buildSectionCard(
                      title: "I. IDENTITÉ DU BÉNÉFICIAIRE",
                      icon: Icons.person_outline,
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(flex: 2, child: _field("N° CIN", _cinController, Icons.fingerprint)),
                              const SizedBox(width: 16),
                              Expanded(flex: 2, child: _field("Prénom", _prenomController, Icons.person)),
                              const SizedBox(width: 16),
                              Expanded(flex: 3, child: _field("Nom de famille", _nomController, Icons.badge)),
                            ],
                          ),
                          const SizedBox(height: 20),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Expanded(
                                flex: 7,
                                child: GestureDetector(
                                  onTap: () => _selectBirthDate(context),
                                  child: AbsorbPointer(
                                    child: _field("Date de naissance", _birthDateController, Icons.calendar_today),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              _ageBadge(),
                            ],
                          ),
                          const SizedBox(height: 20),
                          _field("Adresse Email", _emailController, Icons.email_outlined),
                          const SizedBox(height: 20),
                          Row(
                            children: [
                              Expanded(child: _field("Tél Malvoyant", _phoneMalvoyantController, Icons.phone_android)),
                              const SizedBox(width: 16),
                              Expanded(child: _field("Tél Famille", _phoneFamilleController, Icons.phone)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    _buildSectionCard(
                      title: "II. ADRESSE DE LIVRAISON",
                      icon: Icons.local_shipping_outlined,
                      child: Column(
                        children: [
                          _field("Numéro et Rue", _streetController, Icons.home),
                          const SizedBox(height: 20),
                          Row(
                            children: [
                              Expanded(child: _field("Ville", _cityController, Icons.location_city)),
                              const SizedBox(width: 16),
                              Expanded(child: _field("Code Postal", _postalCodeController, Icons.map)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 32),
              Expanded(
                flex: 1,
                child: Column(
                  children: [
                    _buildSummaryCard(),
                    const SizedBox(height: 24),
                    _buildConfigurationSummary(),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 40),
          _buildPaymentModule(),
          const SizedBox(height: 48),
          _buildActionButtons(),
          const SizedBox(height: 60),
        ],
      ),
    );
  }

  Widget _buildSummaryCard() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("RÉCAPITULATIF COMMANDE", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: Colors.grey)),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(_selectedCaneVersion, style: const TextStyle(fontWeight: FontWeight.bold)),
              Text("$_canePrice TND"),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Abonnement $_subscriptionPeriod", style: const TextStyle(color: Colors.grey)),
              Text("+$_subscriptionPrice TND", style: const TextStyle(color: Colors.orange)),
            ],
          ),
          const Divider(height: 40),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("TOTAL TTC", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
              Text("$_totalPrice TND", style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 24, color: AppTheme.primary)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildConfigurationSummary() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppTheme.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("CONFIGURATION CANNE", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13)),
          const SizedBox(height: 20),
          _field("Numéro SIM (Identifiant)", _simNumberController, Icons.sim_card),
          if (_selectedCaneVersion == "Smart Pro v3") ...[
            const SizedBox(height: 20),
            _dropdown("Langue Vocale", _voiceLanguage, ["Français", "Anglais", "Arabe"], (v) => setState(() => _voiceLanguage = v!)),
          ],
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return SizedBox(
      width: 400,
      height: 64,
      child: ElevatedButton(
        onPressed: (_isLoading || !_isPaymentConfirmed) ? null : _submitData,
        style: ElevatedButton.styleFrom(
          backgroundColor: _isPaymentConfirmed ? AppTheme.primary : Colors.grey,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          elevation: 6,
        ),
        child: _isLoading 
          ? const CircularProgressIndicator(color: Colors.white)
          : Text(
              _isPaymentConfirmed ? "FINALISER LA COMMANDE" : "PAIEMENT REQUIS", 
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)
            ),
      ),
    );
  }

  Widget _buildSectionCard({required String title, required IconData icon, required Widget child}) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 800),
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppTheme.primary, size: 24),
              const SizedBox(width: 12),
              Text(title, style: const TextStyle(fontWeight: FontWeight.w900, color: AppTheme.sidebarBg, fontSize: 16, letterSpacing: 0.5)),
            ],
          ),
          const SizedBox(height: 24),
          child,
        ],
      ),
    );
  }

  Widget _buildPaymentModule() {
    return Container(
      constraints: const BoxConstraints(maxWidth: 800),
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: _isPaymentConfirmed ? AppTheme.normalGreen.withOpacity(0.05) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _isPaymentConfirmed ? AppTheme.normalGreen : Colors.orange.shade300, width: 2),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(_isPaymentConfirmed ? Icons.verified : Icons.payments_rounded, color: _isPaymentConfirmed ? AppTheme.normalGreen : Colors.orange, size: 32),
              const SizedBox(width: 16),
              const Text("VALIDATION DU PAIEMENT", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
            ],
          ),
          const SizedBox(height: 24),
          if (!_isPaymentConfirmed) ...[
            // Price reminder in payment section
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.primary.withOpacity(0.1)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("$_selectedCaneVersion  +  Abonnement $_subscriptionPeriod", style: const TextStyle(color: Colors.grey, fontSize: 12)),
                      Text("Total : $_totalPrice TND", style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: AppTheme.primary)),
                    ],
                  ),
                  const Icon(Icons.receipt_long, color: AppTheme.primary, size: 28),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      _paymentRadio("Espèces", Icons.money),
                      const SizedBox(width: 12),
                      _paymentRadio("Carte", Icons.credit_card),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton.icon(
                onPressed: () => setState(() => _isPaymentConfirmed = true),
                icon: const Icon(Icons.check_circle_outline),
                label: const Text("CONFIRMER LA RÉCEPTION DE L'ARGENT", style: TextStyle(fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              ),
            ),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: AppTheme.normalGreen.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.check_circle, color: AppTheme.normalGreen),
                  const SizedBox(width: 12),
                  Text("PAIEMENT DE ${_amountController.text} TND REÇU PAR $_paymentMethod", style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.normalGreen)),
                  const Spacer(),
                  TextButton(onPressed: () => setState(() => _isPaymentConfirmed = false), child: const Text("Modifier", style: TextStyle(color: Colors.grey))),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _paymentRadio(String label, IconData icon) {
    bool isSel = _paymentMethod == label;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _paymentMethod = label),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: isSel ? AppTheme.primary : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isSel ? AppTheme.primary : Colors.grey.shade300),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: isSel ? Colors.white : Colors.grey, size: 18),
              const SizedBox(width: 8),
              Text(label, style: TextStyle(color: isSel ? Colors.white : Colors.black87, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field(String label, TextEditingController ctrl, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey)),
        const SizedBox(height: 8),
        TextField(
          controller: ctrl,
          decoration: InputDecoration(
            prefixIcon: Icon(icon, size: 20, color: Colors.grey),
            hintText: label,
            filled: true,
            fillColor: Colors.grey.shade50,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
          ),
        ),
      ],
    );
  }

  Widget _dropdown<T>(String hint, T? value, List<T> items, void Function(T?) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(hint, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey)),
        const SizedBox(height: 8),
        DropdownButtonFormField<T>(
          value: value,
          items: items.map((i) => DropdownMenuItem<T>(value: i, child: Text(i.toString()))).toList(),
          onChanged: onChanged,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.grey.shade50,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
          ),
        ),
      ],
    );
  }

  Widget _ageBadge() {
    return Container(
      width: 100,
      height: 56,
      decoration: BoxDecoration(color: AppTheme.primary.withOpacity(0.05), borderRadius: BorderRadius.circular(12), border: Border.all(color: AppTheme.primary.withOpacity(0.1))),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text("ÂGE", style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.grey)),
          Text(_calculatedAge != null ? "$_calculatedAge ans" : "--", style: const TextStyle(fontWeight: FontWeight.w900, color: AppTheme.primary, fontSize: 18)),
        ],
      ),
    );
  }
}
