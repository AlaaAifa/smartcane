import 'package:flutter/material.dart';

import 'dart:convert';

import 'dart:async';

import 'package:url_launcher/url_launcher.dart';

import 'package:flutter_map/flutter_map.dart';

import 'package:latlong2/latlong.dart';

import '../theme.dart';

import '../../services/services.dart';



class AlertsPage extends StatefulWidget {

  final Function(String)? onNavigate;

  const AlertsPage({super.key, this.onNavigate});



  @override

  State<AlertsPage> createState() => _AlertsPageState();

}



class _AlertsPageState extends State<AlertsPage> {

  Map<String, Map<String, dynamic>> usersDict = {};

  bool _isLoading = true;



  // Filter states

  final TextEditingController _searchController = TextEditingController();

  String _searchUser = "";

  String _selectedType = "Tous";

  DateTime? _startDate;

  DateTime? _endDate;



  @override

  void initState() {

    super.initState();

    _loadData();

    _searchController.addListener(() {

      setState(() {

        _searchUser = _searchController.text;

      });

    });

  }



  @override

  void dispose() {

    _searchController.dispose();

    super.dispose();

  }



  Future<void> _loadData() async {

    final usersData = await UserService.getUsers();

    final tempDict = <String, Map<String, dynamic>>{};

    for (final user in usersData) {

      final cin = user["cin"]?.toString();

      if (cin != null) tempDict[cin] = user;

    }

    if (!mounted) return;

    setState(() {

      usersDict = tempDict;

      _isLoading = false;

    });

  }



  String _userName(String? cin) => usersDict[cin]?["nom"]?.toString() ?? cin ?? "Inconnu";



  void _resetFilters() {

    setState(() {

      _searchController.clear();

      _searchUser = "";

      _selectedType = "Tous";

      _startDate = null;

      _endDate = null;

    });

  }



  Future<void> _selectDateRange() async {

    final DateTimeRange? picked = await showDateRangePicker(

      context: context,

      firstDate: DateTime(2020),

      lastDate: DateTime.now().add(const Duration(days: 365)),

      initialDateRange: (_startDate != null && _endDate != null)

          ? DateTimeRange(start: _startDate!, end: _endDate!)

          : null,

      builder: (context, child) {

        return Theme(

          data: Theme.of(context).copyWith(

            colorScheme: const ColorScheme.light(

              primary: AppTheme.primary,

              onPrimary: Colors.white,

              surface: Colors.white,

              onSurface: AppTheme.primary,

            ),

            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(foregroundColor: AppTheme.primary),
            ),

          ),

          child: child!,

        );

      },

    );

