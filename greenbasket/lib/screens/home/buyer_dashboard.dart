import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../buyer/buyer_home_screen.dart';
import '../buyer/orders_screen.dart';
import '../buyer/cart_screen.dart';
import '../buyer/profile_screen.dart';
import '../auth/login_screen.dart';
import '../buyer/wishlist_screen.dart';
import '../buyer/help_support_screen.dart';
import '../../services/cart_service.dart';
import '../../services/wishlist_service.dart';

class BuyerDashboard extends StatefulWidget {
  const BuyerDashboard({super.key});

  @override
  State<BuyerDashboard> createState() => _BuyerDashboardState();
}

class _BuyerDashboardState extends State<BuyerDashboard> {
  int _currentIndex = 0;
  final _supabase = Supabase.instance.client;
  String _name = "Buyer";
  String? _avatarUrl;

  final List<Widget> _screens = [
    const BuyerHomeScreen(),
    const OrdersScreen(),
    const CartScreen(),
    const ProfileScreen(),
    const WishlistScreen(),
    const HelpSupportScreen(),
  ];

  final List<String> _titles = [
    "GreenBasket",
    "My Orders",
    "My Cart",
    "My Profile",
    "My Wishlist",
    "Help & Support",
  ];

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final user = _supabase.auth.currentUser;
    if (user != null) {
      if (mounted) setState(() => _name = user.email?.split('@')[0] ?? "Buyer");
      try {
        final data = await _supabase.from('profiles').select('full_name, avatar_url').eq('id', user.id).single();
        if (mounted) {
          setState(() {
            if (data['full_name'] != null) _name = data['full_name'];
            _avatarUrl = data['avatar_url'];
          });
        }
      } catch (e) {
        debugPrint("Error loading profile: $e");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FBF9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Text(_titles[_currentIndex], style: const TextStyle(color: Color(0xFF1B5E20), fontWeight: FontWeight.bold)),
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu_rounded, color: Color(0xFF2E7D32)),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: GestureDetector(
              onTap: () => setState(() => _currentIndex = 3),
              child: CircleAvatar(
                radius: 18,
                backgroundColor: const Color(0xFFC8E6C9),
                backgroundImage: _avatarUrl != null ? NetworkImage(_avatarUrl!) : null,
                child: _avatarUrl == null ? Text(_name.isNotEmpty ? _name[0].toUpperCase() : "B", style: const TextStyle(color: Color(0xFF2E7D32), fontWeight: FontWeight.bold, fontSize: 14)) : null,
              ),
            ),
          ),
        ],
      ),
      drawer: _buildProfessionalDrawer(),
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildProfessionalDrawer() {
    return Drawer(
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.only(topRight: Radius.circular(40), bottomRight: Radius.circular(40))),
      child: Column(
        children: [
          _buildDrawerHeader(),
          const SizedBox(height: 10),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _buildDrawerItem(0, Icons.home_rounded, "Home"),
                  _buildDrawerItem(1, Icons.shopping_bag_rounded, "My Orders"),
                  _buildDrawerItem(2, Icons.shopping_cart_rounded, "My Cart"),
                  _buildDrawerItem(4, Icons.favorite_rounded, "Wishlist"),
                  const Padding(padding: EdgeInsets.symmetric(horizontal: 32, vertical: 10), child: Divider(height: 1)),
                  _buildDrawerItem(5, Icons.help_outline_rounded, "Help & Support"),
                ],
              ),
            ),
          ),
          _buildLogoutBtn(),
        ],
      ),
    );
  }

  Widget _buildDrawerHeader() {
    return GestureDetector(
      onTap: () {
        setState(() => _currentIndex = 3);
        Navigator.pop(context);
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.only(top: 80, bottom: 40, left: 32, right: 32),
        decoration: const BoxDecoration(
          color: Color(0xFF1B5E20),
          borderRadius: BorderRadius.only(bottomLeft: Radius.circular(60)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(3),
              decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
              child: CircleAvatar(
                radius: 35, 
                backgroundColor: const Color(0xFFE8F5E9), 
                backgroundImage: _avatarUrl != null ? NetworkImage(_avatarUrl!) : null,
                child: _avatarUrl == null ? const Icon(Icons.person, size: 40, color: Color(0xFF1B5E20)) : null,
              ),
            ),
            const SizedBox(height: 20),
            Text(_name, style: const TextStyle(fontSize: 22, color: Colors.white, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            const Text("Healthy Choice, Happy Life", style: TextStyle(color: Colors.white70, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem(int index, IconData icon, String label) {
    bool isSelected = _currentIndex == index;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: InkWell(
        onTap: () {
          setState(() => _currentIndex = index);
          Navigator.pop(context);
        },
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: BoxDecoration(color: isSelected ? const Color(0xFFE8F5E9) : Colors.transparent, borderRadius: BorderRadius.circular(16)),
          child: Row(
            children: [
              Icon(icon, color: isSelected ? const Color(0xFF1B5E20) : Colors.grey[600], size: 22),
              const SizedBox(width: 16),
              Text(label, style: TextStyle(fontSize: 15, fontWeight: isSelected ? FontWeight.bold : FontWeight.w500, color: isSelected ? const Color(0xFF1B5E20) : Colors.grey[800])),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogoutBtn() {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: InkWell(
        onTap: () async {
          await _supabase.auth.signOut();
          // Clear user services
          CartService().setUser(null);
          WishlistService().setUser(null);

          if (!context.mounted) return;

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text("Logged out successfully. See you soon!"),
              backgroundColor: const Color(0xFF2E7D32),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
          );

          Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => const LoginScreen()),
              (route) => false);
        },
        child: Row(
          children: const [
            Icon(Icons.logout_rounded, color: Colors.redAccent),
            SizedBox(width: 12),
            Text("Logout", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, -5))]),
      child: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildNavItem(0, Icons.home_rounded, "Home"),
            _buildNavItem(1, Icons.shopping_bag_rounded, "Orders"),
            _buildNavItem(2, Icons.shopping_cart_rounded, "Cart"),
            _buildNavItem(3, Icons.person_rounded, "Profile"),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    bool isSelected = _currentIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(color: isSelected ? const Color(0xFF2E7D32) : Colors.transparent, borderRadius: BorderRadius.circular(20)),
        child: Row(children: [Icon(icon, color: isSelected ? Colors.white : Colors.grey[400]), if (isSelected) ...[const SizedBox(width: 8), Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))]]),
      ),
    );
  }
}
