import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen>
    with TickerProviderStateMixin {
  final _emailController = TextEditingController();
  bool _loading = false;
  String? _message;
  bool _isSuccess = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _resetPassword() async {
    if (_emailController.text.trim().isEmpty) {
      setState(() {
        _message = "Please enter your email address.";
        _isSuccess = false;
      });
      return;
    }

    setState(() {
      _loading = true;
      _message = null;
    });

    try {
      await Supabase.instance.client.auth.resetPasswordForEmail(
        _emailController.text.trim(),
        redirectTo: 'io.supabase.greenbasket://reset-password',
      );

      setState(() {
        _message =
            "Password reset link has been sent to your email. Please check your inbox.";
        _isSuccess = true;
      });
    } catch (e) {
      setState(() {
        _message = "Failed to send reset email. Please try again.";
        _isSuccess = false;
      });
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // ✨ PREMIUM GRADIENT BACKGROUND
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFE8F5E9), // Very light green
                  Color(0xFFC8E6C9), // Light green
                  Color(0xFFA5D6A7), // Soft green
                ],
              ),
            ),
          ),
          // Decorative Blobs
          Positioned(
            top: -100,
            right: -100,
            child: _buildBlob(300, const Color(0xFF4CAF50).withOpacity(0.1)),
          ),
          Positioned(
            bottom: -50,
            left: -50,
            child: _buildBlob(250, const Color(0xFF81C784).withOpacity(0.2)),
          ),

          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Column(
                children: [
                  // Back Button
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Align(
                      alignment: Alignment.topLeft,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.8),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            )
                          ],
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.arrow_back_rounded,
                              color: Color(0xFF2E7D32)),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ),
                    ),
                  ),

                  Expanded(
                    child: Center(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          children: [
                            // 🔐 LOCK ICON
                            Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                color: const Color(0xFF4CAF50).withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.lock_reset_rounded,
                                size: 50,
                                color: Color(0xFF2E7D32),
                              ),
                            ),
                            const SizedBox(height: 24),
                            const Text(
                              "Forgot Password?",
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF2E7D32),
                                letterSpacing: 1.2,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              "Don't worry! Enter your email and we'll send you a link to reset your password.",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[700],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 48),

                            // 💎 GLASSMORPHISM CONTAINER
                            ClipRRect(
                              borderRadius: BorderRadius.circular(32),
                              child: BackdropFilter(
                                filter:
                                    ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                                child: Container(
                                  padding: const EdgeInsets.all(32),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.8),
                                    borderRadius: BorderRadius.circular(32),
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.5),
                                      width: 2,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.05),
                                        blurRadius: 24,
                                        offset: const Offset(0, 12),
                                      )
                                    ],
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      TextField(
                                        controller: _emailController,
                                        keyboardType:
                                            TextInputType.emailAddress,
                                        decoration: _input("Email Address",
                                            Icons.alternate_email_rounded),
                                      ),
                                      if (_message != null) ...[
                                        const SizedBox(height: 16),
                                        Container(
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: _isSuccess
                                                ? const Color(0xFF4CAF50)
                                                    .withOpacity(0.1)
                                                : Colors.red.withOpacity(0.1),
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            border: Border.all(
                                              color: _isSuccess
                                                  ? const Color(0xFF4CAF50)
                                                  : Colors.red,
                                              width: 1,
                                            ),
                                          ),
                                          child: Row(
                                            children: [
                                              Icon(
                                                _isSuccess
                                                    ? Icons.check_circle_outline
                                                    : Icons.error_outline,
                                                color: _isSuccess
                                                    ? const Color(0xFF2E7D32)
                                                    : Colors.red,
                                                size: 20,
                                              ),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: Text(
                                                  _message!,
                                                  style: TextStyle(
                                                    color: _isSuccess
                                                        ? const Color(
                                                            0xFF2E7D32)
                                                        : Colors.red,
                                                    fontWeight: FontWeight.w500,
                                                    fontSize: 14,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                      const SizedBox(height: 24),
                                      SizedBox(
                                        width: double.infinity,
                                        height: 56,
                                        child: Container(
                                          decoration: BoxDecoration(
                                            borderRadius:
                                                BorderRadius.circular(16),
                                            gradient: const LinearGradient(
                                              colors: [
                                                Color(0xFF4CAF50),
                                                Color(0xFF2E7D32)
                                              ],
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: const Color(0xFF4CAF50)
                                                    .withOpacity(0.3),
                                                blurRadius: 12,
                                                offset: const Offset(0, 6),
                                              )
                                            ],
                                          ),
                                          child: ElevatedButton(
                                            onPressed: _loading
                                                ? null
                                                : _resetPassword,
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor:
                                                  Colors.transparent,
                                              shadowColor: Colors.transparent,
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(16),
                                              ),
                                            ),
                                            child: _loading
                                                ? const CircularProgressIndicator(
                                                    color: Colors.white)
                                                : const Text(
                                                    "Send Reset Link",
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 18,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 32),
                            TextButton.icon(
                              onPressed: () => Navigator.pop(context),
                              icon: const Icon(Icons.arrow_back_rounded,
                                  color: Color(0xFF2E7D32)),
                              label: const Text(
                                "Back to Login",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF2E7D32),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBlob(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }

  InputDecoration _input(String label, IconData icon) {
    return InputDecoration(
      prefixIcon: Icon(icon, color: const Color(0xFF4CAF50), size: 22),
      labelText: label,
      labelStyle: TextStyle(color: Colors.grey[600], fontSize: 14),
      filled: true,
      fillColor: Colors.white.withOpacity(0.5),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.grey.withOpacity(0.2)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFF4CAF50), width: 1.5),
      ),
    );
  }
}
