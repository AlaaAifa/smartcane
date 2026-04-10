import 'package:flutter/material.dart';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import '../../core/theme.dart';

class RentalContractPage extends StatelessWidget {
  final Map<String, dynamic> rentalData;

  const RentalContractPage({super.key, required this.rentalData});

  void _printContract() {
    html.window.print();
  }

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final dateStr = "${today.day.toString().padLeft(2, '0')}/${today.month.toString().padLeft(2, '0')}/${today.year}";
    final contractNum = "LOC-${today.year}-${today.millisecondsSinceEpoch.toString().substring(7)}";

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: AppTheme.sidebarBg,
        title: const Text("Contrat de Location", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: ElevatedButton.icon(
              onPressed: _printContract,
              icon: const Icon(Icons.print_rounded, size: 18),
              label: const Text("Imprimer / Exporter PDF"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppTheme.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
        child: Center(
          child: Container(
            width: 800,
            padding: const EdgeInsets.all(60),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 30, offset: const Offset(0, 10))],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- HEADER ---
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(color: AppTheme.primary, borderRadius: BorderRadius.circular(10)),
                                child: const Icon(Icons.calendar_month, color: Colors.white, size: 30),
                              ),
                              const SizedBox(width: 16),
                              const Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text("SMART CANE", style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: AppTheme.sidebarBg)),
                                  Text("Service de Location d'Équipement", style: TextStyle(color: Colors.grey, fontSize: 11)),
                                ],
                              )
                            ],
                          ),
                          const SizedBox(height: 16),
                          const Text("ZI Charguia II, Tunis, Tunisie", style: TextStyle(color: Colors.grey, fontSize: 12)),
                          const Text("contact@smartcane.tn | +216 70 000 000", style: TextStyle(color: Colors.grey, fontSize: 12)),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text("CONTRAT DE LOCATION", style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppTheme.primary, letterSpacing: 1.2)),
                        const SizedBox(height: 8),
                        _labelValue("N° Contrat", contractNum),
                        _labelValue("Date de création", dateStr),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 40),
                const Divider(thickness: 2, color: AppTheme.primary),
                const SizedBox(height: 30),

                // --- CLIENT INFO ---
                _sectionTitle("1. INFORMATIONS DU LOCATAIRE"),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _infoBlock([
                        _contractRow("Nom & Prénom", rentalData['full_name'] ?? 'N/A'),
                        _contractRow("CIN", rentalData['cin'] ?? 'N/A'),
                        _contractRow("Téléphone", rentalData['phone'] ?? 'N/A'),
                        _contractRow("Date de Naissance", rentalData['birth_date'] ?? 'N/A'),
                      ]),
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                      child: _infoBlock([
                        _contractRow("Adresse", _formatAddress(rentalData['address'])),
                        _contractRow("Contact d'Urgence", "${rentalData['emergency_name']} (${rentalData['emergency_relation']})"),
                        _contractRow("Tél. Urgence", rentalData['emergency_phone'] ?? 'N/A'),
                      ]),
                    ),
                  ],
                ),
                const SizedBox(height: 30),

                // --- PRODUCT INFO ---
                _sectionTitle("2. OBJET DE LA LOCATION"),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("${rentalData['model'] ?? 'Smart Cane'} (Location)", style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: AppTheme.sidebarBg)),
                            const SizedBox(height: 6),
                            Text("Canne Intelligente d'Assistance pour Malvoyants", style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                            const SizedBox(height: 12),
                            Text("N° SIM (4G) Loué : ${rentalData['sim_number'] ?? 'N/A'}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.primary)),
                          ],
                        ),
                      ),
                      const SizedBox(width: 20),
                      Container(
                        height: 60,
                        width: 1,
                        color: Colors.grey.shade300,
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Text("Période de Location", style: TextStyle(color: Colors.grey, fontSize: 11)),
                            Text("${rentalData['duration_months']} Mois", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.sidebarBg)),
                            const SizedBox(height: 4),
                            Text("Du ${rentalData['start_date']} au ${rentalData['end_date']}", style: const TextStyle(color: Colors.grey, fontSize: 11)),
                            const Divider(height: 16),
                            const Text("TOTAL PAYÉ A LA REMISE", style: TextStyle(color: Colors.grey, fontSize: 11)),
                            Text("${rentalData['total_price'] ?? 'N/A'} TND", style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 20, color: AppTheme.primary)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),

                // --- PAYMENT INFO ---
                _sectionTitle("3. RÈGLEMENT ET MODALITÉS"),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(child: _infoBlock([
                      _contractRow("Montant Réglé", "${rentalData['total_price'] ?? 'N/A'} TND"),
                      _contractRow("Mode de Paiement", rentalData['payment_method'] ?? 'N/A'),
                      _contractRow("Caution (Matériel)", "Garantie par contrat"),
                    ])),
                    const SizedBox(width: 24),
                    Expanded(child: _infoBlock([
                      _contractRow("Date de Début", rentalData['start_date'] ?? 'N/A'),
                      _contractRow("Date de Fin", rentalData['end_date'] ?? 'N/A'),
                      _contractRow("Personnel", "____________________"),
                    ])),
                  ],
                ),
                const SizedBox(height: 30),

                // --- TERMS ---
                _sectionTitle("4. CONDITIONS GÉNÉRALES DE LOCATION"),
                const SizedBox(height: 12),
                _clauseText("• Le matériel loué reste la propriété insaisissable de Smart Cane. Le locataire s'interdit de le sous-louer ou de le prêter."),
                _clauseText("• Le locataire reconnaît avoir reçu l'équipement en parfait état de marche. Toute panne ou détérioration doit être signalée immédiatement."),
                _clauseText("• En cas de perte, vol ou destruction totale/partielle du produit, le locataire sera facturé de la contre-valeur du matériel conformément à la valeur à neuf de la canne : [Smart Lite : 1200 TND], [Smart Pro V2 : 1500 TND], [Smart Pro V3 : 1800 TND]."),
                _clauseText("• Le locataire s'engage à restituer le matériel loué dans son état d'origine à la date d'échéance du présent contrat."),
                _clauseText("• En cas de retard de restitution non justifié, une facturation de pénalités pourra être appliquée."),
                const SizedBox(height: 50),

                // --- SIGNATURES ---
                _sectionTitle("5. SIGNATURES"),
                const SizedBox(height: 24),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const Text("Le Locataire (Ou Tuteur Légal)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          const SizedBox(height: 6),
                          Text("${rentalData['full_name'] ?? 'N/A'}", style: const TextStyle(color: Colors.grey, fontSize: 12)),
                          const SizedBox(height: 12),
                          const Text("Lu et approuvé", style: TextStyle(color: Colors.grey, fontSize: 10, fontStyle: FontStyle.italic)),
                          const SizedBox(height: 48),
                          const _SignatureLine(),
                          const SizedBox(height: 6),
                          const Text("Signature & Cachet", style: TextStyle(color: Colors.grey, fontSize: 11)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 40),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const Text("Représentant Smart Cane", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          const SizedBox(height: 6),
                          const Text("Service de Location", style: TextStyle(color: Colors.grey, fontSize: 12)),
                          const SizedBox(height: 12),
                          const Text("Matériel remis en bon état", style: TextStyle(color: Colors.grey, fontSize: 10, fontStyle: FontStyle.italic)),
                          const SizedBox(height: 48),
                          const _SignatureLine(),
                          const SizedBox(height: 6),
                          const Text("Signature & Cachet Officiel", style: TextStyle(color: Colors.grey, fontSize: 11)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 40),
                const Divider(),
                const SizedBox(height: 12),
                const Center(
                  child: Text(
                    "Contrat de Location — Smart Cane | contact@smartcane.tn | +216 70 000 000",
                    style: TextStyle(color: Colors.grey, fontSize: 10),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Row(
      children: [
        Container(width: 4, height: 18, decoration: BoxDecoration(color: AppTheme.primary, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 10),
        Text(title, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: AppTheme.sidebarBg, letterSpacing: 0.8)),
      ],
    );
  }

  Widget _infoBlock(List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
    );
  }

  Widget _contractRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 140, child: Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 12))),
          Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
        ],
      ),
    );
  }

  Widget _labelValue(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text("$label : ", style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _clauseText(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(text, style: TextStyle(fontSize: 11, color: Colors.grey.shade700, height: 1.6)),
    );
  }

  String _formatAddress(dynamic address) {
    if (address == null) return 'Non renseignée';
    if (address is Map) {
      final street = address['street'] ?? '';
      final city = address['city'] ?? '';
      final postal = address['postal_code'] ?? '';
      return [street, city, postal].where((e) => e.isNotEmpty).join(', ');
    }
    return address.toString();
  }
}

class _SignatureLine extends StatelessWidget {
  const _SignatureLine();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200,
      height: 1,
      color: Colors.black,
    );
  }
}
