import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'mechanic_assigned_page.dart';
import 'welcome_page.dart';

class SearchingMechanicPage extends StatefulWidget {
  final String bookingId;

  const SearchingMechanicPage({super.key, required this.bookingId});

  @override
  State<SearchingMechanicPage> createState() => _SearchingMechanicPageState();
}

class _SearchingMechanicPageState extends State<SearchingMechanicPage> {
  bool _isNavigating = false;  // guard against repeated stream-triggered navigation

  Future<void> _cancelBooking() async {
    await FirebaseFirestore.instance
        .collection('bookings')
        .doc(widget.bookingId)
        .update({'status': 'Cancelled'});

    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const WelcomePage()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection("bookings")
            .doc(widget.bookingId)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator(color: Colors.white));
          }

          var bookingData = snapshot.data!.data() as Map<String, dynamic>;
          String status = bookingData["status"];

          // 🚗 Mechanic Accepted → navigate to MechanicAssignedPage
          if (status == "accepted" && !_isNavigating) {
            _isNavigating = true;
            Future.microtask(() {
              if (mounted) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => MechanicAssignedPage(bookingId: widget.bookingId),
                  ),
                );
              }
            });
          }

          // Cancelled from another device
          if (status == "Cancelled" && !_isNavigating) {
            _isNavigating = true;
            Future.microtask(() {
              if (mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const WelcomePage()),
                  (route) => false,
                );
              }
            });
          }

          return _buildSearchingLayout();
        },
      ),
    );
  }

  Widget _buildSearchingLayout() {
    return Column(
      children: [
        const Spacer(),

        // Animated radar icon
        Container(
          padding: const EdgeInsets.all(30),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            shape: BoxShape.circle,
          ),
          child: Container(
            padding: const EdgeInsets.all(25),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.radar, color: Colors.white, size: 80),
          ),
        ),

        const SizedBox(height: 40),

        const Text(
          "Searching for a Mechanic...",
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
            fontFamily: 'Poppins',
            letterSpacing: 1,
          ),
        ),

        const SizedBox(height: 15),

        const Text(
          "Please wait while we find\nsomeone near you",
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white54, fontSize: 15, height: 1.6),
        ),

        const SizedBox(height: 40),

        const CircularProgressIndicator(color: Colors.white),

        const Spacer(),

        // Cancel Button
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 40),
          child: SizedBox(
            width: double.infinity,
            height: 55,
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.redAccent, width: 2),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              ),
              onPressed: () async {
                bool? confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text("Cancel Request?"),
                    content: const Text("Are you sure you want to cancel your service request?"),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("No")),
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        child: const Text("Yes, Cancel", style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
                );
                if (confirm == true) await _cancelBooking();
              },
              child: const Text(
                "CANCEL REQUEST",
                style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, letterSpacing: 2),
              ),
            ),
          ),
        ),
      ],
    );
  }
}