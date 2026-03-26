import 'package:flutter/material.dart';
import '../../services/wishlist_service.dart';
import '../../services/cart_service.dart';

class WishlistScreen extends StatefulWidget {
  const WishlistScreen({super.key});

  @override
  State<WishlistScreen> createState() => _WishlistScreenState();
}

class _WishlistScreenState extends State<WishlistScreen> {
  final _wishlist = WishlistService();
  final _cart = CartService();

  @override
  void initState() {
    super.initState();
    _wishlist.addListener(_onUpdate);
  }

  @override
  void dispose() {
    _wishlist.removeListener(_onUpdate);
    super.dispose();
  }

  void _onUpdate() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final items = _wishlist.items;

    return Scaffold(
      backgroundColor: const Color(0xFFF9FBF9),
      body: items.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: items.length,
              itemBuilder: (context, index) {
                return _buildWishlistItem(items[index]);
              },
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(color: const Color(0xFFE8F5E9), shape: BoxShape.circle),
            child: Icon(Icons.favorite_border_rounded, size: 80, color: const Color(0xFF4CAF50).withOpacity(0.5)),
          ),
          const SizedBox(height: 24),
          const Text("Your Wishlist is Empty", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1B5E20))),
          const SizedBox(height: 8),
          const Text("Save your favorite fresh produce here!", style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildWishlistItem(Map<String, dynamic> product) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: product['image_url'] != null
                ? Image.network(product['image_url'], width: 80, height: 80, fit: BoxFit.cover)
                : Container(color: const Color(0xFFE8F5E9), width: 80, height: 80, child: const Icon(Icons.eco_rounded, color: Color(0xFF4CAF50))),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(product['name'] ?? "Product", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: Color(0xFF1B5E20))),
                const SizedBox(height: 4),
                Text("Rs. ${product['price']}/${product['unit'] ?? 'kg'}", style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: Color(0xFF2E7D32))),
              ],
            ),
          ),
          Row(
            children: [
              IconButton(onPressed: () => _wishlist.toggleFavorite(product), icon: const Icon(Icons.favorite, color: Colors.red)),
              Container(
                decoration: BoxDecoration(color: const Color(0xFF1B5E20).withOpacity(0.05), shape: BoxShape.circle),
                child: IconButton(
                  onPressed: () {
                    _cart.addItem(product);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Added to Cart!"), backgroundColor: Color(0xFF2E7D32)));
                  },
                  icon: const Icon(Icons.add_shopping_cart, color: Color(0xFF1B5E20)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
