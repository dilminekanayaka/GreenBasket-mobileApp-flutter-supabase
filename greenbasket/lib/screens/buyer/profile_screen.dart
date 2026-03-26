import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../auth/login_screen.dart';
import 'account_settings_screen.dart';
import 'address_book_screen.dart';
import 'payment_methods_screen.dart';
import 'help_support_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _supabase = Supabase.instance.client;
  String _name = "Buyer";
  String? _email;
  String? _avatarUrl;
  
  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final user = _supabase.auth.currentUser;
    if (user != null) {
      if (mounted) {
        setState(() {
          _name = user.userMetadata?['full_name'] ?? user.email?.split('@')[0] ?? "Buyer";
          _email = user.email;
        });
      }
      
      try {
        final data = await _supabase.from('profiles').select('full_name, avatar_url').eq('id', user.id).single();
        if (mounted) {
          setState(() {
            _name = data['full_name'] ?? _name;
            _avatarUrl = data['avatar_url'];
          });
        }
      } catch (e) {
        debugPrint("Error loading profile: $e");
      }
    }
  }

  Future<void> _logout() async {
    await _supabase.auth.signOut();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FBF9),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // 🏷️ PROFILE HEADER
            _buildProfileCard(),
            const SizedBox(height: 32),
            
            // 📋 MENU ITEMS
            _buildMenuItem(Icons.person_outline_rounded, "Account Settings", () async {
              final result = await Navigator.push(context, MaterialPageRoute(builder: (_) => const AccountSettingsScreen()));
              if (result == true) _loadUser();
            }),
            _buildMenuItem(Icons.location_on_outlined, "Delivery Addresses", () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const AddressBookScreen()));
            }),
            _buildMenuItem(Icons.payment_rounded, "Payment Methods", () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const PaymentMethodsScreen()));
            }),
            _buildMenuItem(Icons.help_outline_rounded, "Help & Support", () {
               Navigator.push(context, MaterialPageRoute(builder: (_) => const HelpSupportScreen()));
            }),
            const Divider(height: 48),
            _buildMenuItem(Icons.logout_rounded, "Sign Out", _logout, color: Colors.red),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileCard() {
    return Container(
      padding: const EdgeInsets.all(32),
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 15,
            offset: const Offset(0, 5),
          )
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: const BoxDecoration(
              color: Color(0xFF4CAF50),
              shape: BoxShape.circle,
            ),
            child: CircleAvatar(
              radius: 50,
              backgroundColor: const Color(0xFFC8E6C9),
              backgroundImage: _avatarUrl != null ? NetworkImage(_avatarUrl!) : null,
              child: _avatarUrl == null ? Text(
                _name.isNotEmpty ? _name[0].toUpperCase() : "B",
                style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: Color(0xFF2E7D32)),
              ) : null,
            ),
          ),
          const SizedBox(height: 16),
          Text(_name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1B5E20))),
          const SizedBox(height: 4),
          Text(_email ?? "", style: TextStyle(color: Colors.grey[600], fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildMenuItem(IconData icon, String title, VoidCallback onTap, {Color? color}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withOpacity(0.05)),
      ),
      child: ListTile(
        leading: Icon(icon, color: color ?? const Color(0xFF4CAF50)),
        title: Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: color ?? const Color(0xFF1B5E20))),
        trailing: const Icon(Icons.chevron_right_rounded, color: Colors.grey),
        onTap: onTap,
      ),
    );
  }
}
