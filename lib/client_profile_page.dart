import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class ClientProfilePage extends StatefulWidget {
  const ClientProfilePage({super.key});

  @override
  State<ClientProfilePage> createState() => _ClientProfilePageState();
}

class _ClientProfilePageState extends State<ClientProfilePage> {
  final user = FirebaseAuth.instance.currentUser;
  bool uploading = false;

  /// UPDATE PROFILE IMAGE VIA CLOUDINARY
  Future<void> _updateProfileImage() async {
    final picker = ImagePicker();
    final XFile? pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile == null) return;

    setState(() => uploading = true);

    const cloudName = "dszki2etu";
    const uploadPreset = "QaroCarApp";

    var uri = Uri.parse("https://api.cloudinary.com/v1_1/$cloudName/image/upload");
    var bytes = await pickedFile.readAsBytes();

    var request = http.MultipartRequest("POST", uri)
      ..fields['upload_preset'] = uploadPreset
      ..fields['folder'] = "client_images"
      ..files.add(
        http.MultipartFile.fromBytes('file', bytes, filename: pickedFile.name),
      );

    var response = await request.send();
    var responseData = json.decode(await response.stream.bytesToString());

    if (response.statusCode == 200) {
      String imageUrl = responseData['secure_url'];
      await FirebaseFirestore.instance.collection('users').doc(user!.uid).set({
        'imageUrl': imageUrl
      }, SetOptions(merge: true));
    }

    setState(() => uploading = false);
  }

  /// EDIT FIELD SECURE BOTTOM SHEET
  void _editField(String fieldName, String oldValue) {
    TextEditingController controller = TextEditingController(text: oldValue);
    
    // Formatting explicitly for human-readable Titles
    String displayTitle = fieldName.toUpperCase();
    if (fieldName == 'carModel') displayTitle = "DEFAULT CAR MODEL";

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: Container(
            padding: const EdgeInsets.all(25),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Edit $displayTitle", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, fontFamily: 'Poppins')),
                const SizedBox(height: 20),
                TextField(
                  controller: controller,
                  keyboardType: fieldName == 'phone' ? TextInputType.phone : TextInputType.text,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                    hintText: "Enter new $displayTitle",
                    prefixIcon: const Icon(Icons.edit, color: Colors.blueAccent),
                  ),
                ),
                const SizedBox(height: 25),
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    ),
                    onPressed: () async {
                      if (controller.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Field cannot be empty")));
                        return;
                      }
                      if (fieldName == "phone" && controller.text.length < 10) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Invalid phone number")));
                        return;
                      }

                      await FirebaseFirestore.instance.collection('users').doc(user!.uid).update({
                        fieldName: controller.text.trim()
                      });

                      if (mounted) Navigator.pop(context);
                      setState(() {});
                    },
                    child: const Text("SAVE CHANGES", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 2)),
                  ),
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        centerTitle: true,
        title: const Text(
          "MY PROFILE", 
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 24, fontFamily: 'Poppins', letterSpacing: 3)
        ),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('users').doc(user!.uid).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: Colors.white));
          if (!snapshot.hasData || !snapshot.data!.exists) return const Center(child: Text("No Profile Data Found", style: TextStyle(color: Colors.white)));

          var data = snapshot.data!.data() as Map<String, dynamic>;

          return Column(
            children: [
              const SizedBox(height: 10),
              
              // EXPANDED BODY (Matching exact login_page constraints safely)
              Expanded(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(topLeft: Radius.circular(30), topRight: Radius.circular(30)),
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        // PROFILE PICTURE
                        GestureDetector(
                          onTap: _updateProfileImage,
                          child: Stack(
                            alignment: Alignment.bottomRight,
                            children: [
                              CircleAvatar(
                                radius: 75,
                                backgroundColor: Colors.grey.shade200,
                                backgroundImage: data['imageUrl'] != null && data['imageUrl'] != ""
                                    ? NetworkImage(data['imageUrl'] + "?t=${DateTime.now().millisecondsSinceEpoch}")
                                    : null,
                                child: data['imageUrl'] == null || data['imageUrl'] == ""
                                    ? const Icon(Icons.person, size: 80, color: Colors.grey)
                                    : null,
                              ),
                              Container(
                                decoration: const BoxDecoration(color: Colors.blueAccent, shape: BoxShape.circle),
                                padding: const EdgeInsets.all(12),
                                child: const Icon(Icons.camera_alt, color: Colors.white, size: 24),
                              ),
                            ],
                          ),
                        ),
                        
                        if (uploading) const Padding(padding: EdgeInsets.all(15), child: CircularProgressIndicator(color: Colors.blueAccent)),
                        const SizedBox(height: 40),

                        // USER FIELDS
                        _buildEditableTile("name", data['name'] ?? "Not Set", Icons.person_outline),
                        _buildEditableTile("phone", data['phone'] ?? "Not Set", Icons.phone_android),
                        _buildEditableTile("address", data['address'] ?? "Not Set", Icons.location_on_outlined),
                        _buildEditableTile("carModel", data['carModel'] ?? "Not Set", Icons.directions_car_outlined),

                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEditableTile(String field, String value, IconData icon) {
    String displayTitle = field.toUpperCase();
    if (field == 'carModel') displayTitle = "DEFAULT CAR MODEL";

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey.shade300)
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, border: Border.all(color: Colors.grey.shade300)),
          child: Icon(icon, color: Colors.black87),
        ),
        title: Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
        subtitle: Text(displayTitle, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.blueAccent, letterSpacing: 1)),
        trailing: const Icon(Icons.edit, color: Colors.black54),
        onTap: () => _editField(field, value),
      ),
    );
  }
}
