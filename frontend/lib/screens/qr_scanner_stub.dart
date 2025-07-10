// lib/services/qr_scanner_stub.dart

import 'package:flutter/material.dart';
import 'dart:async';

// Stub implementation for web - includes all methods used in the real implementation
class QRViewController {
  // Add all methods that are used in the actual implementation
  void pauseCamera() {
    // No-op for web
  }
  
  void resumeCamera() {
    // No-op for web
  }
  
  void dispose() {
    // No-op for web
  }
  
  // Add the stream that's being accessed
  Stream<Barcode> get scannedDataStream => Stream<Barcode>.empty();
}

class Barcode {
  final String? code;
  const Barcode({this.code});
}

class QRView extends StatelessWidget {
  final Function(QRViewController) onQRViewCreated;
  final QrScannerOverlayShape? overlay;
  final GlobalKey? key;

  const QRView({
    required this.onQRViewCreated,
    this.overlay,
    this.key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Call the callback with a stub controller
    WidgetsBinding.instance.addPostFrameCallback((_) {
      onQRViewCreated(QRViewController());
    });
    
    return Container(
      color: Colors.black,
      child: Center(
        child: Container(
          padding: EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.grey.shade900,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.qr_code_scanner, size: 100, color: Colors.grey),
              SizedBox(height: 20),
              Text(
                'QR Scanner nicht verfügbar auf Web',
                style: TextStyle(fontSize: 18, color: Colors.white),
              ),
              SizedBox(height: 10),
              Text(
                'Bitte nutzen Sie die mobile App',
                style: TextStyle(fontSize: 14, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class QrScannerOverlayShape {
  final Color borderColor;
  final double borderRadius;
  final double borderLength;
  final double borderWidth;
  final double cutOutSize;

  const QrScannerOverlayShape({
    this.borderColor = Colors.white,
    this.borderRadius = 0,
    this.borderLength = 40,
    this.borderWidth = 10,
    this.cutOutSize = 250,
  });
}

class QrCodeToolsPlugin {
  static Future<String?> decodeFrom(String path) async {
    // Stub implementation for web - always returns null
    await Future.delayed(Duration(milliseconds: 100)); // Simulate async operation
    return null;
  }
}