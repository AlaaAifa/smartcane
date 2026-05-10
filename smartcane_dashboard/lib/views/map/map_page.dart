import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
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
    final initialCameraPosition = LatLng(widget.latitude, widget.longitude);

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.background,
        image: DecorationImage(
          image: const NetworkImage("https://www.transparenttextures.com/patterns/carbon-fibre.png"),
          opacity: 0.05,
          colorFilter: ColorFilter.mode(AppTheme.cyan.withOpacity(0.05), BlendMode.srcATop),
        ),
      ),
      child: StreamBuilder<List<Map<String, dynamic>>>(
        stream: AlertService.getAlertsStream(),
        builder: (context, snapshot) {
          final alerts = snapshot.data ?? [];
          
          final List<Marker> markers = alerts.map((alert) {
            final lat = double.tryParse(alert['latitude']?.toString() ?? "") ?? widget.latitude;
            final lon = double.tryParse(alert['longitude']?.toString() ?? "") ?? widget.longitude;
            final type = alert['type']?.toString() ?? "SOS";
            return _buildNeonMarker(lat, lon, type);
          }).toList();

          return Padding(
            padding: const EdgeInsets.all(40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(alertColor, snapshot.connectionState == ConnectionState.waiting),
                const SizedBox(height: 32),
                Expanded(
                  child: snapshot.hasError ? _buildErrorView() : _buildMapView(initialCameraPosition, markers, alerts),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(Color alertColor, bool isSyncing) {
    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: AppTheme.cyan),
          onPressed: () => widget.onBack(),
          style: IconButton.styleFrom(
            backgroundColor: Colors.white.withOpacity(0.05),
            padding: const EdgeInsets.all(12),
            side: BorderSide(color: AppTheme.cyan.withOpacity(0.3)),
          ),
        ),
        const SizedBox(width: 24),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Suivi Temps Réel", style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 1)),
            const SizedBox(height: 8),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: alertColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: alertColor.withOpacity(0.3)),
                  ),
                  child: Text("ALERTE: ${widget.alertType}", style: TextStyle(color: alertColor, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.1)),
                ),
                const SizedBox(width: 16),
                _buildSyncIndicator(isSyncing),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSyncIndicator(bool isSyncing) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: const BoxDecoration(color: AppTheme.neonGreen, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(
          isSyncing ? "SYNCHRONISATION..." : "LIVE FIREBASE CONNECTED",
          style: const TextStyle(color: AppTheme.neonGreen, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 0.5),
        ),
      ],
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.cloud_off_rounded, color: AppTheme.sosRed, size: 64),
          const SizedBox(height: 24),
          const Text("ERREUR DE CONNEXION", style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 1)),
          const SizedBox(height: 12),
          Text("Veuillez vérifier votre configuration Firebase.", style: TextStyle(color: Colors.white.withOpacity(0.5))),
        ],
      ),
    );
  }

  Widget _buildMapView(LatLng initialPos, List<Marker> markers, List<dynamic> alerts) {
    return Container(
      decoration: AppTheme.glassCard(borderColor: Colors.white10),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Stack(
          children: [
            FlutterMap(
              options: MapOptions(initialCenter: initialPos, initialZoom: 15.0),
              children: [
                TileLayer(
                  urlTemplate: 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png',
                  subdomains: const ['a', 'b', 'c', 'd'],
                ),
                MarkerLayer(markers: markers),
              ],
            ),
            if (alerts.isNotEmpty)
              Positioned(
                bottom: 32,
                left: 32,
                right: 32,
                child: _buildTrackingPanel(alerts.first),
              ),
          ],
        ),
      ),
    );
  }

  Marker _buildNeonMarker(double lat, double lon, String type) {
    final color = type == "SOS" ? AppTheme.sosRed : AppTheme.helpOrange;
    return Marker(
      point: LatLng(lat, lon),
      width: 80,
      height: 80,
      child: _PulsingMarker(color: color),
    );
  }

  Widget _buildTrackingPanel(Map<String, dynamic> alert) {
    final isSOS = alert['type'] == 'SOS';
    final color = isSOS ? AppTheme.sosRed : AppTheme.helpOrange;
    
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: AppTheme.glassCard(borderColor: color.withOpacity(0.3)),
      child: Row(
        children: [
          _buildPulseIndicator(color),
          const SizedBox(width: 24),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "SUIVI EN DIRECT: ${alert['type']}".toUpperCase(),
                  style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 10, letterSpacing: 1.2),
                ),
                const SizedBox(height: 4),
                Text(
                  alert['user_id'] ?? "Client Inconnu",
                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 20, color: Colors.white, letterSpacing: 0.5),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(color: AppTheme.neonGreen.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
                      child: Text(
                        "CANNE: ${alert['cane_status']?.toString().toUpperCase() ?? 'ACTIVE'}",
                        style: const TextStyle(color: AppTheme.neonGreen, fontSize: 9, fontWeight: FontWeight.w900),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.03), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white10)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text("SIGNAL GPS", style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.white.withOpacity(0.3), letterSpacing: 1)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.location_searching_rounded, size: 14, color: AppTheme.cyan),
                    const SizedBox(width: 8),
                    Text(
                      "${alert['latitude']}, ${alert['longitude']}",
                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: AppTheme.cyan, fontFamily: 'monospace'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPulseIndicator(Color color) {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle, border: Border.all(color: color.withOpacity(0.3))),
      child: Center(
        child: Icon(Icons.emergency_rounded, color: color, size: 28),
      ),
    );
  }
}

class _PulsingMarker extends StatefulWidget {
  final Color color;
  const _PulsingMarker({required this.color});

  @override
  State<_PulsingMarker> createState() => _PulsingMarkerState();
}

class _PulsingMarkerState extends State<_PulsingMarker> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 1))..repeat(reverse: true);
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
      builder: (context, child) => Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 40 + (40 * _controller.value),
            height: 40 + (40 * _controller.value),
            decoration: BoxDecoration(shape: BoxShape.circle, color: widget.color.withOpacity(0.3 * (1 - _controller.value))),
          ),
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: widget.color,
              boxShadow: [BoxShadow(color: widget.color.withOpacity(0.5), blurRadius: 10, spreadRadius: 2)],
              border: Border.all(color: Colors.white, width: 2),
            ),
          ),
        ],
      ),
    );
  }
}
