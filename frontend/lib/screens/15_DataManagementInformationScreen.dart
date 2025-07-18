import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';

// Farben wie in deinem Projekt (kannst du aus main.dart übernehmen)
import 'package:medapp/main.dart';

class DataManagementInformationScreen extends StatelessWidget {
  final String userName;

  const DataManagementInformationScreen({
    Key? key,
    required this.userName,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final String longText = """
Your personal data is handled with the highest level of care and follows strict security principles.

• **Email**  
  Your email address is stored in plain text and is used as a unique identifier for login and communication.

• **First and Last Name**  
  Both your first and last name are encrypted in the database. Even if the database is accessed by unauthorized parties, your real name cannot be directly read.

• **Password**  
  Your password is securely hashed using a one-way encryption algorithm (bcrypt). It cannot be decrypted and is never stored in plain text.

• **Medical ID**  
  Your medical ID is encrypted using symmetric encryption to protect your sensitive healthcare information.

• **Role in the System**  
  Your role (e.g., patient, admin) is stored in plain text to allow quick access control checks within the system.

• **Text Messages**  
  Messages exchanged within the platform are stored in plain text for easy retrieval and display in conversations.

• **Community Data**  
  Information about communities you join or create is stored in plain text for fast access and visibility to other users.

In summary, only highly sensitive personal identifiers (name, medical ID, password) are protected with encryption. Other less critical data is stored as plain text for usability and system functionality.
""";

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Data Management Information',
          style: GoogleFonts.lato(fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Header Card ──
          Card(
            elevation: 1,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Container(
              height: 80,
              decoration: BoxDecoration(
                color: kMedicalSurface,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(children: [
                Container(
                  width: 4,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      bottomLeft: Radius.circular(16),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                CircleAvatar(
                  radius: 24,
                  backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                  child: Text(
                    (userName)
                        .split(' ')
                        .map((e) => e.isEmpty ? '' : e[0])
                        .take(2)
                        .join(),
                    style: GoogleFonts.lato(
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        userName,
                        style: GoogleFonts.lato(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Security & Privacy Overview",
                        style: GoogleFonts.lato(
                          fontSize: 14,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: Icon(
                    Icons.lock_outline,
                    size: 28,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ]),
            ),
          ).animate().fadeIn(duration: 500.ms).slideX(begin: -0.2, end: 0),

          const SizedBox(height: 8),

          // ── Inhalt: Überschrift + langer Text ──
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "PERSONAL DATA MANAGEMENT AND SECURITY INFORMATION",
                    style: GoogleFonts.lato(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ).animate().fadeIn(duration: 400.ms),

                  const SizedBox(height: 16),

                  Text(
                    longText,
                    style: GoogleFonts.lato(
                      fontSize: 16,
                      height: 1.4,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ).animate().fadeIn(duration: 500.ms, delay: 100.ms),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
