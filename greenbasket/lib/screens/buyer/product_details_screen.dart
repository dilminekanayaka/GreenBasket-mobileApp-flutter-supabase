import 'package:flutter/material.dart';
import 'checkout_screen.dart';

class ProductDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> product;
  const ProductDetailsScreen({super.key, required this.product});

  @override
  State<ProductDetailsScreen> createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen> {
  int _quantity = 1;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // 📸 PRODUCT IMAGE
          _buildProductImage(),
          
          // 🔙 BACK BUTTON
          _buildBackButton(),
          
          // 📝 DETAILS SHEET
          _buildDetailsSheet(),
          
          // 🛒 BOTTOM ACTION BAR
          _buildBottomAction(),
        ],
      ),
    );
  }

  Widget _buildProductImage() {
    return Container(
      height: MediaQuery.of(context).size.height * 0.45,
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5E9),
        image: widget.product['image_url'] != null
            ? DecorationImage(
                image: NetworkImage(widget.product['image_url']),
                fit: BoxFit.cover,
              )
            : null,
      ),
      child: widget.product['image_url'] == null
          ? const Center(child: Icon(Icons.eco_rounded, size: 80, color: Color(0xFF4CAF50)))
          : null,
    );
  }

  Widget _buildBackButton() {
    return Positioned(
      top: 50,
      left: 20,
      child: GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.arrow_back, color: Color(0xFF217D32)),
        ),
      ),
    );
  }

  Widget _buildDetailsSheet() {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        height: MediaQuery.of(context).size.height * 0.6,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(40)),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 20,
              offset: Offset(0, -10),
            )
          ],
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 🏆 TITLE & PRICE
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      widget.product['name'] ?? "Unknown",
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1B5E20),
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4CAF50).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      "Rs. ${widget.product['price']}/${widget.product['unit'] ?? 'kg'}",
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF2E7D32),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              
              // 👨‍🌾 FARMER INFO
              Row(
                children: [
                   const CircleAvatar(
                    radius: 12,
                    backgroundColor: Color(0xFF4CAF50),
                    child: Icon(Icons.person, size: 14, color: Colors.white),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    "by ${widget.product['farmer_name'] ?? 'Farmer'}",
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Spacer(),
                   const Icon(Icons.star_rounded, color: Colors.amber, size: 20),
                  const SizedBox(width: 4),
                  const Text("4.8 (80+ reviews)", style: TextStyle(fontSize: 12)),
                ],
              ),
              const SizedBox(height: 32),
              
              const Text(
                "Description",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Text(
                widget.product['description'] ?? "Fresh and organic produce straight from our farm. Quality guaranteed.",
                style: TextStyle(fontSize: 14, color: Colors.grey[600], height: 1.6),
              ),
              const SizedBox(height: 32),
              
              // 🧺 QUANTITY SELECTOR
              Row(
                children: [
                  const Text("Quantity", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const Spacer(),
                  _buildQtyBtn(Icons.remove, () { if (_quantity > 1) setState(() => _quantity--); }),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Text(_quantity.toString(), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  ),
                  _buildQtyBtn(Icons.add, () => setState(() => _quantity++)),
                ],
              ),
              const SizedBox(height: 100), // Bottom space for bar
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQtyBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: const Color(0xFF2E7D32)),
      ),
    );
  }

  Widget _buildBottomAction() {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Color(0xFFEEEEEE))),
        ),
        child: Row(
          children: [
            // CART ICON BUTTON
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.save_outlined, color: Color(0xFF4CAF50)),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CheckoutScreen(
                        product: widget.product,
                        quantity: _quantity,
                        totalPrice: (widget.product['price'] as num).toDouble() * _quantity,
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E7D32),
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text(
                  "Buy Now",
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
