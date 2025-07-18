import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';

class DataManagementInformationScreen extends StatelessWidget {
  const DataManagementInformationScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Data Management Information',
          style: GoogleFonts.lato(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Große Hauptüberschrift ──
            Text(
              "PERSONAL DATA MANAGEMENT\nAND SECURITY INFORMATION",
              textAlign: TextAlign.center,
              style: GoogleFonts.lato(
                fontSize: 30, // groß
                fontWeight: FontWeight.w900,
                height: 1.3,
                color: theme.colorScheme.primary,
              ),
            )
                .animate()
                .fadeIn(duration: 600.ms)
                .slideY(begin: -0.2, end: 0),

            const SizedBox(height: 32),

            // ── Einleitender Text ──
            Text(
              "Your personal data is handled with the highest level of care. "
                  "The system uses a combination of secure encryption methods and structured storage "
                  "to ensure both privacy and usability. Below you can find an overview of how each data type is stored "
                  "and managed within our database.",
              textAlign: TextAlign.justify,
              style: GoogleFonts.lato(
                fontSize: 16,
                height: 1.5,
                color: theme.colorScheme.onSurface,
              ),
            ).animate().fadeIn(duration: 500.ms, delay: 100.ms),

            const SizedBox(height: 28),

            // ── Einzelne Abschnitte ──
            _buildSection(
              context,
              title: "Email",
              text:
              "Your email address is stored in plain text. It serves as your unique identifier for authentication and communication within the platform. "
                  "While it is not encrypted, it is protected by strict access controls.",
            ),
            _buildSection(
              context,
              title: "First and Last Name",
              text:
              "Your first name and last name are stored in encrypted form. Even if the database were to be compromised, "
                  "your real identity cannot be directly read without proper decryption keys.",
            ),
            _buildSection(
              context,
              title: "Password",
              text:
              "Your password is never stored in plain text. It is securely hashed using bcrypt, "
                  "a one-way encryption algorithm. This means it cannot be decrypted by anyone, including the system administrators.",
            ),
            _buildSection(
              context,
              title: "Medical ID",
              text:
              "Your medical ID is considered highly sensitive information. It is encrypted with symmetric encryption (Fernet/AES) "
                  "to ensure it remains confidential at all times.",
            ),
            _buildSection(
              context,
              title: "Role in the System",
              text:
              "Your assigned role (for example, patient or admin) is stored in plain text for fast access control checks. "
                  "This allows the system to determine permissions without additional decryption overhead.",
            ),
            _buildSection(
              context,
              title: "Text Messages",
              text:
              "Messages exchanged within the platform are stored in plain text for easy retrieval and display in conversations. "
                  "These are considered low-sensitive content for usability reasons.",
            ),
            _buildSection(
              context,
              title: "Community Data",
              text:
              "Information about communities you join or create is stored in plain text. "
                  "This ensures that the system can quickly display and share community details with other users.",
            ),

            const SizedBox(height: 28),

            // ── Zusammenfassung ──
            Text(
              "In summary, only highly sensitive identifiers such as your name, medical ID, and password "
                  "are encrypted or hashed. Less critical information remains in plain text for better performance "
                  "and usability within the platform.",
              textAlign: TextAlign.justify,
              style: GoogleFonts.lato(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                height: 1.5,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ).animate().fadeIn(duration: 600.ms, delay: 200.ms),
          ],
        ),
      ),
    );
  }

  /// Hilfs-Widget für einen formatierten Abschnitt
  Widget _buildSection(BuildContext context,
      {required String title, required String text}) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.lato(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            text,
            textAlign: TextAlign.justify,
            style: GoogleFonts.lato(
              fontSize: 15,
              height: 1.5,
              color: theme.colorScheme.onSurface,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms);
  }
}
