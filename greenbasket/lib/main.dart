import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/shared/splash_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/home/role_router.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 🔴 TEMPORARY: Hardcode Supabase keys (to FIX signup/login)
  await Supabase.initialize(
    url: 'https://qezfovhoxcjxfyozvdkc.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InFlemZvdmhveGNqeGZ5b3p2ZGtjIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Njg1NjU1NTcsImV4cCI6MjA4NDE0MTU1N30.45t60pTo3k8LRiN5W8B4zTr961mVAH4JIWEZgu3i0JA',
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GreenBasket',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        primarySwatch: Colors.green,
        scaffoldBackgroundColor: const Color(0xFFEFF5E8),
        fontFamily: GoogleFonts.poppins().fontFamily,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF4CAF50),
          brightness: Brightness.light,
        ),
      ),
      home: const SplashScreen(),
      routes: {
        '/login': (context) => const LoginScreen(),
        '/role-router': (context) => const RoleRouter(),
      },
    );
  }
}
