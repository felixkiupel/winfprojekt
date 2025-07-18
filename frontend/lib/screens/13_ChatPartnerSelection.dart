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
/// Zeigt zuerst alle bisherigen Chat-Partner mit ungelesenem-Badge
/// und unten das Dropdown, um neue Chats zu starten.
class ChatPartnerSelectionScreen extends StatefulWidget {
  const ChatPartnerSelectionScreen({Key? key}) : super(key: key);

  @override
  State<ChatPartnerSelectionScreen> createState() =>
      _ChatPartnerSelectionScreenState();
}

class _ChatPartnerSelectionScreenState
    extends State<ChatPartnerSelectionScreen> {
  final _secureStorage = const FlutterSecureStorage();

  late final String _baseUrl = (() {
    const env = String.fromEnvironment('API_URL');
    if (env.isNotEmpty) return env;
    final host = Platform.isAndroid ? '10.0.2.2' : '127.0.0.1';
    return 'http://$host:8000';
  })();

  List<Map<String, dynamic>> _recentPartners = [];
  List<Map<String, String>> _partners = [];
  bool _isLoading = true;

  String? _currentRole;
  String? _selectedPartnerId;
  String? _selectedPartnerName;

  @override
  void initState() {
    super.initState();
    _loadPartners();
  }

  Future<void> _loadPartners() async {
    setState(() => _isLoading = true);
    try {
      final token = await _secureStorage.read(key: 'jwt');
      if (token == null) throw Exception('Kein Token gefunden');

      // 1) Profil abrufen, um Rolle zu kennen
      final profileRes = await http.get(
        Uri.parse('$_baseUrl/patient/me'),
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(const Duration(seconds: 10));
      if (profileRes.statusCode != 200) {
        throw Exception('Profil konnte nicht geladen werden');
      }
      final profile = json.decode(profileRes.body) as Map<String, dynamic>;
      _currentRole = profile['role'] as String?;

      // 2) Bisherige Chat-Partner laden inkl. unreadCount
      final recentRes = await http.get(
        Uri.parse('$_baseUrl/dm/partners'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));
      if (recentRes.statusCode == 200) {
        final list = json.decode(recentRes.body) as List<dynamic>;
        _recentPartners = list.map((e) {
          final m = e as Map<String, dynamic>;
          return {
            'id': m['med_id'] as String,
            'name': '${m['firstname']} ${m['lastname']}',
            'unreadCount': (m['unreadCount'] as int?) ?? 0,
          };
        }).toList();
      }

      // 3) Alle Gegenrollen laden (Patienten oder Ärzte) und bereits gechattete entfernen
      final endpoint = (_currentRole == 'doctor')
          ? '/patient/patients'
          : '/patient/doctors';
      final allRes = await http.get(
        Uri.parse('$_baseUrl$endpoint'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));
      if (allRes.statusCode == 200) {
        final list = json.decode(allRes.body) as List<dynamic>;
        _partners = list.map((e) {
          final m = e as Map<String, dynamic>;
          return {
            'id': m['med_id'] as String,
            'name': '${m['firstname']} ${m['lastname']}',
          };
        })
            .where((p) => !_recentPartners.any((r) => r['id'] == p['id']))
            .toList();
      }
    } catch (e) {
      debugPrint('Fehler beim Laden der Partner: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Chat Partner',
          style: GoogleFonts.lato(fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (_recentPartners.isNotEmpty) ...[
            Text(
              'Letzte Chats',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            ..._recentPartners.map((partner) {
              final initials = partner['name']!
                  .split(' ')
                  .map((s) => s.isNotEmpty ? s[0] : '')
                  .take(2)
                  .join();
              final unread = partner['unreadCount'] as int;
              return ListTile(
                leading: CircleAvatar(child: Text(initials)),
                title: Text(partner['name']!),
                trailing: unread > 0
                    ? CircleAvatar(
                  radius: 14,
                  backgroundColor: Colors.teal,
                  child: Text(
                    unread.toString(),
                    style: GoogleFonts.lato(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                )
                    : null,
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => DirectChatScreen(
                        partnerId: partner['id']!,
                        partnerName: partner['name']!,
                      ),
                    ),
                  );
                  await _loadPartners();
                },
              );
            }).toList(),
            const Divider(height: 32),
          ],

          Text(
            'Neuen Chat starten',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),

          DropdownButtonFormField<String>(
            decoration: InputDecoration(
              labelText: 'Partner wählen',
              border: OutlineInputBorder(),
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 8),
            ),
            hint: Text('Partner wählen', style: GoogleFonts.lato()),
            value: _selectedPartnerId,
            items: _partners.map((partner) {
              final initials = partner['name']!
                  .split(' ')
                  .map((s) => s.isNotEmpty ? s[0] : '')
                  .take(2)
                  .join();
              return DropdownMenuItem<String>(
                value: partner['id'],
                child: Row(
                  children: [
                    CircleAvatar(child: Text(initials)),
                    const SizedBox(width: 12),
                    Text(partner['name']!, style: GoogleFonts.lato()),
                  ],
                ),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedPartnerId = value;
                _selectedPartnerName = _partners
                    .firstWhere((p) => p['id'] == value)['name'];
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
              ).then((_) => _loadPartners());
            },
          ),
        ],
      ),
    );
  }
}
