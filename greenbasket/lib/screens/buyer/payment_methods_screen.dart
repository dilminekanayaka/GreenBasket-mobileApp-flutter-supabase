import 'package:flutter/material.dart';

class PaymentMethodsScreen extends StatelessWidget {
  const PaymentMethodsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FBF9),
      appBar: AppBar(
        title: const Text("Payment Methods", style: TextStyle(color: Color(0xFF1B5E20), fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent, elevation: 0,
        leading: IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF1B5E20))),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Available Methods", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1B5E20))),
            const SizedBox(height: 16),
            _buildMethodItem("Cash on Delivery", Icons.money_rounded, const Color(0xFF2E7D32), true),
            const SizedBox(height: 24),
            const Text("Other payment methods are currently unavailable in your region.", style: TextStyle(color: Colors.grey, fontSize: 13)),
          ],
        ),
      ),
    );
  }

  Widget _buildMethodItem(String label, IconData icon, Color color, bool isSelected) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), border: Border.all(color: isSelected ? color : Colors.transparent), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))]),
      child: Row(
        children: [
          Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle), child: Icon(icon, color: color)),
          const SizedBox(width: 20),
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: Color(0xFF1B5E20))),
          const Spacer(),
          if (isSelected) Icon(Icons.check_circle_rounded, color: color),
        ],
      ),
    );
  }
}
