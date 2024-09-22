import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Product> products = [];
  List<Product> filteredProducts = [];
  final TextEditingController searchController = TextEditingController();
  bool showDiscountedPrice = true;

  @override
  void initState() {
    super.initState();
    _initializeRemoteConfig();
    _loadProducts();
    searchController.addListener(_filterProducts);
  }

  Future<void> _initializeRemoteConfig() async {
    await Firebase.initializeApp();
    final remoteConfig = FirebaseRemoteConfig.instance;

    await remoteConfig.setDefaults({'show_discounted_price': true});
    await remoteConfig.fetchAndActivate();

    setState(() {
      showDiscountedPrice = remoteConfig.getBool('show_discounted_price');
    });
  }

  Future<void> _loadProducts() async {
    final data = await _fetchProducts();
    setState(() {
      products = data;
      filteredProducts = data;
    });
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  void _filterProducts() {
    final query = searchController.text.toLowerCase();
    setState(() {
      filteredProducts = products
          .where((product) => product.title.toLowerCase().contains(query))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildSearchBar(),
          const SizedBox(height: 8),
          Expanded(child: _buildProductGrid()),
        ],
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      elevation: 2,
      backgroundColor: const Color(0xFF0C54BE),
      title: const Text(
        'e-Shop',
      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.white), // Change color to white
      ),
      iconTheme: const IconThemeData(color: Colors.white),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFF5F9FD),
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
          ],
        ),
        child: TextField(
          controller: searchController,
          decoration: const InputDecoration(
            hintText: 'Search products...',
            border: InputBorder.none,
            prefixIcon: Icon(Icons.search, color: Color(0xFFCED3DC)),
            contentPadding: EdgeInsets.symmetric(vertical: 12),
          ),
        ),
      ),
    );
  }

  Widget _buildProductGrid() {
    if (filteredProducts.isEmpty) {
      return const Center(child: Text('No products available.'));
    }

    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: _getCrossAxisCount(context),
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 0.75,
      ),
      itemCount: filteredProducts.length,
      itemBuilder: (context, index) {
        return ProductCard(
          product: filteredProducts[index],
          showDiscountedPrice: showDiscountedPrice,
        );
      },
    );
  }

  int _getCrossAxisCount(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < 600) return 2; // Mobile
    if (width < 900) return 3; // Tablet
    return 4; // Desktop
  }

  Future<List<Product>> _fetchProducts() async {
    final String response = await rootBundle.loadString('assets/catalog.json');
    final data = json.decode(response);
    return (data['products'] as List)
        .map((product) => Product.fromJson(product))
        .toList();
  }
}

class Product {
  final String title;
  final String description;
  final double price;
  final double discountPercentage;
  final String imageUrl;
  final double rating;
  final int stock;

  Product({
    required this.title,
    required this.description,
    required this.price,
    required this.discountPercentage,
    required this.imageUrl,
    required this.rating,
    required this.stock,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      title: json['title'],
      description: json['description'],
      price: json['price'].toDouble(),
      discountPercentage: json['discountPercentage'].toDouble(),
      imageUrl: json['images'][0],
      rating: json['rating'].toDouble(),
      stock: json['stock'],
    );
  }

  double get discountedPrice => price - (price * (discountPercentage / 100));
}

class ProductCard extends StatelessWidget {
  final Product product;
  final bool showDiscountedPrice;

  const ProductCard({
    Key? key,
    required this.product,
    required this.showDiscountedPrice,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showProductDetailsDialog(context, product),
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProductImage(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3.0, vertical: 4.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildProductDetails(),
                  const SizedBox(height: 4),
                  ElevatedButton(
                    onPressed: () => _showProductDetailsDialog(context, product),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      backgroundColor: const Color(0xFF0C54BE),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Center(
                      child: Text('Buy Now', style: TextStyle(fontSize: 12, color: Colors.white)),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductImage() {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
      child: Container(
        height: 120,
        width: double.infinity,
        child: Image.network(
          product.imageUrl,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return const Center(child: CircularProgressIndicator());
          },
          errorBuilder: (context, error, stackTrace) {
            return const Center(child: Icon(Icons.error, color: Colors.red));
          },
        ),
      ),
    );
  }

 Widget _buildProductDetails() {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        product.title,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF303F60)),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      const SizedBox(height: 4),
      if (showDiscountedPrice && product.discountPercentage > 0) ...[
        Row(
          children: [
            Text(
              '\$${product.discountedPrice.toStringAsFixed(2)}',
              style: const TextStyle(color: Color.fromARGB(255, 36, 133, 39), fontWeight: FontWeight.w500), 
            ),
            const SizedBox(width: 8),
            Text(
              '\$${product.price.toStringAsFixed(2)}',
              style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.w400, decoration: TextDecoration.lineThrough),
            ),
          ],
        ),
      ] else ...[
        Text(
          '\$${product.price.toStringAsFixed(2)}',
          style: const TextStyle(color: Color(0xFF0C54BE), fontWeight: FontWeight.w500),
        ),
      ],
    ],
  );
}

  void _showProductDetailsDialog(BuildContext context, Product product) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(product.title),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Image.network(product.imageUrl, fit: BoxFit.cover, height: 150),
                const SizedBox(height: 16),
                Text('Price: \$${product.price.toStringAsFixed(2)}'),
                if (product.discountPercentage > 0)
                  Text(
                    'Discounted Price: \$${product.discountedPrice.toStringAsFixed(2)}',
                    style: const TextStyle(color: Colors.red),
                  ),
                const SizedBox(height: 8),
                Text('Rating: ${product.rating}'),
                const SizedBox(height: 8),
                Text('Stock: ${product.stock}'),
                const SizedBox(height: 16),
                Text(product.description),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }
}
