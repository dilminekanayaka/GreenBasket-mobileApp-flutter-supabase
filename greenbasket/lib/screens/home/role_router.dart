import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'farmer_dashboard.dart';
import 'buyer_dashboard.dart';

class RoleRouter extends StatefulWidget {
  const RoleRouter({super.key});

  @override
  State<RoleRouter> createState() => _RoleRouterState();
}

class _RoleRouterState extends State<RoleRouter> {
  String? role;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadRole();
  }

  Future<void> _loadRole() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      if (mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Navigator.of(context)
              .pushNamedAndRemoveUntil('/login', (route) => false);
        });
      }
      return;
    }

    try {
      final data = await Supabase.instance.client
          .from('profiles')
          .select('role')
          .eq('id', user.id)
          .single();

      if (mounted) {
        setState(() {
          role = data['role'];
          loading = false;
        });
      }
    } catch (e) {
      debugPrint("Error loading role: $e");
      if (mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Navigator.of(context)
              .pushNamedAndRemoveUntil('/login', (route) => false);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (role == 'farmer') {
      return const FarmerDashboard();
    } else {
      return const BuyerDashboard();
    }
  }
}
