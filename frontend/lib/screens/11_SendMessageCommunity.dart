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

/// Modell für Community
class Community {
  final String name;
  final String description;

  Community({required this.name, required this.description});

  factory Community.fromJson(Map<String, dynamic> json) {
    return Community(
      name: json['name'] as String,
      description: json['description'] as String,
    );
  }
}

class CommunityPostScreen extends StatefulWidget {
  const CommunityPostScreen({Key? key}) : super(key: key);

  @override
  _CommunityPostScreenState createState() => _CommunityPostScreenState();
}

class _CommunityPostScreenState extends State<CommunityPostScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _bodyController = TextEditingController();
  Community? _selectedCommunity;
  bool _isSending = false;
  bool _isLoading = true;
  String? _error;

  late final FlutterLocalNotificationsPlugin _localNotif;
  List<Community> _communities = [];

  @override
  void initState() {
    super.initState();
    _initNotifications();
    _fetchCommunities();
  }

  void _initNotifications() {
    _localNotif = FlutterLocalNotificationsPlugin();
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    _localNotif.initialize(const InitializationSettings(android: androidSettings, iOS: iosSettings));
  }

  Future<void> _fetchCommunities() async {
    try {
      final uri = Uri.parse('$_baseUrl/communitys/all');
      final resp = await http.get(uri);
      if (resp.statusCode == 200) {
        final List<dynamic> data = jsonDecode(resp.body);
        setState(() {
          _communities = data.map((e) => Community.fromJson(e)).toList();
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'An Error occurred while attempting to load the Communities (${resp.statusCode})';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Networkerror: $e';
        _isLoading = false;
      });
    }
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
          channelDescription: 'Notification after sending',
          importance: Importance.max,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
    );
  }

  Future<void> _logMessage() async {
    final uri = Uri.parse('$_baseUrl/com_messages');
    final payload = jsonEncode({
      'date': DateTime.now().toIso8601String(),
      'community': _selectedCommunity?.name,
      'title': _titleController.text,
      'message': _bodyController.text,
    });
    final resp = await http.put(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: payload,
    );
    if (resp.statusCode < 200 || resp.statusCode >= 300) {
      debugPrint('Log-Request failed: ${resp.statusCode}');
    }
  }

  Future<void> _send() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSending = true);

    // Hier könnte ein richtiger API-Call kommen
    await Future.delayed(const Duration(seconds: 1));

    await _showNotification(_titleController.text, _bodyController.text);
    await _logMessage();

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
        title: Text('New Message', style: GoogleFonts.lato(fontWeight: FontWeight.w700)),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const LogScreen())),
            child: Text('Log', style: GoogleFonts.lato(color: Colors.white)),
          ),
        ],
      ),
      body: Center(
        child: _isLoading
            ? const CircularProgressIndicator()
            : _error != null
            ? Text(_error!, style: TextStyle(color: Colors.red))
            : SingleChildScrollView(
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
                    validator: (v) => (v == null || v.isEmpty) ? 'Please enter title' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _bodyController,
                    decoration: InputDecoration(
                      labelText: 'Text',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    maxLines: 5,
                    validator: (v) => (v == null || v.isEmpty) ? 'Please enter text' : null,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<Community>(
                    value: _selectedCommunity,
                    hint: Text('Community auswählen', style: GoogleFonts.lato()),
                    decoration: InputDecoration(
                      labelText: 'Community',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    // Nur Namen anzeigen, wenn eine Auswahl getroffen wurde
                    selectedItemBuilder: (BuildContext context) {
                      return _communities.map<Widget>((Community c) {
                        return Text(c.name, style: GoogleFonts.lato());
                      }).toList();
                    },
                    items: _communities
                        .map(
                          (c) => DropdownMenuItem<Community>(
                        value: c,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(c.name, style: GoogleFonts.lato(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            Text(
                              c.description,
                              style: GoogleFonts.lato(fontSize: 12, color: Colors.grey[600]),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const Divider(height: 16),
                          ],
                        ),
                      ),
                    )
                        .toList(),
                    onChanged: (c) => setState(() => _selectedCommunity = c),
                    validator: (v) => v == null ? 'Please pick a Community' : null,
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
                          ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : Text('Send', style: GoogleFonts.lato(fontSize: 16)),
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
