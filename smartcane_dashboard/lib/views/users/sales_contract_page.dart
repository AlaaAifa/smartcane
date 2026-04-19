import 'package:flutter/material.dart';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import '../theme.dart';

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
              style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: AppTheme.primary),
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("SMART CANE", style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: AppTheme.sidebarBg)),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text("CONTRAT DE VENTE", style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppTheme.primary)),
                        const SizedBox(height: 8),
                        _labelValue("N Contrat", contractNum),
                        _labelValue("Date", dateStr),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                const Divider(thickness: 2, color: AppTheme.primary),
                const SizedBox(height: 24),
                _sectionTitle("Client"),
                const SizedBox(height: 12),
                _infoBlock([
                  _contractRow("Nom", saleData["nom"]?.toString() ?? "N/A"),
                  _contractRow("CIN", saleData["cin"]?.toString() ?? "N/A"),
                  _contractRow("Email", saleData["email"]?.toString() ?? "N/A"),
                  _contractRow("Telephone", saleData["numero_de_telephone"]?.toString() ?? "N/A"),
                  _contractRow("Contact familial", saleData["contact_familial"]?.toString() ?? "N/A"),
                  _contractRow("Adresse", saleData["adresse"]?.toString() ?? "N/A"),
                ]),
                const SizedBox(height: 24),
                _sectionTitle("Produit"),
                const SizedBox(height: 12),
                _infoBlock([
                  _contractRow("Modele", saleData["version_canne"]?.toString() ?? "Smart Cane"),
                  _contractRow("SIM canne", saleData["sim_de_la_canne"]?.toString() ?? "N/A"),
                  _contractRow("Prix canne", "${saleData['payment_info']?['cane_price'] ?? 'N/A'} TND"),
                  _contractRow("Abonnement", saleData['payment_info']?['subscription_period']?.toString() ?? "Sans abonnement"),
                  _contractRow("Prix abonnement", "${saleData['payment_info']?['subscription_price'] ?? '0'} TND"),
                  _contractRow("Total", "${saleData['payment_info']?['amount'] ?? 'N/A'} TND"),
                ]),
                const SizedBox(height: 24),
                _sectionTitle("Paiement"),
                const SizedBox(height: 12),
                _infoBlock([
                  _contractRow("Mode de paiement", saleData['payment_info']?['method']?.toString() ?? "N/A"),
                  _contractRow("Garantie", saleData['payment_info']?['warranty']?.toString() ?? "N/A"),
                ]),
                const SizedBox(height: 40),
                const Text(
                  "Le client reconnait avoir recu le produit en bon etat. La garantie couvre uniquement les defauts de fabrication.",
                  style: TextStyle(fontSize: 12, height: 1.6, color: Colors.black87),
                ),
                const SizedBox(height: 48),
                Row(
                  children: const [
                    Expanded(child: _SignatureBlock(title: "Le Client")),
                    SizedBox(width: 40),
                    Expanded(child: _SignatureBlock(title: "Representant Smart Cane")),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(title.toUpperCase(), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: AppTheme.sidebarBg));
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
          SizedBox(width: 160, child: Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 12))),
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
}

class _SignatureBlock extends StatelessWidget {
  final String title;
  const _SignatureBlock({required this.title});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        const SizedBox(height: 60),
        Container(width: 220, height: 1, color: Colors.black),
      ],
    );
  }
}
