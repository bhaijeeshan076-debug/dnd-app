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
      title: 'Masjid Auto Silent',
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
  String statusMessage = "Location Check Ho Rahi Hai...";
  bool isInsideMasjid = false;

  // Masjid Lat/Lng & Radius (In Meters)
  final double masjidLat = 19.0419; 
  final double masjidLng = 72.8502;
  final double radiusInMeters = 50.0; 

  @override
  void initState() {
    super.initState();
    _checkLocationAndPermissions();
  }

  Future<void> _checkLocationAndPermissions() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() => statusMessage = "Kripya GPS Location Turn ON Karein");
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() => statusMessage = "Location Permission Denied");
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      setState(() => statusMessage = "Location Permission Denied Permanently");
      return;
    }

    _startLiveTracking();
  }

  void _startLiveTracking() {
    Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 3, 
      ),
    ).listen((Position position) {
      if (!isAutoMuteActive) return;

      double distance = Geolocator.distanceBetween(
        position.latitude,
        position.longitude,
        masjidLat,
        masjidLng,
      );

      if (distance <= radiusInMeters) {
        setState(() {
          isInsideMasjid = true;
          statusMessage = "Aap Masjid Ke Andar Hain (${distance.toInt()}m door)\nPhone SILENT / VIBRATE Zone";
        });
      } else {
        setState(() {
          isInsideMasjid = false;
          statusMessage = "Aap Masjid Se Bahar Hain (${distance.toInt()}m door)\nPhone NORMAL Ringer Zone";
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Masjid Auto Silent / Mute'),
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
                subtitle: const Text('Masjid me aate hi auto silent karega'),
                value: isAutoMuteActive,
                onChanged: (val) {
                  setState(() {
                    isAutoMuteActive = val;
                    if (!val) {
                      statusMessage = "Auto Mute Service Paused";
                      isInsideMasjid = false;
                    }
                  });
                },
              ),
            ),
            const SizedBox(height: 16),
            Card(
              elevation: 4,
              color: isInsideMasjid ? Colors.red.shade50 : Colors.green.shade50,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: ListTile(
                  leading: Icon(
                    isInsideMasjid ? Icons.volume_off : Icons.volume_up,
                    color: isInsideMasjid ? Colors.red : Colors.green,
                    size: 40,
                  ),
                  title: Text(
                    isInsideMasjid ? "MODE: SILENT / VIBRATE" : "MODE: NORMAL RINGER",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isInsideMasjid ? Colors.red.shade900 : Colors.green.shade900,
                    ),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      statusMessage,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
