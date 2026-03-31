import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../services/api_service.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  LatLng _currentLocation = LatLng(36.8065, 10.1815);
  bool _isLoading = false;

  void _sendAlert(String type) async {
    setState(() => _isLoading = true);
    
    // Get current position
    Position position = await Geolocator.getCurrentPosition();
    
    // Send to backend
    bool success = await ApiService.sendAlert(
      "user_789456123", // For demo
      type,
      position.latitude,
      position.longitude,
    );

    setState(() => _isLoading = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Alerte $type envoyée avec succès !"),
          backgroundColor: type == "SOS" ? Colors.red : Colors.orange,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Échec de l'envoi de l'alerte")),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  void _getCurrentLocation() async {
     Position position = await Geolocator.getCurrentPosition();
     setState(() {
       _currentLocation = LatLng(position.latitude, position.longitude);
     });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_currentIndex == 0 ? "Be My Eyes Dashboard" : "Mon Profil")),
      body: _currentIndex == 0 ? _buildDashboard() : const ProfileScreen(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: Theme.of(context).colorScheme.primary,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.map), label: "Dashboard"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profil"),
        ],
      ),
    );
  }

  Widget _buildDashboard() {
    return Stack(
      children: [
          FlutterMap(
            options: MapOptions(initialCenter: _currentLocation, initialZoom: 15),
            children: [
              TileLayer(urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png"),
              MarkerLayer(
                markers: [
                  Marker(
                    point: _currentLocation,
                    child: const Icon(Icons.location_on, color: Colors.blue, size: 40),
                  ),
                ],
              ),
            ],
          ),
          
          // Status Cards
          Positioned(
            top: 20,
            left: 20,
            right: 20,
            child: Row(
              children: [
                _buildStatusCard("Batterie", "85%", Icons.battery_charging_full),
                const SizedBox(width: 10),
                _buildStatusCard("Cane", "Active", Icons.bluetooth_connected),
              ],
            ),
          ),

          // SOS / HELP Buttons
          Positioned(
            bottom: 40,
            left: 20,
            right: 20,
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildAlertButton("HELP", Colors.orange, () => _sendAlert("HELP")),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: _buildAlertButton("SOS", Colors.red, () => _sendAlert("SOS")),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          if (_isLoading)
            const Center(child: CircularProgressIndicator()),
        ],
      );
  }

  Widget _buildStatusCard(String title, String value, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.white.withOpacity(0.95), Colors.white.withOpacity(0.8)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08), 
              blurRadius: 20, 
              spreadRadius: 2, 
              offset: const Offset(0, 10)
            )
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Theme.of(context).primaryColor, size: 28),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 13, color: Colors.blueGrey, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text(value, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Theme.of(context).primaryColor)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAlertButton(String label, Color color, VoidCallback onPressed) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(60),
        splashColor: Colors.white30,
        child: Container(
          height: 120,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            gradient: RadialGradient(
              colors: [color.withOpacity(0.7), color],
              center: const Alignment(-0.3, -0.5),
              radius: 1.5,
            ),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withOpacity(0.2), width: 2),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.6), 
                blurRadius: 25, 
                spreadRadius: 4, 
                offset: const Offset(0, 12)
              ),
              const BoxShadow(
                color: Colors.white24, 
                blurRadius: 15, 
                offset: Offset(-5, -5)
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.white.withOpacity(0.9), size: 32),
              const SizedBox(height: 4),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white, 
                  fontWeight: FontWeight.w900, 
                  fontSize: 26,
                  letterSpacing: 1.5,
                  shadows: [Shadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2))]
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
