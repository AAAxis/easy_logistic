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
  late AnimationController _controller;
  double _swipeOffset = 0.0;



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
            top: 10.0, // Adjust the position of the notifications
            left: 10,
            right: 10,
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('notifications').snapshots(),
              builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
                if (!snapshot.hasData) {
                  return Center(child: CircularProgressIndicator()); // Show a loading indicator while data is loading
                }

                // Get the list of notification documents from the snapshot
                var documents = snapshot.data!.docs;

                if (driverStatusText == "Go Offline") {
                  // Driver is online, show clickable link to open the current task
                  return GestureDetector(
                    onTap: () {
                      // Open the current task when clicked
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 5.0), // Add vertical spacing
                      child: Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10.0), // Set the border radius for rounded corners
                        ),
                        margin: EdgeInsets.zero, // Remove default margin from Card
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 5.0), // Consistent padding
                              child: Text(
                                "Support",
                                style: TextStyle(
                                  fontSize: 18.0, // Match font size with notifications
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 5.0), // Consistent padding
                              child: Text(
                                "Searching for task, try to change your location close to busy area",
                                style: TextStyle(
                                  fontSize: 16.0, // Match font size with notifications
                                  color: Colors.black,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                } else if (documents.isEmpty) {
                  return Text('No notifications'); // Show a message if there are no notifications
                }

                // Create a list of notification widgets
                List<Widget> notificationWidgets = documents.map((document) {
                  var title = document['title']; // Assuming 'title' is the field containing the notification title
                  var body = document['body']; // Assuming 'body' is the field containing the notification body
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 5.0), // Add vertical spacing between notifications
                    child: Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.0), // Set the border radius for rounded corners
                      ),
                      margin: EdgeInsets.zero, // Remove default margin from Card
                      child: ListTile(
                        contentPadding: EdgeInsets.symmetric(horizontal: 10.0, vertical: 5.0), // Optional padding for ListTile
                        title: Text(
                          title,
                          style: TextStyle(
                            fontSize: 18.0,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Text(
                          body,
                          style: TextStyle(
                            fontSize: 16.0,
                          ),
                        ),
                        // Optional: Add an onTap action for each notification
                        onTap: () {
                          // Handle tap on notification
                        },
                      ),
                    ),
                  );
                }).toList();

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: notificationWidgets,
                );
              },
            ),
          ),

          // Swipe toggle after the map
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: GestureDetector(
              onHorizontalDragUpdate: (details) {
                setState(() {
                  _swipeOffset += details.delta.dx; // Update swipe offset
                });
              },
              onHorizontalDragEnd: (details) {
                if (details.primaryVelocity != null && details.primaryVelocity! > 0) {
                  // Swipe right to go online
                  _swipeOffset = 0; // Reset position
                  setState(() {
                    driverStatusText = "Go Offline"; // Update status
                  });
                  makeDriverOnlineNow(context); // Custom function to make the driver online
                } else if (details.primaryVelocity != null && details.primaryVelocity! < 0) {
                  // Swipe left to go offline
                  _swipeOffset = 0; // Reset position
                  setState(() {
                    driverStatusText = "Go Online"; // Update status
                  });
                  makeDriverOfflineNow(context); // Custom function to make the driver offline
                } else {
                  // If the swipe was too slow, reset the position
                  setState(() {
                    _swipeOffset = 0;
                  });
                }
              },
              child: AnimatedContainer(
                duration: Duration(milliseconds: 300),
                transform: Matrix4.translationValues(_swipeOffset, 0, 0), // Animate the swipe
                height: 100.0,
                width: double.infinity,
                color: Colors.blue.shade200,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.0),
                      child: Row(
                        children: [
                          Icon(
                            driverStatusText == "Go Offline" ? Icons.wifi_off : Icons.wifi,
                            color: driverStatusText == "Go Offline" ? Colors.red : Colors.green,
                            size: 40.0,
                          ),
                          SizedBox(width: 10.0),
                          Text(
                            driverStatusText == "Go Offline"
                                ? "Swipe left to go offline"
                                : "Swipe right to go online",
                            style: TextStyle(fontSize: 18.0),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )

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

      }).catchError((error) {
        // Handle errors if any
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $error')),
        );
      });

  }

  void makeDriverOfflineNow(BuildContext context) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    // Update the status in SharedPreferences
    prefs.setString('status', 'offline');
    prefs.setString('current_task', 'searching');

    // Update Firestore
    FirebaseFirestore.instance
        .collection('contractors')
        .doc(prefs.getString("uid")!) // Assuming 'uid' uniquely identifies the driver
        .update({
      'status': 'offline',
      'current_task': 'searching',
    }).then((value) {
      // Reset the swipe offset and update the UI
      setState(() {
        _swipeOffset = 0; // Reset the position to show the offline state correctly
        driverStatusText = "Go Online"; // Update the status text
        driverStatusColor = Colors.green; // Update the status color
      });

      // Navigate to the MainScreen or any other relevant screen
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
