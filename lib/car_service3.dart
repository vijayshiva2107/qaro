import 'package:flutter/material.dart';
import 'car_service2.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
class CarService3 extends StatefulWidget {
  final double latitude;
  final double longitude;

  const CarService3({
    super.key,
    required this.latitude,
    required this.longitude,
  });

  @override
  State<CarService3> createState() => _CarService3State();
}

class _CarService3State extends State<CarService3> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _contactController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _timeController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _carModelController = TextEditingController();

  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  final User? user = FirebaseAuth.instance.currentUser;

  final List<String> _serviceTypes = [
    'General Service',
    'Repair',
    'Emergency Service'
  ];

  String? _selectedServiceType;
Future<String> getServiceType() async {
  final doc = await FirebaseFirestore.instance
      .collection('merchants')
      .doc(user!.uid)
      .get();

  if (doc.exists) {
    return doc.data()?['serviceProvides'] ?? 'Unknown';
  } else {
    return 'Unknown';
  }
}
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

void _submitForm() async {
  if (_formKey.currentState!.validate()) {

    String serviceType = await getServiceType(); // 👈 fetch from Firebase

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Confirm Booking"),
        content: Text(
          "Service: $serviceType\n"
          "Latitude: ${widget.latitude}\n"
          "Longitude: ${widget.longitude}\n\n"
          "Confirm booking?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);

              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CarService2(
                    serviceType: serviceType, // 👈 from Firebase
                    latitude: widget.latitude,
                    longitude: widget.longitude,
                  ),
                ),
              );
            },
            child: const Text("Confirm"),
          ),
        ],
      ),
    );
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Column(
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
                      _buildField("Username", _usernameController),
                      _buildField("Contact Number", _contactController,
                          keyboardType: TextInputType.phone),
                      _buildField("Date", _dateController,
                          onTap: () => _pickDate(context)),
                      _buildField("Time", _timeController,
                          onTap: () => _pickTime(context)),
                      _buildField("Address", _addressController),
                      _buildField("Car Model", _carModelController),
                      _buildDropdown(),
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

  Widget _buildDropdown() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: DropdownButtonFormField<String>(
        decoration: InputDecoration(
          labelText: "Service Type",
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        value: _selectedServiceType,
        hint: const Text("Select Service Type"),
        validator: (value) =>
            value == null ? 'Please select a service type' : null,
        items: _serviceTypes
            .map((type) =>
                DropdownMenuItem(value: type, child: Text(type)))
            .toList(),
        onChanged: (newValue) =>
            setState(() => _selectedServiceType = newValue),
      ),
    );
  }
}