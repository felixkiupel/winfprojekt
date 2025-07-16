import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '06_homescreen.dart';

class RegistrationFormScreen extends StatefulWidget {
  const RegistrationFormScreen({super.key});
  @override
  _RegistrationFormScreenState createState() => _RegistrationFormScreenState();
}

class _RegistrationFormScreenState extends State<RegistrationFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _storage = const FlutterSecureStorage();

  String? firstName, lastName, email, password, passwordConfirm, medId;
  bool loading = false;
  String? message;

  String get _baseUrl {
    const envUrl = String.fromEnvironment('API_URL');
    if (envUrl.isNotEmpty) return envUrl;
    if (Platform.isAndroid) return 'http://10.0.2.2:8000';
    return 'http://127.0.0.1:8000'; // iOS-Simulator & macOS
  }

  Future<void> register() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    setState(() { loading = true; message = null; });

    final uri = Uri.parse('$_baseUrl/register');

    try {
      final res = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'firstname': firstName,
          'lastname': lastName,
          'email': email,
          'password': password,
          'password_confirm': passwordConfirm,
          'med_id': medId,
        }),
      );

      if (res.statusCode == 200 || res.statusCode == 201) {
        final data = jsonDecode(res.body);
        await _storage.write(key: 'access_token', value: data['access_token']);
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreenTemplate()),
        );
      } else {
        final err = jsonDecode(res.body);
        setState(() {
          message = err['detail'] ?? 'Registration failed';
        });
      }
    } catch (e) {
      setState(() { message = 'Fehler: $e'; });
    } finally {
      if (mounted) setState(() { loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Register')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Personal Data Registration',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.lato(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 32),

                // First Name
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'First Name',
                    prefixIcon: Icon(Icons.person),
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) =>
                  (v == null || v.isEmpty) ? 'Enter your First Name' : null,
                  onSaved: (v) => firstName = v,
                ),
                const SizedBox(height: 16),

                // Last Name
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Last Name',
                    prefixIcon: Icon(Icons.person),
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) =>
                  (v == null || v.isEmpty) ? 'Enter your Last Name' : null,
                  onSaved: (v) => lastName = v,
                ),
                const SizedBox(height: 16),

                // Email
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.email),
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Enter your E-Mail';
                    if (!v.contains('@')) return 'Please enter a valid E-Mail';
                    return null;
                  },
                  onSaved: (v) => email = v,
                ),
                const SizedBox(height: 16),

                // Password
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Password',
                    prefixIcon: Icon(Icons.lock),
                    border: OutlineInputBorder(),
                  ),
                  obscureText: true,
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Please enter your password';
                    if (v.length < 6) return 'At least 6 symbols';
                    return null;
                  },
                  onSaved: (v) => password = v,
                ),
                const SizedBox(height: 16),

                // Confirm Password
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Confirm Password',
                    prefixIcon: Icon(Icons.lock),
                    border: OutlineInputBorder(),
                  ),
                  obscureText: true,
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Please confirm';
                    return null;
                  },
                  onSaved: (v) => passwordConfirm = v,
                ),
                const SizedBox(height: 16),

                // Med ID
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Insurance-number',
                    prefixIcon: Icon(Icons.badge),
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) => (v == null || v.isEmpty)
                      ? 'Pleas enter your Insurance-number'
                      : null,
                  onSaved: (v) => medId = v,
                ),
                const SizedBox(height: 24),

                if (message != null) ...[
                  Text(
                    message!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: message!.toLowerCase().contains('success')
                          ? Colors.green
                          : Colors.red,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                loading
                    ? const Center(child: CircularProgressIndicator())
                    : ElevatedButton.icon(
                  onPressed: register,
                  icon: const Icon(Icons.check, color: Colors.white),
                  label: const Text('Submit'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                    textStyle: GoogleFonts.lato(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
