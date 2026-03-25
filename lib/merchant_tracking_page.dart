// lib/merchant_tracking_page.dart
import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class MerchantTrackingPage extends StatefulWidget {
  final String bookingId;
  final String mechanicId;

  const MerchantTrackingPage({super.key, required this.bookingId, required this.mechanicId});

  @override
  State<MerchantTrackingPage> createState() => _MerchantTrackingPageState();
}

class _MerchantTrackingPageState extends State<MerchantTrackingPage> {
  // State variables
  String? serviceType;
  String? carModel;
  String userPhone = "";
  
  LatLng? userLocation;
  LatLng? mechanicLocation;

  // Tracking details
  double distanceKm = 0;
  double etaMinutes = 0;

  // Streams
  StreamSubscription<DocumentSnapshot>? _bookingSubscription;
  StreamSubscription<Position>? _mechanicLocationStream;

  // Map variables
  GoogleMapController? mapController;
  List<LatLng> routePoints = [];
  Set<Polyline> polylines = {};
  Set<Marker> markers = {};
  LatLng? previousLocation;
  LatLng? lastRouteLocation;

  // OSRM Public Server Base
  final String osrmBase = 'https://router.project-osrm.org';
  final int routeFetchIntervalSeconds = 8;
  DateTime? _lastRouteFetchTime;

  @override
  void initState() {
    super.initState();
    _startTracking();
  }

  @override
  void dispose() {
    _bookingSubscription?.cancel();
    _mechanicLocationStream?.cancel();
    super.dispose();
  }

  void _updateMarkers() {
    if (!mounted) return;
    final Set<Marker> newMarkers = {};
    
    if (userLocation != null) {
      newMarkers.add(Marker(
        markerId: const MarkerId('userLoc'),
        position: userLocation!,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        infoWindow: const InfoWindow(title: 'Client Location'),
      ));
    }

    if (mechanicLocation != null) {
      newMarkers.add(Marker(
        markerId: const MarkerId('mechLoc'),
        position: mechanicLocation!,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        infoWindow: const InfoWindow(title: 'You'),
      ));
    }
    
    setState(() {
      markers = newMarkers;
    });
  }

  void _startTracking() {
    // 1. Listen to the Booking Document for User Details
    _bookingSubscription = FirebaseFirestore.instance
        .collection('bookings')
        .doc(widget.bookingId)
        .snapshots()
        .listen((bookingSnapshot) {
      if (!bookingSnapshot.exists || bookingSnapshot.data() == null) return;
      
      final data = bookingSnapshot.data() as Map<String, dynamic>;
      
      if (mounted) {
        setState(() {
          serviceType = data['serviceType'] ?? "";
          carModel = data['carModel'] ?? "";
          if (data['contactNumber'] != null) userPhone = data['contactNumber'];
          
          if (data['location'] != null) {
            GeoPoint geo = data['location'];
            userLocation = LatLng(geo.latitude, geo.longitude);
            _updateMarkers();
          }
        });
      }
    });

    // 2. Listen to Mechanic Location natively via GPS instead of waiting for Firestore
    _listenToMechanicLocation();
  }

