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
  
  // Settings Variablen
  bool _notificationsEnabled = true;
  bool _darkModeEnabled = false;
  String _selectedLanguage = 'Deutsch';
  bool _biometricEnabled = false;
  
  @override
  void initState() {
    super.initState();
    _loadSettings();
  }
  
  Future<void> _loadSettings() async {
    // Lade gespeicherte Einstellungen
    final notifications = await _storage.read(key: 'notifications_enabled');
    final darkMode = await _storage.read(key: 'dark_mode_enabled');
    final language = await _storage.read(key: 'language');
    final biometric = await _storage.read(key: 'biometric_enabled');
    
    setState(() {
      _notificationsEnabled = notifications != 'false';
      _darkModeEnabled = darkMode == 'true';
      _selectedLanguage = language ?? 'Deutsch';
      _biometricEnabled = biometric == 'true';
    });
  }
  
  Future<void> _saveSettings() async {
    await _storage.write(key: 'notifications_enabled', value: _notificationsEnabled.toString());
    await _storage.write(key: 'dark_mode_enabled', value: _darkModeEnabled.toString());
    await _storage.write(key: 'language', value: _selectedLanguage);
    await _storage.write(key: 'biometric_enabled', value: _biometricEnabled.toString());
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Einstellungen gespeichert'),
        backgroundColor: Colors.green,
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
        padding: const EdgeInsets.all(16),
        children: [
          // Account Section
          _buildSectionHeader('Account'),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.person),
                  title: Text('Profile', style: GoogleFonts.lato()),
                  subtitle: Text('Edit your profile information', style: GoogleFonts.lato()),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    // Navigate to profile
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.lock),
                  title: Text('Change Password', style: GoogleFonts.lato()),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    // Navigate to change password
                  },
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Notifications Section
          _buildSectionHeader('Notifications'),
          Card(
            child: SwitchListTile(
              secondary: const Icon(Icons.notifications),
              title: Text('Push Notifications', style: GoogleFonts.lato()),
              subtitle: Text('Receive notifications about appointments', style: GoogleFonts.lato()),
              value: _notificationsEnabled,
              onChanged: (value) {
                setState(() {
                  _notificationsEnabled = value;
                });
                _saveSettings();
              },
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Appearance Section
          _buildSectionHeader('Appearance'),
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  secondary: const Icon(Icons.dark_mode),
                  title: Text('Dark Mode', style: GoogleFonts.lato()),
                  subtitle: Text('Use dark theme', style: GoogleFonts.lato()),
                  value: _darkModeEnabled,
                  onChanged: (value) {
                    setState(() {
                      _darkModeEnabled = value;
                    });
                    _saveSettings();
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.language),
                  title: Text('Language', style: GoogleFonts.lato()),
                  subtitle: Text(_selectedLanguage, style: GoogleFonts.lato()),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () => _showLanguageDialog(),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Security Section
          _buildSectionHeader('Security'),
          Card(
            child: SwitchListTile(
              secondary: const Icon(Icons.fingerprint),
              title: Text('Biometric Authentication', style: GoogleFonts.lato()),
              subtitle: Text('Use fingerprint or face ID', style: GoogleFonts.lato()),
              value: _biometricEnabled,
              onChanged: (value) {
                setState(() {
                  _biometricEnabled = value;
                });
                _saveSettings();
              },
            ),
          ),
          
          const SizedBox(height: 20),
          
          // About Section
          _buildSectionHeader('About'),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.info),
                  title: Text('App Version', style: GoogleFonts.lato()),
                  subtitle: Text('1.0.0', style: GoogleFonts.lato()),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.description),
                  title: Text('Terms of Service', style: GoogleFonts.lato()),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    // Show terms
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.privacy_tip),
                  title: Text('Privacy Policy', style: GoogleFonts.lato()),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    // Show privacy policy
                  },
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 30),
          
          // Logout Button
          ElevatedButton.icon(
            onPressed: () => _showLogoutDialog(),
            icon: const Icon(Icons.logout),
            label: Text('Logout', style: GoogleFonts.lato()),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
          
          const SizedBox(height: 20),
        ],
      ),
    );
  }
  
  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: GoogleFonts.lato(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
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
                _saveSettings();
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
                _saveSettings();
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }
  
  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Logout', style: GoogleFonts.lato()),
        content: Text('Are you sure you want to logout?', style: GoogleFonts.lato()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: GoogleFonts.lato()),
          ),
          ElevatedButton(
            onPressed: () async {
              // Clear storage
              await _storage.deleteAll();
              
              // Navigate to login
              if (mounted) {
                Navigator.of(context).pushNamedAndRemoveUntil(
                  '/login',
                  (route) => false,
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Logout', style: GoogleFonts.lato()),
          ),
        ],
      ),
    );
  }
}