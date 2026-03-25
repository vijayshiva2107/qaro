import 'package:flutter_application_1/intro_page.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_application_1/welcome_page.dart';
import 'package:flutter_application_1/merchant_home_page.dart';
import 'package:flutter_application_1/carmerchant1.dart';
import 'package:flutter_application_1/searching_mechanic_page.dart';
import 'package:flutter_application_1/mechanic_assigned_page.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  _SplashPageState createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    _checkAuthState();
  }

  Future<void> _checkAuthState() async {
    // Wait for 3 seconds and navigate to next screen
    await Future.delayed(const Duration(seconds: 3));

    if (!mounted) return;

    User? currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const IntroPage()),
      );
    } else {
      try {
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid)
            .get();

        if (userDoc.exists && mounted) {
          String storedAccountType = userDoc['accountType'];
          if (storedAccountType == "User") {
            // 🔥 Check for active booking before going to WelcomePage
            final activeBookingQuery = await FirebaseFirestore.instance
                .collection('bookings')
                .where('userId', isEqualTo: currentUser.uid)
                .where('status', whereIn: ['searching', 'accepted'])
                .limit(1)
                .get();

            if (!mounted) return;

            if (activeBookingQuery.docs.isNotEmpty) {
              final activeDoc = activeBookingQuery.docs.first;
              final status = (activeDoc.data())['status'] as String;

              if (!mounted) return;
              if (status == 'searching') {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SearchingMechanicPage(bookingId: activeDoc.id),
                  ),
                );
              } else {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => MechanicAssignedPage(bookingId: activeDoc.id),
                  ),
                );
              }
            } else {
              if (!mounted) return;
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const WelcomePage()),
              );
            }
          } else {
            DocumentSnapshot merchantDoc = await FirebaseFirestore.instance
                .collection('merchants')
                .doc(currentUser.uid)
                .get();

            if (mounted) {
              if (merchantDoc.exists) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const MerchantHomePage()),
                );
              } else {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const Carmerchant1()),
                );
              }
            }
          }
        } else if (mounted) {
          await FirebaseAuth.instance.signOut();
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const IntroPage()),
          );
        }
      } catch (e) {
        if (mounted) {
          await FirebaseAuth.instance.signOut();
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const IntroPage()),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color.fromARGB(255, 17, 16, 16), // 0% Dark
              Color(0xFFFFFFFF), // 50% White
              Color.fromARGB(255, 39, 38, 38), // 100% Dark
            ],
          ),
        ),
        child: Center(
          child: Image.asset(
            'assets/Final_Logo.png',
            width: 200,
            height: 200,
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}
