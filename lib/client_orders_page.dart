import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ClientOrdersPage extends StatefulWidget {
  const ClientOrdersPage({super.key});

  @override
  State<ClientOrdersPage> createState() => _ClientOrdersPageState();
}

class _ClientOrdersPageState extends State<ClientOrdersPage> {
  final String userId = FirebaseAuth.instance.currentUser!.uid;
  String selectedFilter = 'All';

  final List<String> filters = ['All', 'Completed', 'Accepted', 'Cancelled', 'Rejected'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          "MY PAST SERVICES", 
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 2)
        ),
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Filter Tabs
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
            child: Row(
              children: filters.map((filter) {
                bool isSelected = selectedFilter == filter;
                return Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: ChoiceChip(
                    label: Text(
                      filter, 
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.black87,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500
                      )
                    ),
                    selected: isSelected,
                    selectedColor: Colors.black,
                    backgroundColor: Colors.grey.shade200,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          selectedFilter = filter;
                        });
                      }
                    },
                  ),
                );
              }).toList(),
            ),
          ),
          
          // Orders List
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('bookings')
                  .where('userId', isEqualTo: userId)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Colors.black));
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text("No order history found.", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)));
                }

                var docs = snapshot.data!.docs;
                
                // 1. Filter locally based on Selected Tab
                if (selectedFilter != 'All') {
                  docs = docs.where((doc) {
                    var data = doc.data() as Map<String, dynamic>;
                    String status = (data['status'] ?? "").toString().toLowerCase();
                    return status == selectedFilter.toLowerCase();
                  }).toList();
                }

                if (docs.isEmpty) {
                  return Center(child: Text("No $selectedFilter orders found.", style: const TextStyle(fontSize: 15, color: Colors.grey)));
                }

                // 2. Sort by createdAt descending
                docs.sort((a, b) {
                  var aData = a.data() as Map<String, dynamic>;
                  var bData = b.data() as Map<String, dynamic>;
                  var aTime = aData['createdAt'] as Timestamp?;
                  var bTime = bData['createdAt'] as Timestamp?;
                  if (aTime == null || bTime == null) return 0;
                  return bTime.compareTo(aTime);
                });

                return ListView.builder(
                  padding: const EdgeInsets.all(15),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    var doc = docs[index];
                    var data = doc.data() as Map<String, dynamic>;
                    
                    String service = data['serviceType'] ?? "Service";
                    String car = data['carModel'] ?? "Unknown Car";
                    String status = data['status'] ?? "Unknown";
                    Timestamp? createdAt = data['createdAt'] as Timestamp?;
                    String dateString = "Recently";
                    
                    if (createdAt != null) {
                      DateTime d = createdAt.toDate();
                      dateString = "${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year} - ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}";
                    }

                    Color statusColor = Colors.grey;
                    if (status.toLowerCase() == 'completed') statusColor = Colors.green;
                    if (status.toLowerCase() == 'cancelled') statusColor = Colors.redAccent;
                    if (status.toLowerCase() == 'rejected') statusColor = Colors.red;
                    if (status.toLowerCase() == 'accepted' || status.toLowerCase() == 'searching') statusColor = Colors.blue;

                    return Card(
                      elevation: 4,
                      margin: const EdgeInsets.only(bottom: 15),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      child: Padding(
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  service, 
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: statusColor.withOpacity(0.1), 
                                    borderRadius: BorderRadius.circular(10)
                                  ),
                                  child: Text(
                                    status.toUpperCase(), 
                                    style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 1)
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            
                            Row(
                              children: [
                                const Icon(Icons.directions_car, size: 18, color: Colors.grey), 
                                const SizedBox(width: 8), 
                                Text(car, style: TextStyle(color: Colors.grey.shade800, fontWeight: FontWeight.w500))
                              ]
                            ),
                            
                            const SizedBox(height: 12),
                            Divider(color: Colors.grey.shade200, thickness: 1.5),
                            const SizedBox(height: 8),
                            
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Text(dateString, style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
