import 'package:flutter/material.dart';
import 'package:frontend/screens/02a_registration.dart';

import '02b_login.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  _WelcomeScreenState createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<int> _iconIndex;

  final List<IconData> _icons = [
    Icons.local_hospital,
    Icons.medical_services,
    Icons.health_and_safety,
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat();

    _iconIndex = StepTween(begin: 0, end: _icons.length - 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.linear),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3FFF5), // Hellgrauer Hintergrund
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Animiertes Icon
              AnimatedBuilder(
                animation: _iconIndex,
                builder: (context, child) {
                  return Icon(
                    _icons[_iconIndex.value],
                    size: 100,
                    color: Colors.black,
                  );
                },
              ),
              const SizedBox(height: 24),
              const Text(
                'Welcome to Demo App',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 48),

              // ------------------ Button „Create Account“ (oben) mit Icon ------------------
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.person_add, color: Colors.white),
                  label: const Text('Create Account'),
                  onPressed: () {
                    // Tippen navigiert zum HomeScreen (als Beispiel für Create Account)
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => RegistrationScreen()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // ------------------ Button „Sign In“ (unten, Outline-Style) mit Icon ------------------
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.login, color: Colors.black87),
                  label: const Text('Sign In'),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.black54),
                    foregroundColor: Colors.black87,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // ------------------ „Need help?“ als TextButton ------------------
              Center(
                child: TextButton(
                  onPressed: () {
                    // TODO: Bei Bedarf Support-Logik einfügen
                  },
                  child: const Text(
                    'Need help? Contact support',
                    style: TextStyle(color: Colors.black54),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
