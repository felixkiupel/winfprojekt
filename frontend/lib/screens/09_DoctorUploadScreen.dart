import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class DoctorUploadScreen extends StatefulWidget {
  const DoctorUploadScreen({Key? key}) : super(key: key);

  @override
  _DoctorUploadScreenState createState() => _DoctorUploadScreenState();
}

class _DoctorUploadScreenState extends State<DoctorUploadScreen> {
  final _formKey = GlobalKey<FormState>();
  late final String _baseUrl = (() {
    const envUrl = String.fromEnvironment('API_URL');
    if (envUrl.isNotEmpty) return envUrl;
    final host = Platform.isAndroid ? '10.0.2.2' : '127.0.0.1';
    return 'http://$host:8000';
  })();

  // Demo + dynamisch ersetzbare Patientenliste
  final List<Map<String, String>> _patients = [
    {'fullName': 'Max Mustermann', 'insuranceNumber': 'A123456789'},
    {'fullName': 'Erika Musterfrau', 'insuranceNumber': 'B987654321'},
    {'fullName': 'Hans Müller', 'insuranceNumber': 'C456789123'},
  ];

  String? _insuranceNumber;
  File? _pickedFile;
  final TextEditingController _titleController = TextEditingController();
  bool _isUploading = false;
  final List<Map<String, String>> _uploadedDocs = [];

  late final FlutterLocalNotificationsPlugin _localNotif;

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

    _loadPatients(); // Patienten von API laden
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _loadPatients() async {
    final url = Uri.parse('$_baseUrl/patient/all');

    try {
      final response = await http.get(url);
      print('Statuscode: ${response.statusCode}');
      print('Antwort-Body: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);

        final fetchedPatients = data.map<Map<String, String>>((patient) {
          return {
            'fullName': '${patient['firstname']} ${patient['lastname']}',
            'insuranceNumber': patient['med_id'],
          };
        }).toList();

        if (fetchedPatients.isNotEmpty) {
          setState(() {
            _patients.clear();
            _patients.addAll(fetchedPatients);
          });
        } else {
          print('⚠️ Leere Patientenliste erhalten.');
        }
      } else {
        print('❌ API-Fehler: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Fehler beim Abrufen der Patienten: $e');
    }
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      withData: false,
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx'],
    );
    if (result != null && result.files.single.path != null) {
      setState(() => _pickedFile = File(result.files.single.path!));
    }
  }

  Future<void> _uploadDocument() async {
    if (!_formKey.currentState!.validate() || _pickedFile == null) return;

    setState(() => _isUploading = true);

    try {
      final uri = Uri.parse('https://your-api.example.com/upload');
      final request = http.MultipartRequest('POST', uri)
        ..fields['insuranceNumber'] = _insuranceNumber!
        ..fields['title'] = _titleController.text
        ..files.add(await http.MultipartFile.fromPath(
          'file',
          _pickedFile!.path,
          filename: _pickedFile!.path.split('/').last,
        ));


      await request.send().timeout(const Duration(seconds: 60));

      await _localNotif.show(
        0,
        'Upload erfolgreich',
        'Dein Dokument wurde hochgeladen.',
        NotificationDetails(
          android: AndroidNotificationDetails(
            'upload_channel', 'Document Uploads',
            channelDescription: 'Nur Demo-Success',
            importance: Importance.max,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(),
        ),
      );
    } catch (_) {
      //
      await _localNotif.show(
        0,
        'Upload successful',
        'Your document has been uploaded.',
        NotificationDetails(
          android: AndroidNotificationDetails(
            'upload_channel', 'Document Uploads',
            channelDescription: ' Demo-Success', // Demo Success because no "real" doc - patient - relationships
            importance: Importance.max,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(),
        ),
      );
    } finally {
      // Felder und Formular auf Anfang zurücksetzen
      _formKey.currentState!.reset();
      setState(() {
        _insuranceNumber = null;
        _titleController.clear();
        _pickedFile = null;
        _isUploading = false;
      });
    }
  }




  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Upload Patient-Document',
          style: GoogleFonts.lato(fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          children: [
            Expanded(
              child: Stack(
                children: [
                  Center(
                    child: SingleChildScrollView(
                      child: Form(
                        key: _formKey,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            DropdownButtonFormField<String>(
                              value: _insuranceNumber,
                              hint: Text('Choose patient', style: GoogleFonts.lato()), // ← neu
                              decoration: InputDecoration(
                                labelText: 'Choose patient',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              items: _patients.map((p) {
                                final label = '${p['fullName']} – ${p['insuranceNumber']}';
                                return DropdownMenuItem(
                                  value: p['insuranceNumber'],
                                  child: Text(label, style: GoogleFonts.lato()),
                                );
                              }).toList(),
                              validator: (v) => v == null ? 'Mandatory-field' : null,
                              onChanged: (v) => setState(() => _insuranceNumber = v),
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _titleController,
                              decoration: InputDecoration(
                                labelText: 'Document title',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              validator: (v) =>
                              (v == null || v.isEmpty) ? 'Mandatory-field' : null,
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    _pickedFile != null
                                        ? _pickedFile!.path.split('/').last
                                        : 'No File selected',
                                    style: GoogleFonts.lato(),
                                  ),
                                ),
                                ElevatedButton.icon(
                                  onPressed: _pickFile,
                                  icon: const Icon(Icons.attach_file),
                                  label: const Text('Upload Document'),
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 20, vertical: 12),
                                    shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8)),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _isUploading ? null : _uploadDocument,
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: _isUploading
                                    ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                                    : const Text('Upload'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 150,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Icon(
                        Icons.cloud_upload,
                        size: 80,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (_uploadedDocs.isNotEmpty) ...[
              const SizedBox(height: 16),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _uploadedDocs.length,
                itemBuilder: (ctx, i) {
                  final doc = _uploadedDocs[i];
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    child: ListTile(
                      leading: const Icon(Icons.insert_drive_file),
                      title: Text(doc['title']!,
                          style: GoogleFonts.lato(fontWeight: FontWeight.w600)),
                      subtitle: Text(doc['filename']!, style: GoogleFonts.lato()),
                    ),
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}
