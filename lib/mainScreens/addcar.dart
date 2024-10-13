import 'package:taxiapp/mainScreens/Account.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';


class CarInfoList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Car Information'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(builder: (c) => AccountPage()),
            );
          },
        ),
      ),
      body: Material(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(height: 22.0),
            Image.asset(
              "images/logo.png",
              width: 400.0,
              height: 250.0,
            ),
            SizedBox(height: 20.0),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
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
                    itemCount: snapshot.data!.docs.length,
                    itemBuilder: (context, index) {
                      var doc = snapshot.data!.docs[index];
                      return ListTile(
                        title: Text(doc['carModel']),
                        subtitle: Text(doc['carNumber'] + ', ' + doc['carType']),
                        trailing: IconButton(
                          icon: Icon(Icons.delete),
                          onPressed: () => _deleteCarInfo(context, doc.id),
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
            .collection('contractors')
            .doc(uid)
            .collection('vehicle')
            .snapshots();
      }
    } catch (e) {
      print('Error getting car information stream: $e');
    }
  }

  void _deleteCarInfo(BuildContext context, String docId) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? uid = prefs.getString('uid');

      if (uid != null) {
        await FirebaseFirestore.instance
            .collection('contractors')
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
    }
  }
}

class AddNewCarInfo extends StatelessWidget {
  final TextEditingController _carModelController = TextEditingController();
  final TextEditingController _carNumberController = TextEditingController();
  final TextEditingController _carTypeController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(

      body: Material(
        child: ListView(
          padding: EdgeInsets.all(16.0),
          children: [

            TextFormField(
              controller: _carModelController,
              decoration: InputDecoration(
                labelText: 'Car Model',
                prefixIcon: Icon(Icons.directions_car_sharp),
              ),
            ),
            SizedBox(height: 20),
            TextFormField(
              controller: _carNumberController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Car Number',
                prefixIcon: Icon(Icons.numbers),
              ),
            ),
            SizedBox(height: 20),
            TextFormField(
              controller: _carTypeController,
              decoration: InputDecoration(
                labelText: 'Car Type',
                prefixIcon: Icon(Icons.settings),
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                _saveCarInfo(context);
              },
              style: ButtonStyle(
                side: MaterialStateProperty.all(BorderSide(color: Colors.black)),
                backgroundColor: MaterialStateProperty.all(Colors.white),
                elevation: MaterialStateProperty.all(0), // Remove elevation
              ),
              child: Text('Save', style: TextStyle(color: Colors.black)),
            ),
          ],
        ),
      ),
    );
  }
  void _saveCarInfo(BuildContext context) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? uid = prefs.getString('uid');

      if (uid == null) {
        print('User UID not found in shared preferences.');
        return;
      }

      String carModel = _carModelController.text;
      String carNumber = _carNumberController.text;
      String carType = _carTypeController.text;

      // Reference to the 'car' subcollection under the user document
      CollectionReference userCarCollection = FirebaseFirestore.instance
          .collection('contractors')
          .doc(uid)
          .collection('vehicle');

      // Add car information to the 'car' subcollection under the user document
      await userCarCollection.add({
        'carModel': carModel,
        'carNumber': carNumber,
        'carType': carType,
        // Add more fields if needed
      });

      // Clear text fields after saving
      _carModelController.clear();
      _carNumberController.clear();
      _carTypeController.clear();

      // Show success message or navigate to another screen
      // For now, let's print a success message
      print('Car information saved to user\'s car collection in Firestore');
    } catch (e) {
      print('Error saving car information: $e');
      // Handle error as needed
    }
  }
}

