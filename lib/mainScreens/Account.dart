import 'package:driver_app/addcar.dart';
import 'package:driver_app/mainScreens/bank.dart';
import 'package:driver_app/mainScreens/my_settings.dart';

import 'package:driver_app/mainScreens/notifications.dart';
import 'package:driver_app/mainScreens/qr_code.dart';
import 'package:driver_app/slots.dart';
import 'package:flutter/material.dart';
import 'package:driver_app/authentication/auth_screen.dart';
import 'package:driver_app/global/global.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AccountPage extends StatefulWidget {
  @override
  _AccountPageState createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {

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
      MaterialPageRoute(builder: (context) => LoginScreen()),
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

  void updatePhone(String newPhone) {
    setState(() {
      sharedPreferences!.setString("phone", newPhone);
    });
  }


  @override
  Widget build(BuildContext context) {


    return Scaffold(
      body: ListView(
        children: [
          SizedBox(height: 22.0),
          Image.asset(
            "images/Preview.png",
            width: 400.0,
            height: 250.0,
          ),
          SizedBox(height: 20.0),

          ListTile(
            leading: const Icon(Icons.account_circle, color: Colors.black),
            title: const Text(
              "My Profile",
              style: TextStyle(color: Colors.black),
            ),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (c) => MyDrawerPage()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.savings_outlined, color: Colors.black),
            title: const Text(
              "My Bank",
              style: TextStyle(color: Colors.black),
            ),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (c) => EditBankScreen()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.local_laundry_service, color: Colors.black),
            title: const Text(
              "My Service",
              style: TextStyle(color: Colors.black),
            ),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (c) => CarInfoList()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.timelapse, color: Colors.black),
            title: const Text(
              "Working Hours",
              style: TextStyle(color: Colors.black),
            ),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (c) => SchedulePage()),
              );
            },
          ),

          ListTile(
            leading: const Icon(Icons.qr_code, color: Colors.black),
            title: const Text(
              "QR Code",
              style: TextStyle(color: Colors.black),
            ),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (c) => YourScreen()),
              );
            },
          ),


          ListTile(
            leading: const Icon(Icons.notification_add_outlined, color: Colors.black),
            title: const Text(
              "Notifications",
              style: TextStyle(color: Colors.black),
            ),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (c) => NotificationScreen()),
              );
            },
          ),


          const Divider(
            height: 10,
            color: Colors.grey,
            thickness: 2,
          ),

          ListTile(
            leading: const Icon(Icons.exit_to_app, color: Colors.black),
            title: const Text(
              "Sign Out",
              style: TextStyle(color: Colors.black),
            ),
            onTap: () {
              signOutAndClearPrefs(context);
            },
          ),




        ],
      ),
    );
  }
}