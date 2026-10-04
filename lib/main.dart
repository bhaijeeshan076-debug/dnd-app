import 'package:flutter/material.dart';

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
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.add_location_alt),
                label: const Text('Add New Geofence Zone'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
