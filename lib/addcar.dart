import 'package:driver_app/mainScreens/navigation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';


class CarInfoList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('My Service'),
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
      body: Material(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center, // Aligns children to center vertically
          children: [
            SizedBox(height: 22.0),
            Image.asset(
              "images/hola.jpg",
              width: 400.0,
              height: 250.0,
            ),
            SizedBox(height: 20.0),

            Expanded(
              child: StreamBuilder(
                stream: _getCarInfoStream(context),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return CircularProgressIndicator();
                  }
                  if (snapshot.hasError) {
                    return Text('Error: ${snapshot.error}');
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return AddNewCarInfo();
                  }
                  return ListView.builder(
                    itemCount: snapshot.data?.docs.length,
                    itemBuilder: (context, index) {
                      var doc = snapshot.data?.docs[index];
                      return ListTile(
                        title: Text(doc?['carModel']),
                        subtitle: Text(doc?['carNumber'] + ', ' + doc?['carType']),
                        trailing: IconButton(
                          icon: Icon(Icons.delete),
                          onPressed: () => _deleteCarInfo(context, doc!.id),
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



  Stream<QuerySnapshot> _getCarInfoStream(BuildContext context) async* {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? uid = prefs.getString('uid');

      if (uid != null) {
        yield* FirebaseFirestore.instance
            .collection('barber')
            .doc(uid)
            .collection('vehicle')
            .snapshots();
      }
    } catch (e) {
      print('Error getting car information stream: $e');
      // Handle error as needed
    }
  }

  void _deleteCarInfo(BuildContext context, String docId) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? uid = prefs.getString('uid');

      if (uid != null) {
        await FirebaseFirestore.instance
            .collection('barber')
            .doc(uid)
            .collection('vehicle')
            .doc(docId)
            .delete();
        print('Car information deleted from Firebase');
      } else {
        print('User UID not found in shared preferences.');
      }
    } catch (e) {
      print('Error deleting car information: $e');
      // Handle error as needed
    }
  }

}
class AddNewCarInfo extends StatefulWidget {
  @override
  _AddNewCarInfoState createState() => _AddNewCarInfoState();
}

class _AddNewCarInfoState extends State<AddNewCarInfo> {
  final List<Map<String, String>> _carRecords = [];
  final TextEditingController _carModelController = TextEditingController();
  final TextEditingController _carNumberController = TextEditingController();
  final TextEditingController _carTypeController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Material(
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                padding: EdgeInsets.all(16.0),
                itemCount: _carRecords.length,
                itemBuilder: (context, index) {
                  final car = _carRecords[index];
                  return ListTile(
                    title: Text(car['carModel'] ?? ''),
                    subtitle: Text('${car['carNumber']}, ${car['carType']}'),
                    trailing: IconButton(
                      icon: Icon(Icons.delete),
                      onPressed: () => _removeCarRecord(index),
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  TextFormField(
                    controller: _carModelController,
                    decoration: InputDecoration(
                      labelText: 'Service Name',
                      prefixIcon: Icon(Icons.home_repair_service),
                    ),
                  ),
                  SizedBox(height: 20),
                  TextFormField(
                    controller: _carNumberController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Description',
                      prefixIcon: Icon(Icons.numbers),
                    ),
                  ),
                  SizedBox(height: 20),
                  TextFormField(
                    controller: _carTypeController,
                    decoration: InputDecoration(
                      labelText: 'Price',
                      prefixIcon: Icon(Icons.money_outlined),
                    ),
                  ),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _addCarRecord,
                    style: ButtonStyle(
                      side: MaterialStateProperty.all(BorderSide(color: Colors.black)),
                      backgroundColor: MaterialStateProperty.all(Colors.white),
                      elevation: MaterialStateProperty.all(0),
                    ),
                    child: Text('Save', style: TextStyle(color: Colors.black)),
                  ),

                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _addCarRecord() {
    setState(() {
      _carRecords.add({
        'carModel': _carModelController.text,
        'carNumber': _carNumberController.text,
        'carType': _carTypeController.text,
      });
      _carModelController.clear();
      _carNumberController.clear();
      _carTypeController.clear();
    });
  }

  void _removeCarRecord(int index) {
    setState(() {
      _carRecords.removeAt(index);
    });
  }

  void _saveCarRecords() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? uid = prefs.getString('uid');

      if (uid == null) {
        print('User UID not found in shared preferences.');
        return;
      }

      CollectionReference userCarCollection = FirebaseFirestore.instance
          .collection('barber')
          .doc(uid)
          .collection('vehicle');

      for (var car in _carRecords) {
        await userCarCollection.add(car);
      }

      // Clear records after saving
      setState(() {
        _carRecords.clear();
      });

      print('Car information saved to Firestore');
    } catch (e) {
      print('Error saving car information: $e');
    }
  }
}
