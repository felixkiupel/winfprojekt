import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

// ── Screens ───────────────────────────────────────────────────────────
import 'screens/01_welcome.dart';
import 'screens/02b_login.dart';
import 'screens/06_homescreen.dart';

final FlutterLocalNotificationsPlugin localNotif = FlutterLocalNotificationsPlugin();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // .env laden
  try {
    await dotenv.load();
  } catch (_) {
    debugPrint('Keine .env Datei gefunden – nutze Standardwerte');
  }

  const DarwinInitializationSettings iosSettings = DarwinInitializationSettings(
    requestAlertPermission: true,
    requestBadgePermission: true,
    requestSoundPermission: true,
  );
  await localNotif.initialize(
    const InitializationSettings(iOS: iosSettings),
  );

  runApp(MyApp(localNotif: localNotif));
}

class MyApp extends StatelessWidget {
  final FlutterLocalNotificationsPlugin localNotif;

  const MyApp({Key? key, required this.localNotif}) : super(key: key);

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
        // Optional: '/sos': (_) => SOSScreen(localNotif: localNotif),
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          textStyle: GoogleFonts.lato(color: Colors.black87, fontSize: 16),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: Colors.black54,
          textStyle: GoogleFonts.lato(fontSize: 14),
        ),
      ),
    );
  }
}

// ── SplashScreen ───────────────────────────────────────────────────────
class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);
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
