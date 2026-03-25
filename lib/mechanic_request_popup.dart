import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'merchant_tracking_page.dart';

class MechanicRequestPopup extends StatefulWidget {
  final String bookingId;
  final Map<String, dynamic> bookingData;

  const MechanicRequestPopup({
    super.key,
    required this.bookingId,
    required this.bookingData,
  });

  @override
  State<MechanicRequestPopup> createState() => _MechanicRequestPopupState();
}

class _MechanicRequestPopupState extends State<MechanicRequestPopup> {

  int seconds = 15;
  Timer? timer;

  @override
  void initState() {
    super.initState();

    timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (seconds == 0) {
        t.cancel();
        Navigator.pop(context);
      } else {
        setState(() {
          seconds--;
        });
      }
    });
  }
final String mechanicId = FirebaseAuth.instance.currentUser!.uid;
  void acceptRequest() {
    FirebaseFirestore.instance
        .collection("bookings")
        .doc(widget.bookingId)
        .update({
      "status": "accepted",
      "mechanicId": mechanicId,
    }).then((_) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => MerchantTrackingPage(
            bookingId: widget.bookingId,
            mechanicId: mechanicId,
          ),
        ),
      );
    });
  }

  void rejectRequest() {
    FirebaseFirestore.instance
        .collection("bookings")
        .doc(widget.bookingId)
        .update({
      "status": "rejected"
    });

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {

    String serviceType = widget.bookingData["serviceType"] ?? "";
    String carModel = widget.bookingData["carModel"] ?? "";
    String address = widget.bookingData["address"] ?? "";

    return Scaffold(
      backgroundColor: Colors.black.withOpacity(0.9),

      body: Center(
        child: Container(
          margin: const EdgeInsets.all(20),
          padding: const EdgeInsets.all(25),

          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),

          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [

              const Icon(Icons.build, size: 60),

              const SizedBox(height: 10),

              const Text(
                "New Service Request",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 15),

              Text("Service: $serviceType"),
              Text("Car: $carModel"),
              Text("Address: $address"),

              const SizedBox(height: 20),

              Text(
                "Auto closing in $seconds s",
                style: const TextStyle(color: Colors.red),
              ),

              const SizedBox(height: 20),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [

                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                    ),
                    onPressed: acceptRequest,
                    child: const Text("Accept"),
                  ),

                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                    ),
                    onPressed: rejectRequest,
                    child: const Text("Reject"),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}