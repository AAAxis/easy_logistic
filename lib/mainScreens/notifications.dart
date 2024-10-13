import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:taxiapp/widgets/Main_bar.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({Key? key}) : super(key: key);

  @override
  _NotificationScreenState createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  late Stream<QuerySnapshot> _notificationsStream;
  Set<String> _readNotifications = {};

  @override
  void initState() {
    super.initState();
    _requestNotificationPermission();
    _initializeNotificationsStream();
    _loadReadNotifications();
  }

  void _initializeNotificationsStream() {
    _notificationsStream = FirebaseFirestore.instance
        .collection('notifications')
        .orderBy('time', descending: true)
        .snapshots();

    _notificationsStream.listen((snapshot) {
      snapshot.docChanges.forEach((change) {
        if (change.type == DocumentChangeType.added) {
          _handleNotificationChange(change);
        }
      });
    });
  }

  void _handleNotificationChange(DocumentChange change) {
    final notificationData = change.doc.data() as Map<String, dynamic>;
    final id = change.doc.id;
    final title = notificationData['title'] ?? '';
    final body = notificationData['body'] ?? '';
    final time = notificationData['time']?.toDate() ?? DateTime.now();

    // Schedule a notification immediately if it's in the future
    if (time.isAfter(DateTime.now())) {
      _scheduleNotification(id, title, body, time);
    }

    // Display notification in the app
    setState(() {
      _readNotifications.add(id);
    });
  }

  void _requestNotificationPermission() {
    AwesomeNotifications().requestPermissionToSendNotifications();
  }

  Future<void> _loadReadNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    final readIds = prefs.getStringList('readNotifications') ?? [];
    setState(() {
      _readNotifications = readIds.toSet();
    });
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: Text('My Profile'),
        leading: BackButton(
          color: Colors.black, // You can customize the color here
          onPressed: () {
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(builder: (c) => MainScreen()),
            );
          },
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _notificationsStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else {
            final documents = snapshot.data!.docs;
            final filteredDocuments = documents.where((doc) {
              final notificationData = doc.data() as Map<String, dynamic>;
              final time = notificationData['time']?.toDate() ?? DateTime.now();
              return time.isBefore(DateTime.now());
            }).toList();
            return ListView.builder(
              itemCount: filteredDocuments.length,
              itemBuilder: (context, index) {
                final notificationData = filteredDocuments[index].data() as Map<String, dynamic>;
                final id = filteredDocuments[index].id;
                final title = notificationData['title'] ?? '';
                final body = notificationData['body'] ?? '';
                final time = notificationData['time']?.toDate() ?? DateTime.now();

                final formattedTime = DateFormat('MMM dd, yyyy hh:mm a').format(time);
                final isRead = _readNotifications.contains(id);

                return ListTile(
                  leading: Icon(
                    isRead ? Icons.mail_outline : Icons.mail,
                    color: isRead ? Colors.grey : Colors.blue,
                  ),
                  title: Text(title),
                  subtitle: Text(formattedTime),
                  onTap: () {
                    _showNotificationDialog(body);
                    setState(() {

                    });
                  },
                );
              },
            );
          }
        },
      ),
    );
  }

  Future<void> _showNotificationDialog(String body) async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Notification'),
          content: SingleChildScrollView(
            child: Text(body),
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
      },
    );
  }


  void _scheduleNotification(String id, String title, String body, DateTime notificationTime) async {
    final now = DateTime.now();
    if (notificationTime.isAfter(now)) {
      final notificationId = _generateNotificationId(id);
      await AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: notificationId,
          channelKey: 'alerts',
          title: title,
          body: body,
        ),
        schedule: NotificationCalendar(
          weekday: notificationTime.weekday,
          hour: notificationTime.hour,
          minute: notificationTime.minute,
        ),
      );
    }
  }

  int _generateNotificationId(String id) {
    final uniqueId = id.hashCode.abs();
    return uniqueId;
  }
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: NotificationScreen(),
    );
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AwesomeNotifications().initialize(
    'resource://drawable/logo',
    [
      NotificationChannel(
        channelKey: 'alerts',
        channelName: 'Alerts',
        channelDescription: 'Notification channel for basic notifications',
        defaultColor: Color(0xFF9D50DD),
        ledColor: Colors.white,
      )
    ],
  );
  runApp(MyApp());
}
