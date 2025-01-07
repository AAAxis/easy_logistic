import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AddProductScreen extends StatefulWidget {
  @override
  _AddProductScreenState createState() => _AddProductScreenState();
}


class _AddProductScreenState extends State<AddProductScreen> {

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  File? _imageFile;

  @override
  void initState() {
    super.initState();
    // Set initial value for price controller
    _priceController.text = '10.00';
  }


  String _selectedCategory = 'drinks'; // Initialize to the first category

  final List<String> _categories = [
    'combos',
    'single',
    'drinks',

  ];

  Future<void> _uploadImage() async {
  final picker = ImagePicker();
  final pickedFile = await picker.getImage(source: ImageSource.gallery);
  if (pickedFile != null) {
  setState(() {
  _imageFile = File(pickedFile.path);
  });
  }
  }

  Future<void> _saveProduct() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  String? siteToken = prefs.getString('siteToken');

  if (siteToken != null &&
  _nameController.text.isNotEmpty &&
  _descriptionController.text.isNotEmpty &&
  _priceController.text.isNotEmpty &&
  _imageFile != null) {
  try {
  // Upload image to Firebase Storage
  final firebase_storage.Reference ref = firebase_storage.FirebaseStorage.instance
      .ref()
      .child('product_images')
      .child('${DateTime.now().millisecondsSinceEpoch}.jpg');
  await ref.putFile(_imageFile!);

  // Get download URL
  final imageUrl = await ref.getDownloadURL();

  // Save product details to Firestore
  await FirebaseFirestore.instance.collection('merchants').doc(siteToken).collection('products').add({
  'name': _nameController.text,
  'description': _descriptionController.text,
  'category': _selectedCategory, // Fix _categoryController to _selectedCategory
  'price': double.parse(_priceController.text),
  'image_url': imageUrl,
  });

  // Navigate back to previous screen
  Navigator.pop(context);
  } catch (error) {
  print('Error saving product: $error');
  // Show error message to the user
  // You can use a SnackBar or showDialog to display the error
  }
  } else {
  // Show validation error message to the user
  // You can use a SnackBar or showDialog to display the error
  }
  }

  @override
  Widget build(BuildContext context) {
  return Scaffold(
  appBar: AppBar(
  title: Text('Add Product'),
  ),
  body: SingleChildScrollView(
  child: Padding(
  padding: const EdgeInsets.all(16.0),
  child: Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
  TextFormField(
  controller: _nameController,
  decoration: InputDecoration(labelText: 'Product Name'),
  ),
  SizedBox(height: 16.0),
  TextFormField(
  controller: _descriptionController,
  decoration: InputDecoration(labelText: 'Description'),
  ),
  SizedBox(height: 16.0),

  DropdownButtonFormField(
  value: _selectedCategory,
    items: _categories.map((String category) {
      return DropdownMenuItem(
        value: category,
        child: Text(category),
      );
    }).toList(),
    onChanged: (String? value) {
      setState(() {
        _selectedCategory = value ?? ''; // Handle null case
      });
    },
    decoration: InputDecoration(
      labelText: 'Category',
    ),
  ),

    SizedBox(height: 16.0),
    TextFormField(
      controller: _priceController,
      decoration: InputDecoration(labelText: 'Price'),
      keyboardType: TextInputType.numberWithOptions(decimal: true),
    ),
    Row(
      children: [
        IconButton(
          icon: Icon(Icons.remove),
          onPressed: () {
            setState(() {
              // Decrement price by 0.1
              double currentPrice = double.tryParse(_priceController.text) ?? 0.0;
              double newPrice = currentPrice - 0.1;
              _priceController.text = newPrice.toStringAsFixed(2);
            });
          },
        ),
        IconButton(
          icon: Icon(Icons.add),
          onPressed: () {
            setState(() {
              // Increment price by 0.1
              double currentPrice = double.tryParse(_priceController.text) ?? 0.0;
              double newPrice = currentPrice + 0.1;
              _priceController.text = newPrice.toStringAsFixed(2);
            });
          },
        ),
      ],
    ),

  SizedBox(height: 16.0),
  _imageFile == null
  ? ElevatedButton(
  onPressed: _uploadImage,
  child: Text('Upload Image'),
  )
      : Column(
  children: [
  Image.file(
  _imageFile!,
  height: 200,
  ),
  SizedBox(height: 16.0),
  ElevatedButton(
  onPressed: _uploadImage,
  child: Text('Change Image'),
  ),
  ],
  ),
  SizedBox(height: 16.0),
  ElevatedButton(
  onPressed: _saveProduct,
  child: Text('Save Product'),
  ),
  ],
  ),
  ),
  ),
  );
  }
}
