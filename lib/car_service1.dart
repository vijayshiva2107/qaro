import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'service_type_page.dart';
import 'MapsPage.dart';
import 'package:geolocator/geolocator.dart';
import 'searching_mechanic_page.dart';
import 'mechanic_assigned_page.dart';

class CarService1 extends StatefulWidget {
  const CarService1({super.key});

  @override
  State<CarService1> createState() => _CarService1State();
}

class _CarService1State extends State<CarService1> {
  bool _isHoveringYes = false;
  bool _isHoveringNo = false;
  bool _isLoading = false;

  // 🔥 Get Current Location
  Future<Position> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception("Location services are disabled.");
    }

    permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception("Location permission denied.");
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception("Location permission permanently denied.");
    }

    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }

  // 🔥 Check if already has an active booking
  Future<DocumentSnapshot?> _getActiveBooking() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return null;

    final query = await FirebaseFirestore.instance
        .collection('bookings')
        .where('userId', isEqualTo: uid)
        .where('status', whereIn: ['searching', 'accepted'])
        .limit(1)
        .get();

    if (query.docs.isNotEmpty) return query.docs.first;
    return null;
  }

  // 🔥 Navigate to ServiceTypePage (YES)
  void _navigateToServicePage() async {
    try {
      setState(() => _isLoading = true);

      // 🚫 Block if already has active booking
      final activeBooking = await _getActiveBooking();
      if (activeBooking != null) {
        setState(() => _isLoading = false);
        final data = activeBooking.data() as Map<String, dynamic>;
        final status = data['status'] as String;

        if (mounted) {
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text("Active Request Found"),
              content: Text(
                status == 'searching'
                    ? "You already have a service request being searched. Please wait or cancel it first."
                    : "A mechanic has already been assigned to your existing request."
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text("Stay"),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    if (status == 'searching') {
                      Navigator.push(context, MaterialPageRoute(
                        builder: (_) => SearchingMechanicPage(bookingId: activeBooking.id),
                      ));
                    } else {
                      Navigator.push(context, MaterialPageRoute(
                        builder: (_) => MechanicAssignedPage(bookingId: activeBooking.id),
                      ));
                    }
                  },
                  child: const Text("Track My Ride", style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          );
        }
        return;
      }

      Position position = await _getCurrentLocation();
      setState(() => _isLoading = false);

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ServiceTypePage(
            latitude: position.latitude,
            longitude: position.longitude,
          ),
        ),
      );
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  // 🔥 Navigate to MapsPage (NO)
  void _navigateToMapPage() async {
    try {
      setState(() => _isLoading = true);

      Position position = await _getCurrentLocation();

      setState(() => _isLoading = false);

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => MapsPage(
            latitude: position.latitude,
            longitude: position.longitude,
          ),
        ),
      );
    } catch (e) {
      setState(() => _isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Column(
            children: [
              SafeArea(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const Expanded(
                        child: Center(
                          child: Text(
                            "CAR SERVICE",
                            style: TextStyle(
                              color: Colors.white,
                              fontFamily: 'Poppins',
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 5,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 48), // to beautifully center the text against the icon
                    ],
                  ),
                ),
              ),

              Expanded(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'Is the service for you?',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 40),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // YES Button
                          MouseRegion(
                            onEnter: (_) =>
                                setState(() => _isHoveringYes = true),
                            onExit: (_) =>
                                setState(() => _isHoveringYes = false),
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _isHoveringYes
                                    ? Colors.white
                                    : Colors.black,
                                foregroundColor: _isHoveringYes
                                    ? Colors.black
                                    : Colors.white,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 60, vertical: 25),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onPressed: _navigateToServicePage,
                              child: const Text("Yes"),
                            ),
                          ),

                          const SizedBox(width: 40),

                          // NO Button
                          MouseRegion(
                            onEnter: (_) =>
                                setState(() => _isHoveringNo = true),
                            onExit: (_) =>
                                setState(() => _isHoveringNo = false),
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _isHoveringNo
                                    ? Colors.white
                                    : Colors.black,
                                foregroundColor: _isHoveringNo
                                    ? Colors.black
                                    : Colors.white,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 60, vertical: 25),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onPressed: _navigateToMapPage,
                              child: const Text("No"),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // 🔥 Loading Overlay
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.6),
              child: const Center(
                child: CircularProgressIndicator(
                  color: Colors.white,
                ),
              ),
            ),
        ],
      ),
    );
  }
}