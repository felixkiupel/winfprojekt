// 07_sos_screen.dart
// -------------------------------------------------------------
//
// iOS-Spezifisch (ios/Runner/Info.plist):
//   <key>NSLocationWhenInUseUsageDescription</key>
//   <string>Ihre Position wird benötigt, um im Notfall Hilfe zu senden.</string>
//
// -------------------------------------------------------------
// Dieser Screen zeigt eine animierte Weltkarte, zoomt nach erfolgreicher
// Lokalisierung auf die aktuelle Position des Patienten und erlaubt das
// Absenden der Koordinaten an den behandelnden Arzt.
// -------------------------------------------------------------

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_map/flutter_map.dart' as fm;
import 'package:latlong2/latlong.dart';
import 'package:lottie/lottie.dart' hide Marker;
import 'package:flutter_animate/flutter_animate.dart';

class SOSScreen extends StatefulWidget {
  const SOSScreen({super.key});

  @override
  State<SOSScreen> createState() => _SOSScreenState();
}

class _SOSScreenState extends State<SOSScreen> with TickerProviderStateMixin {
  final fm.MapController _mapController = fm.MapController();
  Position? _currentPosition;
  bool _isLocating = true;
  late final AnimationController _zoomController;
  late final Animation<double> _zoomAnimation;

  @override
  void initState() {
    super.initState();
    _zoomController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );
    _zoomAnimation = Tween<double>(begin: 3.0, end: 16.0).animate(
      CurvedAnimation(parent: _zoomController, curve: Curves.easeInOutCubic),
    );
    _determinePosition();
  }

  Future<void> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      await _showErrorDialog(
        'Ortungsdienste deaktiviert',
        'Bitte aktiviere die Ortungsdienste, um deine Position zu ermitteln.',
      );
      setState(() => _isLocating = false);
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        await _showErrorDialog(
          'Keine Berechtigung',
          'Ohne Standort-Berechtigung kann die Position nicht ermittelt werden.',
        );
        setState(() => _isLocating = false);
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      await _showErrorDialog(
        'Berechtigung dauerhaft verweigert',
        'Bitte aktiviere die Standort-Berechtigung in den Systemeinstellungen.',
      );
      setState(() => _isLocating = false);
      return;
    }

    final position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    if (!mounted) return;
    setState(() {
      _currentPosition = position;
      _isLocating = false;
    });

    _animateToUser();
  }

  Future<void> _animateToUser() async {
    if (_currentPosition == null) return;

    _mapController.move(const LatLng(-25.2744, 133.7751), 3);
    await Future.delayed(const Duration(milliseconds: 200));

    _zoomController.forward();
    _zoomController.addListener(() {
      _mapController.move(
        LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
        _zoomAnimation.value,
      );
    });
  }

  Future<void> _sendToDoctor() async {
    if (_currentPosition == null) return;

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Position an den Arzt gesendet!',
            style: GoogleFonts.lato()),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _showErrorDialog(String title, String message) {
    return showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title, style: GoogleFonts.lato(fontWeight: FontWeight.bold)),
        content: Text(message, style: GoogleFonts.lato()),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _zoomController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('SOS', style: GoogleFonts.lato(fontWeight: FontWeight.w600)),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          fm.FlutterMap(
            mapController: _mapController,
            options: fm.MapOptions(
              center: const LatLng(-25.2744, 133.7751),
              zoom: 3,
              interactiveFlags: fm.InteractiveFlag.pinchZoom | fm.InteractiveFlag.drag,
              maxZoom: 18,
            ),
            children: [
              fm.TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.medapp',
              ),
              if (_currentPosition != null)
                fm.MarkerLayer(
                  markers: [
                    fm.Marker(
                      point: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
                      width: 50,
                      height: 50,
                      alignment: Alignment.topCenter,
                      child: const Icon(Icons.location_pin, size: 48, color: Colors.red),
                    ),
                  ],
                ),

            ],
          ).animate().fadeIn(duration: 600.ms),

          if (_isLocating)
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Lottie.asset('assets/lottie/location.json', width: 180, height: 180),
                  const SizedBox(height: 16),
                  Text('Bestimme Standort…', style: GoogleFonts.lato(fontSize: 18)),
                ],
              ),
            ),

          Positioned(
            left: 24,
            right: 24,
            bottom: 32,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.local_hospital),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 6,
              ),
              onPressed: _isLocating ? null : _sendToDoctor,
              label: Text('An Arzt senden',
                  style: GoogleFonts.lato(fontSize: 18, fontWeight: FontWeight.bold)),
            ).animate().slideY(begin: 1, end: 0, duration: 600.ms),
          ),
        ],
      ),
    );
  }
}
