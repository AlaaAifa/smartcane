import 'package:flutter/material.dart';


// ignore: avoid_web_libraries_in_flutter


import 'dart:html' as html;
import '../theme.dart';
import '../layout/sirius_logo.dart';





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


        leading: IconButton(


          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),


          onPressed: () => Navigator.of(context).pop(),


        ),


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


                // --- HEADER ---
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SiriusLogo(size: 80),
                    const SizedBox(width: 32),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "SIRIUS",
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.w900,
                              color: AppTheme.sidebarBg,
                              letterSpacing: 2,
                            ),
                          ),
                          Text(
                            "L'ÉTOILE QUI NE VOUS QUITTE JAMAIS",
                            style: TextStyle(
                              color: const Color(0xFFf5a623).withOpacity(0.8),
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.5,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            "ZI Charguia II, Tunis, Tunisie | contact@smartcane.tn | +216 70 000 000",
                            style: TextStyle(color: Colors.grey, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.sidebarBg.withOpacity(0.03),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.sidebarBg.withOpacity(0.05)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text(
                            "CONTRAT DE VENTE",
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: AppTheme.sidebarBg, letterSpacing: 0.5),
                          ),
                          const SizedBox(height: 8),
                          _labelValue("N°", contractNum),
                          _labelValue("Date", dateStr),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 40),
                const Divider(thickness: 1.5, color: Color(0xFFf5a623)),
                const SizedBox(height: 30),


                _sectionTitle("Bénéficiaire"),


                const SizedBox(height: 12),


                _infoBlock([


                  _contractRow("Nom Complet", saleData["nom"]?.toString() ?? "Non renseigné"),


                  _contractRow("CIN", saleData["cin"]?.toString() ?? "Non renseigné"),


                  _contractRow("Date de Naissance", saleData["birth_date"]?.toString() ?? "Non renseigné"),


                  _contractRow("Email", saleData["email"]?.toString() ?? "Non renseigné"),


                  _contractRow("Téléphone", saleData["numero_de_telephone"]?.toString() ?? "Non renseigné"),


                  _contractRow("Adresse", _formatAddress(saleData['address'])),


                ]),


                const SizedBox(height: 24),


                _sectionTitle("Urgence"),


                const SizedBox(height: 12),


                _infoBlock([


                  _contractRow("Contact d'urgence", saleData["emergency_name"]?.toString() ?? "Non renseigné"),


                  _contractRow("Relation", saleData["emergency_relation"]?.toString() ?? "Non renseigné"),


                  _contractRow("Téléphone Urgence", saleData["emergency_phone"]?.toString() ?? "Non renseigné"),


                ]),


                const SizedBox(height: 24),


                _sectionTitle("Détails Acquisition"),


                const SizedBox(height: 12),


                _infoBlock([


                  _contractRow("Modèle Canne", saleData["version_canne"]?.toString() ?? "SIRIUS"),


                  _contractRow("Numéro SIM", saleData["sim_de_la_canne"]?.toString() ?? "Non renseigné"),


                  _contractRow("Prix Équipement", "${saleData['payment_info']?['cane_price'] ?? 'Non renseigné'} TND"),


                  _contractRow("Durée Abonnement", "${saleData['payment_info']?['subscription_duration_months'] ?? '0'} mois"),


                  _contractRow("Période", "Du ${saleData['payment_info']?['subscription_start']} au ${saleData['payment_info']?['subscription_end']}"),


                  _contractRow("Prix Abonnement", "${saleData['payment_info']?['subscription_price'] ?? '0'} TND"),


                  _contractRow("TOTAL TTC", "${saleData['payment_info']?['total_amount'] ?? 'Non renseigné'} TND"),


                ]),


                const SizedBox(height: 24),


                _sectionTitle("Paiement & Garantie"),


                const SizedBox(height: 12),


                _infoBlock([


                  _contractRow("Mode de règlement", saleData['payment_info']?['method']?.toString() ?? "Non renseigné"),


                  _contractRow("Garantie Matériel", "2 ans (Pièces et main d'œuvre)"),


                ]),


                const SizedBox(height: 40),


                const Text(


                  "Le client reconnaît avoir reçu le produit en bon état. La garantie couvre uniquement les défauts de fabrication.",


                  style: TextStyle(fontSize: 12, height: 1.6, color: Colors.black87),


                ),


                const SizedBox(height: 48),


                Row(


                  children: [


                    const Expanded(child: _SignatureBlock(title: "Le Client")),


                    const SizedBox(width: 40),


                    const Expanded(child: _SignatureBlock(title: "Représentant SIRIUS")),


                  ],


                ),


              ],


            ),


          ),


        ),


      ),


    );


  }





  String _formatAddress(dynamic address) {


    if (address == null) return 'Non renseignée';


    if (address is Map) {


      final street = address['street']?.toString() ?? '';


      final city = address['city']?.toString() ?? '';


      final postal = address['postal_code']?.toString() ?? '';


      final country = address['country']?.toString() ?? '';


      return [street, city, postal, country].where((e) => e.isNotEmpty).join(', ');


    }


    return address.toString();


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


