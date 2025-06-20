import 'package:flutter/material.dart';
import '02a_registration.dart';
import 'package:google_fonts/google_fonts.dart';


class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool _obscureText = true;
  bool _loading = false;
  String? _errorMessage;

  Future<void> _attemptLogin() async {
    final email = emailController.text.trim();
    final password = passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      setState(() {
        _errorMessage = 'Bitte E-Mail und Passwort ausfüllen';
      });
      return;
    }

    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    // TODO: Hier  tatsächliche Login-Logik einfügen.

    await Future.delayed(const Duration(seconds: 2));

    // Beispiel: erfolgreiche Auth, direkt zum HomeScreen wechseln
    setState(() {
      _loading = false;
    });
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => RegistrationScreen()),
    );

    // Wenn Login fehlschlägt, statt Navigator.pushReplacement:
    // setState(() {
    //   _loading = false;
    //   _errorMessage = 'Ungültige Anmeldedaten';
    // });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Sign In',
          style: GoogleFonts.lato(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Colors.black,
        elevation: 6,
        shadowColor: Colors.black54,
        centerTitle: true,
      ),
      backgroundColor: const Color(0xFFF3FFF5),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: 160,
              child: Center(
                child: Hero(
                  tag: 'logo',
                  child: Icon(
                    Icons.local_hospital,
                    size: 80,
                    color: Colors.black87,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // E-Mail-Eingabe
            TextField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                filled: false,
                prefixIcon: const Icon(Icons.email_outlined),
                labelText: 'Email',
                labelStyle: GoogleFonts.lato(),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),

            // Passwort-Eingabe
            TextField(
              controller: passwordController,
              obscureText: _obscureText,
              decoration: InputDecoration(
                filled: false,
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: GestureDetector(
                  onTap: () {
                    setState(() {
                      _obscureText = !_obscureText;
                    });
                  },
                  child: Icon(
                    _obscureText ? Icons.visibility : Icons.visibility_off,
                  ),
                ),
                labelText: 'Password',
                labelStyle: GoogleFonts.lato(),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),

            // Forgot password
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {
                  // TODO: „Passwort vergessen“-Logik hier einfügen
                },
                child: Text(
                  'Forgot your password?',
                  style: GoogleFonts.lato(
                    color: Colors.grey,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Fehlermeldung (falls vorhanden)
            if (_errorMessage != null) ...[
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.red.shade700,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Login-Button
            _loading
                ? ElevatedButton(
              onPressed: null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                elevation: 4,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              ),
            )
                : ElevatedButton(
              onPressed: _attemptLogin,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                elevation: 4,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                'Login',
                style: GoogleFonts.lato(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Create Account-Button (jetzt funktional)
            OutlinedButton(
              onPressed: () {
                // Navigiere zur Registrierungsseite
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => RegistrationScreen()),
                );
              },
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.black54),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                'Create Account',
                style: GoogleFonts.lato(
                  color: Colors.black87,
                  fontSize: 16,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Kontakt-Support-Hinweis
            Center(
              child: Text(
                'Need help? Contact support',
                style: GoogleFonts.lato(
                  fontSize: 14,
                  color: Colors.black54,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
