import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '14_DirectChatScreen.dart'; // ggf. anpassen, falls Pfad anders

/// ----------------------------------------------------------------------------
/// DirectChatScreen
/// ----------------------------------------------------------------------------
/// Eins-zu-eins-Chat zwischen Arzt <-> Patient mit Read/Unread-Status.
/// ----------------------------------------------------------------------------
class DirectChatScreen extends StatefulWidget {
  /// ID des Chat-Partners (Arzt oder Patient)
  final String partnerId;
  final String partnerName;

  const DirectChatScreen({
    Key? key,
    required this.partnerId,
    required this.partnerName,
  }) : super(key: key);

  @override
  State<DirectChatScreen> createState() => _DirectChatScreenState();
}

class _DirectChatScreenState extends State<DirectChatScreen> {
  final _secureStorage = const FlutterSecureStorage();
  final TextEditingController _textCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();

  List<ChatMessage> _messages = [];
  late Timer _pollTimer;
  bool _isSending = false;
  bool _isLoading = true;

  String? _myId;

  // Basis-URL analog zu anderen Screens
  late final String _baseUrl = (() {
    const envUrl = String.fromEnvironment('API_URL');
    if (envUrl.isNotEmpty) return envUrl;
    final host = Platform.isAndroid ? '10.0.2.2' : '127.0.0.1';
    return 'http://$host:8000';
  })();

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await _fetchProfile();
    // Beim ersten Öffnen: alle bisherigen als gelesen markieren
    await _markAsRead();
    await _fetchMessages();

    // Poll alle 5 s nach neuen Nachrichten
    _pollTimer = Timer.periodic(
      const Duration(seconds: 5),
          (_) async {
        await _markAsRead();
        await _fetchMessages();
      },
    );
  }

  Future<void> _fetchProfile() async {
    try {
      final token = await _secureStorage.read(key: 'jwt');
      if (token == null) throw Exception('Kein Token');

      final res = await http.get(
        Uri.parse('$_baseUrl/patient/me'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));

      if (res.statusCode == 200) {
        final data = json.decode(res.body) as Map<String, dynamic>;
        _myId = data['med_id']?.toString() ?? data['id']?.toString();
      }
    } catch (_) {
      // Fallback: bleibt null → ggf. Mock-Daten
    }
  }

  Future<void> _markAsRead() async {
    if (_myId == null) return;
    try {
      final token = await _secureStorage.read(key: 'jwt');
      if (token == null) return;

      await http.patch(
        Uri.parse('$_baseUrl/dm/${widget.partnerId}/read'),
        headers: {'Authorization': 'Bearer $token'},
      );
    } catch (_) {
      // Ignorieren
    }
  }

  Future<void> _fetchMessages() async {
    if (_myId == null) {
      // Fallback auf Dummy
      setState(() {
        _messages = [];
        _isLoading = false;
      });
      _scrollToBottom();
      return;
    }

    try {
      final token = await _secureStorage.read(key: 'jwt');
      if (token == null) throw Exception('Kein Token');

      final uri = Uri.parse('$_baseUrl/dm/${widget.partnerId}/messages');
      final res = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));

      if (res.statusCode == 200) {
        final list = json.decode(res.body) as List<dynamic>;
        setState(() {
          _messages = list.map((e) => ChatMessage.fromJson(e)).toList();
          _isLoading = false;
        });
        _scrollToBottom();
      }
    } catch (_) {
      // Fallback auf Dummy
      setState(() {
        _messages = [];
        _isLoading = false;
      });
      _scrollToBottom();
    }
  }

  Future<void> _sendMessage() async {
    final text = _textCtrl.text.trim();
    if (text.isEmpty || _isSending) return;

    setState(() => _isSending = true);

    try {
      final token = await _secureStorage.read(key: 'jwt');
      if (token == null) throw Exception('Kein Token');

      final uri = Uri.parse('$_baseUrl/dm/${widget.partnerId}/messages');
      final payload = jsonEncode({
        'date': DateTime.now().toIso8601String(),
        'text': text,
      });
      final res = await http.post(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: payload,
      ).timeout(const Duration(seconds: 10));

      if (res.statusCode == 201 || res.statusCode == 200) {
        final data = json.decode(res.body) as Map<String, dynamic>;
        final msg = ChatMessage.fromJson(data);
        setState(() {
          _messages.add(msg);
          _textCtrl.clear();
        });
        _scrollToBottom();
      }
    } catch (_) {
      // Optional: Fehler-SnackBar
    } finally {
      setState(() => _isSending = false);
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent + 60,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _pollTimer.cancel();
    _textCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  // ---------------------------- UI -----------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.partnerName,
            style: GoogleFonts.lato(fontWeight: FontWeight.w700)),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollCtrl,
              padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
              itemCount: _messages.length,
              itemBuilder: (ctx, i) {
                final m = _messages[i];
                final isMe = m.senderId == _myId;
                return Align(
                  alignment:
                  isMe ? Alignment.centerRight : Alignment.centerLeft,
                  child:
                  ChatBubble(message: m, isMe: isMe),
                )
                    .animate()
                    .fadeIn(duration: 300.ms)
                    .slideY(begin: 0.1, end: 0);
              },
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding:
            const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: TextField(
              controller: _textCtrl,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                hintText: 'Nachricht eingeben…',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 10),
                suffixIcon: _isSending
                    ? Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2),
                  ),
                )
                    : IconButton(
                  icon: const Icon(Icons.send_rounded),
                  onPressed: _sendMessage,
                ),
              ),
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
        ],
      ),
    );
  }
}

/// -----------------------------------------------------------------------------
/// ChatMessage-Modell mit Read-Status
/// -----------------------------------------------------------------------------
class ChatMessage {
  final String id;
  final DateTime date;
  final String senderId;
  final String text;
  final bool read;

  ChatMessage({
    required this.id,
    required this.date,
    required this.senderId,
    required this.text,
    required this.read,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
    id: json['id']?.toString() ??
        json['_id']?.toString() ??
        UniqueKey().toString(),
    date: DateTime.parse(json['date'] as String),
    senderId: json['senderId'] as String? ?? 'unknown',
    text: json['text'] as String? ?? '',
    read: json['read'] as bool? ?? false,
  );
  Map<String, dynamic> toJson() => {
    'id': id,
    'date': date.toIso8601String(),
    'senderId': senderId,
    'text': text,
    'read': read,
  };
}

/// -----------------------------------------------------------------------------
/// Bubble-Widget mit Read/Unread-Icon
/// -----------------------------------------------------------------------------
class ChatBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isMe;

  const ChatBubble({Key? key, required this.message, required this.isMe})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bg = isMe
        ? Theme.of(context).colorScheme.primaryContainer
        : Theme.of(context).colorScheme.surfaceVariant;
    final fg = isMe
        ? Theme.of(context).colorScheme.onPrimaryContainer
        : Theme.of(context).colorScheme.onSurfaceVariant;

    return Stack(
      children: [
        Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.7),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(16),
              topRight: const Radius.circular(16),
              bottomLeft: Radius.circular(isMe ? 16 : 0),
              bottomRight: Radius.circular(isMe ? 0 : 16),
            ),
          ),
          child: Text(message.text,
              style: GoogleFonts.lato(color: fg)),
        ),
        if (isMe)
          Positioned(
            bottom: 2,
            right: 6,
            child: Icon(
              message.read ? Icons.done_all_rounded : Icons.done_rounded,
              size: 16,
            ),
          ),
      ],
    );
  }
}
