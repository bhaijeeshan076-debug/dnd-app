import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:geolocator/geolocator.dart';

void main() {
  runApp(const DndGeofenceApp());
}

class DndGeofenceApp extends StatelessWidget {
  const DndGeofenceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Geofence DND',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
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
  bool isDndEnabled = true;
  String locationStatus = "Fetching live GPS location...";
  String dndPermissionStatus = "Checking DND status...";

  @override
  void initState() {
    super.initState();
    _requestAndFetchLocation();
  }

  Future<void> _requestAndFetchLocation() async {
    // Request Location Permission & Get Live Coordinates
    LocationPermission permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always) {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      setState(() {
        locationStatus =
            "Lat: ${position.latitude.toStringAsFixed(4)}, Long: ${position.longitude.toStringAsFixed(4)}";
      });
    } else {
      setState(() {
        locationStatus = "Location Access Denied";
      });
    }

    // Check System DND Permission
    if (await Permission.accessNotificationPolicy.isGranted) {
      setState(() {
        dndPermissionStatus = "DND Control Granted (Active)";
      });
    } else {
      setState(() {
        dndPermissionStatus = "DND Permission Required";
      });
    }
  }

  Future<void> _openDndSettings() async {
    await Permission.accessNotificationPolicy.request();
    _requestAndFetchLocation();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Geofence DND'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Geofence Auto Mute',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    Switch(
                      value: isDndEnabled,
                      onChanged: (val) {
                        setState(() {
                          isDndEnabled = val;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 15),
            Card(
              color: Colors.deepPurple.shade50,
              child: ListTile(
                leading: const Icon(Icons.gps_fixed, color: Colors.deepPurple),
                title: const Text('Live GPS Location'),
                subtitle: Text(locationStatus),
                trailing: IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: _requestAndFetchLocation,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Card(
              color: Colors.orange.shade50,
              child: ListTile(
                leading: const Icon(Icons.do_not_disturb_on, color: Colors.orange),
                title: const Text('System DND Access'),
                subtitle: Text(dndPermissionStatus),
                trailing: TextButton(
                  onPressed: _openDndSettings,
                  child: const Text('Grant Access'),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Active Geofence Radius:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const Card(
              child: ListTile(
                leading: Icon(Icons.location_on, color: Colors.deepPurple),
                title: Text('Current Boundary'),
                subtitle: Text('200m Radius | Auto-silences Calls & Notifications'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
