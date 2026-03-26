import 'dart:io';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';

class AccountSettingsScreen extends StatefulWidget {
  const AccountSettingsScreen({super.key});

  @override
  State<AccountSettingsScreen> createState() => _AccountSettingsScreenState();
}

class _AccountSettingsScreenState extends State<AccountSettingsScreen> {
  final _supabase = Supabase.instance.client;
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _loading = false;
  File? _imageFile;
  String? _currentAvatarUrl;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;
    
    try {
      final data = await _supabase.from('profiles').select().eq('id', user.id).single();
      _nameController.text = data['full_name'] ?? "";
      _emailController.text = user.email ?? "";
      _currentAvatarUrl = data['avatar_url'];
      setState(() {});
    } catch (e) {
      debugPrint("Error loading profile: $e");
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 50);
    if (picked != null) {
      setState(() => _imageFile = File(picked.path));
    }
  }

  void _removeImage() {
    setState(() {
      _imageFile = null;
      _currentAvatarUrl = null;
    });
  }

  Future<String?> _uploadAvatar(String userId) async {
    if (_imageFile == null) return _currentAvatarUrl;

    try {
      final fileExtension = _imageFile!.path.split('.').last;
      final fileName = '$userId.${DateTime.now().millisecondsSinceEpoch}.$fileExtension';
      final filePath = fileName;

      await _supabase.storage.from('avatars').upload(filePath, _imageFile!);
      
      final publicUrl = _supabase.storage.from('avatars').getPublicUrl(filePath);
      return publicUrl;
    } catch (e) {
      debugPrint("Upload error: $e");
      return _currentAvatarUrl;
    }
  }

  Future<void> _updateProfile() async {
    setState(() => _loading = true);
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    try {
      final newAvatarUrl = await _uploadAvatar(user.id);

      // 📝 1. UPDATE PROFILE DATA
      await _supabase.from('profiles').update({
        'full_name': _nameController.text.trim(),
        'avatar_url': newAvatarUrl,
      }).eq('id', user.id);

      // 📧 2. UPDATE EMAIL
      if (_emailController.text.trim() != user.email) {
         await _supabase.auth.updateUser(UserAttributes(email: _emailController.text.trim()));
      }

      // 🔑 3. UPDATE PASSWORD
      if (_passwordController.text.isNotEmpty) {
         await _supabase.auth.updateUser(UserAttributes(password: _passwordController.text.trim()));
      }

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Profile updated! Restart app to see changes everywhere."), backgroundColor: Color(0xFF2E7D32)));
      Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red));
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FBF9),
      appBar: AppBar(
        title: const Text("Edit Profile", style: TextStyle(color: Color(0xFF1B5E20), fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent, elevation: 0,
        leading: IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF1B5E20))),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            _buildProfilePicPicker(),
            const SizedBox(height: 32),
            _buildInputFields(),
            const SizedBox(height: 32),
            _buildPasswordSection(),
            const SizedBox(height: 40),
            SizedBox(width: double.infinity, height: 60, child: ElevatedButton(onPressed: _loading ? null : _updateProfile, style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2E7D32), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))), child: _loading ? const CircularProgressIndicator(color: Colors.white) : const Text("Update Profile", style: TextStyle(color: Colors.white, fontSize: 18)))),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildProfilePicPicker() {
    ImageProvider? image;
    if (_imageFile != null) {
      image = FileImage(_imageFile!);
    } else if (_currentAvatarUrl != null) {
      image = NetworkImage(_currentAvatarUrl!);
    }

    return Column(
      children: [
        Stack(
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(color: Color(0xFF4CAF50), shape: BoxShape.circle),
              child: CircleAvatar(
                radius: 60,
                backgroundColor: const Color(0xFFC8E6C9),
                backgroundImage: image,
                child: image == null ? const Icon(Icons.person, size: 60, color: Color(0xFF1B5E20)) : null,
              ),
            ),
            Positioned(
              bottom: 0, right: 0,
              child: GestureDetector(
                onTap: _pickImage,
                child: Container(padding: const EdgeInsets.all(8), decoration: const BoxDecoration(color: Color(0xFF1B5E20), shape: BoxShape.circle), child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 20)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextButton.icon(onPressed: _pickImage, icon: const Icon(Icons.photo_library_outlined, size: 18, color: Color(0xFF2E7D32)), label: const Text("Change Photo", style: TextStyle(color: Color(0xFF2E7D32)))),
            if (_imageFile != null || _currentAvatarUrl != null) TextButton.icon(onPressed: _removeImage, icon: const Icon(Icons.delete_outline_rounded, color: Colors.red, size: 18), label: const Text("Remove", style: TextStyle(color: Colors.red))),
          ],
        ),
      ],
    );
  }

  Widget _buildInputFields() {
    return Column(
      children: [
        _buildTextField(_nameController, "Full Name", Icons.person_outline_rounded),
        const SizedBox(height: 16),
        _buildTextField(_emailController, "Email Address", Icons.alternate_email_rounded, type: TextInputType.emailAddress),
      ],
    );
  }

  Widget _buildPasswordSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Change Password", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(height: 12),
        _buildTextField(_passwordController, "New Password (Optional)", Icons.lock_outline_rounded, isPass: true),
      ],
    );
  }

  Widget _buildTextField(TextEditingController ctrl, String hint, IconData icon, {TextInputType type = TextInputType.text, bool isPass = false}) {
    return TextField(
      controller: ctrl,
      keyboardType: type,
      obscureText: isPass,
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: const Color(0xFF4CAF50)),
        hintText: hint,
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(vertical: 20),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
      ),
    );
  }
}
