import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_application_1/intro_page.dart';
import 'package:flutter_application_1/car_service1.dart';
import 'package:flutter_application_1/main_carstock.dart';
import 'searching_mechanic_page.dart';
import 'mechanic_assigned_page.dart';
import 'client_orders_page.dart';
import 'client_profile_page.dart';

class WelcomePage extends StatefulWidget {
  const WelcomePage({super.key});

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> {
  final User? currentUser = FirebaseAuth.instance.currentUser;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Match login_page black background
      appBar: AppBar(
        elevation: 0  ,
        backgroundColor: Colors.black,
        title: const Text(
          "WELCOME BACK", 
          style: TextStyle(
            color: Colors.white, 
            fontWeight: FontWeight.bold, 
            fontSize: 24,
            fontFamily: 'Poppins',
            letterSpacing: 3
          )
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        centerTitle: true,
      ),
      drawer: Drawer(
        child: Column(
          children: [
            FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance.collection('users').doc(currentUser?.uid).get(),
              builder: (context, snapshot) {
                String accountName = "Client Portal";
                String email = currentUser?.email ?? "Manage your services securely";
                String? profileImageUrl;
                
                if (snapshot.hasData && snapshot.data!.exists) {
                  var data = snapshot.data!.data() as Map<String, dynamic>?;
                  if (data != null) {
                    if (data.containsKey('name')) accountName = data['name'];
                    if (data.containsKey('imageUrl') && data['imageUrl'] != "") {
                      profileImageUrl = data['imageUrl'];
                    }
                  }
                }
                
                return UserAccountsDrawerHeader(
                  decoration: const BoxDecoration(color: Colors.black),
                  accountName: Text(accountName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  accountEmail: Text(email),
                  currentAccountPicture: CircleAvatar(
                    backgroundColor: Colors.white, 
                    backgroundImage: profileImageUrl != null ? NetworkImage(profileImageUrl) : null,
                    child: profileImageUrl == null ? const Icon(Icons.person, color: Colors.black, size: 40) : null,
                  ),
                );
              }
            ),
            ListTile(
              leading: const Icon(Icons.edit, color: Colors.green),
              title: const Text("Edit Profile"),
              onTap: () {
                Navigator.pop(context); // Close drawer
                Navigator.push(context, MaterialPageRoute(builder: (_) => const ClientProfilePage()));
              },
            ),
            ListTile(
              leading: const Icon(Icons.history, color: Colors.blueAccent),
              title: const Text("Past Services"),
              onTap: () {
                Navigator.pop(context); // Close drawer
                Navigator.push(context, MaterialPageRoute(builder: (_) => const ClientOrdersPage()));
              },
            ),
            const Spacer(),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text("Logout"),
              onTap: () async {
                await FirebaseAuth.instance.signOut();
                if (mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const IntroPage()));
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
      body: Column(
        children: [
          const SizedBox(height: 20),
          Expanded(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 25),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "What do you need help with today?",
                      style: TextStyle(
                        fontSize: 16, 
                        color: Colors.black87, 
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Poppins'
                      ),
                    ),
                    const SizedBox(height: 25),

              // 🔥 Active Booking Tracker Banner
              if (currentUser != null)
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('bookings')
                      .where('userId', isEqualTo: currentUser!.uid)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return const SizedBox.shrink();
                    }

                    var activeDocs = snapshot.data!.docs.where((doc) {
                      var data = doc.data() as Map<String, dynamic>;
                      return data['status'] == 'searching' || data['status'] == 'accepted';
                    }).toList();

                    if (activeDocs.isEmpty) return const SizedBox.shrink();

                    activeDocs.sort((a, b) {
                      var aTime = (a.data() as Map<String, dynamic>)['createdAt'] as Timestamp?;
                      var bTime = (b.data() as Map<String, dynamic>)['createdAt'] as Timestamp?;
                      if (aTime == null || bTime == null) return 0;
                      return bTime.compareTo(aTime);
                    });

                    var activeDoc = activeDocs.first;
                    var data = activeDoc.data() as Map<String, dynamic>;
                    String status = data['status'];

                    return GestureDetector(
                      onTap: () {
                        if (status == 'searching') {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => SearchingMechanicPage(bookingId: activeDoc.id)));
                        } else {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => MechanicAssignedPage(bookingId: activeDoc.id)));
                        }
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 25),
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.blueAccent,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(color: Colors.blueAccent.withOpacity(0.4), blurRadius: 15, offset: const Offset(0, 5)),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
                              child: const Icon(Icons.radar, color: Colors.white, size: 28),
                            ),
                            const SizedBox(width: 15),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text("Active Service Request", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                                  const SizedBox(height: 5),
                                  Text(
                                    status == 'searching' ? "Finding a mechanic..." : "Mechanic is heading your way!", 
                                    style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500)
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 18),
                          ],
                        ),
                      ),
                    );
                  },
                ),

              // 🚗 Premium Option Cards
              _buildActionCard(
                title: "Require a Mechanic?",
                subtitle: "Emergency breakdown & mechanical servicing securely tracked via GPS.",
                icon: Icons.car_repair,
                colors: [Colors.black87, Colors.black],
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CarService1())),
              ),
              
              const SizedBox(height: 25),
              
              _buildActionCard(
                title: "Explore Car Stock",
                subtitle: "Buy, sell, or browse our expansive vehicle marketplace seamlessly.",
                icon: Icons.directions_car,
                colors: [Colors.blue.shade700, Colors.blueAccent],
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MainCarstock())),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    ),
  ],
),
    );
  }

  Widget _buildActionCard({required String title, required String subtitle, required IconData icon, required List<Color> colors, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(25),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: colors, begin: Alignment.topLeft, end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            BoxShadow(color: colors.last.withOpacity(0.4), blurRadius: 15, offset: const Offset(0, 8)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), shape: BoxShape.circle),
              child: Icon(icon, color: Colors.white, size: 40),
            ),
            const SizedBox(height: 20),
            Text(title, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800, letterSpacing: 1.2)),
            const SizedBox(height: 10),
            Text(subtitle, style: const TextStyle(color: Colors.white70, fontSize: 14, height: 1.5)),
          ],
        ),
      ),
    );
  }
}
