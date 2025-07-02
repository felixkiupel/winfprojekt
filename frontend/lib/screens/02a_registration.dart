import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '04_otp_form_screen.dart';
import '03_qr_view_scan.dart';
import '02b_login.dart';
import 'package:image_picker/image_picker.dart';

// Conditional import for QR code tools
import 'qr_scanner_stub.dart'
    if (dart.library.io) 'package:qr_code_tools/qr_code_tools.dart';

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({Key? key}) : super(key: key);

  @override
  _RegistrationScreenState createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  Future<void> pickFromGallery(BuildContext context) async {
    if (kIsWeb) {
      // Show not available on web
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('QR-Import ist nur in der mobilen App verfügbar'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      try {
        final code = await QrCodeToolsPlugin.decodeFrom(image.path);
        if (code != null && code.isNotEmpty) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => OtpFormScreen(code: code),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Kein QR-Code erkannt. Bitte Bild mit QR-Code auswählen.'),
            ),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('QR-Decodierung fehlgeschlagen.')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Keine Bildauswahl getroffen.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Registration')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Show info for web users
              if (kIsWeb) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.only(bottom: 24),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info, color: Colors.blue.shade700),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'QR-Scanner ist nur in der mobilen App verfügbar',
                          style: GoogleFonts.lato(
                            color: Colors.blue.shade700,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.camera_alt, color: Colors.white),
                  label: Text(
                    kIsWeb ? 'QR Scanner (nicht verfügbar)' : 'Scan QR',
                    style: GoogleFonts.lato(color: Colors.white),
                  ),
                  onPressed: kIsWeb
                      ? null
                      : () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const QRViewScreen()),
                          ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kIsWeb ? Colors.grey : null,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.photo, color: Colors.white),
                  label: Text(
                    kIsWeb ? 'QR Import (nicht verfügbar)' : 'Import QR from Gallery',
                    style: GoogleFonts.lato(color: Colors.white),
                  ),
                  onPressed: kIsWeb ? null : () => pickFromGallery(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kIsWeb ? Colors.grey : null,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              // Manual code entry option for web
              if (kIsWeb) ...[
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.keyboard),
                    label: Text(
                      'Code manuell eingeben',
                      style: GoogleFonts.lato(),
                    ),
                    onPressed: () => _showManualCodeEntry(context),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                  ),
                  child: Text('Sign In', style: GoogleFonts.lato(color: Colors.black87)),
                ),
              ),
              const SizedBox(height: 24),
              
              Center(
                child: TextButton(
                  onPressed: () {
                    // Support-Logik
                  },
                  child: const Text('Need help? Contact support'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showManualCodeEntry(BuildContext context) {
    final TextEditingController codeController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Registrierungscode eingeben',
          style: GoogleFonts.lato(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Geben Sie den Registrierungscode ein, den Sie erhalten haben:',
              style: GoogleFonts.lato(fontSize: 14),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: codeController,
              decoration: const InputDecoration(
                labelText: 'Registrierungscode',
                hintText: 'z.B. ABC123XYZ',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.vpn_key),
              ),
              textCapitalization: TextCapitalization.characters,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Abbrechen'),
          ),
          ElevatedButton(
            onPressed: () {
              final code = codeController.text.trim();
              if (code.isNotEmpty) {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => OtpFormScreen(code: code),
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Bitte geben Sie einen Code ein'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Weiter'),
          ),
        ],
      ),
    );
  }
}