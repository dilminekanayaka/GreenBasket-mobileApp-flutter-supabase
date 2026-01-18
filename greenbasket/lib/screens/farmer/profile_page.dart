import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'products_page.dart';
import 'orders_page.dart';

class FarmerProfilePage extends StatefulWidget {
  const FarmerProfilePage({super.key});

  @override
  State<FarmerProfilePage> createState() => _FarmerProfilePageState();
}

class _FarmerProfilePageState extends State<FarmerProfilePage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  String _name = "";
  String _email = "";
  String _phone = "";
  String _location = "";
  String _farmName = "";
  String? _avatarUrl;
  bool _isLoading = false;
  bool _notificationsEnabled = true;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _animationController.forward();
    _loadUserData();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        debugPrint("FarmerProfilePage: No user found, redirecting to login.");
        if (mounted) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.of(context)
                .pushNamedAndRemoveUntil('/login', (route) => false);
          });
        }
        return;
      }

      final data = await Supabase.instance.client
          .from('profiles')
          .select()
          .eq('id', user.id)
          .single();

      setState(() {
        _name = data['full_name'] ?? "";
        _email = user.email ?? "";
        _phone = data['phone'] ?? "Add Phone Number";
        _location = data['location'] ?? "Add Location";
        _farmName = data['farm_name'] ?? "Add Farm Name";
        _avatarUrl = data['avatar_url'];
      });
    } catch (e) {
      debugPrint("Error loading user data: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _updateProfileField(String field, String value) async {
    // Store old value for rollback
    final oldValue = field == 'full_name'
        ? _name
        : field == 'phone'
            ? _phone
            : field == 'location'
                ? _location
                : field == 'farm_name'
                    ? _farmName
                    : "";

    // Optimistic Update: Update UI immediately
    setState(() {
      if (field == 'full_name') _name = value;
      if (field == 'phone') _phone = value;
      if (field == 'location') _location = value;
      if (field == 'farm_name') _farmName = value;
    });

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  "Error: You are no longer signed in. Please log in again."),
              backgroundColor: Colors.red,
            ),
          );
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.of(context)
                .pushNamedAndRemoveUntil('/login', (route) => false);
          });
        }
        return;
      }

      debugPrint("Updating $field to $value for user ${user.id}");

      // Update in Supabase using upsert for reliability
      // We explicitly specify 'id' as the conflict target
      await Supabase.instance.client.from('profiles').upsert({
        'id': user.id,
        field: value,
      }, onConflict: 'id');

      debugPrint("Update successful in Supabase");

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text("${field.replaceAll('_', ' ')} updated successfully!"),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      debugPrint("Error updating profile field: $e");
      // Rollback on error
      setState(() {
        if (field == 'full_name') _name = oldValue;
        if (field == 'phone') _phone = oldValue;
        if (field == 'location') _location = oldValue;
        if (field == 'farm_name') _farmName = oldValue;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed to update: $e"),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _pickAndUploadImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image == null) return;

    setState(() => _isLoading = true);

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      final file = File(image.path);
      final fileExtension = image.path.split('.').last;
      final fileName =
          '${user.id}_${DateTime.now().millisecondsSinceEpoch}.$fileExtension';
      final filePath = 'avatars/$fileName';

      await Supabase.instance.client.storage.from('farm_assets').upload(
            filePath,
            file,
            fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
          );

      final String publicUrl = Supabase.instance.client.storage
          .from('farm_assets')
          .getPublicUrl(filePath);

      await Supabase.instance.client
          .from('profiles')
          .update({'avatar_url': publicUrl}).eq('id', user.id);

      setState(() {
        _avatarUrl = publicUrl;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Profile picture updated!")),
        );
      }
    } catch (e) {
      debugPrint("Error uploading image: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Upload failed: $e")),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showEditDialog(String field, String initialValue) {
    final controller = TextEditingController(
        text: initialValue == "Add Phone Number" ||
                initialValue == "Add Location" ||
                initialValue == "Add Farm Name"
            ? ""
            : initialValue);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Edit ${field.replaceAll('_', ' ')}"),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: "Enter new value"),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel")),
          TextButton(
            onPressed: () {
              _updateProfileField(field, controller.text);
              Navigator.pop(context);
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  void _showPasswordDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Change Password"),
        content: TextField(
          controller: controller,
          obscureText: true,
          decoration: const InputDecoration(hintText: "Enter new password"),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel")),
          TextButton(
            onPressed: () async {
              try {
                await Supabase.instance.client.auth.updateUser(
                  UserAttributes(password: controller.text),
                );
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text("Password updated successfully!")),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Failed to update password: $e")),
                  );
                }
              }
            },
            child: const Text("Update"),
          ),
        ],
      ),
    );
  }

  void _showLanguageDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Select Language"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
                title: const Text("English"),
                onTap: () => Navigator.pop(context)),
            ListTile(
                title: const Text("Sinhala"),
                onTap: () => Navigator.pop(context)),
            ListTile(
                title: const Text("Tamil"),
                onTap: () => Navigator.pop(context)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F9F5),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SingleChildScrollView(
          child: Column(
            children: [
              _buildHeader(),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionTitle("Personal Information"),
                    const SizedBox(height: 12),
                    _buildInfoCard(
                      items: [
                        _InfoItem(
                            icon: Icons.person_outline,
                            label: "Full Name",
                            value: _name.isEmpty ? "Farmer Name" : _name,
                            isAction: true,
                            onTap: () => _showEditDialog('full_name', _name)),
                        _InfoItem(
                            icon: Icons.email_outlined,
                            label: "Email Address",
                            value: _email),
                        _InfoItem(
                            icon: Icons.phone_outlined,
                            label: "Phone Number",
                            value: _phone,
                            isAction: true,
                            onTap: () => _showEditDialog('phone', _phone)),
                        _InfoItem(
                            icon: Icons.location_on_outlined,
                            label: "Location",
                            value: _location,
                            isAction: true,
                            onTap: () =>
                                _showEditDialog('location', _location)),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _buildSectionTitle("Business Details"),
                    const SizedBox(height: 12),
                    _buildInfoCard(
                      items: [
                        _InfoItem(
                            icon: Icons.store_outlined,
                            label: "Farm Name",
                            value: _farmName,
                            isAction: true,
                            onTap: () =>
                                _showEditDialog('farm_name', _farmName)),
                        _InfoItem(
                            icon: Icons.category_outlined,
                            label: "Main Category",
                            value: "Organic Vegetables"),
                        _InfoItem(
                            icon: Icons.verified_user_outlined,
                            label: "Verification Status",
                            value: "Verified",
                            isVerified: true),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _buildSectionTitle("Account Settings"),
                    const SizedBox(height: 12),
                    _buildInfoCard(
                      items: [
                        _InfoItem(
                            icon: Icons.notifications_none_outlined,
                            label: "Notifications",
                            value:
                                _notificationsEnabled ? "Enabled" : "Disabled",
                            isAction: true,
                            onTap: () {
                              setState(() => _notificationsEnabled =
                                  !_notificationsEnabled);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                    content: Text(
                                        "Notifications ${_notificationsEnabled ? 'enabled' : 'disabled'}")),
                              );
                            }),
                        _InfoItem(
                            icon: Icons.language_outlined,
                            label: "Language",
                            value: "English",
                            isAction: true,
                            onTap: _showLanguageDialog),
                        _InfoItem(
                            icon: Icons.lock_outline,
                            label: "Change Password",
                            value: "••••••••",
                            isAction: true,
                            onTap: _showPasswordDialog),
                      ],
                    ),
                    const SizedBox(height: 32),
                    _buildLogoutButton(),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNav(context),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(top: 60, bottom: 30),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF66BB6A), Color(0xFF2E7D32)],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(40),
          bottomRight: Radius.circular(40),
        ),
      ),
      child: Column(
        children: [
          Stack(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: CircleAvatar(
                  radius: 60,
                  backgroundColor: Colors.grey[200],
                  backgroundImage:
                      _avatarUrl != null ? NetworkImage(_avatarUrl!) : null,
                  child: _avatarUrl == null
                      ? Text(
                          _name.isNotEmpty ? _name[0] : "F",
                          style: const TextStyle(
                              fontSize: 40,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2E7D32)),
                        )
                      : null,
                ),
              ),
              Positioned(
                bottom: 5,
                right: 5,
                child: GestureDetector(
                  onTap: _pickAndUploadImage,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(color: Colors.black12, blurRadius: 4)
                      ],
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.edit,
                            color: Color(0xFF2E7D32), size: 20),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            _name,
            style: const TextStyle(
                fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              "PRO FARMER",
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
          fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1B5E20)),
    );
  }

  Widget _buildInfoCard({required List<_InfoItem> items}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: items.length,
        separatorBuilder: (context, index) => Divider(
            height: 1, color: Colors.grey[100], indent: 55, endIndent: 20),
        itemBuilder: (context, index) => items[index],
      ),
    );
  }

  Widget _buildLogoutButton() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red.withOpacity(0.3)),
      ),
      child: ElevatedButton(
        onPressed: () async {
          await Supabase.instance.client.auth.signOut();
          if (mounted) {
            Navigator.of(context)
                .pushNamedAndRemoveUntil('/login', (route) => false);
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.red,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.logout),
            SizedBox(width: 8),
            Text("Sign Out",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
      ),
    );
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
              offset: const Offset(0, -4)),
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
                active: false,
                onTap: () => Navigator.pop(context),
              ),
              _NavItem(
                icon: Icons.inventory_2_rounded,
                label: "Products",
                active: false,
                onTap: () {
                  Navigator.pushReplacement(
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
                active: false,
                onTap: () {
                  Navigator.pushReplacement(
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
                active: true,
                onTap: () {},
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isVerified;
  final bool isAction;
  final VoidCallback? onTap;

  const _InfoItem({
    required this.icon,
    required this.label,
    required this.value,
    this.isVerified = false,
    this.isAction = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
            color: const Color(0xFF4CAF50).withOpacity(0.1),
            borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: const Color(0xFF4CAF50), size: 20),
      ),
      title:
          Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      subtitle: Row(
        children: [
          Text(value,
              style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1B5E20))),
          if (isVerified) ...[
            const SizedBox(width: 4),
            const Icon(Icons.verified, color: Colors.blue, size: 16),
          ],
        ],
      ),
      trailing:
          isAction ? Icon(Icons.chevron_right, color: Colors.grey[400]) : null,
      onTap: onTap,
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _NavItem(
      {required this.icon,
      required this.label,
      required this.active,
      required this.onTap});

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
            Text(label,
                style: TextStyle(
                    fontSize: 12,
                    color: color,
                    fontWeight: active ? FontWeight.w600 : FontWeight.normal)),
          ],
        ),
      ),
    );
  }
}
