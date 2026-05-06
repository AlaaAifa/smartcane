import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:async';
import 'package:url_launcher/url_launcher.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
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
    // We only load users from FastAPI now. 
    // Live alerts come exclusively from the Firebase Stream.
    final usersData = await UserService.getUsers();

    final tempDict = <String, Map<String, dynamic>>{};
    for (final user in usersData) {
      final cin = user["cin"]?.toString();
      if (cin != null) {
        tempDict[cin] = user;
      }
    }

    if (!mounted) {
      return;
    }

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
              onSurface: Colors.black87,
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
    if (number == null || number.isEmpty) {
      return;
    }
    final url = Uri.parse("tel:$number");
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: AlertService.getAlertsStream(),
      builder: (context, snapshot) {
        final liveAlerts = snapshot.data ?? [];
        
        // Apply local filters to the stream data
        final displayAlerts = _filterData(liveAlerts);
        
        if (displayAlerts.isNotEmpty) {
          print("INFO: ${displayAlerts.length} alertes live affichées.");
        }

        return Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text("Alertes Live", style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900)),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(color: AppTheme.sosRed.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                    child: Text("${liveAlerts.where((a) => a['type'] == 'SOS').length} SOS", style: const TextStyle(color: AppTheme.sosRed, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(color: AppTheme.helpOrange.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                    child: Text("${liveAlerts.where((a) => a['type'] == 'HELP').length} HELP", style: const TextStyle(color: AppTheme.helpOrange, fontWeight: FontWeight.bold)),
                  ),
                  const Spacer(),
                  if (snapshot.connectionState == ConnectionState.waiting)
                    const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                  IconButton(onPressed: _loadData, icon: const Icon(Icons.refresh)),
                ],
              ),
              const SizedBox(height: 24),
              _buildFiltersUI(),
              const SizedBox(height: 24),
              Expanded(
                child: snapshot.hasError
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.error_outline, color: Colors.red, size: 48),
                            const SizedBox(height: 16),
                            const Text(
                              "Erreur de connexion Firebase",
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              "Assurez-vous d'avoir configuré Firebase pour le Web.",
                              style: TextStyle(color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                      )
                    : displayAlerts.isEmpty
                        ? Center(child: Text("Aucune alerte correspondante", style: TextStyle(color: Colors.grey.shade500)))
                        : ListView.builder(
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

  List<Map<String, dynamic>> _filterData(List<Map<String, dynamic>> data) {
    return data.where((alert) {
      // 1. Filter by User Name
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

      // 2. Filter by Type
      if (_selectedType != "Tous" && alert["type"] != _selectedType) {
        return false;
      }

      // 3. Filter by Date
      if (_startDate != null || _endDate != null) {
        final tsStr = alert["timestamp"]?.toString() ?? "";
        try {
          final ts = DateTime.parse(tsStr);
          if (_startDate != null && ts.isBefore(_startDate!)) {
            return false;
          }
          if (_endDate != null && ts.isAfter(_endDate!.add(const Duration(days: 1)))) {
            return false;
          }
        } catch (_) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  Widget _buildFiltersUI() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          // User search
          Expanded(
            flex: 3,
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: "Rechercher un utilisateur...",
                prefixIcon: const Icon(Icons.search, size: 20),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                filled: true,
                fillColor: Colors.grey.shade50,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Type filter
          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedType,
                  isExpanded: true,
                  icon: const Icon(Icons.filter_list, size: 20),
                  items: ["Tous", "SOS", "HELP"].map((type) {
                    return DropdownMenuItem(value: type, child: Text(type));
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedType = val);
                  },
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Date range filter
          Expanded(
            flex: 3,
            child: InkWell(
              onTap: _selectDateRange,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today, size: 18, color: Colors.grey),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        (_startDate != null && _endDate != null)
                            ? "${_startDate!.day}/${_startDate!.month} - ${_endDate!.day}/${_endDate!.month}"
                            : "Choisir une période",
                        style: const TextStyle(fontSize: 13),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (_startDate != null)
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _startDate = null;
                            _endDate = null;
                          });
                        },
                        child: const Icon(Icons.close, size: 16, color: Colors.grey),
                      ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Reset button
          IconButton(
            onPressed: _resetFilters,
            icon: const Icon(Icons.restart_alt),
            tooltip: "Réinitialiser les filtres",
            color: AppTheme.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildAlertCard(Map<String, dynamic> alert) {
    final isSOS = alert["type"] == "SOS";
    final color = isSOS ? AppTheme.sosRed : AppTheme.helpOrange;
    final cin = alert["user_id"]?.toString();
    final user = usersDict[cin];

    // Locking logic
    final String? takenBy = alert["taken_by"]?.toString();
    final String? takenByName = alert["taken_by_name"]?.toString();
    final bool isTakenByMe = takenBy == BaseService.staffId;
    final bool isTakenByOthers = takenBy != null && !isTakenByMe;

    return Opacity(
      opacity: isTakenByOthers ? 0.5 : 1.0,
      child: AbsorbPointer(
        absorbing: isTakenByOthers,
        child: GestureDetector(
          onTap: () async {
            // Auto-take if not already taken
            if (takenBy == null) {
              await AlertService.takeAlert(
                alert["alert_id"].toString(),
                firebaseKey: alert["firebase_key"],
              );
            }
            _showAlertDetails(alert, user);
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border(left: BorderSide(color: color, width: 4)),
              boxShadow: [BoxShadow(color: color.withOpacity(0.06), blurRadius: 12, offset: const Offset(0, 4))],
            ),
            child: Row(
              children: [
                isSOS ? const _PulseIcon() : _staticIcon(color),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(alert["type"]?.toString() ?? "", style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: color)),
                          const SizedBox(width: 8),
                          _statusBadge(alert["cane_status"]?.toString()),
                          if (isTakenByOthers) ...[
                            const SizedBox(width: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(4)),
                              child: Text(
                                "PRIS PAR: ${takenByName ?? 'Staff'}",
                                style: TextStyle(color: Colors.grey.shade700, fontSize: 10, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                          if (isTakenByMe) ...[
                            const SizedBox(width: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(4)),
                              child: const Text(
                                "VOTRE CHARGE",
                                style: TextStyle(color: Colors.blue, fontSize: 10, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(alert["user_name"]?.toString() ?? _userName(cin), style: const TextStyle(fontWeight: FontWeight.bold)),
                      Text(
                        "Position: ${alert['latitude']}, ${alert['longitude']}",
                        style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Text(alert["timestamp"]?.toString() ?? "", style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _staticIcon(Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
      child: Icon(Icons.help_outline, color: color, size: 28),
    );
  }

  Widget _statusBadge(String? status) {
    status ??= "normal";
    Color bgColor;
    Color textColor;
    IconData icon;

    switch (status.toLowerCase()) {
      case "sos active":
        bgColor = AppTheme.sosRed.withOpacity(0.1);
        textColor = AppTheme.sosRed;
        icon = Icons.warning_rounded;
        break;
      case "moving":
        bgColor = Colors.blue.withOpacity(0.1);
        textColor = Colors.blue;
        icon = Icons.directions_walk;
        break;
      default:
        bgColor = Colors.green.withOpacity(0.1);
        textColor = Colors.green;
        icon = Icons.check_circle_outline;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(6)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: textColor),
          const SizedBox(width: 4),
          Text(
            status.toUpperCase(),
            style: TextStyle(color: textColor, fontSize: 10, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  String _calculateDuration(Map<String, dynamic> alert) {
    if (alert["status"]?.toString().toUpperCase() == "RESOLVED") {
      return alert["response_time"]?.toString() ?? "Terminé";
    }
    
    final timestampStr = alert["timestamp"];
    if (timestampStr == null) return "N/A";
    try {
      final timestamp = DateTime.parse(timestampStr.toString());
      final diff = DateTime.now().difference(timestamp);
      
      final h = diff.inHours.toString().padLeft(2, '0');
      final m = (diff.inMinutes % 60).toString().padLeft(2, '0');
      final s = (diff.inSeconds % 60).toString().padLeft(2, '0');
      
      return "${h}h ${m}s";
    } catch (e) {
      return "N/A";
    }
  }

  void _showAlertDetails(Map<String, dynamic> alert, Map<String, dynamic>? user) {
    final isSOS = alert["type"] == "SOS";
    final color = isSOS ? AppTheme.sosRed : AppTheme.helpOrange;
    final state = int.tryParse(alert["state"]?.toString() ?? "0") ?? 0;

    // Derived Statuses for Dashboard look
    final String canePosition = (state == 4) ? "FALLEN / DOWN" : "OK / UPRIGHT";
    final String movementStatus = (alert["cane_status"]?.toString().toUpperCase() == "MOVING") ? "MOVING" : "WAITING / STATIC";
    final String safetyState = isSOS ? "SOS ACTIVE" : "NORMAL / HELP";

    // Format Sent Time to HH:mm
    String sentAt = "N/A";
    try {
      final ts = DateTime.parse(alert["timestamp"]);
      sentAt = "${ts.hour.toString().padLeft(2, '0')}:${ts.minute.toString().padLeft(2, '0')}";
    } catch (_) {
      sentAt = alert["timestamp"]?.toString().split('T').last.substring(0, 5) ?? "N/A";
    }

    // 1. Ensure the map widget receives valid coordinates
    // Do not use (0.0, 0.0) as fallback. Use Tunis center if missing.
    double lat = 36.8065;
    double lon = 10.1815;
    try {
      final double? alertLat = double.tryParse(alert['latitude']?.toString() ?? "");
      final double? alertLon = double.tryParse(alert['longitude']?.toString() ?? "");
      if (alertLat != null && alertLon != null && alertLat != 0.0 && alertLon != 0.0) {
        lat = alertLat;
        lon = alertLon;
      }
    } catch (_) {
      // Keep Tunis default
    }

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          width: 900,
          constraints: const BoxConstraints(maxHeight: 950),
          decoration: BoxDecoration(
            color: AppTheme.background,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 20,
                offset: const Offset(0, 10),
              )
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // --- HEADER ---
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(isSOS ? Icons.emergency : Icons.help_outline, color: Colors.white, size: 28),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "DETAILS ALERTE ${alert['type']}",
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 22, letterSpacing: 1.1),
                          ),
                          Text(
                            "RÉFÉRENCE: ${alert['alert_id']}",
                            style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(ctx),
                      icon: const Icon(Icons.close, color: Colors.white),
                    ),
                  ],
                ),
              ),

              // --- CONTENT ---
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Left Column: User & Medical
                          Expanded(
                            flex: 3,
                            child: Column(
                              children: [
                                // 1. USER INFORMATION
                                _sectionCard(
                                  title: "Informations Utilisateur",
                                  icon: Icons.person,
                                  child: Column(
                                    children: [
                                        _infoRow(Icons.account_circle_outlined, "Nom Complet", alert["user_name"]?.toString() ?? _userName(alert["user_id"]?.toString())),
                                        const Divider(height: 24),
                                        Row(
                                          children: [
                                            Expanded(child: _infoRow(Icons.badge_outlined, "CIN / ID", alert["user_id"]?.toString() ?? "N/A")),
                                            Expanded(child: _infoRow(Icons.cake_outlined, "Âge", "${user?['age'] ?? alert['age'] ?? 'N/A'} ans")),
                                          ],
                                        ),
                                        const Divider(height: 24),
                                        _infoRow(Icons.email_outlined, "Email", user?["email"]?.toString() ?? alert["email"]?.toString() ?? "N/A"),
                                        const Divider(height: 24),
                                        Row(
                                          children: [
                                            Expanded(child: _infoRow(Icons.phone_outlined, "Blind person number", user?["numero_de_telephone"]?.toString() ?? alert["user_phone"]?.toString() ?? "N/A")),
                                            Expanded(child: _infoRow(Icons.contact_phone_outlined, "Contact Famille", user?["contact_familial"]?.toString() ?? alert["emergency_phone"]?.toString() ?? "N/A")),
                                          ],
                                        ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 20),
                                // 2. MEDICAL INFORMATION
                                _sectionCard(
                                  title: "Informations Médicales",
                                  icon: Icons.health_and_safety,
                                  child: _buildMedicalContent(user?["etat_de_sante"] ?? alert["health_notes"]),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 20),
                          // Right Column: Alert & Cane
                          Expanded(
                            flex: 2,
                            child: Column(
                              children: [
                                // Alert Info
                                _sectionCard(
                                  title: "Détails Alerte",
                                  icon: Icons.info_outline,
                                  child: Column(
                                    children: [
                                      _infoTile("Type", alert["type"]?.toString() ?? "N/A", color),
                                      _infoTile("Envoyé à", sentAt, Colors.grey),
                                      StreamBuilder(
                                        stream: Stream.periodic(const Duration(seconds: 1)),
                                        builder: (context, snapshot) {
                                          final isResolved = alert["status"]?.toString().toUpperCase() == "RESOLVED";
                                          return _infoTile(
                                            isResolved ? "Temps total" : "Temps écoulé", 
                                            _calculateDuration(alert), 
                                            isResolved ? Colors.green : AppTheme.sosRed
                                          );
                                        }
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 20),
                                // Cane Status
                                _sectionCard(
                                  title: "Statut Canne",
                                  icon: Icons.sensors,
                                  child: Column(
                                    children: [
                                      _statusTile("Position", canePosition, (state == 4) ? AppTheme.sosRed : AppTheme.normalGreen),
                                      const SizedBox(height: 8),
                                      _statusTile("Mouvement", movementStatus, movementStatus == "MOVING" ? Colors.blue : Colors.grey),
                                      const SizedBox(height: 8),
                                      _statusTile("Sécurité", safetyState, isSOS ? AppTheme.sosRed : AppTheme.normalGreen),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      // 4. LOCATION SECTION (Full Width & Centered)
                      // Fix map rendering in Alert dialog: The map must be inside a container with fixed height
                      _sectionCard(
                        title: "Localisation Géographique (Cliquez pour agrandir)",
                        icon: Icons.location_on,
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Expanded(child: _infoRow(Icons.explore_outlined, "Latitude", lat.toString())),
                                Expanded(child: _infoRow(Icons.explore_outlined, "Longitude", lon.toString())),
                              ],
                            ),
                            const SizedBox(height: 20),
                            MouseRegion(
                              cursor: SystemMouseCursors.click,
                              child: Container(
                                height: 400, // Increased height for better visibility
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: Colors.grey.shade200, width: 2),
                                  color: Colors.grey.shade50,
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(14),
                                  child: GoogleMap(
                                    key: UniqueKey(), // Ensure correct initialization and rebuild for Web
                                    initialCameraPosition: CameraPosition(
                                      target: LatLng(lat, lon),
                                      zoom: 15.0,
                                    ),
                                    markers: {
                                      Marker(
                                        markerId: const MarkerId("preview"),
                                        position: LatLng(lat, lon),
                                        infoWindow: InfoWindow(
                                          title: "Position de l'utilisateur",
                                          snippet: "${alert['type']} - $sentAt",
                                        ),
                                      ),
                                    },
                                    onTap: (_) {
                                      Navigator.pop(ctx);
                                      widget.onNavigate?.call(
                                        "/map?lat=$lat&lon=$lon&type=${alert['type']}",
                                      );
                                    },
                                    zoomControlsEnabled: true,
                                    mapToolbarEnabled: true,
                                    myLocationButtonEnabled: false,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // --- ACTIONS ---
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))],
                ),
                child: Builder(
                  builder: (ctx2) {
                    final String? takenBy = alert["taken_by"]?.toString();
                    final String? takenByName = alert["taken_by_name"]?.toString();
                    final bool isTakenByMe = takenBy == BaseService.staffId;
                    final bool isTakenByOthers = takenBy != null && !isTakenByMe;

                    if (isTakenByOthers) {
                      return Container(
                        padding: const EdgeInsets.all(16),
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.lock_outline, color: Colors.grey),
                            const SizedBox(width: 12),
                            Text(
                              "CETTE ALERTE EST EN COURS DE TRAITEMENT PAR : ${takenByName?.toUpperCase() ?? 'UN COLLÈGUE'}",
                              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
                            ),
                          ],
                        ),
                      );
                    }

                    return Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _showCallPicker(context, user, alert),
                            icon: const Icon(Icons.phone_in_talk),
                            label: const Text("APPELER"),
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue.shade700, padding: const EdgeInsets.symmetric(vertical: 20)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              // Show confirmation dialog
                              final bool? confirmed = await showDialog<bool>(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                  title: const Row(
                                    children: [
                                      Icon(Icons.help_outline, color: AppTheme.normalGreen),
                                      SizedBox(width: 12),
                                      Text("Confirmer la résolution"),
                                    ],
                                  ),
                                  content: const Text("Êtes-vous sûr que cette alerte a été résolue ?"),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(ctx, false),
                                      child: Text("ANNULER", style: TextStyle(color: Colors.grey.shade600)),
                                    ),
                                    ElevatedButton(
                                      onPressed: () => Navigator.pop(ctx, true),
                                      style: ElevatedButton.styleFrom(backgroundColor: AppTheme.normalGreen),
                                      child: const Text("CONFIRMER"),
                                    ),
                                  ],
                                ),
                              );

                              if (confirmed == true) {
                                final success = await AlertService.resolveActiveAlert();
                                
                                if (mounted) {
                                  if (success) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text("Alerte résolue et archivée avec succès"),
                                        backgroundColor: AppTheme.normalGreen,
                                      ),
                                    );
                                    Navigator.pop(ctx); // Ferme le dialogue de détails
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text("Erreur lors de la résolution"),
                                        backgroundColor: AppTheme.sosRed,
                                      ),
                                    );
                                  }
                                }
                              }
                            },
                            icon: const Icon(Icons.verified),
                            label: const Text("RÉSOUDRE"),
                            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.normalGreen, padding: const EdgeInsets.symmetric(vertical: 20)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              final success = await AlertService.releaseAlert(
                                alert["alert_id"].toString(),
                                firebaseKey: alert["firebase_key"],
                              );
                              if (success && mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text("Alerte libérée avec succès"),
                                  ),
                                );
                                Navigator.pop(ctx);
                                _loadData();
                              }
                            },
                            icon: const Icon(Icons.history_outlined),
                            label: const Text("LIBÉRER"),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 20),
                              side: BorderSide(color: Colors.grey.shade400),
                            ),
                          ),
                        ),
                      ],
                    );
                  }
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMedicalContent(String? raw) {
    if (raw == null || raw.isEmpty) return const Text("Aucune donnée médicale disponible.");
    
    try {
      final data = jsonDecode(raw);
      final List pathologies = data["pathologies"] ?? [];
      final String group = data["groupe_sanguin"] ?? "Inconnu";
      final String obs = data["observations"] ?? "";
      final String allergy = data["allergie_detail"] ?? "";

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text("Groupe Sanguin: ", style: TextStyle(fontWeight: FontWeight.bold)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(6), border: Border.all(color: Colors.red.shade200)),
                child: Text(group, style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text("Pathologies & Conditions:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(height: 8),
          if (pathologies.isEmpty || pathologies.contains("Aucune pathologie connue"))
            const Text("Aucune pathologie connue", style: TextStyle(color: Colors.grey, fontSize: 13))
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: pathologies.map((p) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.primary.withOpacity(0.1)),
                ),
                child: Text(p.toString(), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.primary)),
              )).toList(),
            ),
          if (allergy.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Text("Allergies:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.sosRed)),
            Text(allergy, style: const TextStyle(fontSize: 13)),
          ],
          if (obs.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Text("Observations:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            Text(obs, style: const TextStyle(fontSize: 13, color: Colors.black87)),
          ],
        ],
      );
    } catch (e) {
      return Text(raw);
    }
  }

  void _showCallPicker(BuildContext context, Map<String, dynamic>? user, Map<String, dynamic> alert) {
    // Si user est nul, on utilise les infos de l'alerte pour ne pas bloquer l'appel
    final String userName = user?["nom"]?.toString() ?? alert["user_name"]?.toString() ?? "Utilisateur";
    final String blindPhone = user?["numero_de_telephone"]?.toString() ?? alert["user_phone"]?.toString() ?? "";
    final String familyPhone = user?["contact_familial"]?.toString() ?? alert["emergency_phone"]?.toString() ?? "";

    if (blindPhone.isEmpty && familyPhone.isEmpty) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.error_outline, color: AppTheme.sosRed),
              SizedBox(width: 12),
              Text("Données manquantes"),
            ],
          ),
          content: Text(
            "Impossible de trouver les coordonnées pour l'utilisateur: $userName.\n\nVeuillez vérifier la configuration.",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("FERMER"),
            ),
          ],
        ),
      );
      return;
    }
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Column(
          children: [
            const Icon(Icons.contact_phone, size: 48, color: AppTheme.primary),
            const SizedBox(height: 16),
            const Text(
              "Choisir un contact",
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20),
            ),
            const SizedBox(height: 4),
            Text(
              "Veuillez sélectionner le numéro à appeler",
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600, fontWeight: FontWeight.normal),
            ),
          ],
        ),
        content: Container(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Divider(),
              if (blindPhone.isNotEmpty)
                _buildContactTile(
                  context: ctx,
                  name: userName,
                  phone: blindPhone,
                  relationship: "Bénéficiaire (Malvoyant)",
                  icon: Icons.person,
                  iconColor: Colors.blue,
                )
              else
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text("Numéro du bénéficiaire non renseigné", 
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade500, fontStyle: FontStyle.italic)),
                ),
              if (familyPhone.isNotEmpty)
                _buildContactTile(
                  context: ctx,
                  name: "Contact d'Urgence",
                  phone: familyPhone,
                  relationship: "Famille / Proche",
                  icon: Icons.family_restroom,
                  iconColor: Colors.orange,
                )
              else
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text("Contact d'urgence non renseigné", 
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade500, fontStyle: FontStyle.italic)),
                ),
              if (blindPhone.isEmpty && familyPhone.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Text(
                    "Aucun numéro de téléphone n'a été trouvé pour cet utilisateur.",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.red),
                  ),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text("ANNULER", style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildContactTile({
    required BuildContext context,
    required String name,
    required String phone,
    required String relationship,
    required IconData icon,
    required Color iconColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.grey.shade200),
        ),
        leading: CircleAvatar(
          backgroundColor: iconColor.withOpacity(0.1),
          child: Icon(icon, color: iconColor),
        ),
        title: Text(
          name,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(relationship, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
            const SizedBox(height: 2),
            Text(phone, style: TextStyle(fontSize: 14, color: iconColor, fontWeight: FontWeight.bold)),
          ],
        ),
        trailing: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.green.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.phone, color: Colors.green, size: 20),
        ),
        onTap: () {
          Navigator.pop(context);
          _callNumber(phone);
        },
      ),
    );
  }


  Widget _sectionCard({required String title, required IconData icon, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: AppTheme.primary),
              const SizedBox(width: 10),
              Text(
                title.toUpperCase(),
                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 1.1, color: AppTheme.primary),
              ),
            ],
          ),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: AppTheme.background, borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, size: 18, color: Colors.grey.shade600),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(color: Colors.grey.shade500, fontSize: 11, fontWeight: FontWeight.bold)),
            Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          ],
        ),
      ],
    );
  }

  Widget _infoTile(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 13, fontWeight: FontWeight.w600)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
            child: Text(value, style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Widget _statusTile(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 10, fontWeight: FontWeight.bold)),
                Text(value, style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 13), overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppTheme.primary),
          const SizedBox(width: 8),
          Text(
            title.toUpperCase(),
            style: TextStyle(
              color: AppTheme.primary,
              fontWeight: FontWeight.w900,
              fontSize: 12,
              letterSpacing: 1.1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _detail(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 130, child: Text(label, style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.w700, fontSize: 13))),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }
}

// SOS Pulse Animation Widget
class _PulseIcon extends StatefulWidget {
  const _PulseIcon();

  @override
  State<_PulseIcon> createState() => _PulseIconState();
}

class _PulseIconState extends State<_PulseIcon> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppTheme.sosRed.withOpacity(0.1 + (0.2 * _controller.value)),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: AppTheme.sosRed.withOpacity(0.3 * _controller.value),
                blurRadius: 8 * _controller.value,
                spreadRadius: 2 * _controller.value,
              )
            ],
          ),
          child: Icon(Icons.emergency, color: AppTheme.sosRed, size: 28),
        );
      },
    );
  }
}
