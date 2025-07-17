import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../push_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // Settings values
  bool _pushNotificationsEnabled = true;
  String _selectedCommunity = 'all_communities';
  String? _userName;
  String? _userEmail;
  
  // Available communities
  final List<Map<String, String>> communities = [
    {'id': 'all_communities', 'name': 'All Communities'},
    {'id': 'aboriginal_health', 'name': 'Aboriginal Health'},
    {'id': 'torres_strait', 'name': 'Torres Strait'},
    {'id': 'remote_communities', 'name': 'Remote Communities'},
    {'id': 'urban_indigenous', 'name': 'Urban Indigenous'},
  ];

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _pushNotificationsEnabled = prefs.getBool('push_notifications_enabled') ?? true;
      _selectedCommunity = prefs.getString('selected_community') ?? 'all_communities';
      _userName = prefs.getString('user_name') ?? 'Test User';
      _userEmail = prefs.getString('user_email') ?? 'test@medapp.com';
    });
  }

  Future<void> _saveSetting(String key, dynamic value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value is bool) {
      await prefs.setBool(key, value);
    } else if (value is String) {
      await prefs.setString(key, value);
    }
  }

  Future<void> _updateCommunity(String communityId) async {
    setState(() {
      _selectedCommunity = communityId;
    });
    await _saveSetting('selected_community', communityId);
    
    // Update push service with new community
    final userId = (await SharedPreferences.getInstance()).getString('user_id') ?? 'test_user';
    await SimplePushService().updateUserCommunity(userId, communityId);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Community updated to: ${_getCommunityName(communityId)}'),
        backgroundColor: Colors.green,
      ),
    );
  }

  String _getCommunityName(String id) {
    return communities.firstWhere((c) => c['id'] == id)['name'] ?? id;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Settings',
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
      body: ListView(
        children: [
          // User Info Section
          Container(
            color: Colors.grey.shade100,
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const CircleAvatar(
                  radius: 40,
                  backgroundColor: Colors.black,
                  child: Icon(Icons.person, size: 40, color: Colors.white),
                ),
                const SizedBox(height: 12),
                Text(
                  _userName ?? 'User',
                  style: GoogleFonts.lato(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _userEmail ?? '',
                  style: GoogleFonts.lato(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Community Selection
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Community Selection',
              style: GoogleFonts.lato(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 8),
          
          ...communities.map((community) => RadioListTile<String>(
            title: Text(
              community['name']!,
              style: GoogleFonts.lato(),
            ),
            value: community['id']!,
            groupValue: _selectedCommunity,
            onChanged: (value) {
              if (value != null) {
                _updateCommunity(value);
              }
            },
          )).toList(),
          
          const Divider(height: 32),
          
          // Notification Settings
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Notifications',
              style: GoogleFonts.lato(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          
          SwitchListTile(
            title: Text(
              'Push Notifications',
              style: GoogleFonts.lato(),
            ),
            subtitle: Text(
              'Receive health updates and alerts',
              style: GoogleFonts.lato(fontSize: 14, color: Colors.grey),
            ),
            value: _pushNotificationsEnabled,
            onChanged: (value) async {
              setState(() {
                _pushNotificationsEnabled = value;
              });
              await _saveSetting('push_notifications_enabled', value);
              
              if (!value) {
                SimplePushService().disconnect();
              } else {
                final userId = (await SharedPreferences.getInstance()).getString('user_id') ?? 'test_user';
                await SimplePushService().initialize(userId: userId);
              }
            },
          ),
          
          const Divider(height: 32),
          
          // Test Section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Developer Options',
              style: GoogleFonts.lato(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          
          ListTile(
            leading: const Icon(Icons.notifications_active),
            title: Text('Send Test Notification', style: GoogleFonts.lato()),
            subtitle: Text(
              'Test push notification system',
              style: GoogleFonts.lato(fontSize: 14, color: Colors.grey),
            ),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () async {
              await SimplePushService().sendTestNotification();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Test notification sent!'),
                  backgroundColor: Colors.green,
                ),
              );
            },
          ),
          
          ListTile(
            leading: const Icon(Icons.bug_report),
            title: Text('Connection Status', style: GoogleFonts.lato()),
            subtitle: Text(
              'Check WebSocket connection',
              style: GoogleFonts.lato(fontSize: 14, color: Colors.grey),
            ),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              _showConnectionStatus();
            },
          ),
          
          const SizedBox(height: 50),
        ],
      ),
    );
  }
  
  void _showConnectionStatus() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Connection Status'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Push Service: ${SimplePushService().isConnected ? "Connected" : "Disconnected"}'),
            const SizedBox(height: 8),
            Text('Selected Community: $_selectedCommunity'),
            const SizedBox(height: 8),
            Text('Notifications: ${_pushNotificationsEnabled ? "Enabled" : "Disabled"}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}