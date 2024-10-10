import 'package:easy_logistic/mainScreens/products.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProductScreen extends StatefulWidget {
  @override
  _ProductScreenState createState() => _ProductScreenState();
}

class Product {
  final String id;
  final String name;
  final String description;
  final String category;
  final double price;
  final String imageUrl;

  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.price,
    required this.imageUrl,
  });
}

class _ProductScreenState extends State<ProductScreen> {
  late List<Product> products = []; // Initialize products as an empty list

  @override
  void initState() {
    super.initState();
    fetchProducts();
  }

  // Your deleteProduct and fetchProducts methods remain the same
  Future<void> fetchProducts() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? siteToken = prefs.getString('siteToken');

    if (siteToken != null) {
      try {
        final querySnapshot = await FirebaseFirestore.instance
            .collection('merchants')
            .doc(siteToken)
            .collection('products')
            .get();

        List<Product> productsList = [];
        querySnapshot.docs.forEach((doc) {
          Product product = Product(
            id: doc.id,
            name: doc['name'],
            description: doc['description'],
            category: doc['category'],
            price: doc['price'],
            imageUrl: doc['image_url'],
          );
          productsList.add(product);
        });

        setState(() {
          products = productsList;
        });
      } catch (error) {
        print('Error fetching products: $error');
      }
    } else {
      // Handle case where siteToken is null
    }
  }



  Future<void> _deleteProduct(String productId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? siteToken = prefs.getString('siteToken');

    if (siteToken != null) {
      try {
        await FirebaseFirestore.instance
            .collection('merchants')
            .doc(siteToken)
            .collection('products')
            .doc(productId)
            .delete();

        // Update the UI by removing the deleted product from the list
        setState(() {
          products.removeWhere((product) => product.id == productId);
        });
      } catch (error) {
        print('Error deleting product: $error');
      }
    } else {
      // Handle case where siteToken is null
    }
  }


  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3, // Number of categories
      child: Scaffold(
        appBar: AppBar(
          title: Text('Products'),
          bottom: TabBar(
            tabs: [
              Tab(text: 'Picked for you'),
              Tab(text: 'Signature'),
              Tab(text: 'Drinks'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildProductList('combos'), // Replace 'category1' with actual category names
            _buildProductList('single'),
            _buildProductList('drinks'),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => AddProductScreen()),
            );
          },
          child: Icon(Icons.add),
        ),
      ),
    );
  }

  Widget _buildProductList(String category) {
    List<Product> filteredProducts = products.where((product) => product.category == category).toList();
    return filteredProducts.isEmpty
        ? Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'No products found in this category',
            style: TextStyle(fontSize: 18),
          ),

        ],
      ),
    )
        : ListView.builder(
      itemCount: filteredProducts.length,
      itemBuilder: (context, index) {
        final product = filteredProducts[index];
        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => FullScreenImageScreen(
                  imageUrl: product.imageUrl,
                  title: product.name,
                  description: product.description,
                ),
              ),
            );
          },
          child: ListTile(
            title: Text(product.name),
            subtitle: Text('${product.category} \$${product.price.toStringAsFixed(2)}'),
            trailing: IconButton(
              icon: Icon(Icons.delete),
              onPressed: () {
                _deleteProduct(product.id);
              },
            ),
            leading: Image.network(
              product.imageUrl,
              width: 50,
              height: 50,
            ),
          ),
        );
      },
    );
  }
}

class FullScreenImageScreen extends StatelessWidget {
  final String imageUrl;
  final String title;
  final String description;

  const FullScreenImageScreen({Key? key, required this.imageUrl, required this.title, required this.description})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () {
                Navigator.pop(context);
              },
              child: Hero(
                tag: 'imageHero',
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              title,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              description,
              style: TextStyle(
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
