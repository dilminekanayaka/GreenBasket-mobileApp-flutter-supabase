import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'orders_page.dart';
import 'products_page.dart';

class RecentActivityPage extends StatefulWidget {
  const RecentActivityPage({super.key});

  @override
  State<RecentActivityPage> createState() => _RecentActivityPageState();
}

class _RecentActivityPageState extends State<RecentActivityPage> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _activities = [];
  final _supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _loadAllActivities();
  }

  Future<void> _loadAllActivities() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    try {
      // Fetch more rows for the full page
      final orders = await _supabase
          .from('orders')
          .select('id, quantity, created_at, status, products(name)')
          .eq('farmer_id', user.id)
          .order('created_at', ascending: false)
          .limit(20);

      final products = await _supabase
          .from('products')
          .select('id, name, created_at')
          .eq('farmer_id', user.id)
          .order('created_at', ascending: false)
          .limit(20);

      List<Map<String, dynamic>> combined = [];

      for (var o in orders) {
        final productName = o['products'] != null ? o['products']['name'] : 'Unknown Product';
        combined.add({
          'type': 'order',
          'title': 'New Order: $productName',
          'subtitle': 'Quantity: ${o['quantity']} • Status: ${o['status']}',
          'time': DateTime.parse(o['created_at']),
          'icon': Icons.shopping_basket_rounded,
          'color': Colors.orange,
        });
      }

      for (var p in products) {
        combined.add({
          'type': 'product',
          'title': 'Product Added: ${p['name']}',
          'subtitle': 'Successfully listed in your shop',
          'time': DateTime.parse(p['created_at']),
          'icon': Icons.add_business_rounded,
          'color': Colors.green,
        });
      }

      combined.sort((a, b) => (b['time'] as DateTime).compareTo(a['time'] as DateTime));

      if (mounted) {
        setState(() {
          _activities = combined;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error loading activities: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FBF9),
      body: Column(
        children: [
          _buildHeader(context),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF4CAF50)))
                : _activities.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        onRefresh: _loadAllActivities,
                        color: const Color(0xFF4CAF50),
                        child: ListView.builder(
                          padding: const EdgeInsets.all(20),
                          itemCount: _activities.length,
                          itemBuilder: (context, index) {
                            final activity = _activities[index];
                            return _ActivityCard(activity: activity);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 20,
        left: 20,
        right: 20,
        bottom: 20,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF66BB6A), Color(0xFF4CAF50)],
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.arrow_back_rounded, color: Colors.white),
            ),
          ),
          const SizedBox(width: 16),
          const Text(
            "Recent Activity",
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history_rounded, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            "No activities yet",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[400],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActivityCard extends StatelessWidget {
  final Map<String, dynamic> activity;

  const _ActivityCard({required this.activity});

  @override
  Widget build(BuildContext context) {
    final timeStr = DateFormat('MMM d, h:mm a').format(activity['time']);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            if (activity['type'] == 'order') {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const FarmerOrdersPage(),
                ),
              );
            } else if (activity['type'] == 'product') {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const FarmerProductsPage(),
                ),
              );
            }
          },
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: (activity['color'] as Color).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    activity['icon'],
                    color: activity['color'],
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        activity['title'],
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        activity['subtitle'],
                        style: TextStyle(color: Colors.grey[600], fontSize: 13),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        timeStr,
                        style: TextStyle(color: Colors.grey[400], fontSize: 11),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: Colors.grey,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
