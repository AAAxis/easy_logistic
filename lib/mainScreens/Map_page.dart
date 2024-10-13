import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:taxiapp/mainScreens/MyOrder.dart';
import 'package:taxiapp/widgets/balance.dart';


class HomeTabPage extends StatefulWidget {
  static final CameraPosition _kGooglePlex = CameraPosition(
    target: LatLng(37.42796133580664, -122.085749655962),
    zoom: 14.4746,
  );

  @override
  _HomeTabPageState createState() => _HomeTabPageState();
}

class _HomeTabPageState extends State<HomeTabPage> {
  Completer<GoogleMapController> _controllerGoogleMap = Completer();
  late GoogleMapController newGoogleMapController;

  Color driverStatusColor = Colors.green;
  String driverStatusText = "Go Online";
  String appBarTitle = "";


  @override
  void initState() {
    super.initState();
    // Request location permissions when the widget initializes
    requestLocationPermission();
    // Listen to changes in driver status
    listenToDriverStatus();
    // Check if there is a current task stored in SharedPreferences

  }

  Future<void> checkForCurrentTask() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? currentTask = prefs.getString('current_task');

    // Check if currentTask contains any data other than 'false'
    if (currentTask != null && currentTask != 'searching') {
      // Open the bottom sheet with order details
      showModalBottomSheet(
        context: context,
        builder: (BuildContext context) {
          return Container(
            // Adjust the height and styling of the bottom sheet as per your requirement
            height: MediaQuery.of(context).size.height * 0.8,
            child: OrderScreen(),
          );
        },
      );
    }
  }




  Future<void> requestLocationPermission() async {
    // Request location permissions
    PermissionStatus permissionStatus = await Permission.location.request();

    if (permissionStatus.isDenied) {
      // Permission denied, handle accordingly

      // You can show a message to the user explaining why you need location permissions
    }
  }

  void listenToDriverStatus() {
    // Get the current user's UID
    String uid = FirebaseAuth.instance.currentUser!.uid;

    // Listen to changes in the driver's status in Firestore where status is "assigned"
    FirebaseFirestore.instance.collection('contractors').doc(uid).snapshots().listen((snapshot) async {
      if (snapshot.exists) {
        // Get the status from the snapshot
        String status = snapshot.get('status');


        setState(() {
          bool isDriverAvailable = status == 'online';
          bool isAssigned = status == 'assigned';

          if (isDriverAvailable) {
            locatePosition();

            // Delay showing the dialog by 5 seconds
            Future.delayed(Duration(seconds: 5), () {
              showAllOrders();
            });

            driverStatusColor = Colors.red;
            driverStatusText = "Go Offline";
          } else if (isAssigned) {
            // Show assigned dialog when the driver is assigned a task
            checkForCurrentTask();
            driverStatusColor = Colors.orange;
            driverStatusText = "Assigned";
          } else {
            driverStatusColor = Colors.green;
            driverStatusText = "Go Online";
          }
        });

      }
    });
  }

  int currentOrderIndex = 0;

  Future<void> showAllOrders() async {
    // Fetch orders collection from Firestore
    QuerySnapshot ordersSnapshot = await FirebaseFirestore.instance
        .collection('orders')
        .where('status', isEqualTo: 'ready') // Filter by status 'ready'
        .get();

    // Check if there are any orders to display
    if (ordersSnapshot.docs.isEmpty) {
      // No orders to display
      return;
    }

    // Display all orders in a bottom sheet
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.8,
          child: ListView.builder(
            itemCount: ordersSnapshot.docs.length,
            itemBuilder: (BuildContext context, int index) {
              DocumentSnapshot document = ordersSnapshot.docs[index];
              Map<String, dynamic> data = document.data() as Map<String, dynamic>;

              // Fetch the store ID
              String storeId = data['store']; // Assuming 'store' contains the store ID from the merchant collection

              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance.collection('merchants').doc(storeId).get(),
                builder: (BuildContext context, AsyncSnapshot<DocumentSnapshot> snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return CircularProgressIndicator(); // Show loading indicator while fetching merchant data
                  }

                  if (!snapshot.hasData || !snapshot.data!.exists) {
                    return ListTile(
                      title: Text("Merchant not found"), // Display error if merchant is not found
                    );
                  }

                  // Extract the store name from the merchant document
                  String storeName = snapshot.data!.get('name'); // Assuming 'name' is the field containing the store name in merchant collection

                  return ListTile(
                    title: Text("Store: $storeName"), // Display the store name
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Name: ${data['name']}"), // Display additional details if needed
                      ],
                    ),
                    trailing: ElevatedButton(
                      onPressed: () {
                        // Close all open modals
                        while (Navigator.canPop(context)) {
                          Navigator.pop(context);
                        }

                        changeStatusToAssigned(document.id); // Pass the document ID to accept the order

                      },
                      child: Text('Accept'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  );
                },
              );
            },
          ),
        );
      },
    );
  }

  Future<void> changeStatusToAssigned(String orderId) async {


    String uid = FirebaseAuth.instance.currentUser!.uid;

    // Store the orderId in shared preferences
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('current_task', orderId);
    await prefs.setString('status', 'assigned');

    await FirebaseFirestore.instance.collection('contractors').doc(uid).update({
      'current_task': orderId, // Assign driver to order
      'status': 'assigned', // Assign driver to order

    });

    // Update the order status and assign driver in Firestore
    await FirebaseFirestore.instance.collection('orders').doc(orderId).update({
      'driver': uid, // Assign driver to order
      'status': 'assigned', // Update order status
    });


  }

  void locatePosition() async {
    // Get the current user's location
    var position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    // Define the new camera position
    CameraPosition newPosition = CameraPosition(
      target: LatLng(position.latitude, position.longitude),
      zoom: 17.0,
    );

    // Move the camera to the new position
    newGoogleMapController.animateCamera(
      CameraUpdate.newCameraPosition(newPosition),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Map Screen'),

        leading: IconButton(
          icon: Icon(Icons.zoom_in_map),
          onPressed: () {
            // Implement your filtering logic here
          },
        ),


      ),
      body: Stack(
        children: [
          GoogleMap(
            mapType: MapType.normal,
            myLocationButtonEnabled: true,
            initialCameraPosition: HomeTabPage._kGooglePlex,
            myLocationEnabled: true,
            onMapCreated: (GoogleMapController controller) {
              _controllerGoogleMap.complete(controller);
              newGoogleMapController = controller;
            },
          ),
          Positioned(
            top: 10.0, // Adjust the position of the notification
            left: 10,
            right: 10,
            child: Container(
              height: 100.0, // Height of the notification
              padding: EdgeInsets.all(15.0), // Padding inside the notification
              color: Colors.white.withOpacity(1.0), // Adjust the background color and opacity
              child: StreamBuilder(
                stream: FirebaseFirestore.instance.collection('notifications').snapshots(),
                builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
                  if (!snapshot.hasData) {
                    return CircularProgressIndicator(); // Show a loading indicator while data is loading
                  }
                  // Get the last notification document from the snapshot
                  var documents = snapshot.data!.docs;
                  if (documents.isEmpty) {
                    return Text('No notifications'); // Show a message if there are no notifications
                  }
                  var lastNotification = documents.last;
                  var title = lastNotification['title']; // Assuming 'title' is the field containing the notification title
                  var body = lastNotification['body']; // Assuming 'body' is the field containing the notification body
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 20.0, // Adjust the font size of the title
                          fontWeight: FontWeight.bold, // Apply bold font weight to the title
                        ),
                      ),
                      SizedBox(height: 10.0), // Add some space between the title and body texts
                      Expanded(
                        child: Text(
                          body,
                          style: TextStyle(
                            fontSize: 16.0, // Adjust the font size of the body
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),

          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 180.0,
              width: double.infinity,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.0),
                    child: ElevatedButton(
                      onPressed: () {
                        if (driverStatusText == "Go Online") {
                          makeDriverOnlineNow(context);
                        } else if (driverStatusText == "Go Offline") {
                          makeDriverOfflineNow(context);
                        } else {
                          showModalBottomSheet(
                            context: context,
                            builder: (BuildContext context) {
                              return Container(
                                // Adjust the height and styling of the bottom sheet as per your requirement
                                height:
                                MediaQuery.of(context).size.height * 0.8,
                                child: OrderScreen(),
                              );
                            },
                          );
                        }
                      },
                      child: Text(
                        driverStatusText, // Use driverStatusText instead of hardcoding button text
                        style: TextStyle(
                          fontSize: 16.0,
                          color: Colors.white,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                        driverStatusColor, // Use driverStatusColor for button color
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void makeDriverOnlineNow(BuildContext context) async {
    // Get the current user's UID
    String uid = FirebaseAuth.instance.currentUser!.uid;

    // Get the current location
    var position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    // Fetch user's approval status from Firestore
    DocumentSnapshot userSnapshot = await FirebaseFirestore.instance
        .collection('contractors')
        .doc(uid)
        .get();


      await FirebaseFirestore.instance.collection('contractors').doc(uid).update({
        'status': 'online',
        'location': GeoPoint(position.latitude, position.longitude),
      }).then((value) {
        // Show a snack notification once update is completed
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Driver is now online')),
        );
      }).catchError((error) {
        // Handle errors if any
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $error')),
        );
      });

  }

  void makeDriverOfflineNow(BuildContext context) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    prefs.setString('status', 'offline');
    prefs.setString('current_task', 'searching');

    FirebaseFirestore.instance
        .collection('contractors')
        .doc(prefs.getString("uid")!) // Assuming 'uid' uniquely identifies the driver
        .update({
      'status': 'offline',
      'current_task': 'searching', // Assuming you want to set 'current_task' to boolean false, not string 'false'
    }).then((value) {
      // Show a snack notification once update is completed
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Driver is now offline')),
      );

      // Navigate to the MainScreen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => PaymentScreen()),
      );
    }).catchError((error) {
      // Handle errors if any
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $error')),
      );
    });
  }
}
