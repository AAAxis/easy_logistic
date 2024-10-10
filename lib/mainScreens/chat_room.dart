
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';


class ChatRoomScreen extends StatefulWidget {
  final Map<String, dynamic> chatRoom;
  final String orderId; // Add the orderId parameter


  ChatRoomScreen({
  required this.chatRoom,
  required this.orderId,
  });


  @override
  _ChatRoomScreenState createState() => _ChatRoomScreenState();
}


class _ChatRoomScreenState extends State<ChatRoomScreen> {
  final TextEditingController messageController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;



  @override
  void initState() {
    super.initState();
    fetchStoreName();
  }

  bool isPickedUp = false;

  String storeName = '';
  String storeAddress = '';


  Future<void> fetchStoreName() async {
    // Assuming 'stores' is the collection name where store details are stored in Firestore
    DocumentSnapshot snapshot = await FirebaseFirestore.instance
        .collection('merchants')
        .doc(widget.chatRoom['store'])
        .get();


    if (snapshot.exists) {
      setState(() {
        Map<String, dynamic> data = snapshot.data() as Map<String, dynamic>;
        storeName = data['name'] as String;
        storeAddress = data['address'] as String;
      });
    }
  }



  Widget buildMessageWidget(String sender, String text) {
    final bool isUser = sender == 'user';
    final Color userColor = Colors.blue;
    final Color driverColor = Colors.green;
    final double elevation = 2.0; // Adjust the elevation as needed

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
              fontSize: (16.0),
              color: Colors.black,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: IconThemeData(color: Colors.black), // Set the icon color to white
        title: Text(
          widget.chatRoom['name'],
          style: TextStyle(
            color: Colors.black, // Set the text color to white
          ),
        ),

      ),
      body: Column(
        children: <Widget>[
          // Add your additional data here (e.g., items and user address)

            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  Center(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        GestureDetector(
                          onTap: () async {
                            // Construct the map URL with the address
                            String mapUrl = 'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(widget.chatRoom['address'])}';
                            // Check if the URL can be launched

                              await launch(mapUrl);

                          },
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(Icons.home, size: 24.0), // Home icon
                              SizedBox(width: 8.0), // Spacing between icon and text
                              Text(
                                widget.chatRoom['address'],
                                style: TextStyle(fontSize: 16.0),
                              ),
                            ],
                          ),
                        ),

                        SizedBox(height: 8.0), // Spacing between rows
                        GestureDetector(
                          onTap: () async {
                            // Construct the map URL with the address
                            String mapUrl = 'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(storeAddress)}';
                            // Check if the URL can be launched

                            await launch(mapUrl);

                          },
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(Icons.store, size: 24.0), // Home icon
                              SizedBox(width: 8.0), // Spacing between icon and text
                              Text(
                                storeName, // Your store name variable here
                                style: TextStyle(fontSize: 16.0),
                              ),
                            ],
                          ),
                        ),

                      ],
                    ),
                  ),

                ],
              ),
            ),
          // Add your chat functionality here (e.g., messages, text input, etc.)
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('orders')
                  .doc(widget.orderId)
                  .collection('messages')
                  .orderBy('timestamp')
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Center(child: CircularProgressIndicator()); // Show loading indicator
                }

                // Directly access docs since snapshot.data is now of type QuerySnapshot
                List<QueryDocumentSnapshot<Object?>> messages = snapshot.data!.docs;

                List<Widget> messageWidgets = messages.map((message) {
                  String text = message['text'];
                  String sender = message['sender'];

                  // Create a widget to display each message
                  return buildMessageWidget(sender, text);
                }).toList();

                return ListView(
                  children: messageWidgets,
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
                    ),
                  ),
                ),

                IconButton(
                  icon: Icon(Icons.send),
                  onPressed: () {
                    // Send the message to Firestore
                    String text = messageController.text.trim();
                    if (text.isNotEmpty) {
                      _firestore
                          .collection('orders')
                          .doc(widget.orderId)
                          .collection('messages')
                          .add({
                        'sender': 'driver',
                        // You can change the sender as needed
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
    );
  }
}