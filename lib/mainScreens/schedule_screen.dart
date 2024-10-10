import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_logistic/widgets/Main_bar.dart';

import '../global/global.dart';



class ScheduleScreen extends StatefulWidget {
  @override
  _ScheduleScreenState createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  bool isSaved = false;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 7,
      child: Scaffold(
        appBar: AppBar(
          title: Text(isSaved ? 'Saved Slots' : 'Schedule'),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: Switch(
                value: isSaved,
                onChanged: (value) {
                  setState(() {
                    isSaved = value;
                  });
                },
              ),
            ),
          ],
          bottom: !isSaved
              ? TabBar(
            tabs: [
              Tab(text: 'Monday'),
              Tab(text: 'Tuesday'),
              Tab(text: 'Wednesday'),
              Tab(text: 'Thursday'),
              Tab(text: 'Friday'),
              Tab(text: 'Saturday'),
              Tab(text: 'Sunday'),
            ],
          )
              : null,
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
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [

            Expanded(
              child: isSaved ? SavedScheduleList() : TabBarView(
                children: [
                  SlotList(day: 'Monday'),
                  SlotList(day: 'Tuesday'),
                  SlotList(day: 'Wednesday'),
                  SlotList(day: 'Thursday'),
                  SlotList(day: 'Friday'),
                  SlotList(day: 'Saturday'),
                  SlotList(day: 'Sunday'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SlotList extends StatelessWidget {
  final String? day;

  SlotList({this.day});

  @override
  Widget build(BuildContext context) {
    Query query = FirebaseFirestore.instance.collection('schedules');

    if (day != null) {
      query = query.where('day', isEqualTo: day); // Filter query by day if provided
    }

    return StreamBuilder<QuerySnapshot>(
      stream: query.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        List<DocumentSnapshot> documents = snapshot.data!.docs;
        return ListView.builder(
          itemCount: documents.length,
          itemBuilder: (context, index) {
            return SlotRow(data: documents[index].data() as Map<String, dynamic>);
          },
        );
      },
    );
  }
}

class SlotRow extends StatelessWidget {
  final Map<String, dynamic> data;

  SlotRow({required this.data});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(
        data['day'],
        style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold),
      ),
      subtitle: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'From: ${data['clockIn']} to ${data['clockOut']}',
                  style: TextStyle(fontSize: 14.0),
                ),
                Text(
                  '${data['provider']}',
                  style: TextStyle(fontSize: 12.0),
                ),
              ],
            ),
          ),
          SizedBox(width: 8.0),
          IconButton(
            icon: Icon(Icons.archive),
            onPressed: () {
              _moveToSaved(context, data);
            },
          ),
        ],
      ),
    );
  }

  void _moveToSaved(BuildContext context, Map<String, dynamic> data) async {
    try {
      // Retrieve UID from preferences
      String? uid = sharedPreferences!.getString("uid") ?? "None"; // Replace with your method to get UID from preferences

      if (uid != null) {
        // Construct the path to the subcollection
        String subcollectionPath = 'contractors/$uid/slot';

        // Add the schedule to the subcollection
        await FirebaseFirestore.instance.collection(subcollectionPath).add(data);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Schedule moved to Saved Slots')),
        );
      } else {
        // Handle case where UID is null
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('UID is null, unable to save schedule')),
        );
      }
    } catch (e) {
      print('Error moving schedule: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error moving schedule')),
      );
    }
  }
}

class SavedScheduleList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: Future<String>.value(sharedPreferences!.getString("uid") ?? "None"), // Convert String to Future<String>
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError || snapshot.data == "None") {
          return Center(child: Text('Error: Unable to fetch UID'));
        }
        String uid = snapshot.data!;

        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('contractors/$uid/slot').snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }
            List<DocumentSnapshot> documents = snapshot.data!.docs;
            return ListView.builder(
              itemCount: documents.length,
              itemBuilder: (context, index) {
                return SavedScheduleRow(data: documents[index].data() as Map<String, dynamic>, docId: documents[index].id);
              },
            );
          },
        );
      },
    );
  }
}

class SavedScheduleRow extends StatelessWidget {
  final Map<String, dynamic> data;
  final String docId;

  SavedScheduleRow({required this.data, required this.docId});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(
        data['day'],
        style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold),
      ),
      subtitle: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'From: ${data['clockIn']} to ${data['clockOut']}',
                  style: TextStyle(fontSize: 14.0),
                ),
                Text(
                  '${data['provider']}',
                  style: TextStyle(fontSize: 12.0),
                ),
              ],
            ),
          ),
          SizedBox(width: 8.0),
          IconButton(
            icon: Icon(Icons.delete),
            onPressed: () {
              _deleteSchedule(context, docId);
            },
          ),
        ],
      ),
    );
  }

  void _deleteSchedule(BuildContext context, String docId) async {
    try {
      // Retrieve UID from preferences
      String? uid = sharedPreferences!.getString("uid");

      if (uid != null) {
        // Construct the path to the document in the subcollection
        String documentPath = 'contractors/$uid/slot/$docId';

        // Delete the document
        await FirebaseFirestore.instance.doc(documentPath).delete();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Schedule deleted')),
        );
      } else {
        // Handle case where UID is null
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('UID is null, unable to delete schedule')),
        );
      }
    } catch (e) {
      print('Error deleting schedule: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting schedule')),
      );
    }
  }
}
