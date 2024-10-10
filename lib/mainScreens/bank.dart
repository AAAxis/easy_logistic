import 'package:driver_app/mainScreens/navigation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class EditBankScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => Navigation()), // Replace AnotherScreen with your target screen
            );
          },
        ),
        title: Text('Schedule'),
      ),

      body: BankInfoForm(),
    );
  }
}

class BankInfoForm extends StatefulWidget {
  @override
  _BankInfoFormState createState() => _BankInfoFormState();
}

class _BankInfoFormState extends State<BankInfoForm> {
  final TextEditingController _bankNameController = TextEditingController();
  final TextEditingController _transitNumberController =
  TextEditingController();
  final TextEditingController _branchController = TextEditingController();

  bool dataExists = false;

  @override
  void initState() {
    super.initState();
    _loadBankInfo();
  }

  void _loadBankInfo() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? uid = prefs.getString('uid');

      if (uid != null) {
        QuerySnapshot snapshot = await FirebaseFirestore.instance
            .collection('barber')
            .doc(uid)
            .collection('bank')
            .get();

        if (snapshot.docs.isNotEmpty) {
          setState(() {
            dataExists = true;
            _bankNameController.text = snapshot.docs[0]['bankName'];
            _transitNumberController.text = snapshot.docs[0]['transitNumber'];
            _branchController.text = snapshot.docs[0]['branch'];
          });
        }
      }
    } catch (e) {
      print('Error loading bank information: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
            controller: _bankNameController,
            readOnly: _bankNameController.text.isNotEmpty,
            decoration: InputDecoration(
              labelText: 'Bank Name',
              prefixIcon: Icon(Icons.account_balance),
            ),
          ),
          SizedBox(height: 20),
          TextFormField(
            controller: _transitNumberController,
            keyboardType: TextInputType.number,
            readOnly: _transitNumberController.text.isNotEmpty,
            decoration: InputDecoration(
              labelText: 'Transit Number',
              prefixIcon: Icon(Icons.format_list_numbered),
            ),
          ),
          SizedBox(height: 20),
          TextFormField(
            controller: _branchController,
            readOnly: _branchController.text.isNotEmpty,
            decoration: InputDecoration(
              labelText: 'Branch',
              prefixIcon: Icon(Icons.location_on),
            ),
          ),
          SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              if (dataExists) {
                _deleteBankInfo();
              } else {
                _saveBankInfo();
              }
            },
            style: ButtonStyle(
              side: MaterialStateProperty.all(BorderSide(color: Colors.black)),
              backgroundColor: MaterialStateProperty.all(Colors.white),
              elevation: MaterialStateProperty.all(0), // Remove elevation
            ),
            child: Text(dataExists ? 'Delete' : 'Save', style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );
  }

  void _saveBankInfo() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? uid = prefs.getString('uid');

      if (uid == null) {
        print('User UID not found in shared preferences.');
        return;
      }

      String bankName = _bankNameController.text;
      String transitNumber = _transitNumberController.text;
      String branch = _branchController.text;

      CollectionReference userBankCollection = FirebaseFirestore.instance
          .collection('barber')
          .doc(uid)
          .collection('bank');

      await userBankCollection.add({
        'bankName': bankName,
        'transitNumber': transitNumber,
        'branch': branch,
      });

      print(
          'Bank information saved to user\'s bank collection in Firestore');

      setState(() {
        dataExists = true;
      });
    } catch (e) {
      print('Error saving bank information: $e');
    }
  }
  void _deleteBankInfo() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? uid = prefs.getString('uid');

      if (uid != null) {
        QuerySnapshot snapshot = await FirebaseFirestore.instance
            .collection('barber')
            .doc(uid)
            .collection('bank')
            .get();

        if (snapshot.docs.isNotEmpty) {
          if (snapshot.docs.length == 1) {
            // If it's the last document, delete the entire collection
            await FirebaseFirestore.instance
                .collection('barber')
                .doc(uid)
                .collection('bank')
                .doc(snapshot.docs[0].id)
                .delete();
            print('Bank information collection deleted from Firestore');
          } else {
            // If not the last document, delete the specific document
            await FirebaseFirestore.instance
                .collection('barber')
                .doc(uid)
                .collection('bank')
                .doc(snapshot.docs[0].id)
                .delete();
            print('Bank information deleted from Firestore');
          }

          // Clear text fields
          setState(() {
            _bankNameController.clear();
            _transitNumberController.clear();
            _branchController.clear();
            dataExists = false;
          });
        }
      }
    } catch (e) {
      print('Error deleting bank information: $e');
    }
  }

}
