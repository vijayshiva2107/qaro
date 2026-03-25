import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

class MerchantOrderDetailsPage extends StatelessWidget {
  final String bookingId;
  final Map<String, dynamic> data;

  const MerchantOrderDetailsPage({super.key, required this.bookingId, required this.data});

  @override
  Widget build(BuildContext context) {
    String service = data['serviceType'] ?? "Unknown Service";
    String car = data['carModel'] ?? "Unknown Car";
    String address = data['address'] ?? "Unknown Address";
    String status = data['status'] ?? "Unknown";
    String phone = data['contactNumber'] ?? "";
    
    Timestamp? createdAt = data['createdAt'] as Timestamp?;
    String dateString = "Recently";
    
    if (createdAt != null) {
      DateTime d = createdAt.toDate();
      dateString = "${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year} at ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}";
    }

    Color statusColor = Colors.grey;
    if (status.toLowerCase() == 'completed') statusColor = Colors.green;
    if (status.toLowerCase() == 'cancelled') statusColor = Colors.redAccent;
    if (status.toLowerCase() == 'rejected') statusColor = Colors.red;
    if (status.toLowerCase() == 'accepted') statusColor = Colors.blue;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("ORDER INVOICE", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 2)),
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            
            // 1. Status Banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 20),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: statusColor.withOpacity(0.5), width: 2),
              ),
              child: Column(
                children: [
                  Icon(
                    status.toLowerCase() == 'completed' ? Icons.check_circle : 
                    status.toLowerCase() == 'cancelled' || status.toLowerCase() == 'rejected' ? Icons.cancel : Icons.info,
                    color: statusColor, size: 40
                  ),
                  const SizedBox(height: 10),
                  Text(
                    status.toUpperCase(),
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 30),
            
            // 2. Job Overview
            const Text("JOB OVERVIEW", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.5)),
            const SizedBox(height: 15),
            
            _buildDetailRow(Icons.build, "Service", service),
            _buildDetailRow(Icons.directions_car, "Vehicle Model", car),
            _buildDetailRow(Icons.calendar_today, "Requested On", dateString),
            
            const SizedBox(height: 30),
            
            // 3. Client Information
            const Text("CLIENT DETAILS", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.5)),
            const SizedBox(height: 15),
            
            _buildDetailRow(Icons.location_on, "Address", address),
            _buildDetailRow(Icons.phone, "Phone Number", phone.isNotEmpty ? phone : "Not provided"),
            
            const SizedBox(height: 40),
            
            // 4. Action Buttons
            if (phone.isNotEmpty) 
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.call, color: Colors.white),
                  label: const Text("Call Client", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  onPressed: () async {
                    final Uri launchUri = Uri(scheme: 'tel', path: phone);
                    if (await canLaunchUrl(launchUri)) {
                      await launchUrl(launchUri);
                    } else {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Could not launch dialer.")));
                      }
                    }
                  },
                ),
              ),
              
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.black87, size: 24),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontSize: 13, color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
                const SizedBox(height: 3),
                Text(value, style: const TextStyle(fontSize: 16, color: Colors.black, fontWeight: FontWeight.bold)),
              ],
            ),
          )
        ],
      ),
    );
  }
}
