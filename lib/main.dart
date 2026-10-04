
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
  String locationStatus = "Checking location permission...";
  String dndPermissionStatus = "Permission not granted";

  @override
  void initState() {
    super.initState();
    _requestPermissions();
  }

  Future<void> _requestPermissions() async {
    // Request Location Permission
    LocationPermission permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always) {
      Position position = await Geolocator.getCurrentPosition();
      setState(() {
        locationStatus = "Current Loc: ${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}";
      });
    } else {
      setState(() {
        locationStatus = "Location Permission Denied";
      });
    }

    // Check DND Policy Access Permission
    if (await Permission.accessNotificationPolicy.isGranted) {
      setState(() {
        dndPermissionStatus = "DND Permission Granted";
      });
    } else {
      setState(() {
        dndPermissionStatus = "DND Permission Required";
      });
    }
  }

  Future<void> _openDndSettings() async {
    await Permission.accessNotificationPolicy.request();
    _requestPermissions();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Location DND Service'),
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
                      'Geofence DND Active',
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
                leading: const Icon(Icons.my_location, color: Colors.deepPurple),
                title: const Text('Live GPS Status'),
                subtitle: Text(locationStatus),
              ),
            ),
            const SizedBox(height: 10),
            Card(
              color: Colors.orange.shade50,
              child: ListTile(
                leading: const Icon(Icons.do_not_disturb_on, color: Colors.orange),
                title: const Text('System DND Permission'),
                subtitle: Text(dndPermissionStatus),
                trailing: TextButton(
                  onPressed: _openDndSettings,
                  child: const Text('Allow'),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Active Fence Radius:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const Card(
              child: ListTile(
                leading: Icon(Icons.location_on, color: Colors.deepPurple),
                title: Text('Office Zone'),
                subtitle: Text('Radius: 200m | Silences calls & WhatsApp'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
