import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:taxiapp/authentication/add_data.dart';
import 'package:taxiapp/widgets/Main_bar.dart';

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
        Uri.parse('https://polskoydm.pythonanywhere.com/global_auth?email=$email'),
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
              .collection("contractors")
              .doc(uid)
              .get();

          if (!userSnapshot.exists) {
            // User does not exist in the "contractors" collection, so create one
            await FirebaseFirestore.instance.collection("contractors").doc(uid).set({
              'email': userEmail,
              'name': '', // You can add more fields as needed
              'phone': '',
              'address': '',
              'status': 'contractor',
              'balance': 0,
            });

            // Optionally navigate to the next page for more data collection
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => FirstPage()),
            );
          } else {
            // User already exists, handle sign-in logic
            readDataAndSetDataLocally(userCredential.user!);
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => MainScreen()),
            );
          }
        } catch (e) {
          if (e is FirebaseAuthException && e.code == 'email-already-in-use') {
            // Sign in existing user
            userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
              email: email,
              password: password,
            );

            // Handle successful sign-in for existing users
            readDataAndSetDataLocally(userCredential.user!);
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => MainScreen()),
            );
          } else {
            print('Failed to create a user account: $e');
          }
        }
      } catch (e) {
        print('Error: $e');
      }
    } else {
      // Handle verification failure
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
        .collection("contractors")
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

  void onCodeFieldChanged(int index) {
    // Automatically submit when the last code field is filled
    if (index == codeControllers.length - 1 && codeControllers[index].text.length == 1) {
      verify();
    } else if (codeControllers[index].text.length == 1) {
      FocusScope.of(context).nextFocus();
    }
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
              SizedBox(height: 20),

              // Email field and Send Code button (hide them if _isEmailSent is true)
              if (!_isEmailSent) ...[
                Container(
                  width: MediaQuery.of(context).size.width - 100,
                  child: TextField(
                    controller: emailController,
                    decoration: InputDecoration(
                      hintText: "Email",
                      border: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.black),
                      ),
                      contentPadding: EdgeInsets.symmetric(vertical: 15, horizontal: 10),
                    ),
                  ),
                ),
                SizedBox(height: 20),
                TextButton(
                  onPressed: () {
                    if (isValidEmail(emailController.text.trim())) {
                      sendEmail(); // Call sendEmail to trigger email verification
                      setState(() {
                        _isEmailSent = true; // Hide email field and button after sending
                      });
                    } else {
                      // Show an error if the email is invalid
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Please enter a valid email')),
                      );
                    }
                  },
                  child: Text('Send Code'),
                  style: TextButton.styleFrom(
                    side: BorderSide(color: Colors.black),
                    padding: EdgeInsets.symmetric(vertical: 15, horizontal: 30),
                  ),
                ),
              ],

              // Verification code fields (show them only if _isEmailSent is true)
              if (_isEmailSent)
                Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(6, (index) {
                        return Container(
                          width: 40,
                          margin: EdgeInsets.symmetric(horizontal: 4),
                          child: TextField(
                            controller: codeControllers[index],
                            keyboardType: TextInputType.number,
                            maxLength: 1,
                            textAlign: TextAlign.center,
                            decoration: InputDecoration(
                              counterText: '',
                              border: OutlineInputBorder(
                                borderSide: BorderSide(color: Colors.black),
                              ),
                            ),
                            onChanged: (value) {
                              onCodeFieldChanged(index);
                            },
                          ),
                        );
                      }),
                    ),
                    SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: verify,
                      child: Text('Submit'),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
