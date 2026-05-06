import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../theme.dart';
import '../../services/services.dart';

class MapPage extends StatefulWidget {
  final double latitude;
  final double longitude;
  final String alertType;
  final VoidCallback onBack;

  const MapPage({
    super.key,
    required this.latitude,
    required this.longitude,
    required this.alertType,
    required this.onBack,
  });

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  List<Map<String, dynamic>> _users = [];
  Timer? _timer;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUsers();
    // Simulate real-time tracking every 10 seconds
    _timer = Timer.periodic(const Duration(seconds: 10), (timer) {
      _loadUsers();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    final users = await UserService.getUsers();
    if (mounted) {
      setState(() {
        _users = users.where((user) => user["role"] == "client" && user["sim_de_la_canne"] != null).toList();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final alertColor = widget.alertType == "SOS" ? AppTheme.sosRed : AppTheme.helpOrange;
    final initialCameraPosition = CameraPosition(
      target: LatLng(widget.latitude, widget.longitude),
      zoom: 15,
    );

    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: AlertService.getAlertsStream(),
      builder: (context, snapshot) {
        final alerts = snapshot.data ?? [];
        
        // Create markers for all active alerts
        final Set<Marker> markers = alerts.map((alert) {
          final lat = double.tryParse(alert['latitude']?.toString() ?? "") ?? widget.latitude;
          final lon = double.tryParse(alert['longitude']?.toString() ?? "") ?? widget.longitude;
          final alertId = alert['alert_id']?.toString() ?? "unknown";
          final type = alert['type']?.toString() ?? "SOS";
          final caneStatus = alert['cane_status']?.toString() ?? "normal";
          
          return Marker(
            markerId: MarkerId(alertId),
            position: LatLng(lat, lon),
            infoWindow: InfoWindow(
              title: "Alerte $type - $caneStatus",
              snippet: "Utilisateur: ${alert['user_id']}",
            ),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              type == "SOS" ? BitmapDescriptor.hueRed : BitmapDescriptor.hueOrange,
            ),
          );
        }).toSet();

        return Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => widget.onBack(),
                  ),
                  const SizedBox(width: 8),
                  const Text("Suivi Temps Réel", style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900)),
                  const SizedBox(width: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(color: alertColor.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                    child: Text("Alerte: ${widget.alertType}", style: TextStyle(color: alertColor, fontWeight: FontWeight.w800)),
                  ),
                  const Spacer(),
                  if (snapshot.connectionState == ConnectionState.waiting)
                    const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                  Text("Live Firebase Connected", style: TextStyle(color: Colors.green.shade600, fontSize: 12, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 20),
              Expanded(
                child: snapshot.hasError
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.cloud_off, color: Colors.red, size: 64),
                            const SizedBox(height: 16),
                            const Text("Firebase non configuré", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            const Text("Veuillez configurer Firebase pour activer le suivi temps réel."),
                          ],
                        ),
                      )
                    : Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: GoogleMap(
                              initialCameraPosition: initialCameraPosition,
                              markers: markers,
                              mapType: MapType.normal,
                              myLocationEnabled: true,
                              myLocationButtonEnabled: true,
                              zoomControlsEnabled: true,
                            ),
                          ),
                          if (alerts.isNotEmpty)
                            Positioned(
                              bottom: 20,
                              left: 20,
                              right: 20,
                              child: _buildTrackingPanel(alerts.first),
                            ),
                        ],
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTrackingPanel(Map<String, dynamic> alert) {
    final isSOS = alert['type'] == 'SOS';
    final color = isSOS ? AppTheme.sosRed : AppTheme.helpOrange;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20, spreadRadius: 5)],
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: color.withOpacity(0.1),
            radius: 25,
            child: Icon(isSOS ? Icons.emergency : Icons.help_outline, color: color, size: 30),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "SUIVI EN DIRECT: ${alert['type']}",
                  style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 12),
                ),
                Text(
                  "Client: ${alert['user_id']}",
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Text(
                  "État: ${alert['cane_status']?.toString().toUpperCase() ?? 'NORMAL'}",
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text("Signal GPS", style: TextStyle(fontSize: 10, color: Colors.grey)),
              Row(
                children: [
                  const Icon(Icons.gps_fixed, size: 14, color: Colors.green),
                  const SizedBox(width: 4),
                  Text("${alert['latitude']}, ${alert['longitude']}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
