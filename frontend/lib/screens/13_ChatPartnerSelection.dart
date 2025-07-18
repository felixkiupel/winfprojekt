import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '14_DirectChatScreen.dart';

/// ---------------------------------------------------------------------------
/// ChatPartnerSelectionScreen
/// ---------------------------------------------------------------------------
/// Lädt alle Patienten per API und ermöglicht Auswahl eines Chat-Partners.
class ChatPartnerSelectionScreen extends StatefulWidget {
  const ChatPartnerSelectionScreen({Key? key}) : super(key: key);

  @override
  State<ChatPartnerSelectionScreen> createState() => _ChatPartnerSelectionScreenState();
}

class _ChatPartnerSelectionScreenState extends State<ChatPartnerSelectionScreen> {
  final _secureStorage = const FlutterSecureStorage();
  late final String _baseUrl = (() {
    const env = String.fromEnvironment('API_URL');
    if (env.isNotEmpty) return env;
    final host = Platform.isAndroid ? '10.0.2.2' : '127.0.0.1';
    return 'http://$host:8000';
  })();

  List<Map<String, String>> _partners = [];
  bool _isLoading = true;
  String? _selectedPartnerId;
  String? _selectedPartnerName;

  @override
  void initState() {
    super.initState();
    _loadPartners();
  }

  Future<void> _loadPartners() async {
    try {
      final token = await _secureStorage.read(key: 'jwt');
      final uri = Uri.parse('$_baseUrl/patient/all');
      final res = await http.get(
        uri,
        headers: {
          if (token != null) 'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) {
        final list = json.decode(res.body) as List<dynamic>;
        setState(() {
          _partners = list.map((e) {
            final map = e as Map<String, dynamic>;
            final firstname = map['firstname'] as String;
            final lastname = map['lastname'] as String;
            return {
              'id': map['med_id'] as String,
              'name': '$firstname $lastname',
            };
          }).toList();
          _isLoading = false;
        });
      } else {
        throw Exception('Failed to load patients');
      }
    } catch (e) {
      // Fallback: leere Liste oder Fehlermeldung
      setState(() => _isLoading = false);
      // Optional: SnackBar mit Fehler
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Partner auswählen', style: GoogleFonts.lato(fontWeight: FontWeight.w700)),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            DropdownButtonFormField<String>(
              decoration: InputDecoration(
                labelText: 'Chat-Partner',
                border: OutlineInputBorder(),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              hint: Text('Partner wählen', style: GoogleFonts.lato()),
              value: _selectedPartnerId,
              items: _partners.map((partner) {
                final name = partner['name']!;
                final initials = name
                    .split(' ')
                    .map((e) => e.isNotEmpty ? e[0] : '')
                    .take(2)
                    .join();
                return DropdownMenuItem<String>(
                  value: partner['id'],
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                        child: Text(
                          initials,
                          style: GoogleFonts.lato(
                            color: Theme.of(context).colorScheme.onPrimaryContainer,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(name, style: GoogleFonts.lato()),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedPartnerId = value;
                  _selectedPartnerName = _partners.firstWhere((p) => p['id'] == value)['name'];
                });
              },
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: const Icon(Icons.chat),
              label: Text('Chat starten', style: GoogleFonts.lato()),
              onPressed: _selectedPartnerId == null
                  ? null
                  : () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => DirectChatScreen(
                      partnerId: _selectedPartnerId!,
                      partnerName: _selectedPartnerName!,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}