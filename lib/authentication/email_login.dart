import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:driver_app/authentication/add_data.dart';
import 'package:driver_app/mainScreens/navigation.dart';
import '../global/global.dart';

final FirebaseAuth _auth = FirebaseAuth.instance;

class EmailLoginScreen extends StatefulWidget {
  const EmailLoginScreen({Key? key}) : super(key: key);

  @override
  _EmailLoginScreenState createState() => _EmailLoginScreenState();
}

class _EmailLoginScreenState extends State<EmailLoginScreen> {
  final TextEditingController emailController = TextEditingController();
  List<TextEditingController> codeControllers = List.generate(6, (index) => TextEditingController());
  bool _isEmailSent = false;
  String? verificationCode;

  Future<void> sendEmail() async {
    final email = emailController.text.trim();

    if (email.isEmpty || !isValidEmail(email)) {
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text('Invalid Email'),
            content: Text('Please enter a valid email address.'),
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
      return;
    }

    try {
      final response = await http.get(
        Uri.parse(
            'https://polskoydm.pythonanywhere.com/global_auth?email=$email'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        setState(() {
          _isEmailSent = true;
          verificationCode = data['verification_code'];
        });
      } else {
        showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: Text('Failed to Send Email'),
              content: Text('Unable to send email. Please try again later.'),
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
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text('Error'),
            content: Text('An error occurred while sending the email: $e'),
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

  bool isValidEmail(String email) {
    final emailRegex = RegExp(r'^[\w-]+(\.[\w-]+)*@[\w-]+(\.[\w-]+)+$');
    return emailRegex.hasMatch(email);
  }

  void verify() async {
    final enteredCode = codeControllers.map((controller) => controller.text).join();
    bool trackingPermissionStatus = sharedPreferences!.getBool("tracking") ?? false;

    if (enteredCode == verificationCode) {
      final email = emailController.text.trim();
      final password = "passwordless";

      try {
        UserCredential userCredential;

        // Attempt to create a user account
        try {
          userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
            email: email,
            password: password,
          );

          String uid = userCredential.user?.uid ?? "";
          String userEmail = userCredential.user?.email ?? "";

          // Check if the user exists in Firestore
          DocumentSnapshot userSnapshot = await FirebaseFirestore.instance
              .collection("barber")
              .doc(uid)
              .get();

          bool isFirstLogin = !userSnapshot.exists;
          if (isFirstLogin) {
            // If the user doesn't exist in Firestore, create a new document
            await FirebaseFirestore.instance.collection("barber").doc(uid).set({
              "uid": uid,
              "name": "Add Full Name",
              "phone": "Add Phone",
              "email": userEmail,
              "address": "Add Location",
              "status": 'contractor',
              "trackingPermission": trackingPermissionStatus,
            });

            final SharedPreferences prefs = await SharedPreferences.getInstance();
            prefs.setString("email", userEmail);
            showDialog(
              context: context,
              builder: (context) {
                return AlertDialog(
                  title: Text('Verification Successful'),
                  content: Text('You have successfully verified your email.'),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        // Add your logic to navigate to the next screen or perform other actions
                       readDataAndSetDataLocally(userCredential.user!);
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => FirstPage()),
                        );
                      },
                      child: Text('OK'),
                    ),
                  ],
                );
              },
            );
          } else {

          }
        } catch (e) {
          if (e is FirebaseAuthException) {
            if (e.code == 'email-already-in-use') {
              // Try to sign in the user with the existing credentials
              try {
                userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
                  email: email,
                  password: password,
                );

                // Handle a successful sign-in
                if (userCredential.user != null) {

                  showDialog(
                    context: context,
                    builder: (context) {
                      return AlertDialog(
                        title: Text('Verification Successful'),
                        content: Text('You have successfully verified your email.'),
                        actions: [
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context);
                              readDataAndSetDataLocally(userCredential.user!);
                              // Add your logic to navigate to the next screen or perform other actions
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => Navigation()),
                              );
                            },
                            child: Text('OK'),
                          ),
                        ],
                      );
                    },
                  );
                }
              } catch (e) {
                // Handle the sign-in error here
                print('Failed to sign in the user: $e');
              }
            } else {
              // Handle other Firebase Authentication errors
              print('Failed to create a user account: $e');
            }
          }
        }
      } catch (e) {
        // Handle errors for Firebase Authentication
        print('Error: $e');
      }
    } else {
      // Verification failed, show an error dialog
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text('Verification Failed'),
            content: Text('Invalid verification code. Please try again.'),
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

  Future<void> readDataAndSetDataLocally(User currentUser) async {
    await FirebaseFirestore.instance
        .collection("barber")
        .doc(currentUser.uid)
        .get()
        .then((snapshot) async {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString("uid", currentUser.uid);
      await prefs.setString("email", snapshot.data()!["email"]);
      await prefs.setString("name", snapshot.data()!["name"]);
      await prefs.setString("phone", snapshot.data()!["phone"]);
      await prefs.setString("address", snapshot.data()!["address"]);
      await prefs.setString("status", 'contractor');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xffffffff),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Image(
                image: NetworkImage(
                  "https://cdn3.iconfinder.com/data/icons/network-and-communications-6/130/291-128.png",
                ),
                height: 90,
                width: 90,
                fit: BoxFit.cover,
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(0, 8, 0, 30),
                child: Text(
                  "Sign In",
                  textAlign: TextAlign.start,
                  overflow: TextOverflow.clip,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontStyle: FontStyle.normal,
                    fontSize: 20,
                    color: Color(0xff3a57e8),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(0, 8, 0, 0),
                child: Text(
                  "Continue with Email",
                  textAlign: TextAlign.start,
                  overflow: TextOverflow.clip,
                  style: TextStyle(
                    fontWeight: FontWeight.w400,
                    fontStyle: FontStyle.normal,
                    fontSize: 14,
                    color: Color(0xff9e9e9e),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                child: Align(
                  alignment: Alignment.center,
                  child: Visibility(
                    visible: !_isEmailSent,
                    child: TextField(
                      controller: emailController,
                      obscureText: false,
                      textAlign: TextAlign.start,
                      maxLines: 1,
                      decoration: InputDecoration(
                        labelText: "Email",
                        filled: true,
                        fillColor: Color(0x00f2f2f3),
                        isDense: false,
                        contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                child: Align(
                  alignment: Alignment.center,
                  child: _isEmailSent
                      ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(6, (index) {
                      return Container(
                        width: 40,
                        margin: EdgeInsets.all(5),
                        child: TextField(
                          controller: codeControllers[index],
                          textAlign: TextAlign.center,
                          keyboardType: TextInputType.number,
                          maxLength: 1,
                          onChanged: (value) {
                            if (value.length == 1 && index < 5) {
                              FocusScope.of(context).nextFocus();
                            }
                            setState(() {}); // Rebuild the widget to update the button state
                          },
                          decoration: InputDecoration(
                            counterText: '', // Remove character counter
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                          ),
                        ),
                      );
                    }),
                  )
                      : MaterialButton(
                    onPressed: sendEmail,
                    color: Color(0xffffffff),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.0),
                      side: BorderSide(color: Color(0xff9e9e9e), width: 1),
                    ),
                    padding: EdgeInsets.all(16),
                    child: Text(
                      "Send Code",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                        fontStyle: FontStyle.normal,
                      ),
                    ),
                    textColor: Color(0xff000000),
                    height: 40,
                    minWidth: 140,
                  ),
                ),
              ),
              _isEmailSent
                  ? Padding(
                padding: EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                child: Align(
                  alignment: Alignment.center,
                  child: MaterialButton(
                    onPressed: verify,
                    color: Color(0xffffffff),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.0),
                      side: BorderSide(color: Color(0xff9e9e9e), width: 1),
                    ),
                    padding: EdgeInsets.all(16),
                    child: Text(
                      "Submit",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                        fontStyle: FontStyle.normal,
                      ),
                    ),
                    textColor: Color(0xff000000),
                    height: 40,
                    minWidth: 140,
                  ),
                ),
              )
                  : SizedBox(),
            ],
          ),
        ),
      ),
    );
  }
}
