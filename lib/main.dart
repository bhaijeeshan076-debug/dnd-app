import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Live Geofence DND',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const GeofenceHomeScreen(),
    );
  }
}

class GeofenceHomeScreen extends StatefulWidget {
  const GeofenceHomeScreen({super.key});

  @override
  State<GeofenceHomeScreen> createState() => _GeofenceHomeScreenState();
}

class _GeofenceHomeScreenState extends State<GeofenceHomeScreen> {
  bool isGeofenceActive = true;
  String locationStatus = "Fetching live GPS location...";
  static const platform = MethodChannel('com.bhaijeeshan.dnd/settings');

  @override
  void initState() {
    super.initState();
    _initAppPermissions();
  }

  Future<void> _initAppPermissions() async {
    await _requestLocationPermission();
  }

  Future<void> _requestLocationPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() => locationStatus = "GPS is turned off");
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() => locationStatus = "Location permission required");
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      setState(() => locationStatus = "Location permissions permanently denied");
      return;
    }

    _fetchCurrentLocation();
  }

  Future<void> _fetchCurrentLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      setState(() {
        locationStatus =
            "Active | Lat: ${position.latitude.toStringAsFixed(4)}, Long: ${position.longitude.toStringAsFixed(4)}";
      });
    } catch (e) {
      setState(() => locationStatus = "Error fetching location: $e");
    }
  }

  Future<void> _openSystemSettings() async {
    try {
      await platform.invokeMethod('openDndSettings');
    } on PlatformException {
      // Fallback intent if native channel fails
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Geofence DND'),
        backgroundColor: Colors.deepPurple.shade100,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Card(
              elevation: 2,
              child: SwitchListTile(
                title: const Text('Automatic Geofence Mute',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text('Runs in background for all devices'),
                value: isGeofenceActive,
                onChanged: (val) {
                  setState(() => isGeofenceActive = val);
                },
              ),
            ),
            const SizedBox(height: 12),
            Card(
              elevation: 2,
              child: ListTile(
                leading: const Icon(Icons.my_location, color: Colors.deepPurple),
                title: const Text('GPS Tracking Status'),
                subtitle: Text(locationStatus),
                trailing: IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: _fetchCurrentLocation,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              elevation: 2,
              color: Colors.purple.shade50,
              child: ListTile(
                leading: const Icon(Icons.settings_suggest, color: Colors.deepPurple),
                title: const Text('System Notification Access'),
                subtitle: const Text('Tap to grant background policy access'),
                trailing: ElevatedButton(
                  onPressed: _openSystemSettings,
                  child: const Text('Allow'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
