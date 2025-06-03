import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '05_registration_form_screen.dart';

class OtpFormScreen extends StatefulWidget {
  final String code;
  const OtpFormScreen({required this.code});

  @override
  _OtpFormScreenState createState() => _OtpFormScreenState();
}

class _OtpFormScreenState extends State<OtpFormScreen> {
  final _formKey = GlobalKey<FormState>();
  String? otp;
  String? password;
  bool loading = false;
  String? errorMessage;

  Future<void> submit() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();
    setState(() {
      loading = true;
      errorMessage = null;
    });

    final apiUrl = dotenv.env['API_URL'] ?? 'http://localhost:5000';
    try {
      final response = await http.post(
        Uri.parse('$apiUrl/auth'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'code': widget.code,
          'otp': otp,
          'password': password,
        }),
      );
      if (response.statusCode == 200) {
        // Auth erfolgreich: Navigiere zum RegistrationFormScreen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => RegistrationFormScreen()),
        );
      } else {
        // Fehler anzeigen
        final body = jsonDecode(response.body);
        setState(() {
          errorMessage = body['error'] ?? 'Authentication failed';
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'An error occurred: $e';
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
      appBar: AppBar(title: const Text('OTP Verification')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: SingleChildScrollView(

            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Auth Code (QR):',
                      style: GoogleFonts.roboto(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.code,
                      style: GoogleFonts.roboto(fontSize: 14),
                    ),

                    const SizedBox(height: 24),
                    TextFormField(
                      decoration: const InputDecoration(
                        labelText: 'One-Time-Password(OTP)',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Bitte OTP eingeben';
                        if (value.length != 6) return 'OTP muss 6-stellig sein';
                        return null;
                      },
                      onSaved: (value) => otp = value,
                    ),
                    const SizedBox(height: 16),
                    if (errorMessage != null) ...[
                      Text(
                        errorMessage!,
                        style: const TextStyle(color: Colors.red),
                      ),
                      const SizedBox(height: 16),
                    ],
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: loading ? null : submit,
                      child: loading
                          ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                          : const Text('Continue'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
