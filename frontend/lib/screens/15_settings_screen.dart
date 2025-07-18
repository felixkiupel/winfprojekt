import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _storage = const FlutterSecureStorage();
  
  // Settings states
  String _selectedLanguage = 'Deutsch';
  bool _darkModeEnabled = false;
  bool _biometricEnabled = false;
  
  @override
  void initState() {
    super.initState();
    _loadSettings();
  }
  
  Future<void> _loadSettings() async {
    final language = await _storage.read(key: 'language');
    final darkMode = await _storage.read(key: 'dark_mode');
    final biometric = await _storage.read(key: 'biometric');
    
    setState(() {
      _selectedLanguage = language ?? 'Deutsch';
      _darkModeEnabled = darkMode == 'true';
      _biometricEnabled = biometric == 'true';
    });
  }
  
  Future<void> _saveSetting(String key, String value) async {
    await _storage.write(key: key, value: value);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Einstellung gespeichert'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 1),
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Settings', style: GoogleFonts.lato()),
        centerTitle: true,
      ),
      body: ListView(
        children: [
          // Profile Section
          Container(
            color: Colors.grey.shade100,
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: Colors.black,
                  child: Icon(Icons.person, size: 40, color: Colors.white),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Medical App User',
                        style: GoogleFonts.lato(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'user@medicalapp.com',
                        style: GoogleFonts.lato(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () {
                    // Edit profile
                  },
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Account Settings
          _buildSectionHeader('Account'),
          _buildListTile(
            icon: Icons.person_outline,
            title: 'Edit Profile',
            onTap: () {
              // Navigate to edit profile
            },
          ),
          _buildListTile(
            icon: Icons.lock_outline,
            title: 'Change Password',
            onTap: () {
              // Navigate to change password
            },
          ),
          _buildListTile(
            icon: Icons.email_outlined,
            title: 'Change Email',
            onTap: () {
              // Navigate to change email
            },
          ),
          
          const Divider(height: 30),
          
          // General Settings
          _buildSectionHeader('General'),
          ListTile(
            leading: const Icon(Icons.language),
            title: Text('Language', style: GoogleFonts.lato()),
            subtitle: Text(_selectedLanguage, style: GoogleFonts.lato()),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => _showLanguageDialog(),
          ),
          SwitchListTile(
            secondary: const Icon(Icons.dark_mode),
            title: Text('Dark Mode', style: GoogleFonts.lato()),
            subtitle: Text('Use dark theme', style: GoogleFonts.lato()),
            value: _darkModeEnabled,
            onChanged: (value) {
              setState(() {
                _darkModeEnabled = value;
              });
              _saveSetting('dark_mode', value.toString());
            },
          ),
          
          const Divider(height: 30),
          
          // Security Settings
          _buildSectionHeader('Security'),
          SwitchListTile(
            secondary: const Icon(Icons.fingerprint),
            title: Text('Biometric Authentication', style: GoogleFonts.lato()),
            subtitle: Text('Use fingerprint or face ID', style: GoogleFonts.lato()),
            value: _biometricEnabled,
            onChanged: (value) {
              setState(() {
                _biometricEnabled = value;
              });
              _saveSetting('biometric', value.toString());
            },
          ),
          _buildListTile(
            icon: Icons.security,
            title: 'Privacy Settings',
            onTap: () {
              // Navigate to privacy settings
            },
          ),
          
          const Divider(height: 30),
          
          // Support & Legal
          _buildSectionHeader('Support & Legal'),
          _buildListTile(
            icon: Icons.help_outline,
            title: 'Help & Support',
            onTap: () {
              // Navigate to help
            },
          ),
          _buildListTile(
            icon: Icons.description_outlined,
            title: 'Terms of Service',
            onTap: () {
              // Show terms
            },
          ),
          _buildListTile(
            icon: Icons.privacy_tip_outlined,
            title: 'Privacy Policy',
            onTap: () {
              // Show privacy policy
            },
          ),
          _buildListTile(
            icon: Icons.info_outline,
            title: 'About',
            onTap: () => _showAboutDialog(),
          ),
          
          const SizedBox(height: 30),
          
          // Logout Button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ElevatedButton.icon(
              onPressed: () => _showLogoutDialog(),
              icon: const Icon(Icons.logout),
              label: Text('Logout', style: GoogleFonts.lato()),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 20),
        ],
      ),
    );
  }
  
  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Text(
        title.toUpperCase(),
        style: GoogleFonts.lato(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: Colors.grey.shade600,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
  
  Widget _buildListTile({
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title, style: GoogleFonts.lato()),
      subtitle: subtitle != null ? Text(subtitle, style: GoogleFonts.lato()) : null,
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }
  
  void _showLanguageDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Select Language', style: GoogleFonts.lato()),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String>(
              title: Text('Deutsch', style: GoogleFonts.lato()),
              value: 'Deutsch',
              groupValue: _selectedLanguage,
              onChanged: (value) {
                setState(() {
                  _selectedLanguage = value!;
                });
                _saveSetting('language', value!);
                Navigator.pop(context);
              },
            ),
            RadioListTile<String>(
              title: Text('English', style: GoogleFonts.lato()),
              value: 'English',
              groupValue: _selectedLanguage,
              onChanged: (value) {
                setState(() {
                  _selectedLanguage = value!;
                });
                _saveSetting('language', value!);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }
  
  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('About MedApp', style: GoogleFonts.lato()),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Medical App', style: GoogleFonts.lato(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Version: 1.0.0', style: GoogleFonts.lato()),
            const SizedBox(height: 4),
            Text('Build: 2024.1', style: GoogleFonts.lato()),
            const SizedBox(height: 16),
            Text('© 2024 MedApp Team', style: GoogleFonts.lato()),
            const SizedBox(height: 8),
            Text('All rights reserved.', style: GoogleFonts.lato()),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close', style: GoogleFonts.lato()),
          ),
        ],
      ),
    );
  }
  
  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Logout', style: GoogleFonts.lato()),
        content: Text(
          'Are you sure you want to logout?',
          style: GoogleFonts.lato(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: GoogleFonts.lato()),
          ),
          ElevatedButton(
            onPressed: () async {
              // Clear all stored data
              await _storage.deleteAll();
              
              // Navigate to login
              if (mounted) {
                Navigator.of(context).pushNamedAndRemoveUntil(
                  '/login',
                  (route) => false,
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: Text('Logout', style: GoogleFonts.lato()),
          ),
        ],
      ),
    );
  }
}