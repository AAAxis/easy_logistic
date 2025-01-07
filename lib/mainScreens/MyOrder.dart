
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../global/global.dart';


class OrderDetailsScreen extends StatefulWidget {
  final Order order;

  const OrderDetailsScreen({Key? key, required this.order}) : super(key: key);

  @override
  _OrderDetailsScreenState createState() => _OrderDetailsScreenState();
}

class _OrderDetailsScreenState extends State<OrderDetailsScreen> {
  String storeName = '';
  String storeAddress = '';
  String _formatTimestamp(DateTime timestamp) {
    // Format the timestamp to display only the time
    String time = '${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}';
    return '$time';
  }

  @override
  void initState() {
    super.initState();
    fetchStoreDetails(widget.order.store);
  }



  void _updateDropOffStatus(BuildContext context) async {
    SharedPreferences? sharedPreferences = await SharedPreferences.getInstance();

    // Fetch current balance from Firestore
    DocumentSnapshot driverSnapshot = await FirebaseFirestore.instance
        .collection('contractors')
        .doc(sharedPreferences!.getString("uid")!)
        .get();

    // Get current balance from Firestore and cast it to double
    double currentBalance = (driverSnapshot['balance'] ?? 0).toDouble();

    // Retrieve the current task ID
    String? currentTaskId = sharedPreferences.getString("current_task");

    // Fetch the current task document
    DocumentSnapshot taskSnapshot = await FirebaseFirestore.instance
        .collection('orders')
        .doc(currentTaskId)
        .get();

    // Retrieve the merchant ID from the current task
    String merchantId = taskSnapshot['store'];
    // Retrieve the total amount for the current task and cast it to double
    double totalAmount = (taskSnapshot['total'] ?? 0).toDouble();
    // Fetch old balance of the merchant and cast it to double

    DocumentSnapshot merchantSnapshot = await FirebaseFirestore.instance
        .collection('merchants')
        .doc(merchantId)
        .get();

    // Get the old balance from Firestore and cast it to double
    double oldBalance = (merchantSnapshot['balance'] ?? 0).toDouble();


    // Update order status to 'completed'
    await FirebaseFirestore.instance
        .collection('orders')
        .doc(currentTaskId)
        .update({'status': 'completed'});

    // Close the bottom sheet
    Navigator.pop(context);

    // Delay for 2 seconds before updating driver's status
    await Future.delayed(Duration(seconds: 2));

    // Update driver's status to 'online'
    await FirebaseFirestore.instance
        .collection('contractors')
        .doc(sharedPreferences.getString("uid")!)
        .update({
      'status': 'online',
      'current_task': false,
    });

    // Add $20 payment row to subcollection 'payments'
    await FirebaseFirestore.instance
        .collection('contractors')
        .doc(sharedPreferences.getString("uid")!)
        .collection('payments')
        .add({
      'amount': 20,
      'current_task': currentTaskId,
      'timestamp': FieldValue.serverTimestamp(),
    });

    // Update local shared preferences
    sharedPreferences.setString('current_task', 'false');
    sharedPreferences.setString('status', 'online');

    // Update driver's balance in Firestore
    await FirebaseFirestore.instance
        .collection('contractors')
        .doc(sharedPreferences.getString("uid")!)
        .update({'balance': currentBalance + 20});

    // Update merchant's balance in Firestore by adding the total amount to the old balance
    await FirebaseFirestore.instance
        .collection('merchants')
        .doc(merchantId)
        .update({'balance': oldBalance + totalAmount});
  }

