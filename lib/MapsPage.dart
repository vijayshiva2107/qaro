import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_places_flutter/google_places_flutter.dart';
import 'car_service2.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MapsPage extends StatefulWidget {
  final double latitude;
  final double longitude;
  const MapsPage({
    super.key,
    required this.latitude,
    required this.longitude,
  });

  @override
  State<MapsPage> createState() => _MapsPageState();
}

class _MapsPageState extends State<MapsPage> {
  late LatLng selectedLocation;
  GoogleMapController? _mapController;
  final TextEditingController _searchController = TextEditingController();
  final User? user = FirebaseAuth.instance.currentUser;
  // 🔥 Replace with your API Key
  final String googleApiKey = "AIzaSyAv0t-9OyNyLeu6TuCXAfdVMnMdpY2P5So";

  @override
  void initState() {
    super.initState();
    selectedLocation = LatLng(widget.latitude, widget.longitude);
  }
  Future<String> getServiceType() async {
  final doc = await FirebaseFirestore.instance
      .collection('merchants')
      .doc(user!.uid)
      .get();

  if (doc.exists) {
    return doc.data()?['serviceProvides'] ?? 'Unknown';
  } else {
    return 'Unknown';
  }
}
  void _moveCamera(double lat, double lng) {
    _mapController?.animateCamera(
      CameraUpdate.newLatLng(
        LatLng(lat, lng),
      ),
    );
    
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Select Repair Location"),
        backgroundColor: Colors.black,
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: selectedLocation,
              zoom: 15,
            ),
            onMapCreated: (controller) {
              _mapController = controller;
            },
            markers: {
              Marker(
                markerId: const MarkerId("selected_location"),
                position: selectedLocation,
                draggable: true,
                onDragEnd: (newPosition) {
                  setState(() {
                    selectedLocation = newPosition;
                  });
                },
              ),
            },
            onTap: (LatLng position) {
              setState(() {
                selectedLocation = position;
              });
            },
          ),

          // 🔍 SEARCH BAR
          Positioned(
            top: 10,
            left: 15,
            right: 15,
            child: GooglePlaceAutoCompleteTextField(
              textEditingController: _searchController,
              googleAPIKey: googleApiKey,
              inputDecoration: InputDecoration(
                hintText: "Search location...",
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              debounceTime: 600,
              isLatLngRequired: true,
              getPlaceDetailWithLatLng: (prediction) {
                double lat = double.parse(prediction.lat!);
                double lng = double.parse(prediction.lng!);

                setState(() {
                  selectedLocation = LatLng(lat, lng);
                });

                _moveCamera(lat, lng);
              },
              itemClick: (prediction) {
                _searchController.text = prediction.description!;
                _searchController.selection =
                    TextSelection.fromPosition(
                      TextPosition(offset: prediction.description!.length),
                    );
              },
            ),
          ),

          // 🔘 CONTINUE BUTTON
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 18),
              ),
              onPressed: () async {
                String serviceType = await getServiceType();
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CarService2(
                      serviceType: serviceType,
                      latitude: selectedLocation.latitude,
                      longitude: selectedLocation.longitude,
                    ),
                  ),
                );
              },
              child: const Text(
                "Continue",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}