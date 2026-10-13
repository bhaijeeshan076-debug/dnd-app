import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:adhan/adhan.dart';
import 'package:intl/intl.dart';

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
      theme: ThemeData.dark().copyWith(
        primaryColor: Colors.green,
        scaffoldBackgroundColor: const Color(0xFF121212),
        appBarTheme: const AppBarTheme(backgroundColor: Colors.green),
      ),
      home: const MainNavigationScreen(),
    );
  }
}

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    const PrayerTimesScreen(),
    const QiblaScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: Colors.green,
        unselectedItemColor: Colors.grey,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.location_on),
            label: 'Auto Silent',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.access_time),
            label: 'Prayer Times',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.explore),
            label: 'Qibla',
          ),
        ],
      ),
    );
  }
}

// ---------------- 1. AUTO SILENT SCREEN ----------------
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool isServiceActive = true;
  bool isPausedManually = false;
  double radiusMeters = 50.0;
  String savedMasjidCoords = "No Location Saved";

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _requestPermissions();
  }

  _loadSettings() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      radiusMeters = prefs.getDouble('radius') ?? 50.0;
      savedMasjidCoords = prefs.getString('masjid_coords') ?? "No Location Saved";
    });
  }

  _saveRadius(double value) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('radius', value);
    setState(() {
      radiusMeters = value;
    });
  }

  _saveCurrentLocationAsMasjid() async {
    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String coords = "${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}";
    await prefs.setString('masjid_coords', coords);
    setState(() {
      savedMasjidCoords = coords;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Current Location Saved as Masjid!')),
    );
  }

  void _requestPermissions() async {
    await [
      Permission.location,
      Permission.locationAlways,
      Permission.accessNotificationPolicy,
    ].request();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Masjid Auto Silent'), centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Icon(
              isPausedManually ? Icons.pause_circle_filled : Icons.check_circle,
              size: 80,
              color: isPausedManually ? Colors.orange : Colors.green,
            ),
            const SizedBox(height: 10),
            Text(
              isPausedManually ? 'Service Paused' : 'Auto Silent Active',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Card(
              color: Colors.grey[900],
              child: ListTile(
                leading: const Icon(Icons.mosque, color: Colors.green),
                title: const Text('Saved Masjid Location'),
                subtitle: Text(savedMasjidCoords),
                trailing: IconButton(
                  icon: const Icon(Icons.my_location, color: Colors.green),
                  onPressed: _saveCurrentLocationAsMasjid,
                ),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  isPausedManually = !isPausedManually;
                });
              },
              icon: Icon(isPausedManually ? Icons.play_arrow : Icons.pause),
              label: Text(isPausedManually ? 'Resume' : 'Pause 30 Mins'),
              style: ElevatedButton.styleFrom(
                backgroundColor: isPausedManually ? Colors.green : Colors.orange,
              ),
            ),
            const SizedBox(height: 30),
            const Text('Set Masjid Detection Radius:'),
            Slider(
              value: radiusMeters,
              min: 20,
              max: 200,
              divisions: 9,
              label: '${radiusMeters.toInt()} meters',
              onChanged: (value) => _saveRadius(value),
            ),
            Text('${radiusMeters.toInt()} Meters', style: const TextStyle(color: Colors.green)),
          ],
        ),
      ),
    );
  }
}

// ---------------- 2. PRAYER TIMES SCREEN ----------------
class PrayerTimesScreen extends StatelessWidget {
  const PrayerTimesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final myCoordinates = Coordinates(19.0760, 72.8777); // Default Coordinates
    final params = CalculationMethod.karachi.getParameters();
    final prayerTimes = PrayerTimes.today(myCoordinates, params);

    return Scaffold(
      appBar: AppBar(title: const Text('Today Prayer Times'), centerTitle: true),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _prayerTile('Fajr', DateFormat.jm().format(prayerTimes.fajr)),
          _prayerTile('Dhuhr', DateFormat.jm().format(prayerTimes.dhuhr)),
          _prayerTile('Asr', DateFormat.jm().format(prayerTimes.asr)),
          _prayerTile('Maghrib', DateFormat.jm().format(prayerTimes.maghrib)),
          _prayerTile('Isha', DateFormat.jm().format(prayerTimes.isha)),
        ],
      ),
    );
  }

  Widget _prayerTile(String name, String time) {
    return Card(
      color: Colors.grey[900],
      child: ListTile(
        title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
        trailing: Text(time, style: const TextStyle(color: Colors.green, fontSize: 16)),
      ),
    );
  }
}

// ---------------- 3. QIBLA SCREEN ----------------
class QiblaScreen extends StatelessWidget {
  const QiblaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Qibla Direction'), centerTitle: true),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.explore, size: 120, color: Colors.green),
            SizedBox(height: 20),
            Text('Point your phone towards Qibla', style: TextStyle(fontSize: 16)),
          ],
        ),
      ),
    );
  }
}
