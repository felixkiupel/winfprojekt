import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'screens/01_welcome.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await dotenv.load();
  } catch (e) {
    print('Keine .env Datei gefunden, verwende Standardwerte');
  }
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Demo Auth Flow',
      theme: ThemeData(
        // ───────────────────────────────────────────────────────────────────
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.black,
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFF3FFF5),
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.black,
          elevation: 6,
          shadowColor: Colors.black54,
          centerTitle: true,
          titleTextStyle: GoogleFonts.lato(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
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
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            textStyle: GoogleFonts.lato(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: Colors.black54),
            foregroundColor: Colors.black87,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            textStyle: GoogleFonts.lato(
              color: Colors.black87,
              fontSize: 16,
            ),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: Colors.black54,
            textStyle: GoogleFonts.lato(fontSize: 14),
          ),
        ),
      ),
      // Statt WelcomeScreen zuerst die SplashScreen
      home: const SplashScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

/// Zeigt für 3 Sekunden nur den Text „Medical App“ an und wechselt dann zur WelcomeScreen
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
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const WelcomeScreen()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text(
          'Medical App',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Colors.green.shade800,
          ),
        ),
      ),
    );
  }
}
