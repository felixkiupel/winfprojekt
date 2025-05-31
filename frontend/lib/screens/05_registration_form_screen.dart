import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '06_homescreen.dart';

class RegistrationFormScreen extends StatefulWidget {
  @override
  _RegistrationFormScreenState createState() => _RegistrationFormScreenState();
}

class _RegistrationFormScreenState extends State<RegistrationFormScreen> {
  final _formKey = GlobalKey<FormState>();
  String? name;
  String? email;
  String? password;
  String? insuranceNumber;
  bool loading = false;
  String? message;

  Future<void> register() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    setState(() {
      loading = true;
      message = null;
    });

    final apiUrl = dotenv.env['API_URL'] ?? 'http://localhost:5000';
    try {
      final response = await http.post(
        Uri.parse('$apiUrl/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': name,
          'email': email,
          'password': password,
          'insuranceNumber': insuranceNumber,
        }),
      );

      if (response.statusCode == 201) {
        // Registrierung erfolgreich – wechsle zum HomeScreenTemplate
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreenTemplate()),
        );
      } else {
        final body = jsonDecode(response.body);
        setState(() {
          message = body['error'] ?? 'Registration failed';
        });
      }
    } catch (e) {
      setState(() {
        message = 'An error occurred: $e';
      });
    } finally {
      setState(() {
        loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Register')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Überschrift
                  Text(
                    'Personal Data Registration',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.lato(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Name-Feld mit Icon
                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Name',
                      prefixIcon: Icon(Icons.person),
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Bitte Name eingeben';
                      return null;
                    },
                    onSaved: (value) => name = value,
                  ),
                  const SizedBox(height: 16),

                  // Email-Feld mit Icon
                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      prefixIcon: Icon(Icons.email),
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Bitte Email eingeben';
                      if (!value.contains('@')) return 'Bitte gültige Email eingeben';
                      return null;
                    },
                    onSaved: (value) => email = value,
                  ),
                  const SizedBox(height: 16),

                  // Passwort-Feld mit Icon
                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Password',
                      prefixIcon: Icon(Icons.lock),
                      border: OutlineInputBorder(),
                    ),
                    obscureText: true,
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Bitte Passwort eingeben';
                      if (value.length < 6) return 'Passwort muss mindestens 6 Zeichen haben';
                      return null;
                    },
                    onSaved: (value) => password = value,
                  ),
                  const SizedBox(height: 16),

                  // Versicherungsnummer-Feld mit Icon
                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Versicherungsnummer',
                      prefixIcon: Icon(Icons.badge),
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Bitte Versicherungsnummer eingeben';
                      if (value.length < 5) return 'Versicherungsnummer zu kurz';
                      return null;
                    },
                    onSaved: (value) => insuranceNumber = value,
                  ),
                  const SizedBox(height: 24),

                  // Feedback-Nachricht (Erfolg/Fehler)
                  if (message != null) ...[
                    Text(
                      message!,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: message == 'Registration successful!' ? Colors.green : Colors.red,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Submit-Button mit Icon und Mindesthöhe
                  if (loading) ...[
                    ElevatedButton(
                      onPressed: null,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                        textStyle: GoogleFonts.lato(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      child: const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      ),
                    ),
                  ] else ...[
                    ElevatedButton.icon(
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
                  ],

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
