import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:medapp/main.dart';

extension ColorUtils on Color {
  /// Dunkelt die Farbe um [amount] (0.0–1.0) ab.
  Color darken([double amount = .1]) {
    final hsl = HSLColor.fromColor(this);
    final lightness = (hsl.lightness - amount).clamp(0.0, 1.0);
    return hsl.withLightness(lightness).toColor();
  }
}

class CommunitySelectionScreen extends StatefulWidget {
  const CommunitySelectionScreen({Key? key}) : super(key: key);

  @override
  _CommunitySelectionScreenState createState() => _CommunitySelectionScreenState();
}

class _CommunitySelectionScreenState extends State<CommunitySelectionScreen> {
  final _storage = const FlutterSecureStorage();
  String? _userName;
  List<String> _userCommunities = [];
  List<Map<String, String>> _allCommunities = [];

  /// Mehrfachauswahl per Häkchen
  Set<String> _selectedCommunities = {};
  bool _isLoading = true;
  bool _isSaving = false;

  // Fallback-Daten (communitys_fallback.json)
  static const List<Map<String, String>> _fallbackCommunities = [
    {"name": "Flutter Enthusiasts", "description": "A community for Flutter devs to exchange tips and best practices."},
    {"name": "Open Source Contributors", "description": "Join forces on open-source Projekte und teile deinen Code."},
    {"name": "Tech Talk", "description": "Diskutiere die neuesten Trends aus IT und Innovation."},
  ];

  // Basis-URL: via --dart-define API_URL, sonst Emulator/Simulator
  late final String _baseUrl = (() {
    const envUrl = String.fromEnvironment('API_URL');
    if (envUrl.isNotEmpty) return envUrl;
    final host = Platform.isAndroid ? '10.0.2.2' : '127.0.0.1';
    return 'http://$host:8000';
  })();

  @override
  void initState() {
    super.initState();
    _fetchCommunities();
  }

  Future<void> _fetchCommunities() async {
    setState(() => _isLoading = true);
    try {
      final token = await _storage.read(key: 'jwt');
      if (token == null) throw Exception('Kein Token gefunden');

      // 1) User-Profil für Namen laden
      final profileRes = await http
          .get(
        Uri.parse('$_baseUrl/patient/me'),
        headers: {'Authorization': 'Bearer $token', 'Accept': 'application/json'},
      )
          .timeout(const Duration(seconds: 10));
      if (profileRes.statusCode == 200) {
        final data = json.decode(profileRes.body) as Map<String, dynamic>;
        final first = data['firstname'] as String? ?? '';
        final last = data['lastname'] as String? ?? '';
        _userName = '$first $last'.trim();
      } else {
        _userName = 'Unknown User';
      }

      // 2) Zugehörige Communities laden
      final meRes = await http
          .get(
        Uri.parse('$_baseUrl/communitys/me'),
        headers: {'Authorization': 'Bearer $token', 'Accept': 'application/json'},
      )
          .timeout(const Duration(seconds: 10));
      if (meRes.statusCode == 200) {
        final list = json.decode(meRes.body) as List<dynamic>;
        _userCommunities = list.cast<String>();
        _selectedCommunities = Set.from(_userCommunities);
      }

      // 3) Alle Communities laden
      final allRes = await http
          .get(
        Uri.parse('$_baseUrl/communitys/all'),
        headers: {'Authorization': 'Bearer $token', 'Accept': 'application/json'},
      )
          .timeout(const Duration(seconds: 10));
      if (allRes.statusCode == 200) {
        final list = json.decode(allRes.body) as List<dynamic>;
        _allCommunities = list
            .map((e) => {
          'name': e['name'] as String,
          'description': e['description'] as String,
        })
            .toList();
      }

      // Fallback, falls API keine Daten liefert
      if (_allCommunities.isEmpty) {
        _allCommunities = List.from(_fallbackCommunities);
      }
    } catch (e) {
      // Fehler: nutze Fallback-Daten
      _allCommunities = List.from(_fallbackCommunities);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveCommunities() async {
    if (_selectedCommunities.isEmpty) return;
    setState(() => _isSaving = true);

    try {
      final token = await _storage.read(key: 'jwt');
      if (token == null) throw Exception('Kein Token gefunden');

      final res = await http.put(
        Uri.parse('$_baseUrl/communitys/me'),
        headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
        body: jsonEncode({'communities': _selectedCommunities.toList()}),
      ).timeout(const Duration(seconds: 10));

      if (res.statusCode == 200 || res.statusCode == 204) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Communities erfolgreich gesetzt')),);
        await _fetchCommunities();
      } else {
        throw Exception('Speichern fehlgeschlagen (\${res.statusCode})');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fehler: \$e')));
    } finally {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Community Auswahl', style: GoogleFonts.lato(fontWeight: FontWeight.w700)),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Header wie Patient ──
          Card(
            elevation: 1,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Container(
              height: 80,
              decoration: BoxDecoration(
                color: kMedicalSurface,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(children: [
                Container(
                  width: 4,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      bottomLeft: Radius.circular(16),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                CircleAvatar(
                  radius: 24,
                  backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                  child: Text(
                    (_userName ?? '')
                        .split(' ')
                        .map((e) => e.isEmpty ? '' : e[0])
                        .take(2)
                        .join(),
                    style: GoogleFonts.lato(
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(_userName ?? '', style: GoogleFonts.lato(fontSize: 18, fontWeight: FontWeight.w700, color: Theme.of(context).colorScheme.onSurface)),
                    const SizedBox(height: 4),
                    Text("Deine Communities: ${_userCommunities.join(', ')}",
                      style: GoogleFonts.lato(fontSize: 14, color: Theme.of(context).colorScheme.onSurfaceVariant),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                )),
                Padding(padding: const EdgeInsets.only(right: 16), child: Icon(Icons.group_outlined, size: 28, color: Theme.of(context).colorScheme.primary)),
              ]),
            ),
          ).animate().fadeIn(duration: 500.ms).slideX(begin: -0.2, end: 0),

          const SizedBox(height: 8),

          Expanded(child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ListView(children: _allCommunities.map((c) {
              final name = c['name']!;
              final desc = c['description']!;
              final checked = _selectedCommunities.contains(name);
              return CheckboxListTile(
                value: checked,
                activeColor: Colors.black,
                checkColor: kMedicalSecondaryContainer,
                title: Text(name, style: GoogleFonts.lato(fontWeight: FontWeight.w600)),
                subtitle: Text(desc, style: GoogleFonts.lato()),
                controlAffinity: ListTileControlAffinity.leading,
                onChanged: (bool? val) {
                  setState(() {
                    if (val == true) _selectedCommunities.add(name);
                    else _selectedCommunities.remove(name);
                  });
                },
              ).animate().fadeIn(duration: 300.ms);
            }).toList()),
          )),

          const SizedBox(height: 8),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 50),
            child: ElevatedButton.icon(
              onPressed: _isSaving ? null : _saveCommunities,
              icon: _isSaving
                  ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.save),
              label: Text(_isSaving ? 'Save…' : 'SAVE COMMUNITYS', style: GoogleFonts.lato(fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.black, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            ).animate().fadeIn(duration: 500.ms, delay: 200.ms),
          ),
        ],
      ),
    );
  }
}
