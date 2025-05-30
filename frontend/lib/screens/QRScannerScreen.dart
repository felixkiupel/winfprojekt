import 'package:flutter/material.dart';

class QRScannerScreen extends StatelessWidget {
  const QRScannerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Account', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.black,
      ),
      backgroundColor: const Color(0xFFF3FFF5),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(
              Icons.qr_code_scanner,
              size: 100,
              color: Colors.black87,
            ),
            SizedBox(height: 20),
            Text(
              'Scan Your QR',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text(
              'Hold your camera over the QR code to register',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}