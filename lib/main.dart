import 'package:flutter/material.dart';
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
      title: 'Auto Geofence Silent',
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
  String locationStatus = "Fetching GPS...";
  String dndStatus = "App Ready (Auto Mode)";

  @override
  void initState() {
    super.initState();
    _checkPermissionsAndStart();
  }

  Future<void> _checkPermissionsAndStart() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() => locationStatus = "Please enable GPS");
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() => locationStatus = "Location Permission Denied");
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      setState(() => locationStatus = "Location Denied Permanently");
      return;
    }

    _updateLocation();
  }

  Future<void> _updateLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      setState(() {
        locationStatus =
            "Active | Lat: ${position.latitude.toStringAsFixed(4)}, Long: ${position.longitude.toStringAsFixed(4)}";
      });
    } catch (e) {
      setState(() => locationStatus = "Location Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Auto Geofence Mute'),
        backgroundColor: Colors.deepPurple.shade100,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Card(
              child: SwitchListTile(
                title: const Text('Geofence Auto Mute',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text('Works automatically on all devices'),
                value: isGeofenceActive,
                onChanged: (val) => setState(() => isGeofenceActive = val),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: ListTile(
                leading: const Icon(Icons.my_location, color: Colors.deepPurple),
                title: const Text('GPS Location Status'),
                subtitle: Text(locationStatus),
                trailing: IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: _updateLocation,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              color: Colors.green.shade50,
              child: ListTile(
                leading: const Icon(Icons.check_circle, color: Colors.green),
                title: const Text('System Service Status'),
                subtitle: Text(dndStatus),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
