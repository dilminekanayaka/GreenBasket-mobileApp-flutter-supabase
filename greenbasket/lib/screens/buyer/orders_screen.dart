import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'order_details_screen.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  final _supabase = Supabase.instance.client;
  Stream<List<Map<String, dynamic>>>? _ordersStream;

  @override
  void initState() {
    super.initState();
    _initStream();
  }

  void _initStream() {
    final user = _supabase.auth.currentUser;
    if (user != null) {
      _ordersStream = _supabase
          .from('orders')
          .stream(primaryKey: ['id'])
          .eq('buyer_id', user.id)
          .order('created_at', ascending: false)
          .map((rows) => List<Map<String, dynamic>>.from(rows));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_ordersStream == null) return const Center(child: Text("Please login to see orders"));

    return Scaffold(
      backgroundColor: const Color(0xFFF9FBF9),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _ordersStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF2E7D32)));
          }
          
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return _buildEmptyState();
          }

          final orders = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: orders.length,
            itemBuilder: (context, index) {
              return _buildOrderCard(orders[index]);
            },
          );
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
            decoration: const BoxDecoration(color: Color(0xFFE8F5E9), shape: BoxShape.circle),
            child: Icon(Icons.receipt_long_outlined, size: 80, color: const Color(0xFF4CAF50).withOpacity(0.5)),
          ),
          const SizedBox(height: 16),
          const Text("No orders yet", style: TextStyle(fontSize: 18, color: Color(0xFF1B5E20), fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildOrderCard(Map<String, dynamic> order) {
    final status = (order['status'] ?? 'pending').toString().toLowerCase();
    
    return FutureBuilder<Map<String, dynamic>>(
      future: _supabase.from('products').select('name, image_url, price, unit').eq('id', order['product_id']).single(),
      builder: (context, prodSnapshot) {
        final product = prodSnapshot.data;
        // Optimization: In a real app, I'd fetch these using a join or local cache.
        // But since streams don't support joins easily in one go, We'll merge or use separate fetch.
        // Actually, let's keep it simple for now or fetch in the stream map.

        return GestureDetector(
          onTap: () {
            // Merge product info for the details screen
            final fullOrder = Map<String, dynamic>.from(order);
            fullOrder['products'] = product;
            Navigator.push(context, MaterialPageRoute(builder: (_) => OrderDetailsScreen(order: fullOrder)));
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))]),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: product?['image_url'] != null
                    ? Image.network(product!['image_url'], width: 60, height: 60, fit: BoxFit.cover)
                    : Container(color: const Color(0xFFE8F5E9), width: 60, height: 60, child: const Icon(Icons.eco_rounded, color: Color(0xFF4CAF50))),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(product?['name'] ?? "Loading...", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1B5E20))),
                      const SizedBox(height: 4),
                      Text("Order #${order['id'].toString().substring(0, 8).toUpperCase()}", style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _buildStatusBadge(status),
                    const SizedBox(height: 8),
                    Text("Rs. ${order['total_price']}", style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Color(0xFF2E7D32))),
                  ],
                ),
                const SizedBox(width: 8),
                const Icon(Icons.chevron_right_rounded, color: Colors.grey),
              ],
            ),
          ),
        );
      }
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    status = status.toLowerCase();
    switch (status) {
      case 'delivered': color = Colors.green; break;
      case 'cancelled': color = Colors.red; break;
      case 'delivering': color = Colors.teal; break;
      case 'accepted': color = Colors.blue; break;
      case 'processing': color = Colors.amber; break;
      default: color = Colors.orange;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
      child: Text(status.toUpperCase(), style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
    );
  }
}
