import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../core/theme.dart';
import '../../core/api_service.dart';

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
    final users = await ApiService.getUsers();
    if (mounted) {
      setState(() {
        _users = users;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    final alertColor = widget.alertType == "SOS" ? AppTheme.sosRed : AppTheme.helpOrange;
    final initialLocation = LatLng(widget.latitude, widget.longitude);

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
              Text("Mise à jour toutes les 10s", style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 20),

          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: FlutterMap(
                options: MapOptions(initialCenter: initialLocation, initialZoom: 15),
                children: [
                  TileLayer(urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png"),
                  MarkerLayer(
                    markers: _users
                      .where((user) {
                        if (user['latitude'] == null || user['longitude'] == null) return false;
                        
                        final bool isRental = user['sale_type'] == 'rented';
                        final bool isInAlert = user['status'] != "normal" && user['status'] != "resolved";
                        
                        // Privacy Logic: Sold canes are only visible during alerts.
                        // Rented canes are always visible for tracking.
                        if (!isRental && !isInAlert) return false;
                        
                        return true;
                      })
                      .map((user) {
                        final lat = user['latitude'] ?? widget.latitude;
                        final lon = user['longitude'] ?? widget.longitude;
                        final bool isUserInAlert = user['status'] != "normal" && user['status'] != "resolved";
                        final bool isRental = user['sale_type'] == 'rented';
                      
                      Color markerColor = Colors.blue; 
                      if (user['status'] == "SOS") markerColor = AppTheme.sosRed;
                      if (user['status'] == "HELP") markerColor = AppTheme.helpOrange;
                      if (!user['is_online']) markerColor = Colors.grey;

                      return Marker(
                        point: LatLng(lat, lon),
                        width: 100,
                        height: 100,
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: markerColor,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2),
                                boxShadow: [BoxShadow(color: markerColor.withOpacity(0.4), blurRadius: 8, spreadRadius: 2)],
                              ),
                                  child: Icon(
                                    isUserInAlert
                                        ? Icons.emergency
                                        : (isRental ? Icons.handshake_rounded : Icons.person),
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(4)),
                                  child: Column(
                                    children: [
                                      Text(
                                        user['prenom'] ?? "",
                                        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                      ),
                                      if (isRental)
                                        const Text(
                                          "LOCATION",
                                          style: TextStyle(color: AppTheme.normalGreen, fontSize: 7, fontWeight: FontWeight.w900),
                                        ),
                                    ],
                                  ),
                                ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
