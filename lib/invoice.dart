import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
class InvoiceGenerator extends StatefulWidget {
  @override
  _InvoiceGeneratorState createState() => _InvoiceGeneratorState();
}





class HistoryScreen extends StatefulWidget {
  @override
  _HistoryScreenState createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  late SharedPreferences _prefs;
  String? _uid;

  @override
  void initState() {
    super.initState();
    _initSharedPreferences();
  }

  Future<void> _initSharedPreferences() async {
    _prefs = await SharedPreferences.getInstance();
    setState(() {
      _uid = FirebaseAuth.instance.currentUser?.uid;
    });
  }

  @override
  Widget build(BuildContext context) {
    return _uid != null
        ? StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('contractors')
          .doc(_uid)
          .collection('invoices')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator()); // Show loading indicator while fetching data
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return Center(
            child: Text('No records found'),
          );
        }
        return ListView.builder(
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            final docId = docs[index].id; // Retrieve the document ID
            final status = data['status'];

            // Determine the icon and whether it's clickable based on the status
            Widget leadingIcon;
            bool clickable = true;

            if (status == 'paid') {
              leadingIcon = IconButton(
                icon: Icon(Icons.money),
                onPressed: () async {
                  // Add your logic here
                },
              );
            } else {
              leadingIcon = IconButton(
                icon: Icon(Icons.language),
                onPressed: () async {
                  final url =
                      'https://polskoydm.pythonanywhere.com/invoice-payment?uid=$_uid&doc=$docId&email=${data['email']}&total=${data['total']}';
                  await launch(url);
                },
              );
            }

            // Get the last 4 characters of the docId
            String displayDocId = docId.length > 5 ? docId.substring(docId.length - 5) : docId;

            // Build the ListTile wrapped in Dismissible
            return Dismissible(
              key: Key(docId),
              background: Container(color: Colors.red),
              direction: DismissDirection.endToStart,
              onDismissed: (direction) async {
                // Remove the document from Firestore
                await FirebaseFirestore.instance
                    .collection('contractors')
                    .doc(_uid)
                    .collection('invoices')
                    .doc(docId)
                    .delete();
                // Show a snackbar or any other feedback
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Invoice deleted'),
                  ),
                );
              },
              child: ListTile(
                leading: leadingIcon,
                title: Text('Invoice #$displayDocId'),
                subtitle: Text('Customer: ${data['customerName']}, Total: ${data['total']}'),
                onTap: clickable
                    ? () {
                  // Handle tapping on invoice item if needed
                }
                    : null,
              ),
            );
          },
        );
      },
    )
        : Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('User not authenticated, please sign in'),
        ],
      ),
    );
  }
}
class _InvoiceGeneratorState extends State<InvoiceGenerator> with SingleTickerProviderStateMixin {
  late SharedPreferences _prefs;
  late TabController _tabController;

