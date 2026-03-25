import 'package:flutter/material.dart';
import 'car_data_loader.dart';
import 'car_detail_page.dart';
import 'package:shimmer/shimmer.dart';
import 'favorite_screen.dart';

class MainCarstock extends StatefulWidget {
  const MainCarstock({super.key});

  @override
  State<MainCarstock> createState() => _MainCarstockState();
}

class _MainCarstockState extends State<MainCarstock> {
  late Future<List<Map<String, dynamic>>> _carDataFuture;
  List<Map<String, dynamic>> _carList = [];
  List<Map<String, dynamic>> _filteredCars = [];
  final TextEditingController _searchController = TextEditingController();
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _carDataFuture = CarDataLoader.loadCarData();
    _searchController.addListener(_filterCars);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

void _filterCars() {
  String query = _searchController.text.toLowerCase();
  setState(() {
    _filteredCars = _carList.where((car) {
      String make = (car["Make"] ?? "").toString().toLowerCase();
      String model = (car["Model"] ?? "").toString().toLowerCase();
      String combined = "$make $model"; // ✅ Combined make & model

      return combined.contains(query); // ✅ Search in combined string
    }).toList();
  });
}


  void _onItemTapped(int index) {
    if (index == 1) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => FavoritesScreen()),
      );
    } else {
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 100,
        backgroundColor: Colors.black,
        title: const Text(
          "CAR STOCK",
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
            fontFamily: 'Poppins',
            letterSpacing: 2,
          ),
        ),
        centerTitle: true,
        automaticallyImplyLeading: true,
        iconTheme: const IconThemeData(
          color: Colors.white, // ✅ Back button color
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: _buildSearchBar(),
          ),
        ),
      ),
      backgroundColor: Colors.black,

      body: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(30),
            topRight: Radius.circular(30),
          ),
        ),
        child: _selectedIndex == 0
            ? _buildCarStockView()
            : const Center(
                child: Text(
                  "Settings Page",
                  style: TextStyle(fontSize: 20, color: Colors.black),
                ),
              ),
      ),

      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.black,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.grey,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.favorite), label: "Favorites"),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: "Settings"),
        ],
      ),
    );
  }

  /// *Search Bar Widget*
  Widget _buildSearchBar() {
  return Container(
    height: 45,
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.2),
          blurRadius: 4,
          offset: const Offset(0, 2),
        ),
      ],
    ),
    child: TextField(
      controller: _searchController,
      decoration: InputDecoration(
        hintText: "Search for cars...",
        prefixIcon: const Icon(Icons.search, color: Colors.black),
        suffixIcon: _searchController.text.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear, color: Colors.black),
                onPressed: () {
                  _searchController.clear(); // ✅ Clear search input
                  _filterCars(); // ✅ Refresh list
                },
              )
            : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(vertical: 12),
      ),
      onChanged: (value) => setState(() {}), // ✅ Update UI when typing
    ),
  );
}


  /// *Car Stock List*
 Widget _buildCarStockView() {
  return FutureBuilder<List<Map<String, dynamic>>>(
    future: _carDataFuture,
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const Center(child: CircularProgressIndicator());
      } else if (snapshot.hasError || snapshot.data == null || snapshot.data!.isEmpty) {
        return const Center(
          child: Text(
            "Error loading data",
            style: TextStyle(color: Colors.black, fontSize: 16),
          ),
        );
      }

      if (_carList.isEmpty) {
        _carList = List.from(snapshot.data!);
        _filteredCars = List.from(_carList);
      }

      return _filteredCars.isEmpty  
          ? const Center(
              child: Text(
                "No cars found. Try a different search!",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
              ),
            )
          : Padding(
              padding: const EdgeInsets.only(top: 10),
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _filteredCars.length,
                itemBuilder: (context, index) {
                  var car = _filteredCars[index];
                  String make = car["Make"] ?? "Unknown Make";
                  String model = car["Model"] ?? "Unknown Model";
                  String price = car["Ex-Showroom_Price"] ?? "N/A";
                  String imageUrl = car["Image_Path"] ?? "assets/Final_Logo.png";
                  int year = int.tryParse(car["Year"]?.toString() ?? "0") ?? 0;
                  bool isNewCar = year >= 2022; // ✅ Check if car is new

                  return GestureDetector(
                    onTap: () {
                      Navigator.push(       
                        context,
                        MaterialPageRoute(
                          builder: (context) => CarDetailPage(car: car),
                        ),
                      );
                    },
                    child: Card(
                      color: Colors.white,
                      elevation: 6,
                      shadowColor: Colors.black.withOpacity(0.3),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        height: 130, // ✅ Adjusted for better layout
                        child: Row(
                          children: [
                            /// *Image with Shimmer Effect & Error Handling*
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                imageUrl,
                                width: 120,
                                height: 90,
                                fit: BoxFit.cover,
                                loadingBuilder: (context, child, loadingProgress) {
                                  if (loadingProgress == null) return child;
                                  return Shimmer.fromColors(
                                    baseColor: Colors.grey[300]!,
                                    highlightColor: Colors.grey[100]!,
                                    child: Container(
                                      width: 120,
                                      height: 90,
                                      color: Colors.white,
                                    ),
                                  );
                                },
                                errorBuilder: (context, error, stackTrace) {
                                  return Image.asset("assets/Final_Logo.png", width: 120, height: 90, fit: BoxFit.cover);
                                },
                              ),
                            ),

                            const SizedBox(width: 12),

                            /// *Car Details*
                            Expanded(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          "$make $model",
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      if (isNewCar)
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: Colors.green,
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: const Text(
                                            "NEW",
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    "₹$price",
                                    style: const TextStyle(
                                      fontSize: 16,
                                      color: Colors.red,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const Icon(Icons.arrow_forward, color: Colors.black),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            );
    },
  );
}
}