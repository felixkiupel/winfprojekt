import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// ----------------------------------------------------------------------------
/// CommunityFeedScreen
/// ----------------------------------------------------------------------------
/// Anzeige aller Nachrichten eines Patienten innerhalb seiner Communities.
/// – Nur PATIENTEN können diese Seite aufrufen (z.B. über ein Role‑Guard).
/// – Nachrichten kommen aus /messages?communities=A,B,…
/// – Fallback auf lokales JSON, falls API down.
/// – Gelesen/Ungelesen wird in SharedPreferences pro User gespeichert.
/// ----------------------------------------------------------------------------

class CommunityFeedScreen extends StatefulWidget {
  const CommunityFeedScreen({Key? key}) : super(key: key);

  @override
  State<CommunityFeedScreen> createState() => _CommunityFeedScreenState();
}

class _CommunityFeedScreenState extends State<CommunityFeedScreen> {
  final _secureStorage = const FlutterSecureStorage();
  late SharedPreferences _prefs;

  bool _isLoading = true;
  bool _isRefreshing = false;

  String? _userName;
  List<String> _userCommunities = [];
  List<MessageItem> _messages = [];
  Set<String> _readMessageIds = {};

  // Basis‑URL analog zu anderen Screens
  late final String _baseUrl = (() {
    const envUrl = String.fromEnvironment('API_URL');
    if (envUrl.isNotEmpty) return envUrl;
    final host = Platform.isAndroid ? '10.0.2.2' : '127.0.0.1';
    return 'http://$host:8000';
  })();

  // ---------------------------- MOCK DATA -----------------------------
  static const String _mockMessagesJson = '''[
    {"id":"1","date":"2025-07-17T12:00:00Z","community":"Community A","title":"Willkommen","message":"Willkommen in unserer Community!","sender":"Dr. Smith","status":"Unread"},
    {"id":"2","date":"2025-07-16T09:00:00Z","community":"Community B","title":"Neue Studie","message":"Bitte lesen Sie die neue Studie...","sender":"Dr. Miller","status":"Unread"}
  ]''';
  // --------------------------------------------------------------------

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    _prefs = await SharedPreferences.getInstance();
    await _loadReadIds();
    await _fetchAll();
  }

  Future<void> _loadReadIds() async {
    final list = _prefs.getStringList('readMessages') ?? [];
    _readMessageIds = list.toSet();
  }

  Future<void> _saveReadIds() async {
    await _prefs.setStringList('readMessages', _readMessageIds.toList());
  }

  Future<void> _fetchAll() async {
    setState(() => _isLoading = true);
    await Future.wait([
      _fetchProfileAndCommunities(),
      _fetchMessages(),
    ]);
    setState(() => _isLoading = false);
  }

  Future<void> _fetchProfileAndCommunities() async {
    try {
      final token = await _secureStorage.read(key: 'jwt');
      if (token == null) throw Exception('Kein Token');

      // Profil
      final profRes = await http.get(
        Uri.parse('$_baseUrl/patient/me'),
        headers: {'Authorization': 'Bearer $token', 'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 10));
      if (profRes.statusCode == 200) {
        final data = json.decode(profRes.body) as Map<String, dynamic>;
        _userName = '${data['firstname'] ?? ''} ${data['lastname'] ?? ''}'.trim();
      }

      // Communities
      final commRes = await http.get(
        Uri.parse('$_baseUrl/communitys/me'),
        headers: {'Authorization': 'Bearer $token', 'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 10));
      if (commRes.statusCode == 200) {
        _userCommunities = (json.decode(commRes.body) as List).cast<String>();
      }
    } catch (_) {
      // Ignoriere – Fallback unten kümmert sich
    }
  }

  Future<void> _fetchMessages() async {
    setState(() => _isRefreshing = true);
    try {
      final token = await _secureStorage.read(key: 'jwt');
      if (token == null) throw Exception('Kein Token');

      final uri = Uri.parse(
        '$_baseUrl/messages?communities=${_userCommunities.join(',')}',
      );
      final res = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));

      if (res.statusCode == 200) {
        final list = json.decode(res.body) as List<dynamic>;
        _messages = list.map((e) => MessageItem.fromJson(e)).toList();
      }
    } catch (_) {
      // Fallback auf lokale JSON
      final list = json.decode(_mockMessagesJson) as List<dynamic>;
      _messages = list.map((e) => MessageItem.fromJson(e)).toList();
    } finally {
      setState(() => _isRefreshing = false);
    }
  }

  bool _isRead(String id) => _readMessageIds.contains(id);

  Future<void> _onMessageTap(MessageItem m) async {
    if (!_isRead(m.id)) {
      setState(() => _readMessageIds.add(m.id));
      await _saveReadIds();
    }
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(m.title, style: GoogleFonts.lato(fontWeight: FontWeight.w700)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(m.message, style: GoogleFonts.lato(fontSize: 16)),
            const SizedBox(height: 12),
            Text('Von: ${m.sender}',
                style: GoogleFonts.lato(fontSize: 14, color: Colors.grey)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Schließen'),
          )
        ],
      ),
    );
  }

  String _groupHeader(DateTime d) {
    // Gruppiert nach Datum (DD.MM.YYYY)
    return '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // Sortiere messages absteigend nach Datum
    _messages.sort((a, b) => b.date.compareTo(a.date));

    return Scaffold(
      appBar: AppBar(
        title: Text('Community Nachrichten', style: GoogleFonts.lato(fontWeight: FontWeight.w700)),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: _fetchMessages,
        child: _messages.isEmpty
            ? ListView(
          children: const [SizedBox(height: 300), Center(child: Text('Keine Nachrichten'))],
        )
            : ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: _messages.length,
          itemBuilder: (ctx, i) {
            final m = _messages[i];
            final showHeader = i == 0 ||
                _groupHeader(m.date) != _groupHeader(_messages[i - 1].date);
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (showHeader)
                  Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 8, top: 16),
                    child: Text(
                      _groupHeader(m.date),
                      style: GoogleFonts.lato(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey),
                    ).animate().fadeIn(duration: 300.ms),
                  ),
                Card(
                  elevation: 1,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    leading: Icon(
                      _isRead(m.id) ? Icons.mark_email_read : Icons.mark_email_unread,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    title: Text(m.title, style: GoogleFonts.lato(fontWeight: FontWeight.w600)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text(
                          m.message,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.lato(),
                        ),
                        const SizedBox(height: 8),
                        Text('Community: ${m.community}',
                            style: GoogleFonts.lato(fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                    onTap: () => _onMessageTap(m),
                  ),
                ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0),
              ],
            );
          },
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// MessageItem‑Modell
// -----------------------------------------------------------------------------
class MessageItem {
  final String id;
  final DateTime date;
  final String community;
  final String title;
  final String message;
  final String sender;

  MessageItem({
    required this.id,
    required this.date,
    required this.community,
    required this.title,
    required this.message,
    required this.sender,
  });

  factory MessageItem.fromJson(Map<String, dynamic> json) {
    return MessageItem(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? UniqueKey().toString(),
      date: DateTime.parse(json['date'] as String),
      community: json['community'] as String? ?? 'Unknown',
      title: json['title'] as String? ?? '-',
      message: json['message'] as String? ?? '-',
      sender: json['sender'] as String? ?? 'Dr. Unknown',
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'date': date.toIso8601String(),
    'community': community,
    'title': title,
    'message': message,
    'sender': sender,
  };
}