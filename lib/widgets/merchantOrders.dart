import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

import '../global/global.dart';

class PaymentStore extends StatefulWidget {
  @override
  _PaymentStoreState createState() => _PaymentStoreState();
}

class _PaymentStoreState extends State<PaymentStore> with TickerProviderStateMixin {
  late TabController _tabController;
  int _selectedIndex = 0; // Initialize with the default index for "Paid" tab

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_handleTabSelection);
    _fetchPayments();
  }

  void _handleTabSelection() {
    setState(() {
      _selectedIndex = _tabController.index;
    });
  }



  List<DocumentSnapshot> _paidOrders = [];
  List<DocumentSnapshot> _otherOrders = [];


  Future<void> _fetchPayments() async {
    QuerySnapshot querySnapshot = await FirebaseFirestore.instance
        .collection('orders')
        .where('store', isEqualTo: sharedPreferences!.getString("siteToken"))
        .get();

    setState(() {
      _paidOrders =
          querySnapshot.docs.where((order) => order['status'] == 'paid')
              .toList();
      _otherOrders =
          querySnapshot.docs.where((order) => order['status'] != 'paid')
              .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text('History'),
          bottom: TabBar(
            controller: _tabController,
            tabs: [
              Tab(text: 'Paid'),
              Tab(text: 'Other'),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildOrdersList(_paidOrders, 0),
            _buildOrdersList(_otherOrders, 1),
          ],
        ),
      ),
    );
  }

  Widget _buildOrdersList(List<DocumentSnapshot> orders, int tabIndex) {
    return ListView.builder(
      itemCount: orders.length,
      itemBuilder: (context, index) {
        final order = orders[index];
        Timestamp timestamp = order['timestamp'];
        DateTime dateTime = timestamp.toDate();
        String formattedDate = DateFormat('dd MMM yyyy').format(dateTime);
        String status = order['status']; // Get the status of the order

        // Choose an icon based on the status (you can customize this)
        IconData icon;
        if (status == 'paid') {
          icon = Icons.payment; // Example icon for paid orders
        } else {
          icon = Icons.outlined_flag; // Example icon for other statuses
        }

        return ListTile(
          leading: CircleAvatar(
            backgroundColor: Colors.blue, // Background color of the circle
            child: Icon(icon, color: Colors.white), // Icon inside the circle
          ),
          title: Text(order.id),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Time: $formattedDate'),
              Text('Status: $status'), // Display the status
            ],
          ),
          onTap: () {
            if (tabIndex == 0) { // Check if the "Paid" tab is selected
              _fetchCartForOrder(order.id);
            }
          },
        );
      },
    );
  }



  void _updateOrderStatus(String orderId, String status) {
    // Update order status in Firestore
    FirebaseFirestore.instance.collection('orders').doc(orderId).update({
      'status': status,
    }).then((_) {
      // After updating status, fetch payments again to reflect changes
      _fetchPayments();
    });
  }


  Future<void> _fetchCartForOrder(String orderId) async {
    // Fetch the order document
    DocumentSnapshot orderSnapshot = await FirebaseFirestore.instance
        .collection('orders')
        .doc(orderId)
        .get();

    // Extract total from the order document
    double total = orderSnapshot['total'].toDouble();

    // Extract cart data from the order document
    List<DocumentSnapshot> cartDocs = [];
    if (orderSnapshot.exists) {
      // Fetch the subcollection 'cart' for the selected order
      QuerySnapshot cartQuerySnapshot = await FirebaseFirestore.instance
          .collection('orders')
          .doc(orderId)
          .collection('cart')
          .get();

      cartDocs = cartQuerySnapshot.docs;
    }

    // Extract comment from order document
    String orderComment = 'No Comments';
    if (orderSnapshot.exists &&
        orderSnapshot.data() != null &&
        (orderSnapshot.data() as Map<String, dynamic>).containsKey('comment')) {
      orderComment = (orderSnapshot.data() as Map<String, dynamic>)['comment'];
    }


    _showCartDialog(cartDocs, orderComment, total, orderId); // Pass orderId as the fourth argument

  }

  void _showCartDialog(List<DocumentSnapshot> cartDocs, String orderComment, double total, String orderId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Cart Details'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (cartDocs != null && cartDocs.isNotEmpty) ...[
                  ...cartDocs.map((cartItem) {
                    // Cast data to Map<String, dynamic>
                    Map<String, dynamic> data = cartItem.data() as Map<String, dynamic>;

                    int quantity = data.containsKey('quantity') ? data['quantity'] : 0;
                       String productImageUrl = data.containsKey('product_image_url') ? data['product_image_url'] : '';
                    String productName = data.containsKey('product_name') ? data['product_name'] : 'Unnamed Product';

                    return ListTile(
                      title: Text(productName),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [

                          Text('Quantity: $quantity'),
                        ],
                      ),
                      leading: productImageUrl.isNotEmpty ? Image.network(
                        productImageUrl,
                        width: 50,
                        height: 50,
                        fit: BoxFit.cover,
                      ) : null,
                    );
                  }),
                ],
                SizedBox(height: 10),
                Text('Total: $total'),
                SizedBox(height: 10),
                if (orderComment != null && orderComment.isNotEmpty) ...[
                  SizedBox(height: 10),
                  Text('Order Comment:', style: TextStyle(fontWeight: FontWeight.bold)),
                  Text(orderComment),
                ],
                SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        _updateOrderStatus(orderId, 'ready');
                        Navigator.of(context).pop();
                      },
                      child: Text('Ready'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: Colors.black,
                      ),
                    ),
                    OutlinedButton(
                      onPressed: () {
                        _updateOrderStatus(orderId, 'declined');
                        Navigator.of(context).pop();
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: BorderSide(color: Colors.red),
                      ),
                      child: Text(
                        'Decline',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

}