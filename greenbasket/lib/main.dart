import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/shared/splash_screen.dart';

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
        primarySwatch: Colors.green,
        scaffoldBackgroundColor: const Color(0xFFEFF5E8),
      ),
      home: const SplashScreen(),
    );
  }
}
