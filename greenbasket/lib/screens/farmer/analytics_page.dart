import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class FarmerAnalyticsPage extends StatefulWidget {
  const FarmerAnalyticsPage({super.key});

  @override
  State<FarmerAnalyticsPage> createState() => _FarmerAnalyticsPageState();
}

class _FarmerAnalyticsPageState extends State<FarmerAnalyticsPage> {
  bool _isLoading = true;
  double _totalRevenue = 0;
  int _totalOrders = 0;
  int _completedOrders = 0;
  List<Map<String, dynamic>> _topProducts = [];
  List<double> _monthlyRevenue = List.filled(6, 0.0);
  final List<String> _months = [];

  @override
  void initState() {
    super.initState();
    _generateMonthLabels();
    _loadAnalytics();
  }

  void _generateMonthLabels() {
    final now = DateTime.now();
    for (int i = 5; i >= 0; i--) {
      final date = DateTime(now.year, now.month - i, 1);
      _months.add(DateFormat('MMM').format(date));
    }
  }

  Future<void> _loadAnalytics() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    setState(() => _isLoading = true);

    try {
      // 1. Total Revenue & Orders
      final ordersRes = await Supabase.instance.client
          .from('orders')
          .select('total_price, status, created_at, product_id, products(name)')
          .eq('farmer_id', user.id);

      final orders = ordersRes as List;
      double revenue = 0;
      int completed = 0;
      Map<String, int> productSales = {};
      Map<String, String> productNames = {};

      final now = DateTime.now();
      final sixMonthsAgo = DateTime(now.year, now.month - 5, 1);

      for (var order in orders) {
        final price = (order['total_price'] as num).toDouble();
        revenue += price;
        if (order['status'] == 'Completed' || order['status'] == 'Delivered') {
          completed++;
        }

        // Top products calculation
        final pid = order['product_id'].toString();
        productSales[pid] = (productSales[pid] ?? 0) + 1;
        if (order['products'] != null) {
          productNames[pid] = order['products']['name'];
        }

        // Monthly revenue
        final createdAt = DateTime.parse(order['created_at']);
        if (createdAt.isAfter(sixMonthsAgo)) {
          int monthDiff = (now.year - createdAt.year) * 12 + now.month - createdAt.month;
          if (monthDiff >= 0 && monthDiff < 6) {
            _monthlyRevenue[5 - monthDiff] += price;
          }
        }
      }

      // Format Top Products
      var sortedProducts = productSales.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      
      _topProducts = sortedProducts.take(5).map((e) => {
        'name': productNames[e.key] ?? 'Unknown',
        'sales': e.value,
      }).toList();

      if (mounted) {
        setState(() {
          _totalRevenue = revenue;
          _totalOrders = orders.length;
          _completedOrders = completed;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error loading analytics: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F9F5),
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSummaryCards(),
                  const SizedBox(height: 24),
                  _buildRevenueChart(),
                  const SizedBox(height: 24),
                  _buildTopProducts(),
                  const SizedBox(height: 24),
                  _buildOrderPerformance(),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 120,
      floating: false,
      pinned: true,
      backgroundColor: const Color(0xFF4CAF50),
      elevation: 0,
       flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.only(left: 56, bottom: 16),
        title: const Text(
          'Detailed Analytics',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF66BB6A), Color(0xFF4CAF50)],
            ),
          ),
        ),
      ),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
        onPressed: () => Navigator.pop(context),
      ),
    );
  }

  Widget _buildSummaryCards() {
    return Row(
      children: [
        _AnalyticsCard(
          title: 'Total Revenue',
          value: 'Rs ${_totalRevenue.toStringAsFixed(0)}',
          icon: Icons.payments_outlined,
          color: Colors.green,
          isLoading: _isLoading,
        ),
        const SizedBox(width: 16),
        _AnalyticsCard(
          title: 'Total Orders',
          value: _totalOrders.toString(),
          icon: Icons.shopping_cart_outlined,
          color: Colors.blue,
          isLoading: _isLoading,
        ),
      ],
    );
  }

  Widget _buildRevenueChart() {
    double maxRevenue = _monthlyRevenue.reduce((a, b) => a > b ? a : b);
    if (maxRevenue == 0) maxRevenue = 1;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Revenue Trends (6 Months)',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1B5E20),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 200,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(6, (index) {
                double height = (_monthlyRevenue[index] / maxRevenue) * 150;
                return Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                      width: 30,
                      height: height < 5 ? 5 : height,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            const Color(0xFF66BB6A),
                            const Color(0xFF4CAF50).withOpacity(0.6),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _months[index],
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopProducts() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Top Selling Products',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1B5E20),
            ),
          ),
          const SizedBox(height: 16),
          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else if (_topProducts.isEmpty)
            const Text('No sales data available')
          else
            ..._topProducts.map((p) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4CAF50).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.eco, color: Color(0xFF4CAF50), size: 20),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          p['name'],
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '${p['sales']} orders',
                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.trending_up, color: Colors.green, size: 20),
                ],
              ),
            )),
        ],
      ),
    );
  }

  Widget _buildOrderPerformance() {
    double completionRate = _totalOrders > 0 ? (_completedOrders / _totalOrders) * 100 : 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Order Performance',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1B5E20),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Completion Rate'),
              Text(
                '${completionRate.toStringAsFixed(1)}%',
                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
              ),
            ],
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: completionRate / 100,
            backgroundColor: Colors.green.withOpacity(0.1),
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF4CAF50)),
            minHeight: 8,
            borderRadius: BorderRadius.circular(4),
          ),
          const SizedBox(height: 20),
          _buildPerformanceItem('Pending Orders', _totalOrders - _completedOrders, Colors.orange),
          _buildPerformanceItem('Total Sales', _totalOrders, Colors.blue),
        ],
      ),
    );
  }

  Widget _buildPerformanceItem(String label, int value, Color color) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[700])),
          Text(
            value.toString(),
            style: TextStyle(fontWeight: FontWeight.bold, color: color),
          ),
        ],
      ),
    );
  }
}

class _AnalyticsCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final bool isLoading;

  const _AnalyticsCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              isLoading ? '...' : value,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1B5E20),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
