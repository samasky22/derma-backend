import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'map_screen.dart';
import 'home_screen.dart';

class LocationScreen extends StatefulWidget {
  const LocationScreen({super.key});

  @override
  _LocationScreenState createState() => _LocationScreenState();
}

class _LocationScreenState extends State<LocationScreen> {
  final TextEditingController controller = TextEditingController();
  final String apiKey = "YOUR_API_KEY";

  Future<void> getLocation() async {
    var status = await Permission.location.request();

    if (status.isGranted) {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      openMap(position.latitude, position.longitude);
    } else {
      showMessage("Permission denied");
    }
  }

  void manualSearch() {
    openMap(31.2001, 29.9187);
  }

  void openMap(double lat, double lng) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MapScreen(lat: lat, lng: lng, apiKey: apiKey),
      ),
    );
  }

  void showMessage(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 🌍 Background (map-like gradient)
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color.fromARGB(255, 135, 185, 201),
                  Color.fromARGB(255, 255, 255, 255),
                ],
                begin: Alignment.topRight,
                end: Alignment.bottomCenter,
              ),
            ),
          ),

          // 📍 Content
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 20),

                /// Back arrow
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.blueGrey),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const HomeScreen(),
                        ),
                      );
                    },
                  ),
                ),
                // Title
                Text(
                  "Find Dermatology Clinics",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),

                const SizedBox(height: 20),

                // 📦 Glass-style card
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 10,
                          offset: Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        TextField(
                          controller: controller,
                          decoration: InputDecoration(
                            prefixIcon: const Icon(Icons.location_city),
                            labelText: "Enter city",
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                        const SizedBox(height: 15),

                        ElevatedButton.icon(
                          onPressed: manualSearch,
                          icon: const Icon(Icons.search),
                          label: const Text("Search Location"),
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 50),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 📍 Floating GPS button
          Positioned(
            bottom: 30,
            right: 20,
            child: FloatingActionButton.extended(
              onPressed: getLocation,
              icon: const Icon(Icons.my_location),
              label: const Text("Use My Location"),
            ),
          ),
        ],
      ),
    );
  }
}
