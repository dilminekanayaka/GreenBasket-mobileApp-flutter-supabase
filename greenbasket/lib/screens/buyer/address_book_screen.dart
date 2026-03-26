import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AddressBookScreen extends StatefulWidget {
  const AddressBookScreen({super.key});

  @override
  State<AddressBookScreen> createState() => _AddressBookScreenState();
}

class _AddressBookScreenState extends State<AddressBookScreen> {
  final _supabase = Supabase.instance.client;
  final _addressCtrl = TextEditingController(text: "No. 123, Galle Road, Colombo 03");
  bool _loading = false;

  Future<void> _updateAddress() async {
    setState(() => _loading = true);
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    try {
      // Assuming we have an address column in profiles. If not, it will fail silently or log error.
      await _supabase.from('profiles').update({'address': _addressCtrl.text.trim()}).eq('id', user.id);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Address updated successfully!"), backgroundColor: Color(0xFF2E7D32)));
    } catch (e) {
      debugPrint("Error updating address: $e");
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FBF9),
      appBar: AppBar(
        title: const Text("Delivery Addresses", style: TextStyle(color: Color(0xFF1B5E20), fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent, elevation: 0,
        leading: IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF1B5E20))),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))]),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Home Address", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1B5E20))),
                  const SizedBox(height: 12),
                  TextField(controller: _addressCtrl, maxLines: 3, decoration: InputDecoration(filled: true, fillColor: const Color(0xFFF1F8E9), border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none))),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _loading ? null : _updateAddress,
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2E7D32), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                      child: const Text("Set as Default", style: TextStyle(color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
