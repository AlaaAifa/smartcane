import 'package:flutter/material.dart';
import '../../core/api_service.dart';
import '../../core/theme.dart';
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

  // --- Identity & Contact ---
  final _nomController = TextEditingController();
  final _prenomController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneMalvoyantController = TextEditingController();
  final _phoneFamilleController = TextEditingController();
  int? _birthDay;
  int? _birthMonth;
  int? _birthYear;
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

  final List<int> _days = List.generate(31, (index) => index + 1);
  final List<int> _months = List.generate(12, (index) => index + 1);
  final List<int> _years = List.generate(100, (index) => DateTime.now().year - index);

  void _updateAge() {
    if (_birthDay == null || _birthMonth == null || _birthYear == null) return;
    final now = DateTime.now();
    int age = now.year - _birthYear!;
    if (now.month < _birthMonth! || (now.month == _birthMonth! && now.day < _birthDay!)) age--;
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

    final fullUserData = {
      "nom": _nomController.text.trim(),
      "prenom": _prenomController.text.trim(),
      "email": _emailController.text.trim(),
      "phone_number_malvoyant": _phoneMalvoyantController.text.trim(),
      "phone_number_famille": _phoneFamilleController.text.trim(),
      "birth_date": (_birthDay != null && _birthMonth != null && _birthYear != null) ? "$_birthDay/$_birthMonth/$_birthYear" : "N/A",
      "age": _calculatedAge?.toString() ?? "0",
      "address": {
        "city": _cityController.text.trim(),
        "street": _streetController.text.trim(),
        "postal_code": _postalCodeController.text.trim(),
      },
      "payment_info": {
        "method": _paymentMethod,
        "amount": _amountController.text.trim(),
        "warranty": _warrantyPeriod,
        "subscription_period": _subscriptionPeriod,
        "subscription_price": _subscriptionPrice.toString(),
        "cane_price": _canePrice.toString(),
        "date": DateTime.now().toString(),
        "confirmed": _isPaymentConfirmed,
      },
      "medical_info": {
        "blood_group": _bloodGroup,
        "condition": _medicalConditionsController.text.trim(),
        "emergency_contacts": _emergencyContacts,
      },
      "cane_details": {
        "model": _selectedCaneVersion,
        "sim_number": _simNumberController.text.trim(),
        "firmware_version": "1.0.0",
        "settings": {"language": _voiceLanguage, "speed": _voiceSpeed}
      },
      "status": "normal",
      "is_online": true,
    };

    final success = await ApiService.addUser(fullUserData);

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
    // Build a full sale data snapshot to pass to the contract
    final saleData = {
      "nom": _nomController.text.trim(),
      "prenom": _prenomController.text.trim(),
      "email": _emailController.text.trim(),
      "phone_number_malvoyant": _phoneMalvoyantController.text.trim(),
      "phone_number_famille": _phoneFamilleController.text.trim(),
      "birth_date": (_birthDay != null && _birthMonth != null && _birthYear != null)
          ? "$_birthDay/$_birthMonth/$_birthYear"
          : "N/A",
      "address": {
        "city": _cityController.text.trim(),
        "street": _streetController.text.trim(),
        "postal_code": _postalCodeController.text.trim(),
      },
      "payment_info": {
        "method": _paymentMethod,
        "amount": _amountController.text.trim(),
        "warranty": _warrantyPeriod,
        "subscription_period": _subscriptionPeriod,
        "subscription_price": _subscriptionPrice.toString(),
        "cane_price": _canePrice.toString(),
      },
      "cane_details": {
        "model": _selectedCaneVersion,
        "sim_number": _simNumberController.text.trim(),
      },
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
      backgroundColor: AppTheme.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Form(
          key: _formKey,
          child: Center(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // --- TOP VERSION SELECTOR ---
                Container(
                  constraints: const BoxConstraints(maxWidth: 800),
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: _canePrices.keys.map((version) {
                      bool isSelected = _selectedCaneVersion == version;
                      return Expanded(
                        child: InkWell(
                          onTap: () {
                            setState(() {
                              _selectedCaneVersion = version;
                              _updateTotalPrice();
                            });
                          },
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            padding: const EdgeInsets.symmetric(vertical: 20),
                            decoration: BoxDecoration(
                              color: isSelected ? AppTheme.primary : Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: isSelected 
                                ? [BoxShadow(color: AppTheme.primary.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 5))]
                                : [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 5)],
                              border: Border.all(color: isSelected ? AppTheme.primary : Colors.grey.shade200),
                            ),
                            child: Column(
                              children: [
                                Icon(
                                  version == "Smart Lite" ? Icons.bolt : (version == "Smart Pro v2" ? Icons.location_on : Icons.graphic_eq),
                                  color: isSelected ? Colors.white : Colors.grey,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  version,
                                  style: TextStyle(color: isSelected ? Colors.white : Colors.black87, fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 16),
              _buildSectionCard(
                title: "I. IDENTITÉ DU CLIENT",
                icon: Icons.person_outline,
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(child: _field("Prénom", _prenomController, Icons.person)),
                        const SizedBox(width: 16),
                        Expanded(child: _field("Nom", _nomController, Icons.badge)),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(flex: 3, child: _dropdown("Jour", _birthDay, _days, (v) { setState(() => _birthDay = v); _updateAge(); })),
                        const SizedBox(width: 8),
                        Expanded(flex: 3, child: _dropdown("Mois", _birthMonth, _months, (v) { setState(() => _birthMonth = v); _updateAge(); })),
                        const SizedBox(width: 8),
                        Expanded(flex: 4, child: _dropdown("Année", _birthYear, _years, (v) { setState(() => _birthYear = v); _updateAge(); })),
                        const SizedBox(width: 16),
                        _ageBadge(),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _field("Email", _emailController, Icons.email_outlined),
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
                title: "II. ADRESSE & FACTURATION",
                icon: Icons.location_on_outlined,
                child: Column(
                  children: [
                    _field("Rue / Quartier", _streetController, Icons.home),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(child: _field("Ville", _cityController, Icons.location_city)),
                        const SizedBox(width: 16),
                        Expanded(child: _field("Code Postal", _postalCodeController, Icons.map)),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _dropdown("Période de Garantie", _warrantyPeriod, ["1 An", "2 Ans", "3 Ans", "Garantie Étendue"], (v) => setState(() => _warrantyPeriod = v!)),
                    const SizedBox(height: 28),
                    const Divider(),
                    const SizedBox(height: 20),
                    const Text("Période d'Abonnement", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey)),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _subscriptionPrices.entries.map((entry) {
                        bool isSel = _subscriptionPeriod == entry.key;
                        return InkWell(
                          onTap: () => setState(() { _subscriptionPeriod = entry.key; _updateTotalPrice(); }),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            decoration: BoxDecoration(
                              color: isSel ? AppTheme.primary : Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: isSel ? AppTheme.primary : Colors.grey.shade300),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text(entry.key, style: TextStyle(color: isSel ? Colors.white : Colors.black87, fontWeight: FontWeight.bold, fontSize: 13)),
                                if (entry.value > 0)
                                  Text("+${entry.value} TND", style: TextStyle(color: isSel ? Colors.white70 : Colors.grey, fontSize: 11)),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withOpacity(0.03),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppTheme.primary.withOpacity(0.1)),
                      ),
                      child: Column(
                        children: [
                          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                            Text("Canne $_selectedCaneVersion", style: const TextStyle(color: Colors.grey, fontSize: 13)),
                            Text("$_canePrice TND", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          ]),
                          if (_subscriptionPrice > 0) ...[
                            const SizedBox(height: 8),
                            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                              Text("Abonnement $_subscriptionPeriod", style: const TextStyle(color: Colors.grey, fontSize: 13)),
                              Text("+$_subscriptionPrice TND", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.orange)),
                            ]),
                          ],
                          const Divider(height: 20),
                          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                            const Text("TOTAL À PAYER", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
                            Text("$_totalPrice TND", style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 22, color: AppTheme.primary)),
                          ]),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              if (_selectedCaneVersion != "Smart Lite")
                _buildSectionCard(
                  title: "III. SANTÉ & SÉCURITÉ",
                  icon: Icons.medical_services_outlined,
                  child: Column(
                    children: [
                      _dropdown("Groupe Sanguin", _bloodGroup, ["Inconnu", "A+", "A-", "B+", "B-", "AB+", "AB-", "O+", "O-"], (v) => setState(() => _bloodGroup = v!)),
                      const SizedBox(height: 20),
                      _field("Notes médicales (Conditions)", _medicalConditionsController, Icons.description_outlined),
                      const SizedBox(height: 20),
                      const Divider(),
                      const SizedBox(height: 20),
                      const Text("Contacts d'Urgence", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(child: _field("Nom", _eContactNameController, Icons.person)),
                          const SizedBox(width: 8),
                          Expanded(child: _field("Tél", _eContactPhoneController, Icons.phone)),
                          const SizedBox(width: 8),
                          Expanded(child: _field("Lien", _eContactRelationController, Icons.favorite)),
                          IconButton(onPressed: _addEmergencyContact, icon: const Icon(Icons.add_circle, color: AppTheme.primary)),
                        ],
                      ),
                      ..._emergencyContacts.map((c) => ListTile(
                        title: Text("${c['name']} (${c['relation']})"),
                        subtitle: Text(c['phone']!),
                        trailing: IconButton(icon: const Icon(Icons.delete, size: 18), onPressed: () => setState(() => _emergencyContacts.remove(c))),
                      )).toList(),
                    ],
                  ),
                ),
              if (_selectedCaneVersion == "Smart Lite")
                 _buildSectionCard(
                  title: "III. SANTÉ (BASIQUE)",
                  icon: Icons.medical_services_outlined,
                  child: Column(
                    children: [
                      _dropdown("Groupe Sanguin", _bloodGroup, ["Inconnu", "A+", "A-", "B+", "B-", "AB+", "AB-", "O+", "O-"], (v) => setState(() => _bloodGroup = v!)),
                      const SizedBox(height: 20),
                      _field("Notes médicales / Allergies", _medicalConditionsController, Icons.description_outlined),
                    ],
                  ),
                ),
              const SizedBox(height: 24),
              _buildSectionCard(
                title: "IV. CONFIGURATION CANNE",
                icon: Icons.settings_outlined,
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(child: _field("Numéro SIM (4G) — Identifiant Canne", _simNumberController, Icons.sim_card_outlined)),
                      ],
                    ),
                    if (_selectedCaneVersion == "Smart Pro v3") ...[
                      const SizedBox(height: 20),
                      _dropdown("Langue Vocale", _voiceLanguage, ["Français", "Anglais", "Arabe", "Espagnol"], (v) => setState(() => _voiceLanguage = v!)),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          const Text("Vitesse:", style: TextStyle(color: Colors.grey, fontSize: 12)),
                          Expanded(child: Slider(value: _voiceSpeed, min: 0.5, max: 2.0, divisions: 6, activeColor: AppTheme.primary, onChanged: (v) => setState(() => _voiceSpeed = v))),
                          Text("${_voiceSpeed}x", style: const TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 32),
              
              // --- Interactive Payment Section ---
              _buildPaymentModule(),
              
              const SizedBox(height: 48),
              SizedBox(
                width: 400,
                height: 60,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitData,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isPaymentConfirmed ? AppTheme.primary : Colors.grey,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: _isLoading 
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(_isPaymentConfirmed ? "FINALISER L'ENREGISTREMENT" : "EN ATTENTE DE PAIEMENT", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
              const SizedBox(height: 60),
            ],
          ),
        ),
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
