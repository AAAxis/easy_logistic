import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:easy_logistic/slots.dart';

import 'alert.dart';
import 'authentication/auth_screen.dart';



class Dashboard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dashboard',
      theme: ThemeData(
        primarySwatch: Colors.green,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: DashboardPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class DashboardPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar:AppBar(
        title: Text('Contractors'),
        actions: [


          IconButton(
            icon: Row(
              children: [
                Icon(Icons.notifications),
                SizedBox(width: 5), // Add some space between icon and text
                Text('Alert', style: TextStyle(fontSize: 12)),
              ],
            ),
            onPressed: () {
              // Logic for navigating to the Notifications page
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => NotificationPage()),
              );
            },
          ),
          IconButton(
            icon: Row(
              children: [
                Icon(Icons.schedule),
                SizedBox(width: 5), // Add some space between icon and text
                Text('Schedule', style: TextStyle(fontSize: 12)),
              ],
            ),
            onPressed: () {
              // Logic for navigating to the Schedule page
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => SchedulePage()),
              );
            },
          ),
        ],
      ),

      body: UserList(),
    );
  }
}

class UserList extends StatefulWidget {
  @override
  _UserListState createState() => _UserListState();
}

class _UserListState extends State<UserList> {
  late TextEditingController _searchController;
  String? selectedUserId;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }


  // Function to sign out
  void _signOut(BuildContext context) async {
    // Clear preferences or perform sign-out logic here
    // Example: Clearing preferences using SharedPreferences
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.clear(); // Clear all preferences

    // Navigate back to login screen
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => LoginScreen()), // Replace LoginScreen() with your actual login screen widget
    );
  }






  @override
  Widget build(BuildContext context) {
    final isSmallScreen = MediaQuery.of(context).size.width < 600;

    return Column(
      children: [
        Expanded(
          child: Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          labelText: 'Search by Email',
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (value) {
                          setState(() {
                            selectedUserId = null;
                          });
                        },
                      ),
                    ),
                    Expanded(
                      child: StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance.collection('contractors').snapshots(),
                        builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
                          if (!snapshot.hasData || snapshot.data == null) {
                            return Center(
                              child: CircularProgressIndicator(),
                            );
                          }

                          final List<DocumentSnapshot> filteredUsers = snapshot.data!.docs.where((doc) {
                            final email = doc['email'].toString().toLowerCase();
                            final searchQuery = _searchController.text.toLowerCase();
                            return email.contains(searchQuery);
                          }).toList();

                          return ListView.builder(
                            itemCount: filteredUsers.length,
                            itemBuilder: (BuildContext context, int index) {
                              final DocumentSnapshot document = filteredUsers[index];
                              return ListTile(
                                title: Text(document['email']),
                                onTap: () {
                                  setState(() {
                                    selectedUserId = document.id;
                                  });
                                  if (isSmallScreen) {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (context) => ChatRoom(chatRoomId: document.id)),
                                    );
                                  }
                                },
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),

              if (selectedUserId != null && !isSmallScreen) ...[
                VerticalDivider(),

                Expanded(
                  child: ChatRoom(
                    chatRoomId: selectedUserId!,
                  ),
                ),
              ],
            ],
          ),
        ),
        // Stacked at the bottom

// Stacked at the bottom
        Container(
          padding: EdgeInsets.all(8.0),
          decoration: BoxDecoration(
            color: Colors.grey[300],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ElevatedButton(
                onPressed: () {
                  _signOut(context); // Pass context to sign-out function
                },
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white, backgroundColor: Colors.red, // Change text color to white
                ),
                child: Text('Sign Out'),
              ),


              SizedBox(width: 8), // Adding space between text and button
              Text('Logged in as Admin'),
            ],
          ),
        ),
      ],
    );
  }



  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}

class ChatRoom extends StatefulWidget {
  final String chatRoomId;

  const ChatRoom({required this.chatRoomId});

  @override
  _ChatRoomState createState() => _ChatRoomState();
}

class _ChatRoomState extends State<ChatRoom> {
  late TextEditingController messageController;

