import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../farmer/products_page.dart';
import '../farmer/add_product_page.dart';
import '../farmer/orders_page.dart';
import '../farmer/profile_page.dart';

class FarmerDashboard extends StatefulWidget {
  const FarmerDashboard({super.key});

  @override
  State<FarmerDashboard> createState() => _FarmerDashboardState();
}

class _FarmerDashboardState extends State<FarmerDashboard>
    with TickerProviderStateMixin {
  int _currentIndex = 0;
  String _name = "Farmer";
  String? _avatarUrl;

  // Dashboard Stats
  int _productCount = 0;
  int _orderCount = 0;
  double _totalEarnings = 0.0;
  List<double> _weeklyEarnings = List.filled(7, 0.0);
  double _growthPercentage = 0.0;
  List<Map<String, dynamic>> _recentActivities = [];
  bool _isStatsLoading = true;

  StreamSubscription? _profileSubscription;
  StreamSubscription? _productsSubscription;
  StreamSubscription? _ordersSubscription;
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _loadUser();

    // Initialize animations
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    _fadeController.forward();
    _slideController.forward();

    _setupProfileListener();
    _setupStatsListeners();
    _loadDashboardStats(isInitial: true);
  }

  void _setupStatsListeners() {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    // Listen for product changes - silent refresh
    _productsSubscription = Supabase.instance.client
        .from('products')
        .stream(primaryKey: ['id'])
        .eq('farmer_id', user.id)
        .listen((_) => _loadDashboardStats(isInitial: false));

    // Listen for order changes - silent refresh
    _ordersSubscription = Supabase.instance.client
        .from('orders')
        .stream(primaryKey: ['id'])
        .eq('farmer_id', user.id)
        .listen((_) => _loadDashboardStats(isInitial: false));
  }

  Future<void> _loadDashboardStats({bool isInitial = false}) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    if (isInitial && mounted) {
      setState(() => _isStatsLoading = true);
    }

    try {
      // 1. Fetch Product Count
      final productRes = await Supabase.instance.client
          .from('products')
          .select('id')
          .eq('farmer_id', user.id);

      final pCount = (productRes as List).length;

      // 2. Fetch Orders Count (total individual sales)
      final ordersRes = await Supabase.instance.client
          .from('orders')
          .select('id')
          .eq('farmer_id', user.id);

      final oCount = (ordersRes as List).length;

      // 3. Fetch Total Earnings
      final earningsRes = await Supabase.instance.client
          .from('orders')
          .select('total_price')
          .eq('farmer_id', user.id);

      double total = 0;
      for (var item in earningsRes as List) {
        total += (item['total_price'] as num).toDouble();
      }

      // 4. Fetch Weekly Earnings for Chart
      final now = DateTime.now();
      final sevenDaysAgo = DateTime(now.year, now.month, now.day)
          .subtract(const Duration(days: 6));

      final weeklyRes = await Supabase.instance.client
          .from('orders')
          .select('total_price, created_at')
          .eq('farmer_id', user.id)
          .gte('created_at', sevenDaysAgo.toIso8601String());

      List<double> dailyTotals = List.filled(7, 0.0);
      for (var item in weeklyRes as List) {
        final date = DateTime.parse(item['created_at']);
        final dayIndex = date.difference(sevenDaysAgo).inDays;
        if (dayIndex >= 0 && dayIndex < 7) {
          dailyTotals[dayIndex] += (item['total_price'] as num).toDouble();
        }
      }

      // Calculate Growth (slightly more dynamic for feedback)
      double growth = 0.0;
      if (oCount > 0) {
        growth = (oCount * 12.5) % 40.0; // Simulated growth based on sales
      } else if (pCount > 0) {
        growth = (pCount * 2.5) % 15.0; // Inventory growth if no sales yet
      }

      // 5. Fetch Recent Activities (Combine latest orders and latest products)
      final latestProducts = await Supabase.instance.client
          .from('products')
          .select('name, created_at')
          .eq('farmer_id', user.id)
          .order('created_at', ascending: false)
          .limit(3);

      final latestOrders = await Supabase.instance.client
          .from('orders')
          .select('product_id, quantity, created_at, products(name)')
          .eq('farmer_id', user.id)
          .order('created_at', ascending: false)
          .limit(3);

      debugPrint(
          "Fetched ${(latestProducts as List).length} products and ${(latestOrders as List).length} orders for activity.");

      final List<Map<String, dynamic>> activities = [];

      for (var p in latestProducts as List) {
        activities.add({
          'type': 'product',
          'title': 'Product Added',
          'subtitle': p['name'],
          'time': DateTime.parse(p['created_at']),
          'icon': Icons.add_box_outlined,
          'color': const Color(0xFFFF9800),
        });
      }

      for (var o in latestOrders as List) {
        final productName =
            o['products'] != null ? o['products']['name'] : 'Unknown Product';
        activities.add({
          'type': 'order',
          'title': 'New Order Received',
          'subtitle': '$productName - ${o['quantity']}',
          'time': DateTime.parse(o['created_at']),
          'icon': Icons.shopping_cart_outlined,
          'color': const Color(0xFF4CAF50),
        });
      }

      // Sort combined activities by time
      activities.sort(
          (a, b) => (b['time'] as DateTime).compareTo(a['time'] as DateTime));
      final finalActivities = activities.take(3).toList();

      if (mounted) {
        setState(() {
          _productCount = pCount;
          _orderCount = oCount;
          _totalEarnings = total;
          _weeklyEarnings = dailyTotals;
          _growthPercentage = growth;
          _recentActivities = finalActivities;
          _isStatsLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error loading dashboard stats: $e");
      if (mounted) setState(() => _isStatsLoading = false);
    }
  }

  double _getMaxEarnings() {
    double max = 0;
    for (var e in _weeklyEarnings) {
      if (e > max) max = e;
    }
    return max == 0 ? 1.0 : max;
  }

  String _getDayLabel(int daysAgo) {
    final date = DateTime.now().subtract(Duration(days: daysAgo));
    final labels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    // weekday is 1-indexed (1=Mon, 7=Sun)
    return labels[date.weekday - 1];
  }

  void _setupProfileListener() {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    _profileSubscription = Supabase.instance.client
        .from('profiles')
        .stream(primaryKey: ['id'])
        .eq('id', user.id)
        .listen((data) {
          if (data.isNotEmpty) {
            setState(() {
              _name = data.first['full_name'] ?? "Farmer";
              _avatarUrl = data.first['avatar_url'];
            });
          }
        });
  }

  @override
  void dispose() {
    _profileSubscription?.cancel();
    _productsSubscription?.cancel();
    _ordersSubscription?.cancel();
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  Future<void> _loadUser() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    try {
      final data = await Supabase.instance.client
          .from('profiles')
          .select('full_name, avatar_url')
          .eq('id', user.id)
          .single();

      setState(() {
        _name = data['full_name'] ?? "Farmer";
        _avatarUrl = data['avatar_url'];
      });
    } catch (e) {
      debugPrint("Error loading user in dashboard: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      drawer: _buildSidebar(context),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF66BB6A),
              const Color(0xFF4CAF50),
              const Color(0xFF388E3C),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              /// ✨ GRADIENT HEADER WITH GLASSMORPHISM
              _buildHeader(context),

              /// 📊 MAIN CONTENT
              Expanded(
                child: Container(
                  margin: const EdgeInsets.only(top: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F9F5),
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(32)),
                  ),
                  child: RefreshIndicator(
                    onRefresh: () => _loadDashboardStats(isInitial: true),
                    color: const Color(0xFF4CAF50),
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: SlideTransition(
                        position: _slideAnimation,
                        child: SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              /// STATS CARDS
                              _buildStatsSection(context),

                              const SizedBox(height: 24),

                              /// QUICK ACTIONS
                              _buildQuickActions(context),

                              const SizedBox(height: 24),

                              /// EARNINGS CHART
                              _buildEarningsCard(context),

                              const SizedBox(height: 24),

                              /// RECENT ACTIVITY
                              _buildRecentActivity(context),

                              const SizedBox(height: 20),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),

      /// 🔽 MODERN BOTTOM NAV
      bottomNavigationBar: _buildBottomNav(context),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Row(
        children: [
          // Menu Icon (Left)
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () {
                  _scaffoldKey.currentState?.openDrawer();
                },
                child: const Icon(
                  Icons.menu_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ),
          ),

          const SizedBox(width: 16),

          // User Info (Expanded)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _name.isNotEmpty ? _name : 'Farmer',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    height: 1.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  'Farmer Account',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white.withOpacity(0.85),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 12),

          // Notification Icon
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () {
                  // TODO: Show notifications
                },
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    const Icon(
                      Icons.notifications_none_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                    // Notification Badge
                    Positioned(
                      top: 10,
                      right: 10,
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF5252),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white,
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(width: 12),

          // Profile Avatar (Right)
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const FarmerProfilePage(),
                ),
              );
            },
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white,
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: CircleAvatar(
                radius: 22,
                backgroundColor: Colors.white,
                child: CircleAvatar(
                  radius: 20,
                  backgroundColor: const Color(0xFF2E7D32),
                  backgroundImage:
                      _avatarUrl != null ? NetworkImage(_avatarUrl!) : null,
                  child: _avatarUrl == null
                      ? Text(
                          _name.isNotEmpty ? _name[0].toUpperCase() : 'F',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        )
                      : null,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.white,
      width: MediaQuery.of(context).size.width * 0.8,
      child: Column(
        children: [
          // Drawer Header
          Container(
            padding:
                const EdgeInsets.only(top: 60, left: 24, bottom: 32, right: 24),
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF66BB6A),
                  const Color(0xFF4CAF50),
                ],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: CircleAvatar(
                    radius: 36,
                    backgroundColor: const Color(0xFF2E7D32),
                    backgroundImage:
                        _avatarUrl != null ? NetworkImage(_avatarUrl!) : null,
                    child: _avatarUrl == null
                        ? Text(
                            _name.isNotEmpty ? _name[0].toUpperCase() : 'F',
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          )
                        : null,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  _name.isNotEmpty ? _name : 'Farmer',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'Verified Farmer Account',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white.withOpacity(0.9),
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Drawer Items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _buildDrawerItem(
                  icon: Icons.dashboard_rounded,
                  label: 'Dashboard',
                  isSelected: true,
                  onTap: () => Navigator.pop(context),
                ),
                _buildDrawerItem(
                  icon: Icons.inventory_2_rounded,
                  label: 'My Products',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const FarmerProductsPage(),
                      ),
                    );
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.shopping_bag_rounded,
                  label: 'Manage Orders',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const FarmerOrdersPage(),
                      ),
                    );
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.analytics_rounded,
                  label: 'Sales Analytics',
                  onTap: () {},
                ),
                _buildDrawerItem(
                  icon: Icons.store_rounded,
                  label: 'My Shop Profile',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const FarmerProfilePage(),
                      ),
                    );
                  },
                ),
                const Divider(height: 32, thickness: 1),
                _buildDrawerItem(
                  icon: Icons.settings_rounded,
                  label: 'Account Settings',
                  onTap: () {},
                ),
                _buildDrawerItem(
                  icon: Icons.help_outline_rounded,
                  label: 'Help & Support',
                  onTap: () {},
                ),
                _buildDrawerItem(
                  icon: Icons.info_outline_rounded,
                  label: 'About GreenBasket',
                  onTap: () {},
                ),
              ],
            ),
          ),

          // Logout Button
          Padding(
            padding: const EdgeInsets.all(24),
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.08),
                borderRadius: BorderRadius.circular(16),
              ),
              child: ListTile(
                onTap: () async {
                  await Supabase.instance.client.auth.signOut();
                  // Note: You should handle navigation to login page here or via listener
                },
                leading: const Icon(Icons.logout_rounded, color: Colors.red),
                title: const Text(
                  'Sign Out',
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String label,
    bool isSelected = false,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: isSelected
            ? const Color(0xFF4CAF50).withOpacity(0.1)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Icon(
          icon,
          color: isSelected ? const Color(0xFF4CAF50) : Colors.grey[700],
          size: 24,
        ),
        title: Text(
          label,
          style: TextStyle(
            color: isSelected ? const Color(0xFF4CAF50) : Colors.grey[800],
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            fontSize: 15,
          ),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Widget _buildStatsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Dashboard Overview',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF1B5E20),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _AnimatedStatCard(
                icon: Icons.inventory_2_rounded,
                label: 'Products',
                value: _isStatsLoading ? '...' : _productCount.toString(),
                color: const Color(0xFF2196F3),
                delay: 0,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const FarmerProductsPage(),
                    ),
                  ).then((_) => _loadDashboardStats());
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _AnimatedStatCard(
                icon: Icons.shopping_bag_rounded,
                label: 'Orders',
                value: _isStatsLoading ? '...' : _orderCount.toString(),
                color: const Color(0xFFFF9800),
                delay: 100,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const FarmerOrdersPage(),
                    ),
                  ).then((_) => _loadDashboardStats());
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _AnimatedStatCard(
                icon: Icons.attach_money_rounded,
                label: 'Earnings',
                value: _isStatsLoading
                    ? '...'
                    : 'Rs ${_totalEarnings.toStringAsFixed(0)}',
                color: const Color(0xFF4CAF50),
                delay: 200,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF1B5E20),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _QuickActionCard(
                icon: Icons.add_circle_outline,
                label: 'Add Product',
                gradientColors: [Color(0xFF4CAF50), Color(0xFF66BB6A)],
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AddProductPage(),
                    ),
                  ).then((_) => _loadDashboardStats());
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _QuickActionCard(
                icon: Icons.list_alt_rounded,
                label: 'View Orders',
                gradientColors: [Color(0xFF2196F3), Color(0xFF42A5F5)],
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const FarmerOrdersPage(),
                    ),
                  ).then((_) => _loadDashboardStats());
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _QuickActionCard(
                icon: Icons.bar_chart_rounded,
                label: 'Analytics',
                gradientColors: [Color(0xFFFF9800), Color(0xFFFFB74D)],
                onTap: () => _loadDashboardStats(isInitial: true),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _QuickActionCard(
                icon: Icons.settings_outlined,
                label: 'Settings',
                gradientColors: [Color(0xFF9C27B0), Color(0xFFBA68C8)],
                onTap: () {},
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEarningsCard(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF1B5E20),
            const Color(0xFF2E7D32),
            const Color(0xFF388E3C),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4CAF50).withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total Earnings',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.9),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _isStatsLoading
                          ? 'Rs 0'
                          : 'Rs ${_totalEarnings.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.arrow_upward,
                                size: 14,
                                color: Colors.white,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${_growthPercentage >= 0 ? '+' : ''}${_growthPercentage.toStringAsFixed(1)}% this month',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    Icons.trending_up_rounded,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Simple graph representation
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildGraphBar((_weeklyEarnings[0] / _getMaxEarnings()) * 100,
                    _getDayLabel(6)),
                _buildGraphBar((_weeklyEarnings[1] / _getMaxEarnings()) * 100,
                    _getDayLabel(5)),
                _buildGraphBar((_weeklyEarnings[2] / _getMaxEarnings()) * 100,
                    _getDayLabel(4)),
                _buildGraphBar((_weeklyEarnings[3] / _getMaxEarnings()) * 100,
                    _getDayLabel(3)),
                _buildGraphBar((_weeklyEarnings[4] / _getMaxEarnings()) * 100,
                    _getDayLabel(2)),
                _buildGraphBar((_weeklyEarnings[5] / _getMaxEarnings()) * 100,
                    _getDayLabel(1)),
                _buildGraphBar((_weeklyEarnings[6] / _getMaxEarnings()) * 100,
                    _getDayLabel(0)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGraphBar(double percentage, String label) {
    return Column(
      children: [
        Container(
          width: 28,
          height: 80 * (percentage / 100),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              colors: [
                Colors.white.withOpacity(0.8),
                Colors.white.withOpacity(0.4),
              ],
            ),
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.white.withOpacity(0.8),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildRecentActivity(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recent Activity',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1B5E20),
              ),
            ),
            TextButton(
              onPressed: () {},
              child: Text(
                'View All',
                style: TextStyle(
                  color: const Color(0xFF4CAF50),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_isStatsLoading)
          const Center(
              child: Padding(
            padding: EdgeInsets.all(20.0),
            child: CircularProgressIndicator(color: Color(0xFF4CAF50)),
          ))
        else if (_recentActivities.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Text(
                'No recent activity',
                style: TextStyle(color: Colors.grey[500]),
              ),
            ),
          )
        else
          ..._recentActivities.map((activity) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _ActivityItem(
                  icon: activity['icon'],
                  title: activity['title'],
                  subtitle: activity['subtitle'],
                  time: _formatActivityTime(activity['time']),
                  iconColor: activity['color'],
                ),
              )),
      ],
    );
  }

  String _formatActivityTime(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  Widget _buildBottomNav(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(
                icon: Icons.home_rounded,
                label: "Home",
                active: _currentIndex == 0,
                onTap: () => setState(() => _currentIndex = 0),
              ),
              _NavItem(
                icon: Icons.inventory_2_rounded,
                label: "Products",
                active: _currentIndex == 1,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const FarmerProductsPage(),
                    ),
                  );
                },
              ),
              _NavItem(
                icon: Icons.shopping_bag_rounded,
                label: "Orders",
                active: _currentIndex == 2,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const FarmerOrdersPage(),
                    ),
                  );
                },
              ),
              _NavItem(
                icon: Icons.person_rounded,
                label: "Profile",
                active: _currentIndex == 3,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const FarmerProfilePage(),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

//////////////////////////////////////////////////
// ANIMATED STAT CARD
//////////////////////////////////////////////////

class _AnimatedStatCard extends StatefulWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final int delay;
  final VoidCallback? onTap;

  const _AnimatedStatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    this.delay = 0,
    this.onTap,
  });

  @override
  State<_AnimatedStatCard> createState() => _AnimatedStatCardState();
}

class _AnimatedStatCardState extends State<_AnimatedStatCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );

    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: widget.color.withOpacity(0.2),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: widget.onTap,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: widget.color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      widget.icon,
                      color: widget.color,
                      size: 24,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    widget.value,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1B5E20),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.label,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

//////////////////////////////////////////////////
// QUICK ACTION CARD
//////////////////////////////////////////////////

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final List<Color> gradientColors;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.label,
    required this.gradientColors,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradientColors,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: gradientColors[0].withOpacity(0.4),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Icon(
                  icon,
                  color: Colors.white,
                  size: 32,
                ),
                const SizedBox(height: 8),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

//////////////////////////////////////////////////
// ACTIVITY ITEM
//////////////////////////////////////////////////

class _ActivityItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String time;
  final Color iconColor;

  const _ActivityItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.time,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1B5E20),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Text(
            time,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }
}

//////////////////////////////////////////////////
// NAVIGATION ITEM
//////////////////////////////////////////////////

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = active ? const Color(0xFF4CAF50) : Colors.grey[600];

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: active
              ? const Color(0xFF4CAF50).withOpacity(0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 26),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: color,
                fontWeight: active ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
