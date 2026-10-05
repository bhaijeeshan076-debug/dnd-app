import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_dnd/flutter_dnd.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Masjid Auto Mute',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      home: const MasjidGeofenceScreen(),
    );
  }
}

class MasjidGeofenceScreen extends StatefulWidget {
  const MasjidGeofenceScreen({super.key});

  @override
  State<MasjidGeofenceScreen> createState() => _MasjidGeofenceScreenState();
}

class _MasjidGeofenceScreenState extends State<MasjidGeofenceScreen> {
  bool isAutoMuteActive = true;
  String statusMessage = "Checking Location...";
  bool isInsideMasjid = false;

  // Set your Masjid Coordinates & Radius (In Meters)
  final double masjidLat = 19.0419; 
  final double masjidLng = 72.8502;
  final double radiusInMeters = 50.0; // 50 Meters Boundary

  @override
  void initState() {
    super.initState();
    _requestPermissionsInApp();
  }

  // Requests location and DND permissions inside the app without going to settings manually
  Future<void> _requestPermissionsInApp() async {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.location,
      Permission.locationAlways,
    ].request();

    bool? isNotificationPolicyGranted = await FlutterDnd.isNotificationPolicyAccessGranted;
    if (isNotificationPolicyGranted == false) {
      // In-app prompt for DND Access
      FlutterDnd.gotoPolicyAccessSettings();
    }

    _startLiveLocationTracking();
  }

  void _startLiveLocationTracking() {
    Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5, // Triggers when user moves 5 meters
      ),
    ).listen((Position position) {
      double distance = Geolocator.distanceBetween(
        position.latitude,
        position.longitude,
        masjidLat,
        masjidLng,
      );

      if (distance <= radiusInMeters) {
        _setPhoneSilent(true);
        setState(() {
          isInsideMasjid = true;
          statusMessage = "Inside Masjid Range (${distance.toInt()}m away)\nPhone Muted Automatically!";
        });
      } else {
        _setPhoneSilent(false);
        setState(() {
          isInsideMasjid = false;
          statusMessage = "Outside Masjid Range (${distance.toInt()}m away)\nPhone Ringer Normal";
        });
      }
    });
  }

  Future<void> _setPhoneSilent(bool silent) async {
    if (await FlutterDnd.isNotificationPolicyAccessGranted ?? false) {
      if (silent) {
        await FlutterDnd.setInterruptionFilter(FlutterDnd.INTERRUPTION_FILTER_NONE);
      } else {
        await FlutterDnd.setInterruptionFilter(FlutterDnd.INTERRUPTION_FILTER_ALL);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Masjid Auto Silent'),
        backgroundColor: Colors.teal.shade100,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Card(
              elevation: 3,
              child: SwitchListTile(
                title: const Text('Masjid Auto Mute Service',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text('Auto-mutes when inside Masjid boundary'),
                value: isAutoMuteActive,
                onChanged: (val) => setState(() => isAutoMuteActive = val),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              elevation: 3,
              color: isInsideMasjid ? Colors.red.shade50 : Colors.green.shade50,
              child: ListTile(
                leading: Icon(
                  isInsideMasjid ? Icons.volume_off : Icons.volume_up,
                  color: isInsideMasjid ? Colors.red : Colors.green,
                  size: 32,
                ),
                title: Text(
                  isInsideMasjid ? "Status: SILENT MODE" : "Status: NORMAL MODE",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(statusMessage),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _requestPermissionsInApp,
              icon: const Icon(Icons.security),
              label: const Text('Allow All Permissions In-App'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                foregroundColor: Colors.white,
              ),
            )
          ],
        ),
      ),
    );
  }
}
