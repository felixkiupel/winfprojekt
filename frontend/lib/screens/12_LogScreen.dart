import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;

// BASE-URL Definition
late final String _baseUrl = (() {
  const envUrl = String.fromEnvironment('API_URL');
  if (envUrl.isNotEmpty) return envUrl;
  final host = Platform.isAndroid ? '10.0.2.2' : '127.0.0.1';
  return 'http://$host:8000';
})();

class LogScreen extends StatefulWidget {
  const LogScreen({Key? key}) : super(key: key);

  @override
  _LogScreenState createState() => _LogScreenState();
}

class _LogScreenState extends State<LogScreen> {
  List<MessageLog> _logs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchLogs();
  }

  Future<void> _fetchLogs() async {
    try {
      final resp = await http.get(Uri.parse('$_baseUrl/messages'));
      if (resp.statusCode == 200) {
        final List<dynamic> data = jsonDecode(resp.body);
        setState(() {
          _logs = data.map((j) => MessageLog.fromJson(j)).toList();
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Log', style: GoogleFonts.lato(fontWeight: FontWeight.w700)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _logs.isEmpty
          ? Center(child: Text('Keine Einträge gefunden.', style: GoogleFonts.lato()))
          : ListView.builder(
        itemCount: _logs.length,
        itemBuilder: (ctx, i) {
          final log = _logs[i];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ListTile(
              title: Text(log.title, style: GoogleFonts.lato(fontWeight: FontWeight.w700)),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(log.message, style: GoogleFonts.lato()),
                  const SizedBox(height: 4),
                  Text(
                    '${log.community} • ${DateTime.parse(log.date).toLocal()}',
                    style: GoogleFonts.lato(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Model für einen Log-Eintrag
class MessageLog {
  final String date;
  final String community;
  final String title;
  final String message;

  MessageLog({
    required this.date,
    required this.community,
    required this.title,
    required this.message,
  });

  factory MessageLog.fromJson(Map<String, dynamic> json) => MessageLog(
    date: json['date'] as String,
    community: json['community'] as String,
    title: json['title'] as String,
    message: json['message'] as String,
  );
}