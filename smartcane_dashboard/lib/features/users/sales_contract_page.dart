import 'package:flutter/material.dart';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import '../../core/theme.dart';

class SalesContractPage extends StatelessWidget {
  final Map<String, dynamic> saleData;

  const SalesContractPage({super.key, required this.saleData});

  void _printContract() {
    html.window.print();
  }

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final dateStr = "${today.day.toString().padLeft(2, '0')}/${today.month.toString().padLeft(2, '0')}/${today.year}";
    final contractNum = "SC-${today.year}-${today.millisecondsSinceEpoch.toString().substring(7)}";

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: AppTheme.sidebarBg,
        title: const Text("Contrat de Vente", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
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
                                child: const Icon(Icons.sensor_occupied_rounded, color: Colors.white, size: 30),
                              ),
                              const SizedBox(width: 16),
                              const Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text("SMART CANE", style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: AppTheme.sidebarBg)),
                                  Text("Technologies d'Assistance Avancée", style: TextStyle(color: Colors.grey, fontSize: 11)),
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
                        const Text("CONTRAT DE VENTE", style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppTheme.primary, letterSpacing: 1.2)),
                        const SizedBox(height: 8),
                        _labelValue("N° Contrat", contractNum),
                        _labelValue("Date", dateStr),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 40),
                const Divider(thickness: 2, color: AppTheme.primary),
                const SizedBox(height: 30),

                // --- CLIENT INFO ---
                _sectionTitle("1. INFORMATIONS DU CLIENT"),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _infoBlock([
                        _contractRow("Nom & Prénom", "${saleData['prenom'] ?? ''} ${saleData['nom'] ?? ''}"),
                        _contractRow("Date de Naissance", saleData['birth_date'] ?? 'N/A'),
                        _contractRow("Téléphone", saleData['phone_number_malvoyant'] ?? 'N/A'),
                        _contractRow("Email", saleData['email'] ?? 'N/A'),
                      ]),
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                      child: _infoBlock([
                        _contractRow("Adresse", _formatAddress(saleData['address'])),
                        _contractRow("Tél. Famille / Urgence", saleData['phone_number_famille'] ?? 'N/A'),
                      ]),
                    ),
                  ],
                ),
                const SizedBox(height: 30),

                // --- PRODUCT INFO ---
                _sectionTitle("2. DÉSIGNATION DU PRODUIT"),
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
                            Text(saleData['cane_details']?['model'] ?? 'Smart Cane', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: AppTheme.sidebarBg)),
                            const SizedBox(height: 6),
                            Text("Canne Intelligente d'Assistance pour Malvoyants", style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                            const SizedBox(height: 12),
                            Text("N° SIM (4G): ${saleData['cane_details']?['sim_number'] ?? 'N/A'}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
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
                            const Text("Prix Canne", style: TextStyle(color: Colors.grey, fontSize: 11)),
                            Text("${saleData['payment_info']?['cane_price'] ?? saleData['payment_info']?['amount'] ?? 'N/A'} TND", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.sidebarBg)),
                            if (saleData['payment_info']?['subscription_period'] != null && saleData['payment_info']?['subscription_period'] != 'Sans Abonnement') ...[
                              const SizedBox(height: 4),
                              Text("Abonnement ${saleData['payment_info']?['subscription_period']}", style: const TextStyle(color: Colors.grey, fontSize: 11)),
                              Text("+${saleData['payment_info']?['subscription_price'] ?? '0'} TND", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.orange)),
                            ],
                            const Divider(height: 12),
                            const Text("TOTAL", style: TextStyle(color: Colors.grey, fontSize: 11)),
                            Text("${saleData['payment_info']?['amount'] ?? 'N/A'} TND", style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 22, color: AppTheme.primary)),
                            const SizedBox(height: 4),
                            Text("Garanti ${saleData['payment_info']?['warranty'] ?? 'N/A'}", style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),

                // --- PAYMENT INFO ---
                _sectionTitle("3. CONDITIONS DE RÈGLEMENT"),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(child: _infoBlock([
                      _contractRow("Mode de Paiement", saleData['payment_info']?['method'] ?? 'N/A'),
                      _contractRow("Montant Réglé", "${saleData['payment_info']?['amount'] ?? 'N/A'} TND"),
                      _contractRow("Garantie", saleData['payment_info']?['warranty'] ?? 'N/A'),
                    ])),
                    const SizedBox(width: 24),
                    Expanded(child: _infoBlock([
                      _contractRow("Date de Vente", dateStr),
                      _contractRow("Personnel Responsable", "____________________"),
                    ])),
                  ],
                ),
                const SizedBox(height: 30),

                // --- TERMS ---
                _sectionTitle("4. CLAUSES ET CONDITIONS"),
                const SizedBox(height: 12),
                _clauseText("• Le client reconnaît avoir reçu le produit en bon état de fonctionnement et conforme à la description."),
                _clauseText("• La garantie couvre les défauts de fabrication. Les dommages causés par une mauvaise utilisation ou un accident physique sont exclus."),
                _clauseText("• Toute modification par un tiers non agréé par Smart Cane annule automatiquement la garantie."),
                _clauseText("• Le numéro SIM 4G intégré est la propriété de Smart Cane. Sa désactivation ou modification non autorisée constitue une violation du présent contrat."),
                _clauseText("• En cas de panne, le client s'engage à contacter le service technique avant toute intervention."),
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
                          const Text("Le Client", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          const SizedBox(height: 6),
                          Text("${saleData['prenom'] ?? ''} ${saleData['nom'] ?? ''}", style: const TextStyle(color: Colors.grey, fontSize: 12)),
                          const SizedBox(height: 60),
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
                          const Text("Service Commercial", style: TextStyle(color: Colors.grey, fontSize: 12)),
                          const SizedBox(height: 60),
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
                    "Merci de votre confiance — Smart Cane | contact@smartcane.tn | +216 70 000 000",
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
        Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: AppTheme.sidebarBg, letterSpacing: 0.8)),
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
