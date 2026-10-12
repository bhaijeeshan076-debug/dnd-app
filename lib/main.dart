import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const MasjidAutoSilentApp());
}

class MasjidAutoSilentApp extends StatelessWidget {
  const MasjidAutoSilentApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Masjid Auto Silent',
      theme: ThemeData(
        primarySwatch: Colors.green,
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool isServiceActive = true;
  bool isPausedManually = false;
  double radiusMeters = 50.0; // Default radius

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _requestPermissions();
  }

  // Load saved settings
  _loadSettings() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      radiusMeters = prefs.getDouble('radius') ?? 50.0;
    });
  }

  // Save custom radius
  _saveRadius(double value) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('radius', value);
    setState(() {
      radiusMeters = value;
    });
  }

  // Request location permissions
  void _requestPermissions() async {
    await [
      Permission.location,
      Permission.accessNotificationPolicy,
    ].request();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Masjid Auto Silent'),
        backgroundColor: Colors.green,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Status Icon
            Icon(
              isPausedManually ? Icons.pause_circle_filled : Icons.check_circle,
              size: 100,
              color: isPausedManually ? Colors.orange : Colors.green,
            ),
            const SizedBox(height: 20),
            Text(
              isPausedManually
                  ? 'Service is Temporarily Paused'
                  : 'Auto Silent Service is Active',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              isPausedManually
                  ? 'App will not mute phone until resumed.'
                  : 'Monitoring location within ${radiusMeters.toInt()} meters of Masjid.',
              style: const TextStyle(color: Colors.grey, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),

            // Manual Override / Pause Button
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  isPausedManually = !isPausedManually;
                });
              },
              icon: Icon(isPausedManually ? Icons.play_arrow : Icons.pause),
              label: Text(isPausedManually ? 'Resume Service' : 'Pause for 30 Mins'),
              style: ElevatedButton.styleFrom(
                backgroundColor: isPausedManually ? Colors.green : Colors.orange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
            const SizedBox(height: 30),

            // Custom Radius Settings Slider
            const Text(
              'Set Masjid Detection Radius:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            Slider(
              value: radiusMeters,
              min: 20,
              max: 200,
              divisions: 9,
              label: '${radiusMeters.toInt()} meters',
              onChanged: (double value) {
                _saveRadius(value);
              },
            ),
            Text('${radiusMeters.toInt()} Meters', style: const TextStyle(color: Colors.green)),
          ],
        ),
      ),
    );
  }
}
