import 'package:flutter/material.dart';

class FarmerHelpSupportPage extends StatelessWidget {
  const FarmerHelpSupportPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FBF9),
      body: Column(
        children: [
          _buildHeader(context),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  _buildContactCard(),
                  const SizedBox(height: 32),
                  _buildFaqSection(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 20,
        left: 20,
        right: 20,
        bottom: 20,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF66BB6A), Color(0xFF4CAF50)],
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.arrow_back_rounded, color: Colors.white),
            ),
          ),
          const SizedBox(width: 16),
          const Text(
            "Help & Support",
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1B5E20),
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1B5E20).withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          const Icon(Icons.support_agent_rounded, size: 60, color: Colors.white),
          const SizedBox(height: 16),
          const Text(
            "Farmer Support Center",
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            "Our dedicated team is here to help you grow",
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFFE8F5E9)),
          ),
          const SizedBox(height: 32),
          Row(
            children: [
              _buildContactBtn(Icons.chat_bubble_rounded, "Live Chat"),
              const SizedBox(width: 16),
              _buildContactBtn(Icons.email_rounded, "Email Support"),
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
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFaqSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Selling on GreenBasket FAQs",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1B5E20),
          ),
        ),
        const SizedBox(height: 16),
        _buildFaqItem(
          "How do I add new products?",
          "Go to 'My Products' and click the '+' button to list your fresh produce.",
        ),
        _buildFaqItem(
          "When do I receive payments?",
          "Payments are processed 24 hours after a customer confirms delivery.",
        ),
        _buildFaqItem(
          "How do I update order status?",
          "Go to 'Manage Orders', select an order, and choose the appropriate status (Processing, Delivering, etc.)",
        ),
        _buildFaqItem(
          "What if a product is out of stock?",
          "You can mark products as inactive or delete them from the 'My Products' page.",
        ),
      ],
    );
  }

  Widget _buildFaqItem(String q, String a) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ExpansionTile(
        title: Text(
          q,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF1B5E20),
            fontSize: 14,
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
            child: Text(
              a,
              style: TextStyle(color: Colors.grey[600], fontSize: 13),
            ),
          )
        ],
      ),
    );
  }
}