  List<TextEditingController> itemNameControllers = [];
  TextEditingController businessNameController = TextEditingController();
  TextEditingController businessLocationController = TextEditingController();
  TextEditingController businessPhoneController = TextEditingController();
  TextEditingController customerNameController = TextEditingController();
   TextEditingController totalController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  List<Map<String, String>> items = [{'itemName': '', 'quantity': '1'}];
  String selectedDate = '';


  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    Future.delayed(Duration(seconds: 1), () {
      _initSharedPreferences();
    });
  }

  Future<void> _initSharedPreferences() async {
    _prefs = await SharedPreferences.getInstance();
    setState(() {
      businessNameController.text = _prefs.getString("name") ?? "No Name";
      businessLocationController.text = _prefs.getString("address") ?? "No Address";
      businessPhoneController.text = _prefs.getString("phone") ?? "No Phone";
      customerNameController.text = '';
      totalController.text = '';
      emailController.text = _prefs.getString("email") ?? "No Email";
      selectedDate = DateTime.now().toIso8601String().split('T')[0];
    });
  }

  void _addNumber(String number) {
    setState(() {
      totalController.text = totalController.text + number;
    });
  }

  void _deleteLastCharacter() {
    setState(() {
      if (totalController.text.isNotEmpty) {
        totalController.text = totalController.text.substring(0, totalController.text.length - 1);
      }
    });
  }



  Future<void> _saveData() async {
    try {
      String? uid = FirebaseAuth.instance.currentUser?.uid;

      Map<String, dynamic> invoiceData = {
        'businessName': businessNameController.text,
        'businessLocation': businessLocationController.text,
        'businessPhone': businessPhoneController.text,
        'customerName': customerNameController.text,
        'total': double.parse(totalController.text),
        'email': emailController.text,
        'selectedDate': DateTime.now().toIso8601String().split('T')[0],
        'user': uid,
        'status': 'open',
        'items': items,
      };

      final DocumentReference docRef = await FirebaseFirestore.instance.collection('contractors').doc(uid).collection('invoices').add(invoiceData);
      final String docId = docRef.id;
      await _sendInvoice(docId, invoiceData);

      customerNameController.clear();
      items.clear();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Invoice sent successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send invoice. Error: $e')),
      );
    }
  }

  Future<void> _sendInvoice(String invoiceId, Map<String, dynamic> invoiceData) async {
    try {
      final String apiUrl = 'https://polskoydm.pythonanywhere.com/generate-pdf-and-send-email';
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode({
          ...invoiceData,
          'invoiceId': invoiceId,
        }),
      );

      if (response.statusCode == 200) {
        print('Invoice sent successfully');
      } else {
        print('Failed to send invoice. Status code: ${response.statusCode}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send invoice. Status code: ${response.statusCode}')),
        );
      }
    } catch (e) {
      print('Error sending invoice: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error sending invoice: $e')),
      );
    }
  }
  Future<void> _showAddDetailsDialog() async {
    String name = '';


    return showDialog<void>(
      context: context,
     // User must tap button to close
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Add Client'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              TextField(
                onChanged: (value) {
                  name = value;
                },
                decoration: InputDecoration(labelText: 'Name'),
              ),

            ],
          ),
          actions: <Widget>[
            ElevatedButton(
              onPressed: () {
                // Add your onPressed logic here
                setState(() { customerNameController.text = name; });
                Navigator.of(context).pop();
                _tabController.animateTo(1);
              },
              child: Text('Save'),
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white, backgroundColor: Colors.black, // Text color
              ),
            )

          ],
        );
      },
    );
  }

  bool _validateFields() {
    double totalValue = double.tryParse(totalController.text) ?? 0;
    return businessNameController.text.isNotEmpty &&
        businessLocationController.text.isNotEmpty &&
        businessPhoneController.text.isNotEmpty &&

        totalValue >= 5;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('New Payment'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'Keypad'),
            Tab(text: 'History'),
          ],
        ),

      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildKeypadTab(),
          HistoryScreen(), // Ensure HistoryScreen is properly defined
        ],
      ),
    );
  }

  Widget _buildKeypadTab() {
    return Container(
      padding: EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 60.0),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 300,
                  padding: EdgeInsets.all(10.0),
                  color: Colors.grey[200],
                  child: Center(
                    child: TextField(
                      controller: totalController,
                      keyboardType: TextInputType.none,
                      decoration: InputDecoration(
                        labelText: 'Price',
                        border: OutlineInputBorder(),
                      ),
                      readOnly: true,
                      onChanged: (value) {

                      },
                      onEditingComplete: () {
                        FocusScope.of(context).unfocus();
                      },
                    ),
                  ),
                ),
                SizedBox(height: 8.0),
                Container(
                  width: 300,
                  height: 500,
                  child: GridView.builder(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 2.0,
                      mainAxisSpacing: 2.0,
                    ),
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    itemCount: 12,
                    itemBuilder: (context, index) {
                      if (index < 9) {
                        String number = (index + 1).toString();
                        return Center(
                          child: Padding(
                            padding: EdgeInsets.all(2.0),
                            child: ElevatedButton(
                              onPressed: () => _addNumber(number),
                              style: ElevatedButton.styleFrom(
                                minimumSize: Size(70, 70),
                                backgroundColor: Colors.black54,
                                textStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                              child: Text(
                                number,
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          ),
                        );
                      } else if (index == 10) {
                        return Center(
                          child: Padding(
                            padding: EdgeInsets.all(2.0),
                            child: ElevatedButton(
                              onPressed: () => _addNumber('0'),
                              style: ElevatedButton.styleFrom(
                                minimumSize: Size(70, 70),
                                backgroundColor: Colors.black54,
                                textStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                              child: Text(
                                '0',
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          ),
                        );
                      } else if (index == 9) {
                        return Center(
                          child: Padding(
                            padding: EdgeInsets.all(2.0),
                            child: ElevatedButton(
                              onPressed: _deleteLastCharacter,
                              style: ElevatedButton.styleFrom(
                                minimumSize: Size(70, 70),
                                backgroundColor: Colors.red,
                                textStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                              child: Icon(
                                Icons.backspace,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        );
                      } else {
                        return Center(
                          child: Padding(
                            padding: EdgeInsets.all(2.0),
                            child: ElevatedButton(
                              onPressed: _validateFields() ? () async {
                                await _showAddDetailsDialog();
                                if (_validateFields()) {
                                  _saveData();
                                }
                              } : null,
                              style: ElevatedButton.styleFrom(
                                minimumSize: Size(70, 70),
                                backgroundColor: Colors.black,
                                textStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                              child: Text(
                                'OK',
                                style: TextStyle(color: Colors.white),
                              ),
                            )

                          ),
                        );
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

}
