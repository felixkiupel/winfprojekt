import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform, File;

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_cached_pdfview/flutter_cached_pdfview.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

extension ColorUtils on Color {
  /// Dunkelt die Farbe um [amount] (0.0–1.0) ab.
  Color darken([double amount = .1]) {
    final hsl = HSLColor.fromColor(this);
    final lightness = (hsl.lightness - amount).clamp(0.0, 1.0);
    return hsl.withLightness(lightness).toColor();
  }
}

class PatientDocumentsScreen extends StatefulWidget {
  const PatientDocumentsScreen({Key? key}) : super(key: key);

  @override
  _PatientDocumentsScreenState createState() => _PatientDocumentsScreenState();
}

class _PatientDocumentsScreenState extends State<PatientDocumentsScreen> {
  final _storage = const FlutterSecureStorage();
  String? _patientName;
  String? _insuranceNumber;
  bool _isLoadingProfile = true;

  // Basis-URL: via --dart-define API_URL, sonst Emulator/Simulator
  late final String _baseUrl = (() {
    const envUrl = String.fromEnvironment('API_URL');
    if (envUrl.isNotEmpty) return envUrl;
    final host = Platform.isAndroid ? '10.0.2.2' : '127.0.0.1';
    return 'http://$host:8000';
  })();

  // Drei englische Dokumente
  final List<Map<String, String>> _documents = [
    {
      'name': 'Vaccination Certificate',
      'url': 'https://henryjaustin.org/wp-content/uploads/2021/01/2020-COVID-19-shot-card-2c.pdf',
    },
    {
      'name': 'Sick Note',
      'url': 'https://arbeitgeberverbandlueneburg.de/wp-content/uploads/2021/06/Muster-AU-Erstbescheinigung.pdf',
    },
    {
      'name': 'Prescription',
      'url': 'https://www.sporlastic.de/fileadmin/user_upload/Allgemein/Digitale_Versorgung/Rezeptvorschlag_re.flex.pdf',
    },
  ];

  final Set<String> _downloading = {};
  String _searchQuery = '';

  List<Map<String, String>> get _filteredDocuments => _documents
      .where((doc) =>
      doc['name']!.toLowerCase().contains(_searchQuery.toLowerCase()))
      .toList();

  @override
  void initState() {
    super.initState();
    _fetchPatientProfile();
  }

  Future<void> _fetchPatientProfile() async {
    try {
      final token = await _storage.read(key: 'jwt');
      if (token == null) throw Exception('No token found');

      final res = await http
          .get(
        Uri.parse('$_baseUrl/patient/me'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      )
          .timeout(const Duration(seconds: 10));

      if (res.statusCode == 200) {
        final data = json.decode(res.body) as Map<String, dynamic>;
        final first = data['firstname'] as String? ?? '';
        final last = data['lastname'] as String? ?? '';
        final medId = data['med_id'] as String? ?? 'N/A';

        setState(() {
          _patientName = '$first $last'.trim();
          _insuranceNumber = medId;
          _isLoadingProfile = false;
        });
      } else {
        throw Exception('Failed to load profile (${res.statusCode})');
      }
    } catch (_) {
      setState(() {
        _patientName = 'Unknown Patient';
        _insuranceNumber = 'N/A';
        _isLoadingProfile = false;
      });
    }
  }

  Future<void> _downloadAndShare(String url, String fileName) async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/$fileName.pdf');

    final response =
    await http.get(Uri.parse(url)).timeout(const Duration(seconds: 60));
    if (response.statusCode != 200) {
      throw Exception('HTTP ${response.statusCode}');
    }

    await file.writeAsBytes(response.bodyBytes, flush: true);

    await Share.shareXFiles(
      [XFile(file.path)],
      text: 'Here is your document: $fileName',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Patient Documents',
          style: GoogleFonts.lato(fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Moderner Patienten-Header ──
          Card(
            elevation: 1,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Container(
              height: 80,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  // Farbstreifen
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

                  // Avatar oder Spinner
                  if (_isLoadingProfile)
                    const SizedBox(
                      width: 48,
                      height: 48,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  else
                    CircleAvatar(
                      radius: 24,
                      backgroundColor:
                      Theme.of(context).colorScheme.primaryContainer,
                      child: Text(
                        (_patientName ?? '')
                            .split(' ')
                            .map((e) => e.isEmpty ? '' : e[0])
                            .take(2)
                            .join(),
                        style: GoogleFonts.lato(
                          color:
                          Theme.of(context).colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  const SizedBox(width: 16),

                  // Name & Versicherungsnummer oder Loader
                  Expanded(
                    child: _isLoadingProfile
                        ? const Center(child: Text('Loading profile…'))
                        : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _patientName ?? '',
                          style: GoogleFonts.lato(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color:
                            Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Insurance Number: ${_insuranceNumber ?? ''}',
                          style: GoogleFonts.lato(
                            fontSize: 14,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: 16),
                    child: Icon(
                      Icons.medical_services_outlined,
                      size: 28,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Suchleiste ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search documents...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (val) => setState(() => _searchQuery = val),
            ),
          ),

          // ── Dokumentliste ──
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _filteredDocuments.length,
              itemBuilder: (ctx, i) {
                final doc = _filteredDocuments[i];
                final name = doc['name']!;
                final url = doc['url']!;
                final isDownloading = _downloading.contains(name);

                return Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  child: ListTile(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            DocumentPreviewScreen(url: url, name: name),
                      ),
                    ),
                    leading:
                    const Icon(Icons.picture_as_pdf, size: 32),
                    title: Text(
                      name,
                      style:
                      GoogleFonts.lato(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      'Tap to preview',
                      style: GoogleFonts.lato(),
                    ),
                    trailing: ElevatedButton.icon(
                      onPressed: isDownloading
                          ? null
                          : () {
                        setState(() => _downloading.add(name));
                        _downloadAndShare(url, name).whenComplete(() {
                          setState(
                                  () => _downloading.remove(name));
                        });
                      },
                      icon: isDownloading
                          ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white),
                      )
                          : const Icon(Icons.download),
                      label: Text(
                        isDownloading ? 'Loading…' : 'Save',
                        style: GoogleFonts.lato(
                            fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        padding:
                        const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                )
                    .animate()
                    .fadeIn(duration: 500.ms)
                    .slideX(begin: -0.2, end: 0, delay: 100.ms);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class DocumentPreviewScreen extends StatefulWidget {
  final String url;
  final String name;

  const DocumentPreviewScreen({
    Key? key,
    required this.url,
    required this.name,
  }) : super(key: key);

  @override
  _DocumentPreviewScreenState createState() =>
      _DocumentPreviewScreenState();
}

class _DocumentPreviewScreenState extends State<DocumentPreviewScreen> {
  double _progress = 0;
  File? _file;

  @override
  void initState() {
    super.initState();
    _startDownload();
  }

  Future<void> _startDownload() async {
    final dir = await getApplicationDocumentsDirectory();
    final savePath = '${dir.path}/${widget.name}.pdf';
    final dio = Dio();

    await dio.download(
      widget.url,
      savePath,
      onReceiveProgress: (received, total) {
        if (total != -1) {
          setState(() => _progress = received / total);
        }
      },
    );

    setState(() => _file = File(savePath));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.name)),
      body: _file == null
          ? Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(value: _progress),
            const SizedBox(height: 12),
            Text('${(_progress * 100).toStringAsFixed(0)}% loaded'),
          ],
        ),
      )
          : PDF().fromPath(_file!.path),
    );
  }
}
