import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../core/theme.dart';

class MapPage extends StatelessWidget {
  final double latitude;
  final double longitude;
  final String alertType;

  const MapPage({
    super.key,
    required this.latitude,
    required this.longitude,
    required this.alertType,
  });

  @override
  Widget build(BuildContext context) {
    final isSOS = alertType == "SOS";
    final color = isSOS ? AppTheme.sosRed : AppTheme.helpOrange;
    final location = LatLng(latitude, longitude);

    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.of(context).pop(),
              ),
              const SizedBox(width: 8),
              const Text("Localisation de l'Alerte", style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900)),
              const SizedBox(width: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                child: Text(alertType, style: TextStyle(color: color, fontWeight: FontWeight.w800)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text("Coordonnées: $latitude, $longitude", style: TextStyle(color: Colors.grey.shade600)),
          const SizedBox(height: 20),

          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: FlutterMap(
                options: MapOptions(initialCenter: location, initialZoom: 16),
                children: [
                  TileLayer(urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png"),
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: location,
                        width: 60,
                        height: 60,
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                                boxShadow: [BoxShadow(color: color.withOpacity(0.4), blurRadius: 12, spreadRadius: 4)],
                              ),
                              child: Icon(isSOS ? Icons.emergency : Icons.help, color: Colors.white, size: 24),
                            ),
                          ],
                        ),
                      ),
                    ],
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
