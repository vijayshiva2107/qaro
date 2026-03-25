  import 'package:flutter/material.dart';
  import 'package:flutter_application_1/main_carstock.dart';
  import 'package:flutter_application_1/merchant_home_page.dart';
  import 'package:image_picker/image_picker.dart';
  import 'package:flutter/foundation.dart';
  import 'package:firebase_auth/firebase_auth.dart';
  import 'package:cloud_firestore/cloud_firestore.dart';
  import 'dart:typed_data';
  import 'package:http/http.dart' as http;
  import 'dart:convert';
  import 'dart:io';

  class Carmerchant1 extends StatefulWidget {
    const Carmerchant1({super.key});

    @override
    State<Carmerchant1> createState() => _Carmerchant1State();
  }

  class _Carmerchant1State extends State<Carmerchant1> {
    final TextEditingController _usernameController = TextEditingController();
    final TextEditingController _phonenoController = TextEditingController();
    final TextEditingController _addressController = TextEditingController();
    XFile? _selectedImage; // for mobile
    Uint8List? _webImage; // for web
    Future<String?> uploadToCloudinary() async {
      const cloudName = "dszki2etu";
      const uploadPreset = "QaroCarApp";

      final url = Uri.parse(
        "https://api.cloudinary.com/v1_1/$cloudName/image/upload",
      );

      var request = http.MultipartRequest("POST", url);
      request.fields['upload_preset'] = uploadPreset;

      if (kIsWeb && _webImage != null) {
        request.files.add(
          http.MultipartFile.fromBytes(
            'file',
            _webImage!,
            filename: "merchant.jpg",
          ),
        );
      } else if (!kIsWeb && _selectedImage != null) {
        request.files.add(
          await http.MultipartFile.fromPath('file', _selectedImage!.path),
        );
      } else {
        return null;
      }

      final response = await request.send();
      final responseData = await response.stream.bytesToString();
      final data = json.decode(responseData);

      if (response.statusCode == 200) {
        return data['secure_url'];
      } else {
        print("Upload failed: $data");
        return null;
      }
    }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? pickedFile =
        await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile == null) return;

    if (kIsWeb) {
      _webImage = await pickedFile.readAsBytes();
    } else {
      _selectedImage = pickedFile; // ✅ FIXED
    }

    setState(() {});
  }

    Future<void> _saveMerchantDetails() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      String? imageUrl;

      // 🔥 Upload to Cloudinary
      if (_selectedImage != null || _webImage != null) {
        imageUrl = await uploadToCloudinary();
      }

      // 🔹 Save merchant details in Firestore
      await FirebaseFirestore.instance
          .collection('merchants')
          .doc(user.uid)
          .set({
        'uid': user.uid,
        'name': _usernameController.text.trim(),
        'phone': _phonenoController.text.trim(),
        'address': _addressController.text.trim(),
        'imageUrl': imageUrl ?? '',
        'createdAt': FieldValue.serverTimestamp(),
      });

      // ✅ Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Merchant details saved successfully!")),
      );

      // ✅ Navigate to new page
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const MerchantHomePage(), // 👈 change this
        ),
      );

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }
    @override
    Widget build(BuildContext context) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Column(
          children: [
            // Title Section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 40),
              decoration: const BoxDecoration(color: Colors.black),
              child: const Center(
                child: Text(
                  'Merchant Details',
                  style: TextStyle(
                    fontSize: 20,
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.bold,
                    letterSpacing: 3,
                    color: Colors.white,
                  ),
                ),
              ),
            ),

            // Form Section
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Merchant Name
                      const SizedBox(height: 10),
                      const Text(
                        'Merchant Name',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _usernameController,
                        decoration: const InputDecoration(
                          hintText: 'Enter Your Name',
                        ),
                      ),

                      // Phone Number
                      const SizedBox(height: 20),
                      const Text(
                        'Phone Number',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _phonenoController,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(hintText: '+91-'),
                      ),

                      // Address
                      const SizedBox(height: 20),
                      const Text(
                        'Address',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _addressController,
                        keyboardType: TextInputType.multiline,
                        decoration: const InputDecoration(
                          hintText: 'Enter your Address',
                        ),
                      ),

                      // Image Upload Section
                      const SizedBox(height: 20),
                      const Text(
                        'Upload your image',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Image Preview
                      Center(
                        child:
                            kIsWeb
                                ? (_webImage != null
                                    ? Image.memory(
                                      _webImage!,
                                      height: 150,
                                      width: 150,
                                      fit: BoxFit.cover,
                                    )
                                    : const Icon(
                                      Icons.image,
                                      size: 100,
                                      color: Colors.grey,
                                    ))
                                : (_selectedImage != null
      ? Image.file(
          File(_selectedImage!.path),
          height: 150,
          width: 150,
          fit: BoxFit.cover,
        )
      : const Icon(
          Icons.image,
          size: 100,
          color: Colors.grey,
        ))
                      ),

                      // Image Picker Button
                      const SizedBox(height: 10),
                      Center(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 10,
                            ),
                          ),
                          onPressed: _pickImage,
                          icon: const Icon(Icons.image),
                          label: const Text("Select Image"),
                        ),
                      ),
                      const SizedBox(height: 30),

                      Center(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 40,
                              vertical: 15,
                            ),
                          ),
                          onPressed: _saveMerchantDetails,
                          child: const Text("SAVE DETAILS"),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }
  }
