import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart' as gc;
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_map/flutter_map.dart' as fm;
import 'package:latlong2/latlong.dart';
import 'package:lottie/lottie.dart' hide Marker;
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vibration/vibration.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';



class SOSScreen extends StatefulWidget {
  const SOSScreen({super.key});

  @override
  State<SOSScreen> createState() => _SOSScreenState();
}

class _SOSScreenState extends State<SOSScreen> with TickerProviderStateMixin {
  final fm.MapController _mapController = fm.MapController();
  Position? _currentPosition;
  String? _currentAddress;
  bool _isLocating = true;
  bool _satellite = false;

  late final AnimationController _zoomController;
  late final Animation<double> _zoomAnimation;

  bool _sent = false;
  final _localNotif = FlutterLocalNotificationsPlugin();

  @override
  void initState() {
    super.initState();
    // Zoom langsamer über 5 Sekunden statt 3
    _zoomController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    );
    _zoomAnimation = Tween<double>(
      begin: 2.0,
      end: 17.0,
    ).animate(
      CurvedAnimation(
        parent: _zoomController,
        // eine gleichmäßigere Kurve für langsameren Zoom
        curve: Curves.easeInOut,
      ),
    );

    _determinePosition();
  }

  Future<void> _determinePosition() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      await _showErrorDialog(
        'Ortungsdienste deaktiviert',
        'Bitte aktiviere die Ortungsdienste, um deine Position zu ermitteln.',
      );
      setState(() => _isLocating = false);
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        await _showErrorDialog(
          'Keine Berechtigung',
          'Ohne Standort‑Berechtigung kann die Position nicht ermittelt werden.',
        );
        setState(() => _isLocating = false);
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      await _showErrorDialog(
        'Berechtigung dauerhaft verweigert',
        'Bitte aktiviere die Standort‑Berechtigung in den Systemeinstellungen.',
      );
      setState(() => _isLocating = false);
      return;
    }

    final position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    if (!mounted) return;

    try {
      await gc.setLocaleIdentifier('de_DE');
      final placemarks = await gc.placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      final p = placemarks.first;
      _currentAddress =
      "${p.street?.isNotEmpty == true ? p.street : ''}, ${p.postalCode} ${p.locality}";
    } catch (_) {
      _currentAddress = null;
    }

    setState(() {
      _currentPosition = position;
      _isLocating = false;
    });

    _animateToUser();
    Vibration.vibrate(duration: 400);
  }

  Future<void> _animateToUser() async {
    if (_currentPosition == null) return;

    _mapController.move(const LatLng(-25.0, 133.0), 3);
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
    if (_currentPosition == null || _sent) return;
    _sent = true;

    const title = 'SOS gesendet';
    final body = 'Deine Position wurde an den Arzt übermittelt.';

    await _localNotif.show(
      0,                // ID
      title,            // Titel
      body,             // Text
      NotificationDetails(
        iOS: DarwinNotificationDetails(
          presentAlert: true,   // Banner
          presentSound: true,
          presentBadge: true,
        ),
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
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('OK')),
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
    final theme = Theme.of(context);
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        // Für den Zurück-Pfeil & alle anderen Icons links
        iconTheme: const IconThemeData(color: Colors.black),
        // Für die Icons in actions
        actionsIconTheme: const IconThemeData(color: Colors.black),
        titleTextStyle: GoogleFonts.lato(
          color: Colors.black,
          fontWeight: FontWeight.w700,
          fontSize: 20,
        ),
        title: const Text('GEO Localisation'),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: _satellite ? 'Karte' : 'Satellit',
            onPressed: () => setState(() => _satellite = !_satellite),
            icon: Icon(_satellite ? Icons.map : Icons.satellite_alt),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Verlaufs‑Hintergrund
          AnimatedContainer(
            duration: const Duration(seconds: 3),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: _isLocating
                    ? [theme.colorScheme.primary, theme.colorScheme.secondary]
                    : [theme.colorScheme.secondary, theme.colorScheme.primary],
              ),
            ),
          ),

          // Welt‑Lottie
          Positioned.fill(
            child: IgnorePointer(
              child: Opacity(
                opacity: 0.07,
                child: Lottie.asset('assets/lottie/world_spin.json', repeat: true),
              ),
            ),
          ),

          // Karte
          fm.FlutterMap(
            mapController: _mapController,
            options: const fm.MapOptions(
              center: LatLng(0, 0),
              zoom: 3,
              interactiveFlags: fm.InteractiveFlag.pinchZoom | fm.InteractiveFlag.drag,
            ),
            children: [
              fm.TileLayer(
                urlTemplate: _satellite
                    ? 'https://{s}.tile.opentopomap.org/{z}/{x}/{y}.png'
                    : 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                subdomains: ['a', 'b', 'c'],
                userAgentPackageName: 'com.example.medapp',
              ),
              if (_currentPosition != null) ...[
                fm.CircleLayer(circles: [
                  fm.CircleMarker(
                    point: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
                    color: theme.colorScheme.primary.withOpacity(0.2),
                    borderColor: theme.colorScheme.primary,
                    borderStrokeWidth: 2,
                    radius: 120,
                  ),
                ]),
                fm.MarkerLayer(markers: [
                  fm.Marker(
                    point: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
                    width: 80,
                    height: 80,
                    alignment: Alignment.center,
                    child: _PulsePin(color: theme.colorScheme.error),
                  ),
                ]),
              ],
            ],
          ).animate().fadeIn(duration: 600.ms),

          // Adresse
          if (!_isLocating && _currentPosition != null)
            SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                child: Material(
                  elevation: 6,
                  borderRadius: BorderRadius.circular(16),
                  color: theme.cardColor.withOpacity(0.9),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    child: Row(
                      children: [
                        const Icon(Icons.place, size: 28, color: Colors.black),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _currentAddress ?? '$_currentPosition',
                            style: GoogleFonts.lato(fontSize: 16, color: Colors.black),
                            maxLines: 2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

          // Standort‑Suche
          if (_isLocating)
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Lottie.asset('assets/lottie/location.json', width: 200, height: 200),
                  const SizedBox(height: 16),
                  Text('Bestimme Standort…', style: GoogleFonts.lato(fontSize: 18)),
                ],
              ),
            ),

          // Aktion‑Button
          if (!_isLocating)
            Positioned(
              left: 24,
              right: 24,
              bottom: 32,
              child: ElevatedButton.icon(
                onPressed: _sent ? null : _sendToDoctor,
                icon: const Icon(Icons.local_hospital),
                label: Text(
                  'Call an Ambulance and send Location',
                  style: GoogleFonts.lato(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 8,
                ),
              ).animate().slideY(begin: 1, end: 0, curve: Curves.easeOutBack, duration: 600.ms),
            )
        ],
      ),
    );
  }
}

// ----------------------------------------------------------------------------
// Pulsierender Pin
// ----------------------------------------------------------------------------
class _PulsePin extends StatefulWidget {
  const _PulsePin({required this.color});
  final Color color;

  @override
  State<_PulsePin> createState() => _PulsePinState();
}

class _PulsePinState extends State<_PulsePin> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl =
  AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (ctx, _) {
        final scale = 1 + math.sin(_ctrl.value * math.pi * 2) * 0.2;
        return Transform.scale(
          scale: scale,
          child: Icon(Icons.location_pin, size: 64, color: widget.color),
        );
      },
    );
  }
}
