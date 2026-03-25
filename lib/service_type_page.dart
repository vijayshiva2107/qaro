import 'package:flutter/material.dart';
import 'location_page.dart';

class ServiceTypePage extends StatefulWidget {
  final double latitude;
  final double longitude;

  const ServiceTypePage({
    super.key,
    required this.latitude,
    required this.longitude,
  });

  @override
  State<ServiceTypePage> createState() => _ServiceTypePageState();
}

class _ServiceTypePageState extends State<ServiceTypePage> {
  Widget buildServiceCard({
    required String title,
    required String imagePath,
  }) {
    return GestureDetector(
      onTap: () {
        // 🔥 Direct navigation when tapped
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => LocationPage(
              serviceType: title,
              latitude: widget.latitude,
              longitude: widget.longitude,
            ),
          ),
        );
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.symmetric(vertical: 12),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.shade200,
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 75,
              height: 75,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.grey.shade100,
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: ClipOval(
                child: Image.asset(
                  imagePath,
                  fit: BoxFit.contain,
                ),
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Poppins',
                ),
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 18),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(top: 50, bottom: 30),
            color: Colors.black,
            child: const Center(
              child: Text(
                "CAR SERVICE",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 6,
                ),
              ),
            ),
          ),
          Expanded(
            child: Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 25),
              decoration: const BoxDecoration(
                color: Color(0xFFF2F2F2),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
              ),
              child: Column(
                children: [
                  const Text(
                    "Service Type",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Poppins',
                    ),
                  ),
                  const SizedBox(height: 30),

                  buildServiceCard(
                    title: "General Service",
                    imagePath: "assets/General_service.png",
                  ),
                  buildServiceCard(
                    title: "Repair",
                    imagePath: "assets/repair.png",
                  ),
                  buildServiceCard(
                    title: "Emergency Service",
                    imagePath: "assets/emergency.png",
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}