  @override
  void initState() {
    super.initState();
    messageController = TextEditingController();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Chat Room'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context) => Dashboard()));

          },
        ),
      ),
      body: Material(
        child: Column(
          children: [
            Expanded(
              child: StreamBuilder<DocumentSnapshot>(
                stream: FirebaseFirestore.instance.collection('contractors').doc(widget.chatRoomId).snapshots(),
                builder: (BuildContext context, AsyncSnapshot<DocumentSnapshot> snapshot) {
                  if (!snapshot.hasData || snapshot.data == null) {
                    return Center(
                      child: CircularProgressIndicator(),
                    );
                  }

                  final userData = snapshot.data!.data() as Map<String, dynamic>?;

                  if (userData == null) {
                    return Center(
                      child: Text('User data not available'),
                    );
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ListTile(

                        title: Text(userData['name'] ?? 'N/A'),
                        subtitle: Text(userData['phone'] ?? 'N/A'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            PopupMenuButton<String>(
                              onSelected: (String value) {
                                if (value == 'Profile') {
                                  showDialog(
                                    context: context,
                                    builder: (BuildContext context) {
                                      return EditUserDialog(
                                        userId: widget.chatRoomId,
                                        initialName: userData['name'] ?? '',
                                        initialPhone: userData['phone'] ?? '',
                                        initialAddress: userData['address'] ?? '',
                                      );
                                    },
                                  );
                                } else if (value == 'Bank') {
                                  showDialog(
                                    context: context,
                                    builder: (BuildContext context) {
                                      return BankInfoDialog(
                                        userId: widget.chatRoomId,
                                      );
                                    },
                                  );

                                } else if (value == 'Slots') {
                                  showDialog(
                                    context: context,
                                    builder: (BuildContext context) {
                                      return SlotInfoDialog(
                                        userId: widget.chatRoomId,
                                      );
                                    },
                                  );

                                } else {
                                  // Handle other menu options if needed
                                }
                              },
                              itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[

                                PopupMenuItem<String>(
                                  value: 'Slots',
                                  child: Text('Slots'),
                                ),
                                PopupMenuItem<String>(
                                  value: 'Bank',
                                  child: Text('Bank'),
                                ),
                                PopupMenuItem<String>(
                                  value: 'Profile',
                                  child: Text('Profile'),
                                ),

                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),

            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('contractors')
                    .doc(widget.chatRoomId)
                    .collection('messages')
                    .orderBy('timestamp')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return Center(child: CircularProgressIndicator());
                  }

                  List<QueryDocumentSnapshot<Map<String, dynamic>>>? messages = snapshot.data?.docs.cast<QueryDocumentSnapshot<Map<String, dynamic>>>();

                  return ListView.builder(
                    reverse: false,
                    itemCount: messages?.length ?? 0,
                    itemBuilder: (BuildContext context, int index) {
                      String text = messages?[index]['text'] ?? '';
                      String sender = messages?[index]['sender'] ?? '';

                      return Dismissible(
                        key: UniqueKey(),
                        direction: DismissDirection.endToStart,
                        onDismissed: (direction) {
                          // Delete the message from Firestore
                          messages?[index].reference.delete().then((value) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Message deleted successfully')),
                            );
                          }).catchError((error) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Failed to delete message: $error')),
                            );
                          });
                        },
                        background: Container(
                          color: Colors.red,
                          child: Icon(Icons.delete, color: Colors.white),
                          alignment: Alignment.centerRight,
                          padding: EdgeInsets.only(right: 20.0),
                        ),
                        child: ListTile(
                          title: Text(text),
                          subtitle: Text(sender),
                          tileColor: sender == 'user' ? Colors.green.withOpacity(0.2) : Colors.blue.withOpacity(0.2), // Adjust colors based on sender
                        ),
                      );
                    },
                  );
                },
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: TextField(
                      controller: messageController,
                      decoration: InputDecoration(
                        hintText: 'Type a message...',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.send),
                    onPressed: () {
                      String text = messageController.text.trim();
                      if (text.isNotEmpty) {
                        FirebaseFirestore.instance
                            .collection('contractors')
                            .doc(widget.chatRoomId)
                            .collection('messages')
                            .add({
                          'sender': 'user',
                          'text': text,
                          'timestamp': FieldValue.serverTimestamp(),
                        });
                        messageController.clear();
                      }
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildMessageWidget(String sender, String text) {
    final bool isUser = sender == 'driver';
    final Color userColor = Colors.blue;
    final Color driverColor = Colors.green;
    final double elevation = 2.0;

    final Color messageColor = isUser ? userColor : driverColor;

    return Container(
      alignment: isUser ? Alignment.centerLeft : Alignment.centerRight,
      child: Card(
        elevation: elevation,
        margin: EdgeInsets.all(10.0),
        color: messageColor,
        shape: RoundedRectangleBorder(
          borderRadius: isUser
              ? BorderRadius.only(
            topLeft: Radius.circular(16.0),
            topRight: Radius.circular(16.0),
            bottomRight: Radius.circular(16.0),
          )
              : BorderRadius.only(
            topLeft: Radius.circular(16.0),
            topRight: Radius.circular(16.0),
            bottomLeft: Radius.circular(16.0),
          ),
        ),
        child: Container(
          padding: EdgeInsets.all(14.0),
          child: Text(
            text,
            style: TextStyle(
              fontSize: 16.0,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    messageController.dispose();
    super.dispose();
  }
}


class EditUserDialog extends StatefulWidget {
  final String userId;
  final String initialName;
  final String initialPhone;
  final String initialAddress;

  const EditUserDialog({
    required this.userId,
    required this.initialName,
    required this.initialPhone,
    required this.initialAddress,
  });

  @override
  _EditUserDialogState createState() => _EditUserDialogState();
}

class _EditUserDialogState extends State<EditUserDialog> {
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;


  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName);
    _phoneController = TextEditingController(text: widget.initialPhone);
    _addressController = TextEditingController(text: widget.initialAddress);

  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('Edit User'),
          IconButton(
            icon: Icon(Icons.close),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          children: [
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Name',
              ),
              onTap: () {
                _nameController.clear();
              },
            ),
            SizedBox(height: 16.0),
            TextField(
              controller: _phoneController,
              decoration: InputDecoration(
                labelText: 'Phone',
              ),
              onTap: () {
                _phoneController.clear();
              },
            ),
            SizedBox(height: 16.0),
            TextField(
              controller: _addressController,
              decoration: InputDecoration(
                labelText: 'Location',
              ),
              onTap: () {
                _addressController.clear();
              },
            ),
            SizedBox(height: 16.0),

          ],
        ),
      ),
      actions: [
        ElevatedButton(
          onPressed: () {
            updateUserData();

          },
          child: Text(
            'Save',
            style: TextStyle(
              color: Colors.white,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.black,
          ),
        ),


        ElevatedButton(
          onPressed: () {
            deleteUserData();
            Navigator.of(context).pop();
          },
          child: Text(
            'Delete',
            style: TextStyle(
              color: Colors.white,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
          ),
        ),
      ],
    );
  }

  void updateUserData() {
    if (_nameController.text.trim().isEmpty ||
        _phoneController.text.trim().isEmpty ||
        _addressController.text.trim().isEmpty) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Validation Error'),
          content: Text('Please fill in all fields.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('OK'),
            ),
          ],
        ),
      );
    } else {
      FirebaseFirestore.instance.collection('contractors').doc(widget.userId).update({
        'name': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'address': _addressController.text.trim(),
      });
      Navigator.of(context).pop(); // Close the dialog after updating data
    }
  }


  void deleteUserData() {
    FirebaseFirestore.instance.collection('contractors').doc(widget.userId).delete();
  }



}





class SlotInfoDialog extends StatefulWidget {
  final String userId;

  const SlotInfoDialog({Key? key, required this.userId}) : super(key: key);

  @override
  _SlotInfoDialogState createState() => _SlotInfoDialogState();
}

class _SlotInfoDialogState extends State<SlotInfoDialog> {
  bool _hasData = false;
  List<DocumentSnapshot> _existingData = [];

  @override
  void initState() {
    super.initState();
    // Check if there's existing data in the Firestore collection
    checkExistingData();
  }

  Future<void> checkExistingData() async {
    // Query Firestore to check if data exists
    QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection('contractors')
        .doc(widget.userId)
        .collection('slot')
        .get();

    // Update state based on whether data exists
    setState(() {
      _hasData = snapshot.docs.isNotEmpty;
      if (_hasData) {
        _existingData = snapshot.docs;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Slot Information'),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _hasData ? buildDataTable() : Container(),
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: Text('Close'),
        ),
      ],
    );
  }

  Widget buildDataTable() {
    return DataTable(
      columns: const <DataColumn>[
        DataColumn(label: Text('Clock In')),
        DataColumn(label: Text('Clock Out')),
        DataColumn(label: Text('Provider')),
        DataColumn(label: Text('Day')),
      ],
      rows: _existingData.map((doc) {
        return DataRow(
          cells: <DataCell>[
            DataCell(Text(doc['clockIn'])),
            DataCell(Text(doc['clockOut'])),
            DataCell(Text(doc['provider'])),
            DataCell(Text(doc['day'])),
          ],
        );
      }).toList(),
    );
  }
}



class BankInfoDialog extends StatefulWidget {
  final String userId;

  BankInfoDialog({required this.userId});

  @override
  _BankInfoDialogState createState() => _BankInfoDialogState();
}
class _BankInfoDialogState extends State<BankInfoDialog> {
  final TextEditingController _bankNameController = TextEditingController();
  final TextEditingController _transitNumberController = TextEditingController();
  final TextEditingController _branchController = TextEditingController();

  bool _hasData = false;
  DocumentSnapshot? _existingData;

  @override
  void initState() {
    super.initState();
    // Check if there's existing data in the Firestore collection
    checkExistingData();
  }

  Future<void> checkExistingData() async {
    // Query Firestore to check if data exists
    // Replace 'users' with your actual collection name
    QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection('contractors')
        .doc(widget.userId)
        .collection('bank')
        .get();

    // Update state based on whether data exists
    setState(() {
      _hasData = snapshot.docs.isNotEmpty;
      if (_hasData) {
        _existingData = snapshot.docs.first;
        _bankNameController.text = _existingData!['bankName'];
        _transitNumberController.text = _existingData!['transitNumber'];
        _branchController.text = _existingData!['branch'];
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Submit Bank Information'),
      content: SingleChildScrollView(
        child: _hasData ? buildDataTable() : buildEditableFields(),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: Text('Cancel'),
        ),
        if (_hasData)
          TextButton(
            onPressed: deleteBankInfo,
            child: Text('Delete'),
          )
        else
          TextButton(
            onPressed: submitBankInfo,
            child: Text('Submit'),
          ),
      ],
    );
  }

  Widget buildDataTable() {
    return DataTable(
      columns: const <DataColumn>[
        DataColumn(label: Text('Bank')),
        DataColumn(label: Text('Number')),
        DataColumn(label: Text('Branch')),
      ],
      rows: <DataRow>[
        DataRow(
          cells: <DataCell>[
            DataCell(Text(_existingData!['bankName'])),
            DataCell(Text(_existingData!['transitNumber'])),
            DataCell(Text(_existingData!['branch'])),
          ],
        ),
      ],
    );
  }

  Widget buildEditableFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        TextField(
          controller: _bankNameController,
          decoration: InputDecoration(labelText: 'Bank Name'),
        ),
        TextField(
          controller: _transitNumberController,
          decoration: InputDecoration(labelText: 'Transit Number'),
          keyboardType: TextInputType.number,
        ),
        TextField(
          controller: _branchController,
          decoration: InputDecoration(labelText: 'Branch'),
          keyboardType: TextInputType.number,
        ),
      ],
    );
  }

  void deleteBankInfo() {
    // Delete existing bank information from Firestore
    FirebaseFirestore.instance
        .collection('contractors')
        .doc(widget.userId)
        .collection('bank')
        .doc(_existingData!.id)
        .delete()
        .then((_) {
      print('Bank information deleted successfully.');
      setState(() {
        _hasData = false;
      });
    }).catchError((error) {
      print('Failed to delete bank information: $error');
    });
    Navigator.of(context).pop();
  }

  void submitBankInfo() {
    // Add new bank information to Firestore
    FirebaseFirestore.instance
        .collection('contractors')
        .doc(widget.userId)
        .collection('bank')
        .add({
      'bankName': _bankNameController.text,
      'transitNumber': _transitNumberController.text,
      'branch': _branchController.text,
      // Add other bank data as needed
    }).then((_) {
      print('Bank information added successfully.');
      Navigator.of(context).pop();
    }).catchError((error) {
      print('Failed to add bank information: $error');
    });
  }
}


void submitBankInfo(String userId, String bankName, String transitNumber,
    String branch) {
  FirebaseFirestore.instance.collection('contractors').doc(userId).collection('bank')
      .doc().set({
    'bankName': bankName,
    'transitNumber': transitNumber,
    'branch': branch,
    // Add other bank data as needed
  })
      .then((_) {
    print('Bank information added successfully.');
  }).catchError((error) {
    print('Failed to add bank information: $error');
  });
}

Future<double> calculateBalance(String userId) async {
  double balance = 0.0;
  QuerySnapshot snapshot = await FirebaseFirestore.instance
      .collection('contractors')
      .doc(userId)
      .collection('transactions')
      .get();

  for (QueryDocumentSnapshot doc in snapshot.docs) {
    balance += double.tryParse(doc['money']) ?? 0.0;
  }

  return balance;
}
