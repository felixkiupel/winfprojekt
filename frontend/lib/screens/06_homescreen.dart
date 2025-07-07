import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '07_SosScreen.dart';

class HomeScreenTemplate extends StatefulWidget {
  const HomeScreenTemplate({super.key});

  @override
  _HomeScreenTemplateState createState() => _HomeScreenTemplateState();
}

class _HomeScreenTemplateState extends State<HomeScreenTemplate> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Home',
          style: GoogleFonts.lato(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Colors.black,
        elevation: 4,
        centerTitle: true,
      ),

      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(color: Colors.black),
              child: Center(
                child: Text(
                  'Menu',
                  style: GoogleFonts.lato(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.home),
              title: Text('Home', style: GoogleFonts.lato()),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.person),
              title: Text('Profile', style: GoogleFonts.lato()),
              onTap: () {
                // Navigator.push(…)
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: Text('Settings', style: GoogleFonts.lato()),
              onTap: () {
                // Navigator.push(…)
              },
            ),
            ListTile(
              leading: const Icon(Icons.local_pharmacy),
              title: Text("Medicament's Achievements", style: GoogleFonts.lato()),
              onTap: () {
                // Logout logic TODO: Gamification / Medicament's
              },
            ),
            ListTile(
              leading: const Icon(Icons.offline_pin),
              title: Text('Offline Documents', style: GoogleFonts.lato()),
              onTap: () {
                // Logout logic TODO: OffLogoutline Caching
              },
            ),
            ListTile(
              leading: const Icon(Icons.warning_amber_rounded),
              title: Text('SOS GEO Localisation', style: GoogleFonts.lato()),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const SOSScreen()),
                );
              },
            ),


            ListTile(
              leading: const Icon(Icons.logout),
              title: Text('Logout', style: GoogleFonts.lato()),
              onTap: () {
                // Logout logic
              },
            ),
          ],
        ),
      ),

      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Welcome text
              Text(
                'Welcome back!',
                style: GoogleFonts.lato(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _FeatureCard(
                    icon: Icons.medical_services,
                    label: 'Medical',
                    color: Colors.green.shade600,
                    onTap: () {
                    },
                  ),
                  _FeatureCard(
                    icon: Icons.analytics,
                    label: 'Statistics',
                    color: Colors.blue.shade600,
                    onTap: () {
                      // Action
                    },
                  ),
                  _FeatureCard(
                    icon: Icons.notifications,
                    label: 'Notifications',
                    color: Colors.red.shade600,
                    onTap: () {
                      // Action
                    },
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Recent activity list
              Text(
                'Recent Activities',
                style: GoogleFonts.lato(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              _ActivityTile(
                title: 'QR code scanned',
                subtitle: '5 minutes ago',
                icon: Icons.qr_code_scanner,
              ),
              _ActivityTile(
                title: 'Password changed',
                subtitle: 'Yesterday, 2:30 PM',
                icon: Icons.lock_reset,
              ),
              _ActivityTile(
                title: 'New document uploaded',
                subtitle: '2 days ago',
                icon: Icons.upload_file,
              ),
              const SizedBox(height: 32),

              // Bottom button to add a new action
              ElevatedButton.icon(
                onPressed: () {
                  // Action: e.g. create a new task
                },
                icon: const Icon(Icons.add),
                label: Text(
                  'New Action',
                  style: GoogleFonts.lato(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Simple card for feature icons
class _FeatureCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _FeatureCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 100,
          margin: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 40, color: Colors.white),
              const SizedBox(height: 8),
              Text(
                label,
                style: GoogleFonts.lato(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}


class _ActivityTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;

  const _ActivityTile({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: Colors.black54),
      title: Text(
        title,
        style: GoogleFonts.lato(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: GoogleFonts.lato(color: Colors.black54),
      ),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: () {
        // Optional tap action
      },
      contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
    );
  }
}
