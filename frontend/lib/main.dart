import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:medapp/screens/02a_registration.dart';
import 'package:medapp/screens/05_registration_form_screen.dart';

// ── Screens ───────────────────────────────────────────────────────────
import 'screens/01_welcome.dart';
import 'screens/02b_login.dart';
import 'screens/06_homescreen.dart';

// ── Farbdefinitions-Block ────────────────────────────────────────────
const Color kMedicalPrimary              = Color(0xFFF5FFF6);
const Color kMedicalPrimaryContainer     = Color(0xFFE8F5E9);
const Color kMedicalSecondary            = Color(0xFF81C784);
const Color kMedicalSecondaryContainer   = Color(0xFFA5D6A7);
const Color kMedicalBackground           = kMedicalPrimary;
const Color kMedicalSurface              = Colors.white;
const Color kMedicalSurfaceVariant       = Color(0xFFE0F2F1);
const Color kMedicalError                = Color(0xFFD32F2F);

const Color kMedicalOnPrimary            = Colors.white;
const Color kMedicalOnPrimaryContainer   = Color(0xFF212121);
const Color kMedicalOnSecondary          = Color(0xFF212121);
const Color kMedicalOnSecondaryContainer = Color(0xFF212121);
const Color kMedicalOnBackground         = Color(0xFF212121);
const Color kMedicalOnSurface            = Color(0xFF212121);
const Color kMedicalOnSurfaceVariant     = Color(0xFF212121);
const Color kMedicalOnError              = Colors.white;

const ColorScheme medicalColorScheme = ColorScheme(
  brightness: Brightness.light,
  primary: kMedicalPrimary,
  onPrimary: kMedicalOnPrimary,
  primaryContainer: kMedicalPrimaryContainer,
  onPrimaryContainer: kMedicalOnPrimaryContainer,
  secondary: kMedicalSecondary,
  onSecondary: kMedicalOnSecondary,
  secondaryContainer: kMedicalSecondaryContainer,
  onSecondaryContainer: kMedicalOnSecondaryContainer,
  background: kMedicalBackground,
  onBackground: kMedicalOnBackground,
  surface: kMedicalSurface,
  onSurface: kMedicalOnSurface,
  surfaceVariant: kMedicalSurfaceVariant,
  onSurfaceVariant: kMedicalOnSurfaceVariant,
  error: kMedicalError,
  onError: kMedicalOnError,
);

final FlutterLocalNotificationsPlugin localNotif = FlutterLocalNotificationsPlugin();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await dotenv.load();
    debugPrint('.env Datei gefunden – top');
  } catch (_) {
    debugPrint('Keine .env Datei gefunden – nutze Standardwerte');
  }

  const iosSettings = DarwinInitializationSettings(
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
      },
    );
  }

  ThemeData _buildTheme() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: medicalColorScheme,
      scaffoldBackgroundColor: medicalColorScheme.primary,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.black,
        elevation: 6,
        shadowColor: medicalColorScheme.onSurface.withOpacity(0.18),
        centerTitle: true,
        titleTextStyle: GoogleFonts.lato(
          color: medicalColorScheme.onPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      textTheme: TextTheme(
        bodyLarge: GoogleFonts.lato(color: medicalColorScheme.onSurface),
        bodyMedium: GoogleFonts.lato(color: medicalColorScheme.onSurface),
        titleMedium: GoogleFonts.lato(color: medicalColorScheme.onSurface),
        titleSmall: GoogleFonts.lato(color: medicalColorScheme.onSurfaceVariant),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: BorderSide(color: Colors.black, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: BorderSide(color: Colors.black, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: BorderSide(color: Colors.black, width:2),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: BorderSide(color: medicalColorScheme.surfaceVariant, width: 2),
        ),
        hintStyle: GoogleFonts.lato(color: medicalColorScheme.onSurfaceVariant),
        labelStyle: GoogleFonts.lato(color: medicalColorScheme.onSurface),
        prefixStyle: GoogleFonts.lato(color: medicalColorScheme.onSurface),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          elevation: 4,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          textStyle: GoogleFonts.lato(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: medicalColorScheme.onSurfaceVariant),
          foregroundColor: medicalColorScheme.onSurface,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          textStyle: GoogleFonts.lato(fontSize: 16),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: medicalColorScheme.onSurfaceVariant,
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
            color: medicalColorScheme.secondary,
          ),
        ),
      ),
    );
  }
}
