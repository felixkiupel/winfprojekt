import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '04_otp_form_screen.dart';
import '03_qr_view_scan.dart';
import '02b_login.dart';
import 'package:qr_code_tools/qr_code_tools.dart';
import 'package:image_picker/image_picker.dart';

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({Key? key}) : super(key: key);

  @override
  _RegistrationScreenState createState() => _RegistrationScreenState();
}

Future<void> pickFromGallery(BuildContext context) async {
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
        // Kein QR-Code gefunden oder leerer Inhalt
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Kein QR-Code erkannt. Bitte Bild mit QR-Code auswählen.')),
        );
      }
    } catch (e) {
      // Fehler bei der Decodierung
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('QR-Decodierung fehlgeschlagen.')),
      );
    }
  } else {
    // Nutzer hat kein Bild ausgewählt (Picker abgebrochen)
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Keine Bildauswahl getroffen.')),
    );
  }
}

class _RegistrationScreenState extends State<RegistrationScreen> {
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
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.camera_alt, color: Colors.white),
                  label: Text('Scan QR', style: GoogleFonts.lato(color: Colors.white)),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const QRViewScreen()),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.photo, color: Colors.white),
                  label: Text('Import QR from Gallery', style: GoogleFonts.lato(color: Colors.white)),
                  onPressed: () => pickFromGallery(context),
                ),
              ),
              const SizedBox(height: 16),
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
}