  void _listenToMechanicLocation() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    
    if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
      return;
    }

    _mechanicLocationStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5,
      ),
    ).listen((Position position) {
      LatLng newLoc = LatLng(position.latitude, position.longitude);
      _handleMechanicLocationUpdate(newLoc);

      // Write to Firestore so the client can track the mechanic
      FirebaseFirestore.instance
          .collection('merchants')
          .doc(widget.mechanicId)
          .update({
        "location": GeoPoint(position.latitude, position.longitude)
      });
    });
  }

  Future<void> _handleMechanicLocationUpdate(LatLng newLoc) async {
    if (mechanicLocation == null) {
      if (mounted) {
        setState(() {
          mechanicLocation = newLoc;
          previousLocation = newLoc;
          lastRouteLocation = newLoc;
        });
      }
      
      _updateMarkers();
      _calculateDistanceFallback();
      await _getRouteFromOSRM();
      _fitMapToBothPoints();
      return;
    }

    if (newLoc.latitude == mechanicLocation!.latitude &&
        newLoc.longitude == mechanicLocation!.longitude) {
      return;
    }

    await _animateMarker(newLoc);

    if (lastRouteLocation != null && userLocation != null) {
      double movedDistance = Geolocator.distanceBetween(
        lastRouteLocation!.latitude,
        lastRouteLocation!.longitude,
        newLoc.latitude,
        newLoc.longitude,
      );

      if (movedDistance > 20) {
        lastRouteLocation = newLoc;
        await _getRouteFromOSRM();
      }
    }
  }

  void _calculateDistanceFallback() {
    if (userLocation == null || mechanicLocation == null) return;
    double meters = Geolocator.distanceBetween(
      userLocation!.latitude,
      userLocation!.longitude,
      mechanicLocation!.latitude,
      mechanicLocation!.longitude,
    );
    if (mounted) {
      setState(() {
        distanceKm = meters / 1000;
        etaMinutes = (distanceKm / 30) * 60; // 30 km/h avg speed fallback
      });
    }
  }

  Future<void> _animateMarker(LatLng newPosition) async {
    if (previousLocation == null) {
      previousLocation = newPosition;
      mechanicLocation = newPosition;
      _updateMarkers();
      return;
    }

    const int steps = 20;
    for (int i = 1; i <= steps; i++) {
      if (!mounted) return;
      
      double lat = previousLocation!.latitude +
          (newPosition.latitude - previousLocation!.latitude) * (i / steps);
      double lng = previousLocation!.longitude +
          (newPosition.longitude - previousLocation!.longitude) * (i / steps);
          
      mechanicLocation = LatLng(lat, lng);
      _updateMarkers();
      
      try {
         mapController?.moveCamera(CameraUpdate.newLatLng(mechanicLocation!));
      } catch (_) {}

      await Future.delayed(const Duration(milliseconds: 30));
    }
    previousLocation = newPosition;
  }

  Future<void> _getRouteFromOSRM() async {
    if (userLocation == null || mechanicLocation == null) return;

    if (_lastRouteFetchTime != null) {
      final diff = DateTime.now().difference(_lastRouteFetchTime!);
      if (diff.inSeconds < routeFetchIntervalSeconds) return;
    }
    _lastRouteFetchTime = DateTime.now();

    final origin = '${mechanicLocation!.longitude},${mechanicLocation!.latitude}';
    final destination = '${userLocation!.longitude},${userLocation!.latitude}';

    final url = Uri.parse(
        '$osrmBase/route/v1/driving/$origin;$destination?overview=full&geometries=polyline&steps=false');

    try {
      final resp = await http.get(url);
      if (resp.statusCode != 200) return;

      final data = json.decode(resp.body);
      if (data['code']?.toLowerCase() != 'ok') return;

      final routes = data['routes'] as List<dynamic>? ?? [];
      if (routes.isEmpty) return;

      final route = routes[0];
      final num? routeDuration = route['duration'];
      final num? routeDistance = route['distance'];

      if (mounted) {
        setState(() {
          if (routeDuration != null) etaMinutes = routeDuration / 60.0;
          if (routeDistance != null) distanceKm = routeDistance / 1000.0;
        });
      }

      final String? geometry = route['geometry'];
      if (geometry != null && geometry.isNotEmpty) {
        final decoded = _decodePolyline(geometry, precision: 5);
        if (mounted) {
          setState(() {
            routePoints = decoded;
            polylines = {
              Polyline(
                polylineId: const PolylineId('route'),
                points: routePoints,
                color: Colors.blueAccent,
                width: 5,
              ),
            };
          });
        }
        _fitMapToRoute();
      }
    } catch (e) {
      debugPrint('OSRM exception: $e');
    }
  }

  void _fitMapToRoute() {
    if (routePoints.isNotEmpty && mapController != null) {
      try {
        LatLngBounds bounds = _boundsFromLatLngList(routePoints);
        mapController!.animateCamera(CameraUpdate.newLatLngBounds(bounds, 50.0));
      } catch (_) {}
    }
  }

  void _fitMapToBothPoints() {
    if (userLocation != null && mechanicLocation != null && mapController != null) {
      try {
        LatLngBounds bounds = _boundsFromLatLngList([userLocation!, mechanicLocation!]);
        mapController!.animateCamera(CameraUpdate.newLatLngBounds(bounds, 60.0));
      } catch (_) {}
    }
  }

  List<LatLng> _decodePolyline(String encoded, {int precision = 5}) {
    List<LatLng> poly = [];
    int index = 0, len = encoded.length;
    int lat = 0, lng = 0;
    final int factor = _pow10(precision);

    while (index < len) {
      int b, shift = 0, result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = ((result & 1) != 0) ? ~(result >> 1) : (result >> 1);
      lat += dlat;

      shift = 0; result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = ((result & 1) != 0) ? ~(result >> 1) : (result >> 1);
      lng += dlng;

      poly.add(LatLng(lat / factor, lng / factor));
    }
    return poly;
  }

  int _pow10(int n) {
    int r = 1;
    for (int i = 0; i < n; i++) r *= 10;
    return r;
  }

  LatLngBounds _boundsFromLatLngList(List<LatLng> list) {
    if (list.isEmpty) throw Exception("List is empty");
    double minLat = list.first.latitude, maxLat = minLat;
    double minLng = list.first.longitude, maxLng = minLng;

    for (final p in list.skip(1)) {
      if (p.latitude < minLat) minLat = p.latitude;
      if (p.latitude > maxLat) maxLat = p.latitude;
      if (p.longitude < minLng) minLng = p.longitude;
      if (p.longitude > maxLng) maxLng = p.longitude;
    }
    return LatLngBounds(
        southwest: LatLng(minLat, minLng), northeast: LatLng(maxLat, maxLng));
  }

  void _finishJob() async {
    bool confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Finish Job?"),
        content: const Text("Have you arrived and completed the service?"),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false), 
            child: const Text("No", style: TextStyle(color: Colors.black))
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true), 
            child: const Text("Yes, Complete", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold))
          ),
        ],
      ),
    ) ?? false;

    if (confirm) {
      await FirebaseFirestore.instance.collection('bookings').doc(widget.bookingId).update({
        'status': 'Completed'
      });
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Job Marked as Completed!"),
          backgroundColor: Colors.green,
        ));
      }
    }
  }

  void _cancelRide() async {
    bool confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Cancel Ride?"),
        content: const Text("Are you sure you want to cancel this booking? The user will be notified immediately."),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false), 
            child: const Text("No, Keep Ride", style: TextStyle(color: Colors.black))
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true), 
            child: const Text("Yes, Cancel", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold))
          ),
        ],
      ),
    ) ?? false;

    if (confirm) {
      await FirebaseFirestore.instance.collection('bookings').doc(widget.bookingId).update({
        'status': 'Cancelled'
      });
      if (mounted) {
        Navigator.pop(context); // Go back to Home
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Ride Cancelled Successfully."),
          backgroundColor: Colors.redAccent,
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          "NAVIGATING TO CLIENT",
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            letterSpacing: 2,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: mechanicLocation == null || userLocation == null
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Colors.black),
                  SizedBox(height: 15),
                  Text(
                    "Locating User...",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            )
          : Stack(
              children: [
                Positioned.fill(
                  child: GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: mechanicLocation ?? userLocation ?? const LatLng(0, 0),
                      zoom: 15.0,
                    ),
                    myLocationEnabled: true,
                    polylines: polylines,
                    markers: markers,
                    onMapCreated: (GoogleMapController controller) {
                      mapController = controller;
                      _fitMapToBothPoints();
                    },
                  ),
                ),

                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(30),
                        topRight: Radius.circular(30),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 20,
                          offset: Offset(0, -5),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 40,
                          height: 5,
                          margin: const EdgeInsets.only(bottom: 20),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.person, size: 40, color: Colors.black),
                            ),
                            const SizedBox(width: 20),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    "Client Request",
                                    style: TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const SizedBox(height: 5),
                                  Text(
                                    "Service: ${serviceType ?? 'General'} • ${carModel ?? 'Unknown Car'}",
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 25),
                        
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildStatCard("ETA", "${etaMinutes.toStringAsFixed(0)} min", Icons.timer),
                            _buildStatCard("DISTANCE", "${distanceKm.toStringAsFixed(1)} km", Icons.route),
                          ],
                        ),
                        
                        const SizedBox(height: 20),
                        Divider(color: Colors.grey.shade300),
                        const SizedBox(height: 15),
                        
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildActionButton(
                              icon: Icons.call, 
                              label: "Call", 
                              color: Colors.green, 
                              onTap: () async {
                                if (userPhone.isNotEmpty) {
                                  final Uri launchUri = Uri(
                                    scheme: 'tel',
                                    path: userPhone,
                                  );
                                  if (await canLaunchUrl(launchUri)) {
                                    await launchUrl(launchUri);
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Could not launch phone dialer.")));
                                  }
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Phone number not available.")));
                                }
                              }
                            ),
                            _buildActionButton(
                              icon: Icons.check_circle, 
                              label: "Finish Job", 
                              color: Colors.blueAccent, 
                              onTap: _finishJob,
                            ),
                            _buildActionButton(
                              icon: Icons.cancel, 
                              label: "Cancel", 
                              color: Colors.redAccent, 
                              onTap: _cancelRide,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon) {
    return Container(
      width: 140,
      padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(15),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 5)),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.white70, size: 28),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white60,
              fontSize: 12,
              letterSpacing: 1.2,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({required IconData icon, required String label, required Color color, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 13,
              color: Colors.black87,
            ),
          )
        ],
      ),
    );
  }
}
