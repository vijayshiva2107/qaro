import 'package:flutter/material.dart';

class MerchantDetailsPage extends StatelessWidget {
  final String merchantName;
  final String merchantPhone;
  final String merchantImageUrl;

  const MerchantDetailsPage({
    super.key,
    required this.merchantName,
    required this.merchantPhone,
    required this.merchantImageUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Merchant Details"),
        backgroundColor: Colors.black,
      ),
      body: Center(
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9, // 90% of screen width
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12), // Reduced size
            border: Border.all(color: Colors.black, width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                spreadRadius: 2,
              )
            ],
          ),
          child: Row(
            children: [
              // Merchant Image on the Left
              CircleAvatar(
                radius: 40, // Slightly larger for better visibility
                backgroundImage: NetworkImage(merchantImageUrl),
              ),
              const SizedBox(width: 15), // Space between image and text

              // Merchant Details on the Right
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Merchant Name
                    Text(
                      merchantName,
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),

                    const SizedBox(height: 5),

                    // Merchant Phone
                    Row(
                      children: [
                        const Icon(Icons.phone, color: Colors.black, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          merchantPhone,
                          style: const TextStyle(fontSize: 16),
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    // Call Button
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                      ),
                      onPressed: () {
                        // Add call functionality here
                      },
                      icon: const Icon(Icons.call, size: 20),
                      label: const Text("Call"),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      backgroundColor: Colors.grey[200],
    );
  }
}