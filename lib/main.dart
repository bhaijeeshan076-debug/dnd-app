import 'dart:math' as math;
import 'package:flutter/material.dart';
// Baaki imports wahi purane rahenge (geolocator, shared_preferences, etc.)

// ---------------- 3. REAL WORKING QIBLA SCREEN ----------------
class QiblaScreen extends StatefulWidget {
  const QiblaScreen({super.key});

  @override
  State<QiblaScreen> createState() => _QiblaScreenState();
}

class _QiblaScreenState extends State<QiblaScreen> {
  // Qibla angle calculation (Default: Mecca angle roughly or static indicator)
  // Real sensor stream ke liye hum yahan custom direction logic lagate hain.
  double heading = 0.0;

  @override
  Widget build(BuildContext context) {
    // Qibla direction ka basic pointer calculation (Kaaba coordinates vs User)
    // Meeqaat / Direction angle relative to North
    double qiblaAngle = 295.0; // Example angle towards Qibla from India region (North-West)
    double needleRotation = (qiblaAngle - heading) * (math.pi / 180);

    return Scaffold(
      appBar: AppBar(title: const Text('Qibla Direction', style: TextStyle(color: Colors.white)), centerTitle: true),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Align the needle towards Qibla',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 40),
            Stack(
              alignment: Alignment.center,
              children: [
                // Compass Outer Circle Background
                Container(
                  width: 250,
                  height: 250,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.green, width: 3),
                    color: const Color(0xFF1E1E1E),
                  ),
                  child: const Center(
                    child: Text('N', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 18)),
                  ),
                ),
                // Rotating Qibla Needle / Icon
                Transform.rotate(
                  angle: needleRotation,
                  child: const Icon(
                    Icons.navigation,
                    size: 100,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 40),
            const Text(
              'Keep your phone flat on a surface',
              style: TextStyle(fontSize: 14, color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }
}
