import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AboutGreenBasketPage extends StatelessWidget {
  const AboutGreenBasketPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F9F5),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: const Color(0xFF4CAF50),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF66BB6A), Color(0xFF4CAF50)],
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 40),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Image.asset(
                          'assets/images/logo.png',
                          width: 80,
                          height: 80,
                          errorBuilder: (context, error, stackTrace) => const Icon(
                            Icons.eco,
                            size: 80,
                            color: Color(0xFF4CAF50),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                   Text(
                    'GreenBasket',
                    style: GoogleFonts.poppins(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1B5E20),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Version 1.0.0',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 32),
                  _buildSection(
                    title: 'Our Mission',
                    content: 'Connecting fresh local produce directly from farmers to your doorstep. We believe in sustainable farming and fair pricing for everyone in the chain.',
                  ),
                  const SizedBox(height: 24),
                  _buildSection(
                    title: 'Why GreenBasket?',
                    content: '• Fresh organic produce\n• Direct farmer support\n• Environmentally friendly\n• Fair trade for all',
                  ),
                  const SizedBox(height: 32),
                  const Divider(),
                  const SizedBox(height: 32),
                  const Text(
                    'Follow Us',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1B5E20),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildSocialIcon(Icons.language, 'Website'),
                      const SizedBox(width: 20),
                      _buildSocialIcon(Icons.facebook, 'Facebook'),
                      const SizedBox(width: 20),
                      _buildSocialIcon(Icons.camera_alt_outlined, 'Instagram'),
                    ],
                  ),
                  const SizedBox(height: 60),
                  Text(
                    '© 2026 GreenBasket Team',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[500],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({required String title, required String content}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1B5E20),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          content,
          textAlign: TextAlign.justify,
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey[700],
            height: 1.6,
          ),
        ),
      ],
    );
  }

  Widget _buildSocialIcon(IconData icon, String label) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF4CAF50).withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: const Color(0xFF4CAF50), size: 28),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}
