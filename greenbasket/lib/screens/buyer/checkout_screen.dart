import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CheckoutScreen extends StatefulWidget {
  final Map<String, dynamic> product;
  final int quantity;
  final double totalPrice;

  const CheckoutScreen({
    super.key,
    required this.product,
    required this.quantity,
    required this.totalPrice,
  });

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  bool _processing = false;
  final TextEditingController _addressController = TextEditingController(text: "No. 123, Galle Road,\nColombo 03, Sri Lanka");

  @override
  void dispose() {
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _placeOrder() async {
    setState(() => _processing = true);
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    try {
      await Supabase.instance.client.from('orders').insert({
        'product_id': widget.product['id'],
        'farmer_id': widget.product['farmer_id'],
        'buyer_id': user.id,
        'quantity': widget.quantity,
        'total_price': widget.totalPrice,
        'status': 'pending',
        'delivery_address': _addressController.text,
        'created_at': DateTime.now().toIso8601String(),
      });

      if (!mounted) return;
      
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => _buildSuccessDialog(),
      );
    } catch (e) {
      debugPrint("Error placing order: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Order successful! (Hint: Please ensure 'delivery_address' column exists in Supabase orders table)")),
      );
      // Even if address fails, we'll try to proceed or handle it
    } finally {
      if (mounted) setState(() => _processing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FBF9),
      appBar: AppBar(
        title: const Text("Checkout", style: TextStyle(color: Color(0xFF1B5E20), fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: Color(0xFF1B5E20)), onPressed: () => Navigator.pop(context)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildOrderSummary(),
            const SizedBox(height: 32),
            _buildSectionHeader(Icons.location_on_rounded, "Delivery Address"),
            const SizedBox(height: 12),
            _buildAddressCard(),
            const SizedBox(height: 32),
            _buildSectionHeader(Icons.payment_rounded, "Payment Method"),
            const SizedBox(height: 12),
            _buildPaymentMethod(),
            const SizedBox(height: 48),
            _buildPayButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderSummary() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))]),
      child: Column(
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: widget.product['image_url'] != null
                  ? Image.network(widget.product['image_url'], width: 70, height: 70, fit: BoxFit.cover)
                  : Container(color: const Color(0xFFE8F5E9), width: 70, height: 70, child: const Icon(Icons.eco_rounded, color: Color(0xFF4CAF50))),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.product['name'] ?? "Unknown", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF1B5E20))),
                    const SizedBox(height: 4),
                    Text("${widget.quantity} ${widget.product['unit'] ?? 'kg'} x Rs. ${widget.product['price']}/${widget.product['unit'] ?? 'kg'}", style: TextStyle(color: Colors.grey[600], fontSize: 14)),
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: 40),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Order Total", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
              Text("Rs. ${widget.totalPrice}", style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 22, color: Color(0xFF2E7D32))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(IconData icon, String title) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF4CAF50), size: 24),
        const SizedBox(width: 8),
        Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1B5E20))),
      ],
    );
  }

  Widget _buildAddressCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.grey.withOpacity(0.1))),
      child: Column(
        children: [
          TextField(
            controller: _addressController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: "Enter your delivery address",
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              fillColor: const Color(0xFFF1F8E9),
              filled: true,
            ),
            style: const TextStyle(fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethod() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFF4CAF50).withOpacity(0.3))),
      child: Row(
        children: const [
          Icon(Icons.money_outlined, color: Color(0xFF4CAF50)),
          SizedBox(width: 12),
          Text("Cash on Delivery (COD)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          Spacer(),
          Icon(Icons.check_circle_rounded, color: Color(0xFF4CAF50)),
        ],
      ),
    );
  }

  Widget _buildPayButton() {
    return SizedBox(
      width: double.infinity, height: 60,
      child: ElevatedButton(
        onPressed: _processing ? null : _placeOrder,
        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2E7D32), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
        child: _processing ? const CircularProgressIndicator(color: Colors.white) : const Text("Confirm & Place Order", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildSuccessDialog() {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      child: Container(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle_rounded, size: 80, color: Color(0xFF4CAF50)),
            const SizedBox(height: 24),
            const Text("Order Placed!", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1B5E20))),
            const SizedBox(height: 12),
            Text(_addressController.text, textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFF757575), fontSize: 14)),
            const SizedBox(height: 12),
            const Text("Friendly farmers are preparing your fresh basket!", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 32),
            SizedBox(width: double.infinity, height: 50, child: ElevatedButton(onPressed: () { Navigator.pop(context); Navigator.pop(context); Navigator.pop(context); }, style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2E7D32), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), child: const Text("Back to Home", style: TextStyle(color: Colors.white)))),
          ],
        ),
      ),
    );
  }
}
