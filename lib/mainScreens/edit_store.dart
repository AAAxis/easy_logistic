import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:easy_logistic/authentication/auth_screen.dart';
import 'package:url_launcher/url_launcher.dart';


class EditProfileScreen extends StatefulWidget {

  @override
  _EditProfileScreenState createState() => _EditProfileScreenState();
}

Future<void> clearSharedPreferences(BuildContext context) async {
  try {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (c) => LoginScreen()),
    );
  } catch (e) {
    // Handle any errors here
    print('Failed to clear SharedPreferences: $e');
  }
}

class _EditProfileScreenState extends State {

  Map<String, dynamic>? merchantData;
  String? siteToken;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    fetchMerchantData();
  }

  void _openMyOrdersLink() async {
    // Retrieve token from SharedPreferences
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String token = prefs.getString('siteToken') ?? '';


    // URL with token appended
    String url = 'https://polskoydm.pythonanywhere.com/$token/dashboard';


    await launch(url);

  }

  // Function to fetch merchant data from Firebase
  Future<void> fetchMerchantData() async {
    try {
      setState(() {
        _isLoading = true; // Set isLoading to true before fetching data
      });
      SharedPreferences prefs = await SharedPreferences.getInstance();
      setState(() {
        siteToken = prefs.getString('siteToken');
      });
      // Access Firestore instance
      FirebaseFirestore firestore = FirebaseFirestore.instance;

      // Get the document from the "merchants" collection using the merchant ID
      DocumentSnapshot documentSnapshot = await firestore.collection('merchants').doc(siteToken).get();

      // Check if the document exists
      if (documentSnapshot.exists) {
        setState(() {
          // Set the merchant data
          merchantData = documentSnapshot.data() as Map<String, dynamic>?;

        });
      } else {
        setState(() {
          // Handle if the document doesn't exist
          merchantData = null;
        });
      }
    } catch (error) {
      setState(() {
        // Handle any errors
        merchantData = null;
      });
    }
    setState(() {
      _isLoading = false; // Set isLoading to true before fetching data
    });
  }




  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('My Profile'),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 20),
            Text('Store Name: ${merchantData!['name'] ?? 'N/A'}'),
            SizedBox(height: 20),
            Text('Address: ${merchantData!['address'] ?? 'N/A'}'),
            SizedBox(height: 20),
            Text('Image Url: ${merchantData!['link'] ?? 'N/A'}'),
            SizedBox(height: 20),
            Text('Typee: ${merchantData!['type'] ?? 'N/A'}'),
            SizedBox(height: 20),
            Text('Reciving Orders: ${merchantData!['receivingOrders'] ?? 'N/A'}'),
            SizedBox(height: 20),
            Text('Balance: ${merchantData!['balance'] ?? 'N/A'}'),

            SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
               clearSharedPreferences(context);// Log out
              },
              child: Text('Disconnect'),
            ),
            SizedBox(height: 10),


          ],
        ),
      ),
    );
  }
}