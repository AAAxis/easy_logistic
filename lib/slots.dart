import 'package:driver_app/mainScreens/navigation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Schedule {
  final String clockIn;
  final String clockOut;
  final String day;

  Schedule({
    required this.clockIn,
    required this.clockOut,
    required this.day,
  });

  Map<String, dynamic> toMap() {
    return {
      'clockIn': clockIn,
      'clockOut': clockOut,
      'day': day,
    };
  }
}

class SchedulePage extends StatefulWidget {
  @override
  _SchedulePageState createState() => _SchedulePageState();
}

class _SchedulePageState extends State<SchedulePage> {
  final TextEditingController _clockInController = TextEditingController(text: '8:00 AM');
  final TextEditingController _clockOutController = TextEditingController(text: '8:00 PM');
  String _selectedDay = 'Monday'; // Default day selection

  final List<String> _daysOfWeek = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  CollectionReference schedules = FirebaseFirestore.instance.collection('schedules');

  void _submitSchedule() {
    // Validate and submit schedule data
    if (_clockInController.text.isEmpty ||
        _clockOutController.text.isEmpty ||
        _selectedDay.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('All fields are required')),
      );
      return;
    }

    // Add schedule data to Firestore
    schedules.add(Schedule(
      clockIn: _clockInController.text,
      clockOut: _clockOutController.text,
      day: _selectedDay,
    ).toMap());

    // Display success message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Schedule submitted successfully')),
    );
  }

  Future<void> _selectTime(BuildContext context, TextEditingController controller) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: 8, minute: 0), // Default to 8:00 AM
    );
    if (picked != null) {
      controller.text = picked.format(context);
    }
  }

  void _showAddScheduleDialog(BuildContext context) {
    TextEditingController clockInController = TextEditingController(text: '8:00 AM');
    TextEditingController clockOutController = TextEditingController(text: '8:00 PM');
    String selectedDay = _daysOfWeek[0]; // Default to Monday

    GlobalKey<FormState> formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Add Schedule"),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: clockInController,
                    decoration: InputDecoration(labelText: 'Clock In'),
                    onTap: () => _selectTime(context, clockInController),
                    validator: (value) {
                      if (value!.isEmpty) {
                        return 'Please enter a valid time';
                      }
                      return null;
                    },
                  ),
                  TextFormField(
                    controller: clockOutController,
                    decoration: InputDecoration(labelText: 'Clock Out'),
                    onTap: () => _selectTime(context, clockOutController),
                    validator: (value) {
                      if (value!.isEmpty) {
                        return 'Please enter a valid time';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: selectedDay,
                    items: _daysOfWeek.map((String day) {
                      return DropdownMenuItem<String>(
                        value: day,
                        child: Text(day),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      selectedDay = newValue!;
                    },
                    decoration: InputDecoration(
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text("Cancel"),
            ),
            TextButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  formKey.currentState!.save();
                  // Add the schedule
                  schedules.add(Schedule(
                    clockIn: clockInController.text,
                    clockOut: clockOutController.text,
                    day: selectedDay,
                  ).toMap())
                      .then((_) {
                    // Close the dialog
                    Navigator.of(context).pop();
                  })
                      .catchError((error) {
                    // Handle errors if any
                    print("Failed to add schedule: $error");
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to add schedule')),
                    );
                  });
                }
              },
              child: Text("Add"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Working Hours'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(builder: (c) => Navigation()),
            );
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton.icon(
              onPressed: () {
                _showAddScheduleDialog(context);
              },
              icon: Icon(Icons.add),
              label: Text('Add Schedule'),
            ),
            SizedBox(height: 16),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: schedules.snapshots(),
                builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
                  if (snapshot.hasError) {
                    return Text('Something went wrong');
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }

                  return ListView.builder(
                    itemCount: snapshot.data!.docs.length,
                    itemBuilder: (BuildContext context, int index) {
                      Map<String, dynamic> data = snapshot.data!.docs[index].data() as Map<String, dynamic>;
                      return Dismissible(
                        key: Key(snapshot.data!.docs[index].id),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          color: Colors.red,
                          alignment: Alignment.centerRight,
                          padding: EdgeInsets.symmetric(horizontal: 20.0),
                          child: Icon(
                            Icons.delete,
                            color: Colors.white,
                          ),
                        ),
                        confirmDismiss: (direction) async {
                          return await showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return AlertDialog(
                                title: Text("Confirm"),
                                content: Text("Are you sure you want to delete this schedule?"),
                                actions: <Widget>[
                                  TextButton(
                                    onPressed: () => Navigator.of(context).pop(false),
                                    child: Text("Cancel"),
                                  ),
                                  TextButton(
                                    onPressed: () => Navigator.of(context).pop(true),
                                    child: Text("Delete"),
                                  ),
                                ],
                              );
                            },
                          );
                        },
                        onDismissed: (direction) {
                          schedules.doc(snapshot.data!.docs[index].id).delete();
                        },
                        child: Card(
                          elevation: 3,
                          margin: EdgeInsets.symmetric(vertical: 8),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.blue,
                              child: Icon(
                                Icons.schedule,
                                color: Colors.white,
                              ),
                            ),
                            title: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '${data['day']}',
                                  style: TextStyle(fontSize: 16),
                                ),
                                Text(
                                  '${data['clockIn']} - ${data['clockOut']}',
                                  textAlign: TextAlign.end,
                                  style: TextStyle(color: Colors.grey), // Make time gray
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
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
