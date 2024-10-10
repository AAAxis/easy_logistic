import 'package:easy_logistic/invoice.dart';
import 'package:easy_logistic/mainScreens/addcar.dart';
import 'package:easy_logistic/mainScreens/notifications.dart';
import 'package:easy_logistic/mainScreens/qr_code.dart';
import 'package:easy_logistic/mainScreens/schedule_screen.dart';
import 'package:easy_logistic/widgets/balance.dart';
import 'package:easy_logistic/widgets/my_settings.dart';
import 'package:flutter/material.dart';
import 'package:easy_logistic/authentication/auth_screen.dart';
import 'package:easy_logistic/global/global.dart';
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
            "images/profile.png",
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
            leading: Icon(Icons.receipt),
            title: Text('Create Payment'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => InvoiceGenerator()),
              );
            },
          ),

          ListTile(
            leading: const Icon(Icons.date_range, color: Colors.black),
            title: const Text(
              "Schedudle",
              style: TextStyle(color: Colors.black),
            ),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (c) => ScheduleScreen()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.currency_bitcoin_outlined, color: Colors.black),
            title: const Text(
              "My Balance",
              style: TextStyle(color: Colors.black),
            ),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (c) => PaymentScreen()),
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