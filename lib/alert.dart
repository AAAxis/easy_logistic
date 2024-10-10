import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';


class NotificationPage extends StatefulWidget {
  @override
  _NotificationPageState createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  late Stream<QuerySnapshot> _notificationsStream;
  final TextEditingController _titleController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _notificationsStream =
        FirebaseFirestore.instance.collection('notifications').snapshots();
  }

  void _addNotification(String title, String body, DateTime combinedDateTime) {
    FirebaseFirestore.instance.collection('notifications').add({
      'title': title,
      'body': body,
      'time': combinedDateTime,
    }).then((value) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Notification added successfully')),
      );
    }).catchError((error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to add notification: $error')),
      );
    });
  }

  void _deleteNotification(String id) {
    FirebaseFirestore.instance.collection('notifications').doc(id).delete().then((value) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Notification deleted successfully')),
      );
    }).catchError((error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete notification: $error')),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Notifications'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _titleController,
                    decoration: InputDecoration(
                      labelText: 'Notification Message',
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () {
                    DateTime timestamp = DateTime.now().add(Duration(minutes: 5));
                    _addNotification(
                      _titleController.text,
                      'Notification',
                      timestamp,
                    );
                    _titleController.clear();
                  },
                  icon: Icon(Icons.send),
                ),
              ],
            ),
            SizedBox(height: 16),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _notificationsStream,
                builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
                  if (snapshot.hasError) {
                    return Center(
                      child: Text('Error: ${snapshot.error}'),
                    );
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(
                      child: CircularProgressIndicator(),
                    );
                  }

                  if (snapshot.data!.docs.isEmpty) {
                    return Center(
                      child: Text('No notifications found'),
                    );
                  }

                  return ListView(
                    children: snapshot.data!.docs.map((DocumentSnapshot document) {
                      Map<String, dynamic> data = document.data() as Map<String, dynamic>;
                      DateTime notificationDate = (data['time'] as Timestamp).toDate();
                      return Dismissible(
                        key: UniqueKey(),
                        onDismissed: (direction) {
                          _deleteNotification(document.id);
                        },
                        direction: DismissDirection.endToStart,
                        background: Container(
                          color: Colors.red,
                          alignment: Alignment.centerRight,
                          padding: EdgeInsets.only(right: 20),
                          child: Icon(Icons.delete, color: Colors.white),
                        ),
                        child: Card(
                          elevation: 3,
                          margin: EdgeInsets.symmetric(vertical: 4),
                          child: ListTile(
                            title: Text(
                              data['title'],
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(height: 4),
                                Text(
                                  data['body'],
                                  style: TextStyle(color: Colors.grey[800]),
                                ),
                              ],
                            ),
                            trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '${notificationDate.year}-${notificationDate.month}-${notificationDate.day}',
                                  style: TextStyle(color: Colors.grey),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  '${notificationDate.hour}:${notificationDate.minute}',
                                  style: TextStyle(color: Colors.grey),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
