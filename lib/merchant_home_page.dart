import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_application_1/carmerchantProfile.dart';
import 'package:flutter_application_1/intro_page.dart';
import 'mechanic_request_popup.dart';
import 'merchant_tracking_page.dart';
import 'merchant_orders_page.dart';

class MerchantHomePage extends StatefulWidget {
  const MerchantHomePage({super.key});

  @override
  State<MerchantHomePage> createState() => _MerchantHomePageState();
}

class _MerchantHomePageState extends State<MerchantHomePage> {

  final AudioPlayer _audioPlayer = AudioPlayer();
  int lastBookingCount = 0;

  StreamSubscription<Position>? positionStream;

  @override
  void initState() {
    super.initState();
    startLocationUpdates();
  }

  @override
  void dispose() {
    positionStream?.cancel();
    super.dispose();
  }

  // 🔴 START GPS LOCATION STREAM
  void startLocationUpdates() async {

    LocationPermission permission = await Geolocator.requestPermission();

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return;
    }

    positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5,
      ),
    ).listen((Position position) {

      String mechanicId = FirebaseAuth.instance.currentUser!.uid;

      FirebaseFirestore.instance
          .collection("merchants")
          .doc(mechanicId)
          .update({
        "location": GeoPoint(
          position.latitude,
          position.longitude,
        )
      });

    });
  }

  void playNotification() async {
    await _audioPlayer.play(AssetSource('sounds/notification.mp3'));
  }

  void showRequestPopup(String bookingId, Map<String,dynamic> data) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MechanicRequestPopup(
          bookingId: bookingId,
          bookingData: data,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,

      drawer: Drawer(
        child: Column(
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Colors.black),
              child: Center(
                child: CircleAvatar(
                  radius: 40,
                  backgroundColor: Colors.white,
                  child: Icon(Icons.person,size:40,color:Colors.black),
                ),
              ),
            ),

            ListTile(
              leading: const Icon(Icons.person),
              title: const Text("Profile"),
              onTap: (){
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context)=> const CarMerchantProfile(),
                  ),
                );
              },
            ),

            ListTile(
              leading: const Icon(Icons.history, color: Colors.blueAccent),
              title: const Text("Orders"),
              onTap: (){
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:(context)=> const MerchantOrdersPage(),
                  ),
                );
              },
            ),

            const Spacer(),
            const Divider(),

            ListTile(
              leading: const Icon(Icons.logout,color:Colors.red),
              title: const Text(
                "Logout",
                style: TextStyle(color: Colors.red),
              ),
              onTap:(){
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder:(context)=> const IntroPage(),
                  ),
                );
              },
            ),

            const SizedBox(height:20)
          ],
        ),
      ),

      body: Column(
        children: [

          // HEADER
          Builder(
            builder:(context)=> Container(
              width:double.infinity,
              padding:const EdgeInsets.symmetric(
                  vertical:40,horizontal:20),

              child:Row(
                children:[
                  IconButton(
                    icon:const Icon(Icons.menu,color:Colors.white),
                    onPressed:(){
                      Scaffold.of(context).openDrawer();
                    },
                  ),

                  const Expanded(
                    child:Center(
                      child:Text(
                        "Home",
                        style:TextStyle(
                          fontSize:20,
                          letterSpacing:3,
                          fontWeight:FontWeight.bold,
                          color:Colors.white,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width:48)
                ],
              ),
            ),
          ),

          // BODY
          Expanded(
            child:Container(
              padding:const EdgeInsets.all(20),

              decoration:const BoxDecoration(
                color:Colors.white,
                borderRadius:BorderRadius.only(
                  topLeft:Radius.circular(30),
                  topRight:Radius.circular(30),
                ),
              ),

              child:StreamBuilder<QuerySnapshot>(
                stream:FirebaseFirestore.instance
                    .collection("bookings")
                    .where("status",isEqualTo:"searching")
                    .snapshots(),

                builder:(context,snapshot){

                  if(!snapshot.hasData){
                    return const Center(
                        child:CircularProgressIndicator());
                  }

                  var bookings = snapshot.data!.docs;

                  // 🔔 detect new booking
                  if(bookings.length > lastBookingCount){

                    var newBooking = bookings.last;
                    var data = newBooking.data() as Map<String,dynamic>;

                    playNotification();

                    WidgetsBinding.instance
                        .addPostFrameCallback((_){
                      showRequestPopup(newBooking.id,data);
                    });

                    lastBookingCount = bookings.length;
                  }

                  if(bookings.isEmpty){
                    return const Center(
                      child:Text("No Service Requests"),
                    );
                  }

                  return ListView.builder(
                    itemCount:bookings.length,
                    itemBuilder:(context,index){

                      var booking = bookings[index];
                      var data = booking.data() as Map<String,dynamic>;

                      String serviceType = data["serviceType"] ?? "";
                      String carModel = data["carModel"] ?? "";
                      String address = data["address"] ?? "";
                      String bookingId = booking.id;

                      return Card(
                        elevation:4,
                        margin:const EdgeInsets.symmetric(vertical:10),

                        child:Padding(
                          padding:const EdgeInsets.all(15),

                          child:Column(
                            crossAxisAlignment:CrossAxisAlignment.start,
                            children:[

                              Text(
                                "Service: $serviceType",
                                style:const TextStyle(
                                  fontWeight:FontWeight.bold,
                                  fontSize:18,
                                ),
                              ),

                              const SizedBox(height:5),

                              Text("Car: $carModel"),
                              Text("Address: $address"),

                              const SizedBox(height:15),

                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,

                                children:[

                                  ElevatedButton(
                                    style:ElevatedButton.styleFrom(
                                      backgroundColor:Colors.green,
                                    ),
                                    onPressed:(){

                                      String mechanicId =
                                          FirebaseAuth.instance.currentUser!.uid;

                                      FirebaseFirestore.instance
                                          .collection("bookings")
                                          .doc(bookingId)
                                          .update({
                                        "status":"accepted",
                                        "mechanicId": mechanicId
                                      }).then((_) {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => MerchantTrackingPage(
                                              bookingId: bookingId,
                                              mechanicId: mechanicId,
                                            ),
                                          ),
                                        );
                                      });

                                    },
                                    child:const Text("Accept"),
                                  ),

                                  ElevatedButton(
                                    style:ElevatedButton.styleFrom(
                                      backgroundColor:Colors.red,
                                    ),
                                    onPressed:(){

                                      FirebaseFirestore.instance
                                          .collection("bookings")
                                          .doc(bookingId)
                                          .update({
                                        "status":"rejected"
                                      });

                                    },
                                    child:const Text("Reject"),
                                  ),
                                ],
                              )
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          )
        ],
      ),
    );
  }
}