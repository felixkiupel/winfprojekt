import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '04_otp_form_screen.dart';

// Conditional imports
import 'qr_scanner_stub.dart'
    if (dart.library.io) 'package:qr_code_scanner/qr_code_scanner.dart';

class QRViewScreen extends StatefulWidget {
  const QRViewScreen({Key? key}) : super(key: key);

  @override
  State<QRViewScreen> createState() => _QRViewScreenState();
}

class _QRViewScreenState extends State<QRViewScreen> {
  QRViewController? controller;
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');

  @override
  void reassemble() {
    super.reassemble();
    if (!kIsWeb && Platform.isAndroid) {
      controller?.pauseCamera();
      controller?.resumeCamera();
    }
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  void _onQRViewCreated(QRViewController qrController) {
    if (kIsWeb) return; // Do nothing on web
    
    controller = qrController;
    controller!.scannedDataStream.listen((scanData) {
      controller!.pauseCamera();
      final code = scanData.code;
      if (code != null && code.isNotEmpty) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => OtpFormScreen(code: code)),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Live QR Scanner'),
        backgroundColor: Colors.black,
      ),
      body: kIsWeb ? _buildWebFallback() : _buildQRScanner(),
    );
  }

  Widget _buildWebFallback() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.qr_code_scanner,
              size: 120,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 32),
            Text(
              'QR Scanner nicht verfügbar',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Der QR Code Scanner ist nur in der mobilen App verfügbar.',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
              },
              icon: const Icon(Icons.arrow_back),
              label: const Text('Zurück'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () {
                // Manual code entry dialog
                _showManualCodeEntry(context);
              },
              child: const Text('Code manuell eingeben'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQRScanner() {
    return Stack(
      children: [
        QRView(
          key: qrKey,
          onQRViewCreated: _onQRViewCreated,
          overlay: QrScannerOverlayShape(
            borderColor: Colors.greenAccent,
            borderRadius: 10,
            borderLength: 30,
            borderWidth: 8,
            cutOutSize: MediaQuery.of(context).size.width * 0.8,
          ),
        ),
        Positioned(
          top: 16,
          left: 16,
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Text(
              'QR-Code scannen',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }

  void _showManualCodeEntry(BuildContext context) {
    final TextEditingController codeController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Code manuell eingeben'),
        content: TextField(
          controller: codeController,
          decoration: const InputDecoration(
            labelText: 'Registrierungscode',
            hintText: 'Code hier eingeben',
            border: OutlineInputBorder(),
          ),
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
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (_) => OtpFormScreen(code: code),
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