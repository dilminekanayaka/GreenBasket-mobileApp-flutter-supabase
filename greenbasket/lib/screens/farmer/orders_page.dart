import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'profile_page.dart';
import 'products_page.dart';
import 'dart:async';

class FarmerOrdersPage extends StatefulWidget {
  const FarmerOrdersPage({super.key});

  @override
  State<FarmerOrdersPage> createState() => _FarmerOrdersPageState();
}

class _FarmerOrdersPageState extends State<FarmerOrdersPage> with SingleTickerProviderStateMixin {
  String _searchQuery = '';
  String _selectedStatus = 'All';
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  StreamSubscription? _ordersSubscription;

  final List<String> _statuses = [
    'All',
    'Pending',
    'Accepted',
    'Processing',
    'Delivering',
    'Delivered',
    'Cancelled',
  ];

  bool _isLoading = true;
  List<Map<String, dynamic>> _fetchedOrders = [];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(duration: const Duration(milliseconds: 600), vsync: this);
    _fadeAnimation = CurvedAnimation(parent: _animationController, curve: Curves.easeInOut);
    _animationController.forward();
    _setupRealtimeOrders();
  }

  void _setupRealtimeOrders() {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    debugPrint("🔄 Setting up Orders Page Realtime Listener for ${user.id}");

    // 🕵️ REAL-TIME STREAM
    // Note: Make sure 'Realtime' is enabled for 'orders' table in Supabase Dashboard -> Database -> Replication
    _ordersSubscription = Supabase.instance.client
        .from('orders')
        .stream(primaryKey: ['id'])
        .listen(
          (List<Map<String, dynamic>> data) {
            debugPrint("🛍️ Realtime Update: Orders table changed (${data.length} total items in stream)");
            // We filter locally or just re-fetch to get joins (profiles/products)
            _fetchOrdersData();
          },
          onError: (error) => debugPrint("❌ Orders Page Stream Error: $error"),
        );

    _fetchOrdersData();
  }

  Future<void> _fetchOrdersData() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    try {
      // 1. Fetch Orders and joined Products (Product join usually works if FK exists)
      final ordersResponse = await Supabase.instance.client
          .from('orders')
          .select('*, products(name, unit)')
          .eq('farmer_id', user.id)
          .order('created_at', ascending: false);

      final List<dynamic> rawOrders = ordersResponse as List<dynamic>;
      
      // 2. Collect unique buyer IDs to fetch profiles separately (Safe Join)
      final buyerIds = rawOrders.map((o) => o['buyer_id'].toString()).toSet().toList();
      
      Map<String, String> buyerNames = {};
      if (buyerIds.isNotEmpty) {
        final profilesResponse = await Supabase.instance.client
            .from('profiles')
            .select('id, full_name')
            .inFilter('id', buyerIds);
        
        for (var p in (profilesResponse as List)) {
          buyerNames[p['id'].toString()] = p['full_name'] ?? 'Customer';
        }
      }

      final List<Map<String, dynamic>> ordersList = [];

      for (var item in rawOrders) {
        final product = item['products'];
        final buyerId = item['buyer_id'].toString();
        final orderId = item['id'].toString();

        ordersList.add({
          'id': orderId.substring(0, 8).toUpperCase(),
          'realId': orderId,
          'customerName': buyerNames[buyerId] ?? 'Customer',
          'items': [
            {
              'name': product != null ? product['name'] : 'Product',
              'quantity': item['quantity'],
              'unit': product != null ? product['unit'] : '',
            }
          ],
          'totalAmount': (item['total_price'] as num).toDouble(),
          'status': item['status'],
          'orderDate': item['created_at'].toString().split('T')[0],
          'deliveryAddress': item['delivery_address'] ?? 'No address provided',
        });
      }

      if (mounted) {
        setState(() {
          _fetchedOrders = ordersList;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("❌ Error fetching orders: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _ordersSubscription?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get _filteredOrders {
    return _fetchedOrders.where((order) {
      final matchesStatus = _selectedStatus == 'All' || order['status'].toString().toLowerCase() == _selectedStatus.toLowerCase();
      final matchesSearch = order['customerName'].toString().toLowerCase().contains(_searchQuery.toLowerCase()) || order['id'].toString().toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesStatus && matchesSearch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F9F5),
      body: Column(
        children: [
          _buildHeader(context),
          _buildSearch(context),
          _buildStatusChips(context),
          Expanded(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: Color(0xFF4CAF50)))
                  : _filteredOrders.isEmpty
                      ? _buildEmptyState(context)
                      : ListView.builder(
                          padding: const EdgeInsets.all(20),
                          itemCount: _filteredOrders.length,
                          itemBuilder: (context, index) {
                            return _OrderCard(
                              order: _filteredOrders[index],
                              onTap: () =>
                                  _showOrderDetails(_filteredOrders[index]),
                              onStatusChange: (newStatus) => _updateOrderStatus(
                                  _filteredOrders[index], newStatus),
                            );
                          },
                        ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(context),
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
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [const Color(0xFF66BB6A), const Color(0xFF4CAF50)],
        ),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
        boxShadow: [BoxShadow(color: const Color(0xFF4CAF50).withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
              child: const Icon(Icons.arrow_back, color: Colors.white, size: 24),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('My Orders', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 0.5)),
                const SizedBox(height: 4),
                Text('${_filteredOrders.length} orders found', style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.9))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearch(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
      child: Container(
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2))]),
        child: TextField(
          onChanged: (v) => setState(() => _searchQuery = v),
          decoration: InputDecoration(
            hintText: 'Search by customer or order ID...',
            hintStyle: TextStyle(color: Colors.grey[400]),
            prefixIcon: Icon(Icons.search, color: Colors.grey[600]),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChips(BuildContext context) {
    return SizedBox(
      height: 50,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        scrollDirection: Axis.horizontal,
        itemCount: _statuses.length,
        itemBuilder: (context, index) {
          final status = _statuses[index];
          final isSelected = _selectedStatus == status;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => setState(() => _selectedStatus = status),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  gradient: isSelected ? LinearGradient(colors: [const Color(0xFF4CAF50), const Color(0xFF66BB6A)]) : null,
                  color: isSelected ? null : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: isSelected ? Colors.transparent : Colors.grey.withOpacity(0.3)),
                  boxShadow: isSelected ? [BoxShadow(color: const Color(0xFF4CAF50).withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 2))] : null,
                ),
                child: Center(child: Text(status, style: TextStyle(color: isSelected ? Colors.white : Colors.grey[700], fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500, fontSize: 14))),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(color: Colors.grey[100], shape: BoxShape.circle),
            child: Icon(Icons.shopping_bag_outlined, size: 80, color: Colors.grey[400]),
          ),
          const SizedBox(height: 24),
          Text('No orders found', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.grey[700])),
          const SizedBox(height: 8),
          Text('Orders from customers will appear here', style: TextStyle(fontSize: 14, color: Colors.grey[500])),
        ],
      ),
    );
  }

  Future<void> _updateOrderStatus(Map<String, dynamic> order, String newStatus) async {
    final statusToUpdate = newStatus.toLowerCase();
    debugPrint("🔄 Updating order ${order['realId']} to status: $statusToUpdate");
    
    try {
      // Perform the update and request the updated row back to verify success
      final response = await Supabase.instance.client
          .from('orders')
          .update({'status': statusToUpdate})
          .eq('id', order['realId'])
          .select();

      if ((response as List).isEmpty) {
        debugPrint("⚠️ Update returned 0 rows for ID: ${order['realId']}. This could be an RLS policy issue or an ID mismatch.");
        throw Exception("No rows updated. You might not have permission to update this order.");
      }

      debugPrint("✅ Order updated successfully: ${response.first}");
      
      // Manually trigger refresh to ensure UI is up to date even if stream is delayed
      await _fetchOrdersData();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Order status: ${newStatus.toUpperCase()}"), 
            backgroundColor: const Color(0xFF2E7D32), 
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          )
        );
      }
    } catch (e) {
      debugPrint("❌ Update error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to update: $e"), backgroundColor: Colors.redAccent)
        );
      }
    }
  }

  void _showOrderDetails(Map<String, dynamic> order) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _OrderDetailsSheet(
        order: order,
        onStatusChange: (newStatus) => _updateOrderStatus(order, newStatus),
      ),
    );
  }

  Widget _buildBottomNav(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: const BorderRadius.vertical(top: Radius.circular(24)), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 16, offset: const Offset(0, -4))]),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(icon: Icons.home_rounded, label: "Home", active: false, onTap: () => Navigator.pop(context)),
              _NavItem(icon: Icons.inventory_2_rounded, label: "Products", active: false, onTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const FarmerProductsPage()))),
              _NavItem(icon: Icons.shopping_bag_rounded, label: "Orders", active: true, onTap: () {}),
              _NavItem(icon: Icons.person_rounded, label: "Profile", active: false, onTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const FarmerProfilePage()))),
            ],
          ),
        ),
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final Map<String, dynamic> order;
  final VoidCallback onTap;
  final Function(String) onStatusChange;

  const _OrderCard({required this.order, required this.onTap, required this.onStatusChange});

  @override
  Widget build(BuildContext context) {
    final status = order['status'].toString().toLowerCase();
    final items = order['items'] as List;

    Color statusColor = Colors.orange;
    if (status == 'accepted') statusColor = Colors.blue;
    if (status == 'processing') statusColor = Colors.purple;
    if (status == 'delivering') statusColor = Colors.teal;
    if (status == 'delivered') statusColor = Colors.green;
    if (status == 'cancelled') statusColor = Colors.red;

    final displayStatus = status[0].toUpperCase() + status.substring(1);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 12, offset: const Offset(0, 4))]),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(order['customerName'], style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1B5E20))),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                    child: Text(displayStatus, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: statusColor)),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ...items.map((item) => Text("• ${item['name']} - ${item['quantity']} ${item['unit']}", style: TextStyle(color: Colors.grey[700], fontSize: 13))),
              const Divider(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Rs ${order['totalAmount'].toStringAsFixed(2)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF4CAF50))),
                  Text(order['orderDate'], style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OrderDetailsSheet extends StatelessWidget {
  final Map<String, dynamic> order;
  final Function(String) onStatusChange;

  const _OrderDetailsSheet({required this.order, required this.onStatusChange});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> items = List<Map<String, dynamic>>.from(order['items']);
    final currentStatus = order['status'].toString().toLowerCase();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Order #${order['id']}", 
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1B5E20))),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close_rounded, color: Colors.grey),
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          /// CUSTOMER & ADDRESS
          _DetailRow(icon: Icons.person_rounded, label: "Customer", value: order['customerName']),
          _DetailRow(icon: Icons.location_on_rounded, label: "Delivery Address", value: order['deliveryAddress']),
          _DetailRow(icon: Icons.calendar_today_rounded, label: "Order Date", value: order['orderDate']),
          
          const Divider(height: 32),
          
          /// ITEMS
          const Text("Items Ordered", 
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1B5E20))),
          const SizedBox(height: 12),
          ...items.map((item) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("${item['name']} x ${item['quantity']} ${item['unit']}", 
                  style: TextStyle(color: Colors.grey[800], fontSize: 14)),
              ],
            ),
          )),
          
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Total Amount", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              Text("Rs ${order['totalAmount'].toStringAsFixed(2)}", 
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF4CAF50))),
            ],
          ),

          const Divider(height: 40),
          
          /// STATUS UPDATE
          const Text("Update Status", 
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1B5E20))),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8, runSpacing: 8,
            children: [
              'pending', 
              'accepted', 
              'processing', 
              'delivering', 
              'delivered', 
              'cancelled'
            ].map((s) {
              final isCurrent = currentStatus == s;
              return ChoiceChip(
                label: Text(s[0].toUpperCase() + s.substring(1)),
                selected: isCurrent,
                onSelected: (v) { 
                  if (v && !isCurrent) { 
                    Navigator.pop(context); 
                    onStatusChange(s); 
                  } 
                },
                selectedColor: const Color(0xFF4CAF50),
                labelStyle: TextStyle(
                  color: isCurrent ? Colors.white : Colors.black87,
                  fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                ),
                backgroundColor: Colors.grey[100],
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _DetailRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF4CAF50), size: 20),
          const SizedBox(width: 12),
          Text("$label: ", style: const TextStyle(fontWeight: FontWeight.bold)),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _NavItem({required this.icon, required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = active ? const Color(0xFF4CAF50) : Colors.grey[600];
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(color: active ? const Color(0xFF4CAF50).withOpacity(0.1) : Colors.transparent, borderRadius: BorderRadius.circular(16)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 26),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(fontSize: 12, color: color, fontWeight: active ? FontWeight.w600 : FontWeight.normal)),
          ],
        ),
      ),
    );
  }
}