    if (picked != null) {

      setState(() {

        _startDate = picked.start;

        _endDate = picked.end;

      });

    }

  }



  Future<void> _callNumber(String? number) async {

    if (number == null || number.isEmpty) return;

    final url = Uri.parse("tel:$number");

    if (await canLaunchUrl(url)) await launchUrl(url);

  }



  @override

  Widget build(BuildContext context) {

    if (_isLoading) {

      return const Center(child: CircularProgressIndicator(color: AppTheme.primary));

    }



    return StreamBuilder<List<Map<String, dynamic>>>(

      stream: AlertService.getAlertsStream(),

      builder: (context, snapshot) {

        final liveAlerts = snapshot.data ?? [];

        final displayAlerts = _filterData(liveAlerts);



        return Padding(

          padding: const EdgeInsets.all(48),

          child: Column(

            crossAxisAlignment: CrossAxisAlignment.start,

            children: [

              _buildHeader(liveAlerts, snapshot.connectionState),

              const SizedBox(height: 48),

              _buildFiltersUI(),

              const SizedBox(height: 32),

              Expanded(

                child: snapshot.hasError

                    ? const Center(child: Icon(Icons.cloud_off_rounded, color: AppTheme.sosRed, size: 48))

                    : displayAlerts.isEmpty

                        ? Center(child: Column(

                            mainAxisAlignment: MainAxisAlignment.center,

                            children: [

                              Icon(Icons.check_circle_outline_rounded, color: Colors.grey.withOpacity(0.3), size: 64),

                              const SizedBox(height: 16),

                              Text("AUCUNE ALERTE ACTIVE", style: TextStyle(color: Colors.grey.withOpacity(0.5), fontWeight: FontWeight.w900, letterSpacing: 1)),

                            ],

                          ))

                        : ListView.builder(

                            physics: const BouncingScrollPhysics(),

                            itemCount: displayAlerts.length,

                            itemBuilder: (context, index) => _buildAlertCard(displayAlerts[index]),

                          ),

              ),

            ],

          ),

        );

      },

    );

  }



  Widget _buildHeader(List<Map<String, dynamic>> alerts, ConnectionState state) {

    return Row(

      children: [

        Column(

          crossAxisAlignment: CrossAxisAlignment.start,

          children: [

            Text("Alertes Live", style: Theme.of(context).textTheme.headlineMedium),

            const SizedBox(height: 6),

            const Text("Surveillance en temps réel des incidents", style: TextStyle(color: Color(0xFF64748B), fontSize: 14, fontWeight: FontWeight.w500)),

          ],

        ),

        const SizedBox(width: 40),

        _liveSummaryBadge(alerts.where((a) => a['type'] == 'SOS').length, AppTheme.sosRed, "SOS"),

        const SizedBox(width: 12),

        _liveSummaryBadge(alerts.where((a) => a['type'] == 'HELP').length, AppTheme.helpYellow, "AIDE"),

        const Spacer(),

        Container(

          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),

          decoration: BoxDecoration(

            color: const Color(0xFFF1F5F9),

            borderRadius: BorderRadius.circular(12),

            border: Border.all(color: Colors.grey.withOpacity(0.1)),

          ),

          child: Row(

            children: [

              _LiveDot(),

              const SizedBox(width: 10),

              Text(

                state == ConnectionState.waiting ? "RECONNEXION..." : "FIREBASE CONNECTÉ",

                style: TextStyle(color: state == ConnectionState.waiting ? Colors.orange : AppTheme.neonGreen, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 0.5),

              ),

            ],

          ),

        ),

        const SizedBox(width: 16),

        IconButton(

          onPressed: _loadData,

          icon: const Icon(Icons.refresh_rounded, color: AppTheme.primary, size: 20),

          style: IconButton.styleFrom(backgroundColor: const Color(0xFFF1F5F9), padding: const EdgeInsets.all(12)),

        ),

      ],

    );

  }



  Widget _liveSummaryBadge(int count, Color color, String label) {

    return Container(

      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),

      decoration: BoxDecoration(color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(10), border: Border.all(color: color.withOpacity(0.2))),

      child: Row(

        children: [

          Text("$count", style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 14)),

          const SizedBox(width: 8),

          Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 10, letterSpacing: 0.5)),

        ],

      ),

    );

  }



  List<Map<String, dynamic>> _filterData(List<Map<String, dynamic>> data) {

    return data.where((alert) {

      final cin = alert["user_id"]?.toString();

      final embeddedName = alert["user_name"]?.toString().toLowerCase() ?? "";

      final dictName = usersDict[cin]?["nom"]?.toString().toLowerCase() ?? "";

      final searchUserLower = _searchUser.toLowerCase();



      if (searchUserLower.isNotEmpty) {

        bool matches = false;

        if (embeddedName.contains(searchUserLower)) matches = true;

        if (dictName.contains(searchUserLower)) matches = true;

        if (cin != null && cin.toLowerCase().contains(searchUserLower)) matches = true;

        if (!matches) return false;

      }

      if (_selectedType != "Tous" && alert["type"] != _selectedType) return false;

      if (_startDate != null || _endDate != null) {

        final tsStr = alert["timestamp"]?.toString() ?? "";

        try {

          final ts = DateTime.parse(tsStr);

          if (_startDate != null && ts.isBefore(_startDate!)) return false;

          if (_endDate != null && ts.isAfter(_endDate!.add(const Duration(days: 1)))) return false;

        } catch (_) { return false; }

      }

      return true;

    }).toList();

  }



  Widget _buildFiltersUI() {

    return Container(

      padding: const EdgeInsets.all(32),

      decoration: BoxDecoration(

        color: Colors.white,

        borderRadius: BorderRadius.circular(24),

        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 20, offset: const Offset(0, 4))],

        border: Border.all(color: Colors.grey.withOpacity(0.1)),

      ),

      child: Row(

        children: [

          Expanded(

            flex: 3,

            child: TextField(

              controller: _searchController,

              style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w600),

              decoration: AppTheme.inputDecoration("Rechercher par nom ou CIN...", Icons.search_rounded),

            ),

          ),

          const SizedBox(width: 24),

          Expanded(

            flex: 2,

            child: Container(

              padding: const EdgeInsets.symmetric(horizontal: 16),

              decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFE2E8F0))),

              child: DropdownButtonHideUnderline(

                child: DropdownButton<String>(

                  value: _selectedType,

                  isExpanded: true,

                  icon: const Icon(Icons.filter_list_rounded, size: 18, color: AppTheme.primary),

                  style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w700, fontSize: 14),

                  items: ["Tous", "SOS", "HELP"].map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),

                  onChanged: (v) { if (v != null) setState(() => _selectedType = v); },

                ),

              ),

            ),

          ),

          const SizedBox(width: 24),

          Expanded(

            flex: 3,

            child: InkWell(

              onTap: _selectDateRange,

              borderRadius: BorderRadius.circular(16),

              child: Container(

                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),

                decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFE2E8F0))),

                child: Row(

                  children: [

                    const Icon(Icons.calendar_today_rounded, size: 16, color: AppTheme.primary),

                    const SizedBox(width: 12),

                    Expanded(

                      child: Text(

                            (_startDate != null && _endDate != null) ? "${_startDate!.day}/${_startDate!.month} - ${_endDate!.day}/${_endDate!.month}"
                            : "Sélectionner période",

                        style: const TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w600, fontSize: 14),

                      ),

                    ),

                    if (_startDate != null)

                      GestureDetector(

                        onTap: () { setState(() { _startDate = null; _endDate = null; }); },

                        child: const Icon(Icons.close_rounded, size: 16, color: Color(0xFF94A3B8)),

                      ),

                  ],

                ),

              ),

            ),

          ),

          const SizedBox(width: 24),

          IconButton(

            onPressed: _resetFilters,

            icon: const Icon(Icons.restart_alt_rounded, color: Color(0xFF94A3B8)),

            style: IconButton.styleFrom(backgroundColor: const Color(0xFFF1F5F9), padding: const EdgeInsets.all(12)),

          ),

        ],

      ),

    );

  }



  Widget _buildAlertCard(Map<String, dynamic> alert) {

    final isSOS = alert["type"] == "SOS";
    final color = isSOS ? AppTheme.sosRed : const Color(0xFFF97316); // Orange pour HELP

    final cin = alert["user_id"]?.toString();

    final user = usersDict[cin];



    final String? takenBy = alert["taken_by"]?.toString();

    final String? takenByName = alert["taken_by_name"]?.toString();

    final bool isTakenByMe = takenBy == BaseService.staffId;

    final bool isTakenByOthers = takenBy != null && !isTakenByMe;



    String timeStr = alert["timestamp"]?.toString() ?? "";

    try {

      final ts = DateTime.parse(timeStr);

      timeStr = "${ts.hour.toString().padLeft(2,'0')}:${ts.minute.toString().padLeft(2,'0')}";

    } catch (_) {}



    return Opacity(

      opacity: isTakenByOthers ? 0.45 : 1.0,

      child: AbsorbPointer(

        absorbing: isTakenByOthers,

        child: GestureDetector(

          onTap: () async {

            if (takenBy == null) {

              await AlertService.takeAlert(

                alert["alert_id"].toString(),

                firebaseKey: alert["firebase_key"],

                fullAlertData: alert,

              );

            }

            _showAlertDetails(alert, user);

          },

          child: _AlertCardWidget(

            alert: alert,

            isSOS: isSOS,

            color: color,

            timeStr: timeStr,

            userName: alert["user_name"]?.toString() ?? _userName(cin),

            isTakenByMe: isTakenByMe,

            isTakenByOthers: isTakenByOthers,

            takenByName: takenByName,

          ),

        ),

      ),

    );

  }



  void _showAlertDetails(Map<String, dynamic> alert, Map<String, dynamic>? user) {

    final isSOS = alert["type"] == "SOS";
    final color = isSOS ? AppTheme.sosRed : const Color(0xFFF97316); // Orange pour HELP

    final state = int.tryParse(alert["state"]?.toString() ?? "0") ?? 0;



    String sentAt = "Non renseigné";

    try {

      final ts = DateTime.parse(alert["timestamp"]);

      sentAt = "${ts.hour.toString().padLeft(2, '0')}:${ts.minute.toString().padLeft(2, '0')}";

    } catch (_) {}



    double lat = 36.8065;

    double lon = 10.1815;

    try {

      final double? alertLat = double.tryParse(alert['latitude']?.toString() ?? "");

      final double? alertLon = double.tryParse(alert['longitude']?.toString() ?? "");

      if (alertLat != null && alertLon != null && alertLat != 0.0 && alertLon != 0.0) {

        lat = alertLat; lon = alertLon;

      }

    } catch (_) {}



    showDialog(

      context: context,

      builder: (ctx) => StreamBuilder<List<Map<String, dynamic>>>(

        stream: AlertService.getAlertsStream(),

        builder: (context, streamSnapshot) {

          final allAlerts = streamSnapshot.data ?? [];

          final currentAlert = allAlerts.firstWhere(

            (a) => a["alert_id"].toString() == alert["alert_id"].toString(),

            orElse: () => alert,

          );

          

          final liveState = int.tryParse(currentAlert["state"]?.toString() ?? "0") ?? 0;

          final String liveStatus = currentAlert["caneStatus"]?.toString() ?? 

                                   currentAlert["cane_status"]?.toString() ?? 

                                   ((liveState == 4) ? "CHUTE DÉTECTÉE" : "CANNE DROITE");



          return Dialog(
            backgroundColor: Colors.transparent,
            child: Container(
              width: 950,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(32),
                border: Border.all(color: color.withOpacity(0.5), width: 2),
                boxShadow: [BoxShadow(color: color.withOpacity(0.2), blurRadius: 40, spreadRadius: 10)],
              ),

              child: Column(

                mainAxisSize: MainAxisSize.min,

                children: [

                  _alertHeader(currentAlert, isSOS, color),

                  Flexible(

                    child: SingleChildScrollView(

                      padding: const EdgeInsets.all(40),

                      child: Column(

                        children: [

                          Row(

                            crossAxisAlignment: CrossAxisAlignment.start,

                            children: [

                              Expanded(

                                flex: 3,

                                child: Column(

                                  children: [

                                    _sectionCardFull(

                                      title: "BÉNÉFICIAIRE",

                                      icon: Icons.person_rounded,

                                      child: Column(

                                        children: [

                                          _infoRowFull(Icons.account_circle_rounded, "NOM COMPLET", currentAlert["user_name"]?.toString() ?? _userName(currentAlert["user_id"]?.toString())),
                                          const SizedBox(height: 16),
                                          Row(
                                            children: [
                                              Expanded(child: _infoRowFull(Icons.badge_rounded, "CIN", currentAlert["user_id"]?.toString() ?? "Non renseigné")),
                                              const SizedBox(width: 16),
                                              Expanded(child: _infoRowFull(Icons.cake_rounded, "ÂGE", "${user?['age'] ?? currentAlert['age'] ?? 'Non renseigné'} ANS")),
                                            ],
                                          ),
                                          const SizedBox(height: 16),
                                          Row(
                                            children: [
                                              Expanded(child: _infoRowFull(Icons.phone_rounded, "TÉLÉPHONE", user?["numero_de_telephone"]?.toString() ?? currentAlert["user_phone"]?.toString() ?? "Non renseigné")),
                                              const SizedBox(width: 16),
                                              Expanded(child: _infoRowFull(Icons.contact_phone_rounded, "URGENCE", user?["contact_familial"]?.toString() ?? currentAlert["emergency_phone"]?.toString() ?? "Non renseigné")),
                                            ],
                                          ),

                                        ],

                                      ),

                                    ),

                                    const SizedBox(height: 24),

                                    _sectionCardFull(

                                      title: "ANTÉCÉDENTS MÉDICAUX",

                                      icon: Icons.medical_services_rounded,

                                      child: _buildMedicalContentFull(user?["etat_de_sante"] ?? currentAlert["health_notes"]),

                                    ),

                                  ],

                                ),

                              ),

                              const SizedBox(width: 24),

                              Expanded(

                                flex: 2,

                                child: Column(

                                  children: [

                                    _sectionCardFull(

                                      title: "DÉTAILS ALERTE",
                                      icon: Icons.info_rounded,
                                      child: Column(
                                        children: [
                                          _infoTileCompact("TYPE", currentAlert["type"]?.toString() ?? "Non renseigné", color),

                                          _infoTileCompact("HEURE", sentAt, const Color(0xFF64748B)),

                                          _infoTileCompact("STATUT", currentAlert["status"]?.toString() ?? "EN COURS", AppTheme.neonGreen),

                                        ],

                                      ),

                                    ),

                                    const SizedBox(height: 24),

                                    _sectionCardFull(
                                      title: "CAPTEURS CANNE",
                                      icon: Icons.sensors_rounded,
                                      child: ValueListenableBuilder<Map<String, dynamic>>(
                                        valueListenable: AlertService.caneStatusNotifier,
                                        builder: (context, caneData, child) {
                                          final String cStatus = caneData["caneStatus"]?.toString() ?? "UPRIGHT";
                                          final String cLabel = caneData["caneLabel"]?.toString() ?? "CANNE DROITE";
                                          final String cEmoji = caneData["caneEmoji"]?.toString() ?? "✅";
                                          final String pitch = caneData["pitch"]?.toString() ?? "0";
                                          final String roll = caneData["roll"]?.toString() ?? "0";

                                          Color statusColor = AppTheme.neonGreen;
                                          if (cStatus.contains("FALL_DETECTED") || cStatus.contains("SHOCK_DETECTED")) {
                                            statusColor = AppTheme.sosRed;
                                          } else if (cStatus == "INCLINED" || cStatus == "ON_GROUND" || cStatus == "STATIONARY") {
                                            statusColor = AppTheme.accent;
                                          }

                                          return _statusTileFull(
                                            "ÉTAT PHYSIQUE", 
                                            "$cEmoji $cLabel", 
                                            statusColor,
                                            subValue: "Pitch: $pitch°, Roll: $roll°",
                                          );
                                        },
                                      ),
                                    ),

                                  ],

                                ),

                              ),

                            ],

                          ),

                          const SizedBox(height: 24),

                          _sectionCardFull(

                            title: "GÉOLOCALISATION EN TEMPS RÉEL",

                            icon: Icons.map_rounded,

                            child: Container(

                              height: 400,
                              decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFFE2E8F0))),
                              child: ClipRRect(

                                borderRadius: BorderRadius.circular(19),

                                child: FlutterMap(

                                  options: MapOptions(initialCenter: LatLng(lat, lon), initialZoom: 16.0),

                                  children: [

                                    TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png'),

                                    MarkerLayer(markers: [Marker(point: LatLng(lat, lon), child: Icon(Icons.location_on_rounded, color: AppTheme.sosRed, size: 48, shadows: [Shadow(color: Colors.black.withOpacity(0.3), blurRadius: 10)]))]),

                                  ],

                                ),

                              ),

                            ),

                          ),

                        ],

                      ),

                    ),

                  ),

                  _alertActions(currentAlert, user, ctx, isSOS, color),

                ],

              ),

            ),

          );

        },

      ),

    );

  }



  Widget _alertHeader(Map<String, dynamic> alert, bool isSOS, Color color) {
    final gradientColors = isSOS ? const [Color(0xFFEF4444), Color(0xFFB91C1C)] : const [Color(0xFFF97316), Color(0xFFC2410C)];
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: gradientColors),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        border: const Border(bottom: BorderSide(color: Colors.transparent)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(14)),
            child: Icon(isSOS ? Icons.warning_rounded : Icons.help_rounded, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 20),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("ALERTE ${alert['type']} DÉTECTÉE", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 20, letterSpacing: 0.5)),
              const SizedBox(height: 4),
              Text("ID TRANSACTION: ${alert['alert_id']}", style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1)),
            ],
          ),
          const Spacer(),
          IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close_rounded, color: Colors.white)),
        ],
      ),
    );
  }



  Widget _alertActions(Map<String, dynamic> alert, Map<String, dynamic>? user, BuildContext ctx, bool isSOS, Color color) => Container(
    padding: const EdgeInsets.all(32),
    decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: const BorderRadius.vertical(bottom: Radius.circular(32)), border: Border(top: BorderSide(color: Colors.grey.withOpacity(0.1)))),
    child: Row(
      children: [
        Expanded(child: AppGradientButton(label: "APPELER CONTACTS", icon: Icons.phone_in_talk_rounded, color: color, onTap: () => _showCallPicker(context, user, alert))),

        const SizedBox(width: 16),

        Expanded(
          child: AppGradientButton(
            label: "MARQUER RÉSOLU",
            icon: Icons.verified_rounded,
            color: AppTheme.neonGreen,
            onTap: () async {
              final bool? confirmed = await _showConfirmDialog();
              if (confirmed == true) {
                if (alert["firebase_key"] == "active_alert") {
                  await AlertService.resolveActiveAlert(fullAlertData: alert);
                } else {
                  await AlertService.resolveAlert(alert["alert_id"].toString(), firebaseKey: alert["firebase_key"], fullAlertData: alert);
                }
                if (mounted) Navigator.pop(ctx);
              }
            },
          ),
        ),

        const SizedBox(width: 16),

        Expanded(
          child: AppGradientButton(
            label: "LIBÉRER L'ALERTE",
            icon: Icons.undo_rounded,
            color: const Color(0xFF64748B),
            outlined: true,
            onTap: () async {
              final success = await AlertService.releaseAlert(alert["alert_id"].toString(), firebaseKey: alert["firebase_key"]);
              if (success && mounted) Navigator.pop(ctx);
            },
          ),
        ),
      ],
    ),
  );



  Future<bool?> _showConfirmDialog() => showDialog<bool>(

    context: context,

    builder: (ctx) => AlertDialog(

      backgroundColor: Colors.white,

      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),

      title: const Text("Confirmer Résolution", style: TextStyle(fontWeight: FontWeight.w900, color: AppTheme.primary)),
      content: const Text("Voulez-vous clôturer cette intervention ?", style: TextStyle(color: Color(0xFF475569), fontWeight: FontWeight.w500)),

      actions: [

        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("ANNULER", style: TextStyle(color: Color(0xFF94A3B8), fontWeight: FontWeight.w800))),

        AppGradientButton(onTap: () => Navigator.pop(ctx, true), label: "CONFIRMER", color: AppTheme.neonGreen, icon: Icons.check_rounded),

      ],

    ),

  );



  Widget _buildMedicalContentFull(String? raw) {

    if (raw == null || raw.isEmpty) return const Text("Aucune donnée disponible.");

    try {

      final data = jsonDecode(raw);

      final List pathologies = data["pathologies"] ?? [];

      final String group = data["groupe_sanguin"] ?? "INCONNU";

      final String obs = data["observations"] ?? "";

      return Column(

        crossAxisAlignment: CrossAxisAlignment.start,

        children: [

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFFCBD5E1), width: 1.0),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Text("GROUPE SANGUIN: ", style: TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF64748B), fontSize: 11)),
                Text(group, style: const TextStyle(color: AppTheme.sosRed, fontWeight: FontWeight.w900, fontSize: 14)),
              ],
            ),
          ),

          const SizedBox(height: 24),

          const Text("PATHOLOGIES :", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 10, color: Color(0xFF94A3B8), letterSpacing: 1)),

          const SizedBox(height: 12),

          Wrap(

            spacing: 8, runSpacing: 8, 

            children: pathologies.map((p) => Container(

              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), 

              decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFFCBD5E1))), 

              child: Text(p.toString().toUpperCase(), style: const TextStyle(fontSize: 10, color: AppTheme.primary, fontWeight: FontWeight.w900))

            )).toList()

          ),

          if (obs.isNotEmpty) ...[

            const SizedBox(height: 24), 

            const Text("OBSERVATIONS :", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 10, color: Color(0xFF94A3B8), letterSpacing: 1)), 

            const SizedBox(height: 8),

            Text(obs, style: const TextStyle(fontSize: 14, color: Color(0xFF475569), fontWeight: FontWeight.w500, height: 1.5))

          ],

        ],

      );

    } catch (_) { return Text(raw); }

  }



  void _showCallPicker(BuildContext context, Map<String, dynamic>? user, Map<String, dynamic> alert) {

    final String blindPhone = user?["numero_de_telephone"]?.toString() ?? alert["user_phone"]?.toString() ?? "";

    final String familyPhone = user?["contact_familial"]?.toString() ?? alert["emergency_phone"]?.toString() ?? "";

    showDialog(context: context, builder: (ctx) => AlertDialog(

      title: const Text("Appeler"),

      content: Column(mainAxisSize: MainAxisSize.min, children: [

        if (blindPhone.isNotEmpty) ListTile(leading: const Icon(Icons.person), title: const Text("Bénéficiaire"), subtitle: Text(blindPhone), onTap: () { Navigator.pop(ctx); _callNumber(blindPhone); }),

        if (familyPhone.isNotEmpty) ListTile(leading: const Icon(Icons.family_restroom), title: const Text("Famille"), subtitle: Text(familyPhone), onTap: () { Navigator.pop(ctx); _callNumber(familyPhone); }),

      ]),

    ));

  }



  Widget _sectionCardFull({required String title, required IconData icon, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),

      child: Column(

        crossAxisAlignment: CrossAxisAlignment.start, 

        children: [

          Row(children: [Icon(icon, size: 16, color: AppTheme.primary), const SizedBox(width: 12), Text(title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 1, color: AppTheme.primary))]),

          const SizedBox(height: 24),

          child,

        ]

      ),

    );

  }



  Widget _infoRowFull(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFCBD5E1), width: 1.0),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(children: [
        Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: AppTheme.primary.withOpacity(0.05), borderRadius: BorderRadius.circular(10)), child: Icon(icon, size: 18, color: AppTheme.primary)),
        const SizedBox(width: 16),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.5)), Text(value, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: AppTheme.primary))])),
      ]),
    );
  }



  Widget _infoTileCompact(String label, String value, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFCBD5E1), width: 1.0),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween, 
        children: [
          Text(label, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 0.5)), 
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), 
            decoration: BoxDecoration(color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(8)), 
            child: Text(value, style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 11))
          )
        ]
      )
    );
  }



  Widget _statusTileFull(String label, String value, Color color, {String? subValue}) {
    return Container(
      padding: const EdgeInsets.all(20), 
      decoration: BoxDecoration(color: color.withOpacity(0.05), borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFCBD5E1), width: 1.0)), 
      child: Row(
        children: [
          Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle, boxShadow: [BoxShadow(color: color.withOpacity(0.3), blurRadius: 8)])), 
          const SizedBox(width: 16), 
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start, 
              children: [
                Text(label, style: const TextStyle(color: Color(0xFF64748B), fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.5)), 
                const SizedBox(height: 4), 
                Text(value, style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 15)),
                if (subValue != null) ...[
                  const SizedBox(height: 4),
                  Text(subValue, style: TextStyle(color: color.withOpacity(0.7), fontSize: 11, fontWeight: FontWeight.w600)),
                ]
              ]
            )
          )
        ]
      )
    );
  }


}



