import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import '02a_registration.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController emailController    = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final FlutterSecureStorage _storage            = const FlutterSecureStorage();

  bool _obscureText  = true;
  bool _loading      = false;
  String? _errorMessage;

  late final String _baseUrl = (() {
    const envUrl = String.fromEnvironment('API_URL');
    if (envUrl.isNotEmpty) return envUrl;
    final host = Platform.isAndroid ? '10.0.2.2' : '127.0.0.1';
    return 'http://$host:8000';
  })();

  Future<void> _attemptLogin() async {
    final email    = emailController.text.trim();
    final password = passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      setState(() => _errorMessage = 'Please enter your E-Mail and Password');
      return;
    }

    setState(() {
      _loading      = true;
      _errorMessage = null;
    });

    try {
      final uri = Uri.parse('$_baseUrl/login');
      final res = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      if (res.statusCode == 200) {
        final data  = jsonDecode(res.body) as Map<String, dynamic>;
        final token = data['access_token'] as String?;
        if (token == null) throw Exception('Token fehlt in der Antwort');

        // 1) JWT sicher speichern
        await _storage.write(key: 'jwt', value: token);

        // 2) Navigiere zur Home‑Seite
        if (!mounted) return;
        Navigator.of(context).pushReplacementNamed('/home');
      } else {
        // Fehlernachricht aus Backend-Response übernehmen
        final detail = (jsonDecode(res.body) as Map<String, dynamic>)['detail'];
        setState(() => _errorMessage = detail?.toString() ?? 'Please enter a valid E-Mail and Password');
      }
    } catch (e) {
      setState(() => _errorMessage = 'Login failed: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Sign In', style: GoogleFonts.lato(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w600)),
        backgroundColor: Colors.black,
        elevation: 6,
        centerTitle: true,
      ),
      backgroundColor: const Color(0xFFF3FFF5),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Logo
            SizedBox(
              height: 160,
              child: Center(
                child: Hero(
                  tag: 'logo',
                  child: Icon(Icons.local_hospital, size: 80, color: Colors.black87),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // E-Mail
            TextField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.email_outlined),
                labelText: 'Email',
                labelStyle: GoogleFonts.lato(),
                border: const OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 20),

            // Passwort
            TextField(
              controller: passwordController,
              obscureText: _obscureText,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: GestureDetector(
                  onTap: () => setState(() => _obscureText = !_obscureText),
                  child: Icon(_obscureText ? Icons.visibility : Icons.visibility_off),
                ),
                labelText: 'Password',
                labelStyle: GoogleFonts.lato(),
                border: const OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 12),

            // "Passwort vergessen"
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {
                  // TODO: Passwort-Reset
                },
                child: Text('Forgot your password?', style: GoogleFonts.lato(color: Colors.grey)),
              ),
            ),

            const SizedBox(height: 16),

            // Fehlermeldung
            if (_errorMessage != null) ...[
              Text(_errorMessage!, textAlign: TextAlign.center, style: TextStyle(color: Colors.red.shade700, fontSize: 14)),
              const SizedBox(height: 16),
            ],

            // Login-Button
            ElevatedButton(
              onPressed: _loading ? null : _attemptLogin,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                elevation: 4,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: _loading
                  ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : Text('Login', style: GoogleFonts.lato(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
            ),

            const SizedBox(height: 16),

            // Registrierung
            OutlinedButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const RegistrationScreen()),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.black54),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: Text('Create Account', style: GoogleFonts.lato(color: Colors.black87, fontSize: 16)),
            ),

            const SizedBox(height: 24),

            Center(child: Text('Need help? Contact support', style: GoogleFonts.lato(fontSize: 14, color: Colors.black54))),
          ],
        ),
      ),
    );
  }
}
