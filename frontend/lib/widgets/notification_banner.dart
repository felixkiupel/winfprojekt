import 'package:flutter/material.dart';
import '../models/message.dart';

class NotificationBanner extends StatelessWidget {
  final Message message;
  final VoidCallback onRead;

  const NotificationBanner({
    super.key,
    required this.message,
    required this.onRead,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.amberAccent,
      margin: const EdgeInsets.all(8),
      child: ListTile(
        title: Text(message.content),
        trailing: IconButton(
          icon: const Icon(Icons.check),
          onPressed: onRead,
          tooltip: 'Mark as read',
        ),
      ),
    );
  }
}
