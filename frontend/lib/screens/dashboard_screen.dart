// lib/screens/dashboard_screen.dart
import 'package:flutter/material.dart';
import '../widgets/notification_banner.dart';
import '../models/message.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  List<Message> messages = [];
  Message? pushNotification;


  void markAsRead() {
    setState(() {
      if (pushNotification != null) {
        pushNotification!.read = true;
      }
    });
  }

  @override
  void initState() {
    super.initState();

    // Beispielhafte Community-Meldung
    messages = [
      Message("Willkommen in der Community!", DateTime.now().subtract(const Duration(days: 1)), true),
    ];

    // Simulierter Push
    Future.delayed(const Duration(seconds: 2), () {
      setState(() {
        pushNotification = Message("Neue Gesundheitsinfo verfügbar!", DateTime.now(), false);
      });
    });
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Community Dashboard')),
      body: Column(
        children: [
          if (pushNotification != null && !pushNotification!.read)
            NotificationBanner(
              message: pushNotification!,
              onRead: markAsRead,
            ),
          Expanded(
            child: ListView(
              children: messages
                  .map((msg) => ListTile(
                        title: Text(msg.content),
                        subtitle: Text(msg.timestamp.toIso8601String()),
                      ))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }
}