class _AlertCardWidget extends StatefulWidget {

  final Map<String, dynamic> alert;

  final bool isSOS;

  final Color color;

  final String timeStr;

  final String userName;

  final bool isTakenByMe;

  final bool isTakenByOthers;

  final String? takenByName;



  const _AlertCardWidget({

    required this.alert,

    required this.isSOS,

    required this.color,

    required this.timeStr,

    required this.userName,

    required this.isTakenByMe,

    required this.isTakenByOthers,

    this.takenByName,

  });



  @override

  State<_AlertCardWidget> createState() => _AlertCardWidgetState();

}



class _AlertCardWidgetState extends State<_AlertCardWidget> {

  bool _hovered = false;

  @override

  Widget build(BuildContext context) {

    return MouseRegion(

      onEnter: (_) => setState(() => _hovered = true),

      onExit: (_) => setState(() => _hovered = false),

      child: AnimatedContainer(

        duration: const Duration(milliseconds: 300),

        margin: const EdgeInsets.only(bottom: 20),

        padding: const EdgeInsets.all(24),

        decoration: BoxDecoration(
          color: widget.color,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.transparent, width: 2),
          boxShadow: [
            BoxShadow(
              color: widget.color.withOpacity(_hovered ? 0.5 : 0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            )
          ],
        ),

        child: Row(

          children: [

            widget.isSOS ? const _PulseIcon() : Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(16)),
              child: const Icon(Icons.help_outline_rounded, color: Colors.white, size: 32),
            ),

            const SizedBox(width: 24),

            Expanded(

              child: Column(

                crossAxisAlignment: CrossAxisAlignment.start,

                children: [

                  Row(

                    children: [

                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
                        child: Text(
                          widget.alert["type"]?.toString().toUpperCase() ?? "", 
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 1)
                        ),
                      ),
                      const SizedBox(width: 12),
                      if (widget.isTakenByOthers)
                        _staffBadge("OCCUPÉ PAR: ${widget.takenByName?.toUpperCase() ?? 'STAFF'}", const Color(0xFF94A3B8)),
                      if (widget.isTakenByMe)
                        _staffBadge("VOTRE CHARGE", AppTheme.neonGreen),

                    ],

                  ),

                  const SizedBox(height: 12),

                  Text(widget.userName, style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.white, fontSize: 18)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.location_on_rounded, size: 14, color: Colors.white.withOpacity(0.8)),
                      const SizedBox(width: 6),
                      Text("COORD: ${widget.alert['latitude']}, ${widget.alert['longitude']}", style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 12, fontWeight: FontWeight.w600)),
                    ],
                  ),

                ],

              ),

            ),

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(10)),
              child: Text(widget.timeStr, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w800)),
            ),

          ],

        ),

      ),

    );

  }



  Widget _staffBadge(String label, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(6), border: Border.all(color: Colors.white.withOpacity(0.3))),
    child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
  );

}



