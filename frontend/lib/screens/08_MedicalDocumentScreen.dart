import 'dart:async';
import 'dart:io';
import 'package:share_plus/share_plus.dart';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:flutter_animate/flutter_animate.dart';

class MedicalDocumentsScreen extends StatefulWidget {
  const MedicalDocumentsScreen({Key? key}) : super(key: key);

  @override
  _MedicalDocumentsScreenState createState() => _MedicalDocumentsScreenState();
}

class _MedicalDocumentsScreenState extends State<MedicalDocumentsScreen> {
  // Platzhalter-Dokumente
  final List<Map<String, String>> _documents = List.generate(
    8,
        (i) =>
    {
      'name': 'Medical Document ${i + 1}',
      'url': 'https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf'
      , // Platzhalter-URL
    },
  );

  final Set<String> _downloading = {};


  Future<void> _downloadAndShare(String url, String fileName) async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/$fileName.pdf');

    // 1) Download
    final response = await http.get(Uri.parse(url)).timeout(
        const Duration(seconds: 60));
    if (response.statusCode != 200) throw Exception(
        'HTTP ${response.statusCode}');
    await file.writeAsBytes(response.bodyBytes, flush: true);

    // 2) Share-Sheet öffnen
    await Share.shareXFiles(
      [XFile(file.path)],
      text: 'Hier dein Medical Document: $fileName',
    );
  }


  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Medical Documents',
          style: GoogleFonts.lato(fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _documents.length,
        itemBuilder: (context, index) {
          final doc = _documents[index];
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
              leading: const Icon(Icons.description, size: 32),
              title: Text(
                name,
                style: GoogleFonts.lato(fontWeight: FontWeight.w600),
              ),
              subtitle: Text(
                'Beschreibung hier…',
                style: GoogleFonts.lato(),
              ),
              trailing: ElevatedButton.icon(
                onPressed: isDownloading
                    ? null
                    : () => _downloadAndShare(url, name),
                icon: isDownloading
                    ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
                    : const Icon(Icons.download),
                label: Text(
                  isDownloading ? 'Lädt…' : 'Speichern',
                  style: GoogleFonts.lato(fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(
                      vertical: 12, horizontal: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          )
              .animate()
              .fadeIn(duration: 500.ms)
              .slideX(begin: -0.2, end: 0, delay: 100.ms * index);
        },
      ),
    );
  }
}
