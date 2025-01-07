import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:taxiapp/mainScreens/addbank.dart';
import 'package:taxiapp/widgets/Main_bar.dart';

import '../global/global.dart';

class PaymentScreen extends StatefulWidget {
  @override
  _PaymentScreenState createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {

  double balance = 0.0; // Define _balance variable


  List<DocumentSnapshot> _payments = [];

  @override
  void initState() {
    super.initState();
    _fetchPayments();
  }

  Future<void> _fetchPayments() async {
    // Fetch balance from the driver collection
    DocumentSnapshot driverSnapshot = await FirebaseFirestore.instance
        .collection('contractors')
        .doc(sharedPreferences!.getString("uid")!)
        .get();


    // Get the balance from the driver document and cast it to double
    balance = (driverSnapshot['balance'] ?? 0).toDouble(); // Ensure it's not null and cast to double

    // Fetch payments
    QuerySnapshot querySnapshot = await FirebaseFirestore.instance
        .collection('contractors')
        .doc(sharedPreferences!.getString("uid")!)
        .collection('payments')
        .get();

    setState(() {
      _payments = querySnapshot.docs;
      // You can use the fetched balance for any purpose in your UI
    });
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Balance: \$${balance.toStringAsFixed(2)}', // Assuming _balance is your balance variable
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(builder: (c) => MainScreen()),
            );
          },
        ),
      ),
      body: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.money_outlined, color: Colors.black),
            title: const Text(
              "Payout Method",
              style: TextStyle(color: Colors.black),
            ),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (c) => BankInfoList()),
              );
            },
          ),
          // Display balance

          DataTable(
            columns: [
              DataColumn(label: Text('Order ID')),
              DataColumn(label: Text('Timestamp')),
              DataColumn(label: Text('Amount')),
            ],
            rows: _payments.map((payment) {
              // Get the timestamp from Firebase and convert it to DateTime
              Timestamp timestamp = payment['timestamp'];
              DateTime dateTime = timestamp.toDate();

              // Format the timestamp
              String formattedDate = DateFormat('dd MMM yyyy').format(dateTime);
              String lastSixCharacters = payment['current_task'].toString().substring(payment['current_task'].toString().length - 9);

              return DataRow(cells: [
                DataCell(Text(lastSixCharacters)),
                DataCell(Text(formattedDate)),
                DataCell(Text(payment['amount'].toString())),

              ]);
            }).toList(),
          ),
          SizedBox(height: 20),
        ],
      ),
    );
  }

}