  void _updatePickupStatus() {
    setState(() {
      widget.order.status = 'picked up'; // Update status locally
    });

    // Open an AlertDialog with the same data as on the bottom sheet
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Order Details'),
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Display cart items
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: widget.order.cartItems.map((cartItem) => Row(
                  children: [
                    Image.network(
                      cartItem.image,
                      width: 50, // Adjust the width as needed
                      height: 50, // Adjust the height as needed
                    ),
                    SizedBox(width: 8), // Add some space between image and text
                    Text(
                      '${cartItem.name} - X ${cartItem.quantity}',
                      style: TextStyle(fontSize: 16),
                    ),
                  ],
                )).toList(),
              ),
              SizedBox(height: 16.0), // Spacing between sections
              Text('Order Total: ${widget.order.total.toString()}'),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                // Update the order status to "picked up" in Firebase
                FirebaseFirestore.instance
                    .collection('orders')
                    .doc(sharedPreferences!.getString("current_task")) // Assuming 'name' field uniquely identifies the order
                    .update({'status': 'picked up'})
                    .then((value) {
                  // If the update is successful, close the AlertDialog
                  Navigator.pop(context);
                }).catchError((error) {
                  // If there's an error updating the order status, show an error message
                  print('Error updating order status: $error');
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text('Failed to update order status'),
                    duration: Duration(seconds: 2),
                  ));
                });
              },
              child: Text('Confirm'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close the AlertDialog
              },
              child: Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Future<void> fetchStoreDetails(String storeId) async {
    try {
      DocumentSnapshot snapshot = await FirebaseFirestore.instance
          .collection('merchants')
          .doc(storeId)
          .get();

      if (snapshot.exists) {
        setState(() {
          Map<String, dynamic> data = snapshot.data() as Map<String, dynamic>;
          storeName = data['name'] as String;
          storeAddress = data['address'] as String;
        });
      }
    } catch (error) {
      print('Error fetching store details: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Order Details'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0), // Add padding around the content
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              GestureDetector(
                onTap: () async {
                  // Construct the map URL with the store address
                  String mapUrl = 'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(storeAddress)}';
                  await launch(mapUrl);
                },
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.store, size: 24.0), // Store icon
                    SizedBox(width: 8.0), // Spacing between icon and text
                    Text(
                      storeName,
                      style: TextStyle(fontSize: 16.0),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 8.0), // Spacing between rows
              Text('   .   Order: ${sharedPreferences!.getString("current_task") ?? "No Task"}'),
              Text('   .   Created Time: ${_formatTimestamp(widget.order.timestamp)}'),
              Text('   .   Status: ${widget.order.status}'),
              Text('   .   Name: ${widget.order.name}'),
              Text('   .   Comment: ${widget.order.comment}'), // Add this line to display the order comment


              SizedBox(height: 8.0), // Spacing between rows
              GestureDetector(
                onTap: () async {
                  // Construct the map URL with the address
                  String mapUrl = 'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(widget.order.address)}';
                  await launch(mapUrl);
                },
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.home, size: 24.0), // Home icon
                    SizedBox(width: 8.0), // Spacing between icon and text
                    Text(
                      widget.order.address,
                      style: TextStyle(fontSize: 16.0),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 16.0), // Spacing between sections
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  SizedBox(height: 36.0),
                  ElevatedButton(
                    onPressed: () {
                      if (widget.order.status == 'picked up') {
                        _updateDropOffStatus(context);

                        // If the update is successful, update the UI and close the AlertDialog

                      } else {
                        _updatePickupStatus();
                        // If the update is successful, update the UI and close the AlertDialog

                      }
                    },
                    style: ButtonStyle(
                      backgroundColor: MaterialStateProperty.resolveWith<Color>((Set<MaterialState> states) {
                        // Set the button color based on the order status
                        if (states.contains(MaterialState.disabled)) {
                          return widget.order.status == 'picked up' ? Colors.red : Colors.black;
                        }
                        return widget.order.status == 'picked up' ? Colors.red : Colors.black;
                      }),
                    ),
                    child: Text(
                      widget.order.status == 'picked up' ? 'Drop Off' : 'Pick Up',
                      style: TextStyle(
                        color: Colors.white,
                      ),
                    ),
                  )

                ],
              ),

            ],
          ),
        ),
      ),
    );
  }

}

class CartItem {
  final String name;
  final int quantity;
  final String image;

  CartItem({
    required this.name,
    required this.quantity,
    required this.image,
  });
}
class Order {
  final String address;
  final String driver;
  final String email;
  final String name;
  String status;
  final String store;
  final DateTime timestamp;
  final int total;
  final String comment; // Add comment field to the Order class
  List<CartItem> cartItems;

  Order({
    required this.address,
    required this.driver,
    required this.email,
    required this.name,
    required this.status,
    required this.store,
    required this.timestamp,
    required this.total,
    required this.comment, // Initialize comment directly in the constructor
    required this.cartItems,
  });
}



class OrderScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: _getOrderIdFromSharedPrefs(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(),
          );
        }

        if (snapshot.hasError || snapshot.data == null) {
          return Center(
            child: Text('Error fetching order ID'),
          );
        }

        return OrderDetailsWidget(orderId: snapshot.data!);
      },
    );
  }

  Future<String> _getOrderIdFromSharedPrefs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('current_task') ?? '';
  }
}
class OrderDetailsWidget extends StatelessWidget {
  final String orderId;

  const OrderDetailsWidget({Key? key, required this.orderId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('orders').doc(orderId).get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Text('Error: ${snapshot.error}'),
          );
        }

        if (!snapshot.hasData || snapshot.data!.data() == null) {
          return Center(
            child: Text('Order not found'),
          );
        }

        var orderData = snapshot.data!.data() as Map<String, dynamic>;

        Order order = Order(
          address: orderData['address'],
          driver: orderData['driver'],
          email: orderData['email'],
          name: orderData['name'],
          status: orderData['status'],
          store: orderData['store'],
          timestamp: (orderData['timestamp'] as Timestamp).toDate(),
          total: orderData['total'],
          comment: orderData['comment'] ?? 'No Comment', // Include the comment field with a default value if it's null
          cartItems: [], // Initialize cartItems list
        );


        // Fetch cart items
        FirebaseFirestore.instance
            .collection('orders')
            .doc(orderId)
            .collection('cart')
            .get()
            .then((querySnapshot) {
          List<CartItem> cartItems = [];
          querySnapshot.docs.forEach((doc) {
            cartItems.add(CartItem(
              name: doc['product_name'],
              quantity: doc['quantity'],
              image: doc['product_image_url'],
            ));
          });

          // Update the order with cart items
          order.cartItems = cartItems;
        }).catchError((error) {
          print('Error fetching cart items: $error');
        });

        return OrderDetailsScreen(order: order);
      },
    );
  }
}
