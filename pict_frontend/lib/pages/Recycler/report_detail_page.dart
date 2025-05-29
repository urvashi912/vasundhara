import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class ReportDetailPage extends StatelessWidget {
  final Map report;

  const ReportDetailPage({required this.report, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Convert the lat and lon to double
    final LatLng reportLocation = LatLng(
      double.parse(report['location']['lat'].toString()),
      double.parse(report['location']['lon'].toString()),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Report Details'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  report['description'] ?? 'No Description',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 10),
                Text(
                  report['location']['formattedAddress'] ?? 'No Address',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
          ),
          Expanded(
            child: GoogleMap(
              initialCameraPosition: CameraPosition(
                target: reportLocation,
                zoom: 14.0,
              ),
              markers: {
                Marker(
                  markerId: MarkerId(report['id'].toString()),
                  position: reportLocation,
                  infoWindow: InfoWindow(
                    title: report['description'],
                  ),
                ),
              },
            ),
          ),
        ],
      ),
    );
  }
}