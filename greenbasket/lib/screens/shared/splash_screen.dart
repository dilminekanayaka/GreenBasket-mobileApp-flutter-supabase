import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import '../auth/login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _mainController;
  late AnimationController _particleController;

  late Animation<double> _logoScale;
  late Animation<double> _logoOpacity;
  late Animation<double> _textBlur;
  late Animation<double> _textOpacity;

  final List<Particle> _particles = List.generate(15, (index) => Particle());

  @override
  void initState() {
    super.initState();

    _mainController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    );

    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();

    _logoScale = TweenSequence<double>([
      TweenSequenceItem(
          tween: Tween(begin: 0.0, end: 1.1)
              .chain(CurveTween(curve: Curves.easeOutBack)),
          weight: 60),
      TweenSequenceItem(
          tween: Tween(begin: 1.1, end: 1.0)
              .chain(CurveTween(curve: Curves.easeInOut)),
          weight: 40),
    ]).animate(_mainController);

    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
          parent: _mainController,
          curve: const Interval(0.0, 0.4, curve: Curves.easeIn)),
    );

    _textOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
          parent: _mainController,
          curve: const Interval(0.5, 0.8, curve: Curves.easeIn)),
    );

    _textBlur = Tween<double>(begin: 10.0, end: 0.0).animate(
      CurvedAnimation(
          parent: _mainController,
          curve: const Interval(0.5, 0.9, curve: Curves.easeOut)),
    );

    _mainController.forward();

    // Creative navigation transition
    Future.delayed(const Duration(milliseconds: 3500), () {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                const LoginScreen(),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
              return FadeTransition(
                opacity: animation,
                child: ScaleTransition(
                  scale: Tween<double>(begin: 1.1, end: 1.0).animate(animation),
                  child: child,
                ),
              );
            },
            transitionDuration: const Duration(milliseconds: 1000),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _mainController.dispose();
    _particleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8F5E9),
      body: Stack(
        children: [
          // ✨ ANIMATED GRADIENT BACKGROUND
          _buildAnimatedBackground(),

          // 🍃 FLOATING PARTICLES (LEAVES)
          ..._particles.map((p) => _buildParticle(p)),

          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 🟢 BREATHING LOGO ANIMATION
                AnimatedBuilder(
                  animation: _mainController,
                  builder: (context, child) {
                    return Opacity(
                      opacity: _logoOpacity.value,
                      child: Transform.scale(
                        scale: _logoScale.value,
                        child: child,
                      ),
                    );
                  },
                  child: Hero(
                    tag: 'logo',
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.green.withOpacity(0.2),
                            blurRadius: 40,
                            spreadRadius: 10,
                          ),
                        ],
                      ),
                      child: Image.asset(
                        "assets/images/logo.png",
                        width: 240,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 40),

                // 🏷️ GLITCH/REVEAL TEXT ANIMATION
                AnimatedBuilder(
                  animation: _mainController,
                  builder: (context, child) {
                    return Opacity(
                      opacity: _textOpacity.value,
                      child: ImageFiltered(
                        imageFilter: ImageFilter.blur(
                          sigmaX: _textBlur.value,
                          sigmaY: _textBlur.value,
                        ),
                        child: child,
                      ),
                    );
                  },
                  child: Column(
                    children: [
                      const Text(
                        "GreenBasket",
                        style: TextStyle(
                          fontSize: 44,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF1B5E20),
                          letterSpacing: 4.0,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        "NATURE'S BEST TO YOU",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: Colors.green[800],
                          letterSpacing: 6.0,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Creative Loader
          Positioned(
            bottom: 60,
            left: 0,
            right: 0,
            child: _buildCreativeLoader(),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedBackground() {
    return AnimatedBuilder(
      animation: _particleController,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment(
                0.5 * math.sin(_particleController.value * 2 * math.pi),
                0.5 * math.cos(_particleController.value * 2 * math.pi),
              ),
              radius: 1.5,
              colors: const [
                Color(0xFFF1F8E9),
                Color(0xFFC8E6C9),
                Color(0xFFA5D6A7),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildParticle(Particle p) {
    return AnimatedBuilder(
      animation: _particleController,
      builder: (context, child) {
        final progress = (_particleController.value + p.offset) % 1.0;
        return Positioned(
          left: p.x * MediaQuery.of(context).size.width +
              math.sin(progress * 2 * math.pi) * 20,
          top: (1 - progress) * MediaQuery.of(context).size.height,
          child: Opacity(
            opacity: math.sin(progress * math.pi) * 0.4,
            child: Transform.rotate(
              angle: progress * 4 * math.pi,
              child: Icon(
                Icons.spa, // Leaf-like icon
                color: Colors.green[400],
                size: p.size,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCreativeLoader() {
    return Center(
      child: FadeTransition(
        opacity: _textOpacity,
        child: SizedBox(
          width: 200,
          child: Column(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  minHeight: 2,
                  backgroundColor: Colors.green.withOpacity(0.1),
                  valueColor:
                      const AlwaysStoppedAnimation<Color>(Color(0xFF2E7D32)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class Particle {
  final double x = math.Random().nextDouble();
  final double offset = math.Random().nextDouble();
  final double size = 10.0 + math.Random().nextDouble() * 20.0;
}