class _PulseIcon extends StatefulWidget {

  const _PulseIcon();

  @override

  State<_PulseIcon> createState() => _PulseIconState();

}

class _PulseIconState extends State<_PulseIcon> with SingleTickerProviderStateMixin {

  late AnimationController _c;

  @override

  void initState() { super.initState(); _c = AnimationController(vsync: this, duration: const Duration(seconds: 1))..repeat(reverse: true); }

  @override

  void dispose() { _c.dispose(); super.dispose(); }

  @override

  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _c, 
    builder: (context, child) => Container(
      padding: const EdgeInsets.all(16), 
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2 + (0.15 * _c.value)), 
        borderRadius: BorderRadius.circular(16), 
        boxShadow: [
          BoxShadow(color: Colors.white.withOpacity(0.3 * _c.value), blurRadius: 15 * _c.value, spreadRadius: 2 * _c.value)
        ]
      ), 
      child: const Icon(Icons.emergency_rounded, color: Colors.white, size: 32)
    )
  );

}



Widget _liveBadge(int count, Color color, String label) => Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(20), border: Border.all(color: color.withOpacity(0.4))), child: Text("$count $label", style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)));



class _LiveDot extends StatefulWidget {

  @override

  State<_LiveDot> createState() => _LiveDotState();

}

class _LiveDotState extends State<_LiveDot> with SingleTickerProviderStateMixin {

  late AnimationController _c;

  @override

  void initState() { super.initState(); _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 800))..repeat(reverse: true); }

  @override

  void dispose() { _c.dispose(); super.dispose(); }

  @override

  Widget build(BuildContext context) => AnimatedBuilder(animation: _c, builder: (_, __) => Container(width: 8, height: 8, decoration: BoxDecoration(shape: BoxShape.circle, color: AppTheme.neonGreen, boxShadow: [BoxShadow(color: AppTheme.neonGreen.withOpacity(0.5 * _c.value), blurRadius: 8)])));

}


