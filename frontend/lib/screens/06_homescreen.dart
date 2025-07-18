import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:timeago/timeago.dart' as timeago;

import '02b_login.dart';
import '10_CommunityMenu.dart';
import '12_ReceiveMessageCommunity.dart';
import 'fragments/a_sidebar.dart';

class HomeScreenTemplate extends StatefulWidget {
  const HomeScreenTemplate({super.key});

  @override
  _HomeScreenTemplateState createState() => _HomeScreenTemplateState();
}

class _HomeScreenTemplateState extends State<HomeScreenTemplate> {
  final _storage = const FlutterSecureStorage();
  int _totalUnread = 0;

  String? _firstName;
  bool _hasCommunities = true;
  List<MessageItem> _communityMessages = [];

  late final String _baseUrl = (() {
    const envUrl = String.fromEnvironment('API_URL');
    if (envUrl.isNotEmpty) return envUrl;
    final host = Platform.isAndroid ? '10.0.2.2' : '127.0.0.1';
    return 'http://$host:8000';
  })();

  @override
  void initState() {
    super.initState();
    _checkAuth();
    _loadPatientProfile();
    _loadUnreadCount();
    _loadCommunitiesAndMessages();
  }

  Future<void> _checkAuth() async {
    final token = await _storage.read(key: 'jwt');
    if (token == null) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  Future<void> _loadPatientProfile() async {
    try {
      final token = await _storage.read(key: 'jwt');
      if (token == null) return;
      final res = await http.get(
        Uri.parse('$_baseUrl/patient/me'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) {
        final data = json.decode(res.body) as Map<String, dynamic>;
        setState(() => _firstName = data['firstname'] as String?);
      }
    } catch (_) {}
  }

  Future<void> _loadUnreadCount() async {
    try {
      final token = await _storage.read(key: 'jwt');
      if (token == null) return;
      final res = await http.get(
        Uri.parse('$_baseUrl/dm/partners'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) {
        final list = json.decode(res.body) as List<dynamic>;
        int sum = 0;
        for (var e in list) {
          sum += (e['unreadCount'] as int?) ?? 0;
        }
        setState(() => _totalUnread = sum);
      }
    } catch (_) {}
  }

  Future<void> _loadCommunitiesAndMessages() async {
    final token = await _storage.read(key: 'jwt');
    if (token == null) return;

    final commRes = await http.get(
      Uri.parse('$_baseUrl/communitys/me'),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    ).timeout(const Duration(seconds: 10));

    if (commRes.statusCode != 200) {
      setState(() => _hasCommunities = false);
      return;
    }
    final comms = (json.decode(commRes.body) as List).cast<String>();
    if (comms.isEmpty) {
      setState(() => _hasCommunities = false);
      return;
    }

    final uri = Uri.parse(
      '$_baseUrl/messages?communities=${Uri.encodeComponent(comms.join(','))}',
    );
    final msgRes = await http.get(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    ).timeout(const Duration(seconds: 10));

    if (msgRes.statusCode == 200) {
      final list = json.decode(msgRes.body) as List<dynamic>;
      final fetched = list
          .map((e) => MessageItem.fromJson(e as Map<String, dynamic>))
          .toList();
      setState(() => _communityMessages = fetched.take(3).toList());
    }
  }

  Future<void> _logout() async {
    await _storage.delete(key: 'jwt');
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
    );
  }

  String _formatRelativeTime(DateTime date) =>
      timeago.format(date, locale: 'de');

  @override
  Widget build(BuildContext context) {
    final welcomeText = _firstName != null
        ? 'Welcome back, $_firstName!'
        : 'Welcome back!';
    return Scaffold(
      onDrawerChanged: (isOpen) {
        if (isOpen) _loadUnreadCount();
      },
      appBar: AppBar(
        title: Text(
          'Home',
          style: GoogleFonts.lato(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Colors.black,
        elevation: 4,
        centerTitle: true,
      ),
      drawer: Sidebar(
        totalUnread: _totalUnread,
        loadUnreadCount: _loadUnreadCount,
        logout: _logout,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              welcomeText,
              style: GoogleFonts.lato(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _FeatureCard(
                  icon: Icons.medical_services,
                  label: 'Community Moderation',
                  color: Colors.green.shade600,
                  onTap: () {},
                ),
                _FeatureCard(
                  icon: Icons.analytics,
                  label: 'Statistics',
                  color: Colors.blue.shade600,
                  onTap: () {},
                ),
                _FeatureCard(
                  icon: Icons.notifications,
                  label: 'Notifications',
                  color: Colors.red.shade600,
                  onTap: () {},
                ),
              ],
            ),
            const SizedBox(height: 32),
            Text(
              'Recent Community Activities',
              style: GoogleFonts.lato(
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            if (!_hasCommunities)
              Center(
                child: Text(
                  'Du bist noch in keiner Community.',
                  style:
                  GoogleFonts.lato(fontSize: 16, color: Colors.black54),
                ),
              )
            else if (_communityMessages.isEmpty)
              const Center(child: CircularProgressIndicator())
            else
              ..._communityMessages.map(
                    (m) => _ActivityTile(
                  title: m.title,
                  subtitle: _formatRelativeTime(m.date),
                  icon: Icons.forum,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const CommunityFeedScreen(),
                      ),
                    );
                  },
                ),
              ),
            const SizedBox(height: 32),
            OutlinedButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const CommunitySelectionScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.add),
              label: Text(
                'Select Communities',
                style: GoogleFonts.lato(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.black),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _FeatureCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 100,
          margin: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 40, color: Colors.white),
              const SizedBox(height: 8),
              Text(
                label,
                style: GoogleFonts.lato(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActivityTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  const _ActivityTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: Colors.black54),
      title: Text(
        title,
        style:
        GoogleFonts.lato(fontSize: 16, fontWeight: FontWeight.w600),
      ),
      subtitle:
      Text(subtitle, style: GoogleFonts.lato(color: Colors.black54)),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      contentPadding:
      const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
      onTap: onTap,
    );
  }
}
