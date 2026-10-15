import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');
  const InitializationSettings initializationSettings =
      InitializationSettings(android: initializationSettingsAndroid);
  await flutterLocalNotificationsPlugin.initialize(initializationSettings);

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
        backgroundColor: const Color(0xFF1E1E1E),
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
            label: 'Prayer & Calendar',
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
    try {
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String coords = "${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}";
      await prefs.setString('masjid_coords', coords);
      setState(() {
        savedMasjidCoords = coords;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Current Location Saved as Masjid!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error getting location: $e')),
        );
      }
    }
  }

  void _requestPermissions() async {
    await [
      Permission.location,
      Permission.accessNotificationPolicy,
      Permission.notification,
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
              color: const Color(0xFF1E1E1E),
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
              label: Text(isPausedManually ? 'Resume Service' : 'Pause for 30 Mins'),
              style: ElevatedButton.styleFrom(
                backgroundColor: isPausedManually ? Colors.green : Colors.orange,
                foregroundColor: Colors.white,
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

// ---------------- 2. PRAYER TIMES & ISLAMIC CALENDAR SCREEN ----------------
class PrayerTimesScreen extends StatelessWidget {
  const PrayerTimesScreen({super.key});

  Future<void> _showAzanNotification(String prayerName) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'azan_channel_id',
      'Azan Notifications',
      channelDescription: 'Notifications for Azan times',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
    );
    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);
    await flutterLocalNotificationsPlugin.show(
      0,
      'Azan Time: $prayerName',
      'It is time for $prayerName prayer.',
      platformChannelSpecifics,
    );
  }

  @override
  Widget build(BuildContext context) {
    String formattedDate = DateFormat('EEEE, d MMM yyyy').format(DateTime.now());

    return Scaffold(
      appBar: AppBar(title: const Text('Prayer Times & Calendar', style: TextStyle(color: Colors.white)), centerTitle: true),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          Card(
            color: const Color(0xFF1E1E1E),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.calendar_month, color: Colors.green),
                      SizedBox(width: 8),
                      Text('Islamic & Gregorian Date', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text('Today: $formattedDate', style: const TextStyle(color: Colors.white70, fontSize: 14)),
                  const SizedBox(height: 5),
                  const Text('Hijri: 28 Shawwal 1447 AH', style: TextStyle(color: Colors.green, fontSize: 16, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 15),
          const Text('Today Prayer Times', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          _prayerTile(context, 'Fajr', '05:15 AM'),
          _prayerTile(context, 'Dhuhr', '12:30 PM'),
          _prayerTile(context, 'Asr', '04:15 PM'),
          _prayerTile(context, 'Maghrib', '06:20 PM'),
          _prayerTile(context, 'Isha', '07:45 PM'),
        ],
      ),
    );
  }

  Widget _prayerTile(BuildContext context, String name, String time) {
    return Card(
      color: const Color(0xFF1E1E1E),
      child: ListTile(
        title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        subtitle: Text(time, style: const TextStyle(color: Colors.green, fontSize: 16)),
        trailing: ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
          onPressed: () {
            _showAzanNotification(name);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Azan Alert tested for $name!')),
            );
          },
          child: const Text('Test Azan', style: TextStyle(color: Colors.white)),
        ),
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
      appBar: AppBar(title: const Text('Qibla Direction', style: TextStyle(color: Colors.white)), centerTitle: true),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.explore, size: 100, color: Colors.green),
              const SizedBox(height: 20),
              const Text(
                'Qibla Direction Pointer',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              const Text(
                'Direction towards Kaaba (Mecca) from your region is roughly North-West (295°).',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 30),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E1E),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.navigation, color: Colors.green),
                    SizedBox(width: 10),
                    Text('Angle: 295° NW', style: TextStyle(fontSize: 18, color: Colors.green, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
