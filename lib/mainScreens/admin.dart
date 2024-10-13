import 'package:taxiapp/invoice.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:taxiapp/mainScreens/upload.dart';
import '../alert.dart';
import '../slots.dart';
import '../widgets/merchantOrders.dart';
import 'edit_store.dart';

class AdminPage extends StatefulWidget {
  @override
  _AdminPageState createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  String? siteToken;
  Map<String, dynamic>? merchantData;
  bool receivingOrders = false;

  @override
  void initState() {
    super.initState();
    loadSiteToken();
  }

  Future<void> toggleReceivingOrdersStatus() async {
    try {
      FirebaseFirestore firestore = FirebaseFirestore.instance;
      await firestore.collection('merchants').doc(siteToken).update({
        'receivingOrders': !receivingOrders,
      });

      setState(() {
        receivingOrders = !receivingOrders;
      });
    } catch (error) {
      // Handle error
    }
  }

  Future<void> loadSiteToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      siteToken = prefs.getString('siteToken');
    });

    if (siteToken != null) {
      fetchMerchantData(siteToken!);
    }
  }

  Future<void> fetchMerchantData(String token) async {
    try {
      FirebaseFirestore firestore = FirebaseFirestore.instance;
      DocumentSnapshot documentSnapshot = await firestore.collection('merchants').doc(token).get();

      if (documentSnapshot.exists) {
        setState(() {
          merchantData = documentSnapshot.data() as Map<String, dynamic>?;
          receivingOrders = merchantData!['receivingOrders'] ?? false;
        });
      } else {
        setState(() {
          merchantData = null;
        });
      }
    } catch (error) {
      setState(() {
        merchantData = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Admin Panel'),
      ),
      body: siteToken != null
          ? merchantData != null
          ? ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 50,
                backgroundImage: merchantData!['link'] != null
                    ? NetworkImage(merchantData!['link'])
                    : null,
                child: merchantData!['link'] == null
                    ? Icon(Icons.store, size: 50)
                    : null,
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ' ${merchantData!['name'] ?? 'N/A'}',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: () {
                        toggleReceivingOrdersStatus(); // Toggle receiving orders status
                      },
                      child: Text(receivingOrders ? 'Close Store' : 'Open Store'),
                    ),
                  ],
                ),
              ),
            ],
          ),

          SizedBox(height: 20),
          ListTile(
            leading: Icon(Icons.edit),
            title: Text('My Profile'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => EditProfileScreen()),
              );
            },
          ),
          ListTile(
            leading: Icon(Icons.add_box),
            title: Text('Add Item'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ProductScreen()),
              );
            },
          ),
          ListTile(
            leading: Icon(Icons.credit_card),
            title: Text('Payment'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => InvoiceGenerator()),
              );
            },
          ),
          ListTile(
            leading: Icon(Icons.schedule),
            title: Text('Working Hours'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => SchedulePage()),
              );
            },
          ),
          ListTile(
            leading: Icon(Icons.notifications),
            title: Text('Add Alert'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => NotificationPage()),
              );
            },
          ),

          ListTile(
            leading: Icon(Icons.history),
            title: Text('My Orders'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => PaymentStore()),
              );
            },
          ),
        ],
      )
          : Center(child: CircularProgressIndicator())
          : Center(child: Text('Site Token not loaded')),
    );
  }
}
