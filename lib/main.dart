import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

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
      theme: ThemeData(primarySwatch: Colors.teal),
      home: const PermissionScreen(),
    );
  }
}

class PermissionScreen extends StatefulWidget {
  const PermissionScreen({super.key});

  @override
  State<PermissionScreen> createState() => _PermissionScreenState();
}

class _PermissionScreenState extends State<PermissionScreen> {
  bool _isGranted = false;

  Future<void> _requestPermissions() async {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.location,
      Permission.locationAlways,
      Permission.accessNotificationPolicy,
    ].request();

    if (statuses[Permission.accessNotificationPolicy]?.isGranted == false) {
      await openAppSettings();
    }

    setState(() {
      _isGranted = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Masjid Auto Silent'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(
              _isGranted ? Icons.check_circle_outline : Icons.security,
              size: 100,
              color: _isGranted ? Colors.green : Colors.teal,
            ),
            const SizedBox(height: 24),
            Text(
              _isGranted
                  ? "App Automatic Activated!"
                  : "Automatic Silent Chalu Karne Ke Liye Niche Button Par Click Karein",
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              _isGranted
                  ? "Ab Masjid me aate hi aapka phone auto silent ho jayega."
                  : "Isse app ko Location aur Silent mode control karne ki permission mil jayegi.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey[700]),
            ),
            const SizedBox(height: 36),
            if (!_isGranted)
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.vertical(16),
                  backgroundColor: Colors.teal,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: _requestPermissions,
                child: const Text(
                  "ALLOW & ACTIVATE NOW",
                  style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
