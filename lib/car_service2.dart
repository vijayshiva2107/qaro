import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'searching_mechanic_page.dart';

class CarService2 extends StatefulWidget {
  final String serviceType;
  final double latitude;
  final double longitude;

  const CarService2({
    super.key,
    required this.serviceType,
    required this.latitude,
    required this.longitude,
  });

  @override
  State<CarService2> createState() => _CarService2State();
}

class _CarService2State extends State<CarService2> {
  final _formKey = GlobalKey<FormState>();

  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;

  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _timeController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _contactController = TextEditingController();
  final TextEditingController _carModelController = TextEditingController();

  bool _isLoading = false;

  Future<void> _pickDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _dateController.text =
            "${picked.day}/${picked.month}/${picked.year}";
      });
    }
  }

  Future<void> _pickTime(BuildContext context) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (picked != null) {
      setState(() {
        _selectedTime = picked;
        _timeController.text = picked.format(context);
      });
    }
  }

  // 🔥 Save booking and redirect to searching page
  Future<void> _saveBooking() async {
    try {
      setState(() => _isLoading = true);

      final user = FirebaseAuth.instance.currentUser;

      final bookingRef =
          await FirebaseFirestore.instance.collection("bookings").add({
        "userId": user?.uid ?? "guest_user",
        "serviceType": widget.serviceType,
        "date": _dateController.text,
        "time": _timeController.text,
        "address": _addressController.text,
        "contactNumber": _contactController.text,
        "carModel": _carModelController.text,
        "location": GeoPoint(widget.latitude, widget.longitude),
        "status": "searching",
        "createdAt": FieldValue.serverTimestamp(),
      });

      setState(() => _isLoading = false);

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => SearchingMechanicPage(bookingId: bookingRef.id),
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      _saveBooking();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                color: Colors.black,
                child: const Center(
                  child: Text(
                    'CAR SERVICE',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 24,
                      letterSpacing: 5,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                  ),
                  child: SingleChildScrollView(
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          _buildField("Date", _dateController,
                              onTap: () => _pickDate(context)),
                          _buildField("Time", _timeController,
                              onTap: () => _pickTime(context)),
                          _buildField("Address", _addressController),
                          _buildField("Contact Number", _contactController,
                              keyboardType: TextInputType.phone),
                          _buildField("Car Model", _carModelController),

                          const SizedBox(height: 20),

                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(
                                  vertical: 18, horizontal: 70),
                            ),
                            onPressed: _submitForm,
                            child: const Text(
                              "Book",
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),

          // 🔥 Loading overlay
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildField(
    String label,
    TextEditingController controller, {
    VoidCallback? onTap,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: TextFormField(
        controller: controller,
        readOnly: onTap != null,
        keyboardType: keyboardType,
        validator: (value) =>
            value == null || value.isEmpty ? "Please enter $label" : null,
        onTap: onTap,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    );
  }
}