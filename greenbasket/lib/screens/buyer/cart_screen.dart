import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/cart_service.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final _cart = CartService();
  final _supabase = Supabase.instance.client;
  bool _processing = false;
  final _addressController = TextEditingController(text: "No. 123, Galle Road, Colombo 03");

  @override
  void initState() {
    super.initState();
    _cart.addListener(_onCartUpdate);
  }

  @override
  void dispose() {
    _cart.removeListener(_onCartUpdate);
    _addressController.dispose();
    super.dispose();
  }

  void _onCartUpdate() {
    if (mounted) setState(() {});
  }

  Future<void> _placeOrders() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    setState(() => _processing = true);

    try {
      // We need farmer_id for each order. Let's fetch products to get farmer_ids.
      final ids = _cart.items.map((i) => i.id).toList();
      final productsRes = await _supabase
          .from('products')
          .select('id, farmer_id')
          .inFilter('id', ids);
      
      final farmerMap = {for (var p in productsRes) p['id']: p['farmer_id']};

      final List<Map<String, dynamic>> finalOrders = [];
      for (var item in _cart.items) {
        final fId = farmerMap[item.id];
        if (fId == null) {
          debugPrint("⚠️ Warning: Could not find farmer_id for product ${item.name} (${item.id})");
          // Fallback or skip? For now, we skip or use a default if available, 
          // but better to ensure data integrity.
          continue; 
        }
        finalOrders.add({
          'product_id': item.id,
          'buyer_id': user.id,
          'farmer_id': fId,
          'quantity': item.quantity,
          'total_price': (item.price * item.quantity),
          'status': 'pending',
          'delivery_address': _addressController.text,
          'created_at': DateTime.now().toIso8601String(),
        });
      }

      if (finalOrders.isEmpty) {
        throw Exception("Could not process orders: No valid farmer IDs found.");
      }

      await _supabase.from('orders').insert(finalOrders);

      _cart.clear();
      if (!mounted) return;
      
      showDialog(
        context: context,
        builder: (context) => _buildSuccessDialog(),
      );
    } catch (e) {
      debugPrint("Error placing orders: $e");
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _processing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FBF9),
      body: _cart.items.isEmpty
          ? _buildEmptyCart()
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(20),
                    itemCount: _cart.items.length,
                    itemBuilder: (context, index) {
                      final item = _cart.items[index];
                      return _buildCartItem(item);
                    },
                  ),
                ),
                _buildOrderSummaryFooter(),
              ],
            ),
    );
  }

  Widget _buildEmptyCart() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: const BoxDecoration(color: Color(0xFFE8F5E9), shape: BoxShape.circle),
            child: Icon(Icons.shopping_basket_outlined, size: 80, color: const Color(0xFF4CAF50).withOpacity(0.5)),
          ),
          const SizedBox(height: 24),
          const Text("Your basket is empty", style: TextStyle(fontSize: 20, color: Color(0xFF1B5E20), fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text("Fresh goodies are waiting for you!", style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildCartItem(CartItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))]),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: item.imageUrl != null
                ? Image.network(item.imageUrl!, width: 70, height: 70, fit: BoxFit.cover)
                : Container(width: 70, height: 70, color: const Color(0xFFE8F5E9), child: const Icon(Icons.eco_rounded, color: Color(0xFF4CAF50))),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1B5E20))),
                const SizedBox(height: 4),
                Text("Rs. ${item.price}/${item.unit}", style: TextStyle(color: Colors.grey[600], fontSize: 13)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                children: [
                  _buildQtyBtn(Icons.remove, () => _cart.updateQuantity(item.id, -1)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(item.quantity.toString(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                  _buildQtyBtn(Icons.add, () => _cart.updateQuantity(item.id, 1)),
                ],
              ),
              const SizedBox(height: 8),
              Text("Rs. ${item.price * item.quantity}", style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF2E7D32), fontSize: 16)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQtyBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(color: const Color(0xFFF1F8E9), borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFF4CAF50).withOpacity(0.2))),
        child: Icon(icon, size: 18, color: const Color(0xFF2E7D32)),
      ),
    );
  }

  Widget _buildOrderSummaryFooter() {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(40), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 20, offset: const Offset(0, -5))]),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text("Total Items", style: TextStyle(fontSize: 16, color: Colors.grey)), Text("${_cart.items.length}", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold))]),
            const SizedBox(height: 12),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text("Grand Total", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1B5E20))), Text("Rs. ${_cart.totalPrice}", style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Color(0xFF2E7D32)))]),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity, height: 60,
              child: ElevatedButton(
                onPressed: _processing ? null : () {
                   showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: Colors.transparent, builder: (context) => _buildAddressSheet());
                },
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2E7D32), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)), elevation: 5),
                child: _processing ? const CircularProgressIndicator(color: Colors.white) : const Text("Place Order Now", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddressSheet() {
    return Container(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, top: 32, left: 24, right: 24),
      decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(40))),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Confirm Delivery Address", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1B5E20))),
            const SizedBox(height: 16),
            TextField(controller: _addressController, maxLines: 3, decoration: InputDecoration(fillColor: const Color(0xFFF1F8E9), filled: true, border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none))),
            const SizedBox(height: 24),
            SizedBox(width: double.infinity, height: 60, child: ElevatedButton(onPressed: () { Navigator.pop(context); _placeOrders(); }, style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2E7D32), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))), child: const Text("Confirm & Place Orders", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)))),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSuccessDialog() {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle_rounded, size: 80, color: Color(0xFF4CAF50)),
            const SizedBox(height: 24),
            const Text("Orders Placed!", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1B5E20))),
            const SizedBox(height: 12),
            const Text("Your fresh produce will be delivered soon!", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 32),
            SizedBox(width: double.infinity, height: 50, child: ElevatedButton(onPressed: () => Navigator.pop(context), style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2E7D32), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), child: const Text("Awesome!", style: TextStyle(color: Colors.white)))),
          ],
        ),
      ),
    );
  }
}
