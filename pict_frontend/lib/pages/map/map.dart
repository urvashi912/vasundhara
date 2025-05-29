// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:mongo_dart/mongo_dart.dart';

void main() async {
  await dotenv.load(fileName: ".env");
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Garbage Complaint Map',
      theme: ThemeData(
        primarySwatch: Colors.green,
      ),
      home: const MapScreen(),
    );
  }
}

class MapScreen extends StatefulWidget {
  const MapScreen({Key? key}) : super(key: key);

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  late GoogleMapController mapController;
  Set<Marker> markers = {};
  bool isLoading = true;

  final LatLng _center = const LatLng(20.5937, 78.9629); // India center

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
    _loadComplaints();
  }

  Future<void> _loadComplaints() async {
    try {
      final db = await Db.create(dotenv.env['MONGODB_URI']!);
      await db.open();

      final collection = db.collection('complaints');
      final complaints = await collection.find().toList();

      setState(() {
        markers = complaints.map((complaint) {
          return Marker(
            markerId: MarkerId(complaint['_id'].toString()),
            position: LatLng(
              complaint['location']['coordinates'][1],
              complaint['location']['coordinates'][0],
            ),
            infoWindow: InfoWindow(
              title: 'Complaint #${complaint['_id']}',
              snippet: complaint['description'] ?? 'No description',
            ),
          );
        }).toSet();
        isLoading = false;
      });

      await db.close();
    } catch (e) {
      print('Error loading complaints: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Garbage Complaints Map'),
      ),
      body: Stack(
        children: [
          GoogleMap(
            onMapCreated: _onMapCreated,
            initialCameraPosition: CameraPosition(
              target: _center,
              zoom: 5,
            ),
            markers: markers,
          ),
          if (isLoading)
            const Center(
              child: CircularProgressIndicator(),
            ),
        ],
      ),
    );
  }
}