import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class CarMerchantProfile extends StatefulWidget {
  const CarMerchantProfile({super.key});

  @override
  State<CarMerchantProfile> createState() => _CarMerchantProfileState();
}

class _CarMerchantProfileState extends State<CarMerchantProfile> {

  final user = FirebaseAuth.instance.currentUser;

  bool uploading = false;

  /// UPDATE PROFILE IMAGE
  Future<void> _updateProfileImage() async {

    final picker = ImagePicker();

    final XFile? pickedFile =
        await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile == null) return;

    setState(() {
      uploading = true;
    });

    const cloudName = "dszki2etu";
    const uploadPreset = "QaroCarApp";

    var uri = Uri.parse(
        "https://api.cloudinary.com/v1_1/$cloudName/image/upload");

    var bytes = await pickedFile.readAsBytes();

    var request = http.MultipartRequest("POST", uri)
      ..fields['upload_preset'] = uploadPreset
      ..fields['folder'] = "merchant_images"
      ..files.add(
        http.MultipartFile.fromBytes(
          'file',
          bytes,
          filename: pickedFile.name,
        ),
      );

    var response = await request.send();

    var responseData =
        json.decode(await response.stream.bytesToString());

    if (response.statusCode == 200) {

      String imageUrl = responseData['secure_url'];

      await FirebaseFirestore.instance
          .collection('merchants')
          .doc(user!.uid)
          .set({
        'imageUrl': imageUrl
      }, SetOptions(merge: true));

    }

    setState(() {
      uploading = false;
    });
  }

  /// EDIT FIELD BOTTOM SHEET
  void _editField(String fieldName, String oldValue) {

    TextEditingController controller =
        TextEditingController(text: oldValue);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) {

        return Padding(
          padding: EdgeInsets.only(
              bottom:
                  MediaQuery.of(context).viewInsets.bottom),

          child: Container(
            padding: const EdgeInsets.all(20),

            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [

                Text(
                  "Edit $fieldName",
                  style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 15),

                TextField(
                  controller: controller,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: "Enter new value",
                  ),
                ),

                const SizedBox(height: 20),

                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                  ),

                  onPressed: () async {

                    if (controller.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context)
                          .showSnackBar(
                        const SnackBar(
                          content: Text(
                              "Field cannot be empty"),
                        ),
                      );
                      return;
                    }

                    /// PHONE VALIDATION
                    if (fieldName == "phone" &&
                        controller.text.length < 10) {

                      ScaffoldMessenger.of(context)
                          .showSnackBar(
                        const SnackBar(
                          content: Text(
                              "Invalid phone number"),
                        ),
                      );
                      return;
                    }

                    await FirebaseFirestore.instance
                        .collection('merchants')
                        .doc(user!.uid)
                        .update({
                      fieldName: controller.text.trim()
                    });

                    Navigator.pop(context);

                    setState(() {});
                  },

                  child: const Text("Update"),
                )
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

      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('merchants')
            .doc(user!.uid)
            .snapshots(),

        builder: (context, snapshot) {

          if (snapshot.connectionState ==
              ConnectionState.waiting) {

            return const Center(
              child: CircularProgressIndicator(
                  color: Colors.white),
            );
          }

          if (!snapshot.hasData ||
              !snapshot.data!.exists) {

            return const Center(
              child: Text(
                "No Data Found",
                style:
                    TextStyle(color: Colors.white),
              ),
            );
          }

          var data =
              snapshot.data!.data() as Map<String, dynamic>;

          return Column(
            children: [

              /// HEADER
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(
                        vertical: 40),

                child: const Center(
                  child: Text(
                    'Profile',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 3,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),

              /// BODY
              Expanded(
                child: Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.all(20),

                  decoration:
                      const BoxDecoration(
                    color: Colors.white,
                    borderRadius:
                        BorderRadius.only(
                      topLeft:
                          Radius.circular(30),
                      topRight:
                          Radius.circular(30),
                    ),
                  ),

                  child: SingleChildScrollView(
                    child: Column(
                      children: [

                        const SizedBox(height: 30),

                        /// PROFILE IMAGE
                        GestureDetector(
                          onTap: _updateProfileImage,

                          child: CircleAvatar(
                            radius: 70,
                            backgroundColor:
                                Colors.grey
                                    .shade200,

                            backgroundImage:
                                data['imageUrl'] !=
                                            null &&
                                        data['imageUrl'] !=
                                            ""
                                    ? NetworkImage(
                                        data['imageUrl'] +
                                            "?t=${DateTime.now().millisecondsSinceEpoch}")
                                    : null,

                            child: data['imageUrl'] ==
                                        null ||
                                    data['imageUrl'] ==
                                        ""
                                ? const Icon(
                                    Icons.camera_alt,
                                    size: 40,
                                  )
                                : null,
                          ),
                        ),

                        if (uploading)
                          const Padding(
                            padding:
                                EdgeInsets.all(
                                    10),
                            child:
                                CircularProgressIndicator(),
                          ),

                        const SizedBox(height: 40),

                        _buildEditableTile(
                            "name",
                            data['name'] ??
                                ""),

                        _buildEditableTile(
                            "phone",
                            data['phone'] ??
                                ""),

                        _buildEditableTile(
                            "address",
                            data['address'] ??
                                ""),

                        _buildInfoTile(
                          "Service Provides",
                          data['serviceProvides'] ??
                              "Not Selected",
                        ),

                        const SizedBox(height: 40),

                        ElevatedButton(
                          style:
                              ElevatedButton
                                  .styleFrom(
                            backgroundColor:
                                Colors.black,
                            foregroundColor:
                                Colors.white,
                          ),

                          onPressed: () {
                            Navigator.pop(
                                context);
                          },

                          child:
                              const Text("Back"),
                        ),
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

  Widget _buildEditableTile(
      String field, String value) {

    return Column(
      children: [

        ListTile(
          title: Text(
            value,
            style: const TextStyle(
                fontSize: 18,
                fontWeight:
                    FontWeight.w500),
          ),

          subtitle:
              Text(field.toUpperCase()),

          trailing:
              const Icon(Icons.edit),

          onTap: () {
            _editField(field, value);
          },
        ),

        const Divider(),
      ],
    );
  }

  Widget _buildInfoTile(
      String label, String value) {

    return Column(
      children: [

        ListTile(
          title: Text(
            value,
            style: const TextStyle(
                fontSize: 18,
                fontWeight:
                    FontWeight.w500),
          ),

          subtitle:
              Text(label.toUpperCase()),
        ),

        const Divider(),
      ],
    );
  }
}