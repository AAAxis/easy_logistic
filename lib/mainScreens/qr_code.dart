import 'package:driver_app/mainScreens/navigation.dart';
import 'package:flutter/material.dart';
class YourScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('QR Code'),
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
      body: Center(
        child: Image.network(
          'https://polskoydm.pythonanywhere.com/static/qrcode_theholylabs.com.png',
          width: 300, // Adjust width as needed
          height: 300, // Adjust height as needed
        ),
      ),
    );
  }
}
