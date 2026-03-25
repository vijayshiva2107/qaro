import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class CarDetailPage extends StatefulWidget {
  final Map<String, dynamic> car;

  const CarDetailPage({super.key, required this.car});

  @override
  _CarDetailPageState createState() => _CarDetailPageState();
}

class _CarDetailPageState extends State<CarDetailPage> {
  bool isFavorite = false;

  @override
  void initState() {
    super.initState();
    _checkIfFavorite();
  }

  /// Check if the car is already in favorites
  Future<void> _checkIfFavorite() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? favoriteCars = prefs.getString('favorite_cars');

    if (favoriteCars != null) {
      List<dynamic> decodedList = json.decode(favoriteCars);
      List<Map<String, dynamic>> favorites =
          decodedList.cast<Map<String, dynamic>>();

      setState(() {
        isFavorite = favorites.any(
          (car) => car["Model"] == widget.car["Model"],
        );
      });
    }
  }

  /// Add or remove from favorites
  Future<void> _toggleFavorite() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? favoriteCars = prefs.getString('favorite_cars');
    List<Map<String, dynamic>> favorites = [];

    if (favoriteCars != null) {
      List<dynamic> decodedList = json.decode(favoriteCars);
      favorites = decodedList.cast<Map<String, dynamic>>();
    }

    setState(() {
      if (isFavorite) {
        favorites.removeWhere((car) => car["Model"] == widget.car["Model"]);
        isFavorite = false;
      } else {
        favorites.add(widget.car);
        isFavorite = true;
      }
    });

    await prefs.setString('favorite_cars', json.encode(favorites));
  }

  /// Helper method to safely get a field value
  String _getField(String key) {
    if (!widget.car.containsKey(key) || widget.car[key] == null) {
      return "Not Available";
    }

    String value = widget.car[key].toString().trim();
    return value.isNotEmpty ? value : "Not Available";
  }

  /// Build Car Image (Handles Network & Asset Images)
  Widget _buildCarImage() {
    String? imagePath = widget.car["Image_Path"];
    print(widget.car);
    if (imagePath == null || imagePath.isEmpty) {
      return Image.asset(
        "assets/Final_Logo.png",
        width: 100,
        height: 100,
        fit: BoxFit.fitHeight,
      );
    }

    if (imagePath.startsWith("http")) {
      // Load from Network
      return Image.network(
        imagePath,
        width: double.infinity,
        height: 200,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Image.asset(
            "assets/no_image.png",
            width: double.infinity,
            height: 200,
            fit: BoxFit.cover,
          );
        },
      );
    } else {
      // Load from Assets
      return Image.asset(
        imagePath,
        width: double.infinity,
        height: 200,
        fit: BoxFit.cover,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(
          "${widget.car["Make"] ?? "Unknown"} ${widget.car["Model"] ?? "Unknown"}",
          style: const TextStyle(color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: Icon(
              isFavorite ? Icons.favorite : Icons.favorite_border,
              color: Colors.red,
            ),
            onPressed: _toggleFavorite,
          ),
        ],
        automaticallyImplyLeading: true,
        iconTheme: const IconThemeData(
          color: Colors.white, // ✅ Back button color
        ),
      ),
      backgroundColor: Colors.black, // ✅ Set full background to black

      body: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white, // ✅ White foreground
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(30), // ✅ Rounded top corners
            topRight: Radius.circular(30),
          ),
        ),
        child: SingleChildScrollView(
          child: Column(
            children: [
              /// Car Image
              SizedBox(
                height: 200,
                width: double.infinity,
                child: _buildCarImage(),
              ),

              /// Car Details List
              const SizedBox(height: 20),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: widget.car.keys.length,
                itemBuilder: (context, index) {
                  String key = widget.car.keys.elementAt(index);

                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 8,
                      horizontal: 16,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          flex: 2,
                          child: Text(
                            key.replaceAll("_", " "), // Format key names
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.black,
                            ), // ✅ Change text color to black
                          ),
                        ),
                        Expanded(
                          flex: 3,
                          child: Text(
                            _getField(key),
                            textAlign: TextAlign.right,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
