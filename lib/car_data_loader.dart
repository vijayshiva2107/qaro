import 'dart:convert';
import 'package:flutter/services.dart';

class CarDataLoader {
  static Future<List<Map<String, dynamic>>> loadCarData() async {
    try {
      String jsonString = await rootBundle.loadString('assets/cars.json');
      List<dynamic> jsonList = json.decode(jsonString);

      // Return full JSON data without filtering out any fields
      return jsonList.map((car) => Map<String, dynamic>.from(car)).toList();

    } catch (e) {
      print("Error loading car data: $e");
      return [];
    }
  }
}