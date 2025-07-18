import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import '12_LogScreen.dart';


// BASE-URL Definition
late final String _baseUrl = (() {
  const envUrl = String.fromEnvironment('API_URL');
  if (envUrl.isNotEmpty) return envUrl;
  final host = Platform.isAndroid ? '10.0.2.2' : '127.0.0.1';
  return 'http://$host:8000';
})();

class CommunityPostScreen extends StatefulWidget {
  const CommunityPostScreen({Key? key}) : super(key: key);

  @override
  _CommunityPostScreenState createState() => _CommunityPostScreenState();
}

class _CommunityPostScreenState extends State<CommunityPostScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _bodyController = TextEditingController();
  String? _selectedCommunity;
  bool _isSending = false;

  late final FlutterLocalNotificationsPlugin _localNotif;

  final List<String> _communities = [
    'Community A',
    'Community B',
    'Community C',
  ];

  @override
  void initState() {
    super.initState();
    _localNotif = FlutterLocalNotificationsPlugin();
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    _localNotif.initialize(
      const InitializationSettings(android: androidSettings, iOS: iosSettings),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  Future<void> _showNotification(String notifTitle, String notifBody) async {
    await _localNotif.show(
      0,
      notifTitle,
      notifBody,
      NotificationDetails(
        android: AndroidNotificationDetails(
          'send_channel',
          'Send Notifications',
          channelDescription: 'Benachrichtigung nach Senden',
          importance: Importance.max,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
    );
  }

  /// Loggt die Nachricht per PUT an /messages
  Future<void> _logMessage() async {
    final uri = Uri.parse('$_baseUrl/com_messages');
    final payload = jsonEncode({
      'date': DateTime.now().toIso8601String(),
      'community': _selectedCommunity,
      'title': _titleController.text,
      'message': _bodyController.text,
    });
    final resp = await http.put(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: payload,
    );
    if (resp.statusCode < 200 || resp.statusCode >= 300) {
      // Optional: Fehlerbehandlung
      debugPrint('Log-Request fehlgeschlagen: ${resp.statusCode}');
    }
  }

  Future<void> _send() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSending = true);

    // Simulierter API-Call
    await Future.delayed(const Duration(seconds: 1));

    // Notification mit den eingegebenen Werten
    await _showNotification(
      _titleController.text,
      _bodyController.text,
    );

    // Nachricht loggen
    await _logMessage();

    // Zurücksetzen
    _formKey.currentState!.reset();
    setState(() {
      _selectedCommunity = null;
      _titleController.clear();
      _bodyController.clear();
      _isSending = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Neue Nachricht',
          style: GoogleFonts.lato(fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const LogScreen()),
              );
            },
            child: Text('Log', style: GoogleFonts.lato(color: Colors.white)),
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.message, size: 48, color: Theme.of(context).primaryColor),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: _titleController,
                    decoration: InputDecoration(
                      labelText: 'Titel',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    validator: (v) => (v == null || v.isEmpty) ? 'Bitte Titel eingeben' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _bodyController,
                    decoration: InputDecoration(
                      labelText: 'Text',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    maxLines: 5,
                    validator: (v) => (v == null || v.isEmpty) ? 'Bitte Text eingeben' : null,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _selectedCommunity,
                    hint: Text('Community auswählen', style: GoogleFonts.lato()),
                    decoration: InputDecoration(
                      labelText: 'Community',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    items: _communities
                        .map((c) => DropdownMenuItem(value: c, child: Text(c, style: GoogleFonts.lato())))
                        .toList(),
                    onChanged: (v) => setState(() => _selectedCommunity = v),
                    validator: (v) => v == null ? 'Bitte eine Community wählen' : null,
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isSending ? null : _send,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: _isSending
                          ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                          : Text('Senden', style: GoogleFonts.lato(fontSize: 16)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}