import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'car_detail_page.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  _FavoritesScreenState createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  List<Map<String, dynamic>> favorites = [];

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  /// Load favorite cars from SharedPreferences
  Future<void> _loadFavorites() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? favoriteCars = prefs.getString('favorite_cars');
    if (favoriteCars != null) {
      List<dynamic> decodedList = json.decode(favoriteCars);
      setState(() {
        favorites = decodedList.cast<Map<String, dynamic>>();
      });
    }
  }

  /// Remove a car from favorites
  Future<void> _removeFromFavorites(String model) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      favorites.removeWhere((car) => car["Model"] == model);
    });
    await prefs.setString('favorite_cars', json.encode(favorites));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 100,
        backgroundColor: Colors.black,
        title: const Text(
          "FAVORITES",
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
    color: Colors.white, // ✅ Change back button color
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
        child: favorites.isEmpty
            ? const Center(
                child: Text(
                  "No favorite cars yet",
                  style: TextStyle(color: Colors.black, fontSize: 18),
                ),
              )
            : ListView.builder(
                itemCount: favorites.length,
                itemBuilder: (context, index) {
                  var car = favorites[index];
                  return Card(
                    color: Colors.white,
                    margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: ListTile(
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          car["Image"] ?? "https://via.placeholder.com/100",
                          width: 80,
                          height: 60,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(Icons.car_repair, size: 50);
                          },
                        ),
                      ),
                      title: Text(
                        "${car["Make"] ?? "Unknown"} ${car["Model"] ?? ""}",
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        "Price: ${car["Ex-Showroom_Price"] ?? "N/A"}",
                        style: const TextStyle(color: Colors.red),
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.cancel, color: Colors.red),
                        onPressed: () => _removeFromFavorites(car["Model"]),
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => CarDetailPage(car: car)),
                        );
                      },
                    ),
                  );
                },
              ),
      ),
    );
  }
}