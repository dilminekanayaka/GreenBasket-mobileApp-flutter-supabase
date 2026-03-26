import 'package:flutter/material.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FBF9),
      appBar: AppBar(
        title: const Text("Help & Support", style: TextStyle(color: Color(0xFF1B5E20), fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent, elevation: 0,
        leading: IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF1B5E20))),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            _buildContactCard(),
            const SizedBox(height: 32),
            _buildFaqSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildContactCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: const Color(0xFF1B5E20), borderRadius: BorderRadius.circular(32)),
      child: Column(
        children: [
          const Icon(Icons.support_agent_rounded, size: 60, color: Colors.white),
          const SizedBox(height: 16),
          const Text("How can we help you?", style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text("Our team is available 24/7", style: TextStyle(color: Color(0xFFE8F5E9))),
          const SizedBox(height: 32),
          Row(
            children: [
              _buildContactBtn(Icons.chat_bubble_rounded, "Chat Live"),
              const SizedBox(width: 16),
              _buildContactBtn(Icons.email_rounded, "Email User"),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildContactBtn(IconData icon, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), borderRadius: BorderRadius.circular(16)),
        child: Column(
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(height: 8),
            Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildFaqSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Frequently Asked Questions", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1B5E20))),
        const SizedBox(height: 16),
        _buildFaqItem("How do I track my order?", "You can track your order in real-time from the 'My Orders' section."),
        _buildFaqItem("Are the products direct from farmers?", "Yes, all products are directly sourced from certified local farmers."),
        _buildFaqItem("What is the delivery time?", "Usually within 2-4 hours for fresh produce in city limits."),
      ],
    );
  }

  Widget _buildFaqItem(String q, String a) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: ExpansionTile(
        title: Text(q, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1B5E20))),
        children: [Padding(padding: const EdgeInsets.all(16), child: Text(a, style: const TextStyle(color: Colors.grey)))],
      ),
    );
  }
}
