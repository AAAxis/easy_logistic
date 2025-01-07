import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:taxiapp/authentication/email_login.dart';
import 'package:taxiapp/mainScreens/admin.dart';
import 'package:taxiapp/mainScreens/notifications.dart';
import 'package:taxiapp/mainScreens/qr_code.dart';
import 'package:taxiapp/mainScreens/schedule_screen.dart';
import 'package:taxiapp/widgets/balance.dart';
import 'package:taxiapp/widgets/my_settings.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../global/global.dart';

class AccountPage extends StatefulWidget {
  @override
  _AccountPageState createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  final GlobalKey<FormState> formKey = GlobalKey<FormState>(); // Initialize formKey
  final TextEditingController codeController = TextEditingController();
  int tapCount = 0;

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

  Future<void> loginMerchant() async {
    final enteredCode = codeController.text.trim();

    try {
      DocumentSnapshot merchantSnapshot =
      await FirebaseFirestore.instance.collection("merchants").doc(enteredCode).get();

      if (merchantSnapshot.exists) {
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('siteToken', enteredCode);
        Navigator.pop(context);
        Navigator.push(
          context,
          MaterialPageRoute(builder: (c) => AdminPage()),
        );
      } else {
        showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: Text('Verification Failed'),
              content: Text('Merchant site not found. Please enter a valid verification code.'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: Text('OK'),
                ),
              ],
            );
          },
        );
      }
    } catch (e) {
      // Handle errors
      print('Error: $e');
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text('Error'),
            content: Text('An error occurred. Please try again later.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: Text('OK'),
              ),
            ],
          );
        },
      );
    }
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
            leading: const Icon(Icons.dashboard_customize, color: Colors.black), // You can change this icon if needed
            title: const Text(
              "Dashboard",
              style: TextStyle(
                fontSize: 18,
                color: Colors.black,
              ),
            ),
            onTap: () async {
              String? siteToken = sharedPreferences!.getString("siteToken");
              if (siteToken != null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => AdminPage()),
                );
              } else {
                showDialog(
                  context: context,
                  builder: (context) {
                    return AlertDialog(
                      title: Text('Admin Panel'),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TextFormField(
                            controller: codeController,
                            decoration: InputDecoration(
                              labelText: 'Security Code',
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter the verification code';
                              }
                              return null;
                            },
                          ),
                          SizedBox(height: 18),
                          GestureDetector(
                            onTap: () {
                              const url = 'https://polskoydm.pythonanywhere.com/merchant_register';
                              launch(url);
                            },
                            child: Text(
                              "I Don't have a code",
                              style: TextStyle(
                                color: Colors.blue,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      actions: [
                        TextButton(
                          onPressed: () {
                            loginMerchant();
                          },
                          child: Text('Submit'),
                        ),
                      ],
                    );
                  },
                );
              }
            },
          ),

          ListTile(
            leading: const Icon(Icons.date_range, color: Colors.black),
            title: const Text(
              "Schedule",
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
            leading: const Icon(Icons.currency_exchange_rounded, color: Colors.black),
            title: const Text(
              "My Stats",
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
            leading: const Icon(Icons.language, color: Colors.black),
            title: const Text(
              "Language: English",
              style: TextStyle(color: Colors.black),
            ),
            onTap: () {
              // Language selection action
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
