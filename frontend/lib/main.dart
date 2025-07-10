import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'screens/01_welcome.dart';
import 'screens/02b_login.dart';
import 'screens/06_homescreen.dart';

import 'screens/02a_registration.dart';     // ← 
import 'screens/03_qr_view_scan.dart';      // ← 
import 'screens/04_otp_form_screen.dart';   // ← 
import 'screens/05_registration_form_screen.dart'; // ← 

import 'screens/settings_screen.dart';       // ← 

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await dotenv.load();
  } catch (_) {
    debugPrint('Keine .env Datei gefunden – nutze Standardwerte');
  }
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Medical App',
      theme: _buildTheme(),
      initialRoute: '/',
      routes: {
        '/': (_) => const SplashScreen(),
        '/welcome': (_) => const WelcomeScreen(),
        '/login': (_) => const LoginScreen(),
        '/home': (_) => const HomeScreenTemplate(),
        
        '/registration': (_) => const RegistrationScreen(),  // ← 
        '/qr': (_) => const QRViewScreen(),                  // ← 
        '/settings': (_) => const SettingsScreen(),          // ← 
      },
      
      onGenerateRoute: (settings) {
        // Route für OTP Screen mit QR-Code als Parameter
        if (settings.name == '/otp') {
          final args = settings.arguments as Map<String, dynamic>?;
          final code = args?['code'] ?? '';
          return MaterialPageRoute(
            builder: (_) => OtpFormScreen(code: code),  // ← 
          );
        }
        
        if (settings.name == '/registration-form') {
          return MaterialPageRoute(
            builder: (_) => RegistrationFormScreen(),
          );
        }
        return null;
      },
    );
  }

  ThemeData _buildTheme() {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: Colors.black, brightness: Brightness.light),
      scaffoldBackgroundColor: const Color(0xFFF3FFF5),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.black,
        elevation: 6,
        shadowColor: Colors.black54,
        centerTitle: true,
        titleTextStyle: GoogleFonts.lato(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w600),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      textTheme: TextTheme(
        bodyLarge: GoogleFonts.lato(color: Colors.black87),
        bodyMedium: GoogleFonts.lato(color: Colors.black87),
        titleMedium: GoogleFonts.lato(color: Colors.black87),
        titleSmall: GoogleFonts.lato(color: Colors.black54),
      ),
      inputDecorationTheme: InputDecorationTheme(
        labelStyle: GoogleFonts.lato(color: Colors.black87),
        prefixStyle: GoogleFonts.lato(color: Colors.black87),
        hintStyle: GoogleFonts.lato(color: Colors.black38),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: BorderSide(color: Colors.grey.shade400),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: const BorderSide(color: Colors.black, width: 2),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          elevation: 4,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          textStyle: GoogleFonts.lato(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Colors.black54),
          foregroundColor: Colors.black87,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          textStyle: GoogleFonts.lato(color: Colors.black87, fontSize: 16),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: Colors.black54, textStyle: GoogleFonts.lato(fontSize: 14)),
      ),
    );
  }
}

// ── SplashScreen ───────────────────────────────────────────────────────
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Timer(const Duration(seconds: 3), () {
      Navigator.pushReplacementNamed(context, '/welcome');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text('Medical App', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.green.shade800)),
      ),
    );
  }
}