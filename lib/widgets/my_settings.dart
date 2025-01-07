import 'package:taxiapp/authentication/email_login.dart';
import 'package:taxiapp/mainScreens/addcar.dart';
import 'package:flutter/material.dart';
import 'package:taxiapp/global/global.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:taxiapp/widgets/Main_bar.dart';


class MyDrawerPage extends StatefulWidget {
  @override
  _MyDrawerPageState createState() => _MyDrawerPageState();
}

class _MyDrawerPageState extends State<MyDrawerPage> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final GlobalKey<FormState> formKey = GlobalKey<FormState>(); // Initialize formKey

  @override
  void initState() {
    super.initState();
  }

  Future<void> signOutAndClearPrefs(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => EmailLoginScreen()),
    );
  }

  bool isPhoneNumberValid(String? value) {
    if (value == null) return false;
    final RegExp regex = RegExp(r'^\+\d{11}$');
    return regex.hasMatch(value);
  }

  void updateName(String newName) {
    setState(() {
      sharedPreferences!.setString("name", newName);
    });
  }

  void updateAddress(String newAddress) {
    setState(() {
      sharedPreferences!.setString("address", newAddress);
    });
  }

  void updatePhone(String newPhone) {
    setState(() {
      sharedPreferences!.setString("phone", newPhone);
    });
  }



  @override

  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('My Profile'),
        leading: BackButton(
          color: Colors.black, // You can customize the color here
          onPressed: () {
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(builder: (c) => MainScreen()),
            );
          },
        ),
      ),
      body: ListView(
        children: [
          Container(
            width: 180,
            height: 180,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              image: DecorationImage(
                fit: BoxFit.cover,
                // Use AssetImage to load the image from assets
                image: AssetImage('images/people.png'),
              ),
            ),
          ),
          SizedBox(height: 20),

          ListTile(
            leading: const Icon(Icons.email, color: Colors.black),
            title: Text(
              FirebaseAuth.instance.currentUser?.email ?? "No Email",
              style: const TextStyle(color: Colors.black),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.person, color: Colors.black),
            title: Text(
              sharedPreferences!.getString("name") ?? "No Name",
              style: TextStyle(color: Colors.black),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.location_city, color: Colors.black),
            title: Text(
              sharedPreferences!.getString("address") ?? "No Address",
              style: TextStyle(color: Colors.black),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.phone, color: Colors.black),
            title: Text(
              sharedPreferences!.getString("phone") ?? "No Phone",
              style: TextStyle(color: Colors.black),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.directions_car_sharp, color: Colors.black),
            title: const Text(
              "Vehicle Info",
              style: TextStyle(color: Colors.black),
            ),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (c) => CarInfoList()),
              );
            },
          ),// Adding


          const Divider(
            height: 10,
            color: Colors.grey,
            thickness: 2,
          ),

          ListTile(
            leading: Icon(Icons.delete, color: Colors.red),
            title: Text(
              "Delete Profile",
              style: TextStyle(color: Colors.black),
            ),
            onTap: () async {
              // Clear preferences
              signOutAndClearPrefs(context);

              String email =
                  FirebaseAuth.instance.currentUser?.email ?? "No Email";
              // Encode the email address to handle special characters
              String encodedEmail = Uri.encodeComponent(email);

              var response = await http.delete(Uri.parse(
                  'https://polskoydm.pythonanywhere.com/delete?email=$encodedEmail'));

              if (response.statusCode == 200) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text("Delete User Data Request sent"),
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text("Failed to delete account data"),
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
  }
}
