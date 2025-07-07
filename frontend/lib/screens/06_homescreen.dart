import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '07_SosScreen.dart';

class HomeScreenTemplate extends StatefulWidget {
  const HomeScreenTemplate({super.key});

  @override
  _HomeScreenTemplateState createState() => _HomeScreenTemplateState();
}

class _HomeScreenTemplateState extends State<HomeScreenTemplate> {
  int _unreadCount = 0;
  String _selectedCommunity = 'all_communities';
  
  @override
  void initState() {
    super.initState();
    _initializePushService();
    _loadCommunityPreference();
    _listenToPushMessages();
  }
  
  Future<void> _initializePushService() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('user_id') ?? 'test_user';
    
    // Initialize push service if notifications are enabled
    final pushEnabled = prefs.getBool('push_notifications_enabled') ?? true;
    if (pushEnabled) {
      await SimplePushService().initialize(userId: userId);
    }
  }
  
  Future<void> _loadCommunityPreference() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _selectedCommunity = prefs.getString('selected_community') ?? 'all_communities';
    });
  }
  
  void _listenToPushMessages() {
    SimplePushService().messageStream.listen((message) {
      if (message['type'] == 'unread_count') {
        setState(() {
          _unreadCount = message['count'] ?? 0;
        });
      }
    });
  }
  
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
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications, color: Colors.white),
                onPressed: () {
                  // Navigate to notifications screen
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Notifications screen coming soon')),
                  );
                },
              ),
              if (_unreadCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 20,
                      minHeight: 20,
                    ),
                    child: Center(
                      child: Text(
                        '$_unreadCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white),
            onPressed: () {
              Navigator.pushNamed(context, '/settings').then((_) {
                // Reload community preference when returning from settings
                _loadCommunityPreference();
              });
            },
          ),
        ],
      ),

      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(color: Colors.black),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.local_hospital, color: Colors.white, size: 60),
                    const SizedBox(height: 10),
                    Text(
                      'MedApp Menu',
                      style: GoogleFonts.lato(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
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
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Profile screen coming soon')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.medical_services),
              title: Text('Health Records', style: GoogleFonts.lato()),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Health Records coming soon')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.calendar_today),
              title: Text('Appointments', style: GoogleFonts.lato()),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Appointments coming soon')),
                );
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.settings),
              title: Text('Settings', style: GoogleFonts.lato()),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/settings');
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
                  MaterialPageRoute(
                    builder: (_) => const SOSScreen(),   // ← dein Screen
                  ),
                );
              },
            ),

            ListTile(
              leading: const Icon(Icons.logout),
              title: Text('Logout', style: GoogleFonts.lato()),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Help & Support coming soon')),
                );
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: Text('Logout', style: GoogleFonts.lato(color: Colors.red)),
              onTap: () async {
                // Clear user data
                final prefs = await SharedPreferences.getInstance();
                await prefs.clear();
                
                // Disconnect push service
                SimplePushService().disconnect();
                
                // Navigate to login
                if (context.mounted) {
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    '/login',
                    (route) => false,
                  );
                }
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
              const SizedBox(height: 8),
              
              // Community indicator
              if (_selectedCommunity != 'all_communities')
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.green.shade100,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Community: ${_getCommunityName(_selectedCommunity)}',
                    style: GoogleFonts.lato(
                      fontSize: 14,
                      color: Colors.green.shade800,
                    ),
                    textAlign: TextAlign.center,
                  ),
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
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Medical services coming soon')),
                      );
                    },
                  ),
                  _FeatureCard(
                    icon: Icons.analytics,
                    label: 'Statistics',
                    color: Colors.blue.shade600,
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Health statistics coming soon')),
                      );
                    },
                  ),
                  _FeatureCard(
                    icon: Icons.notifications,
                    label: 'Alerts',
                    color: Colors.red.shade600,
                    badge: _unreadCount > 0 ? '$_unreadCount' : null,
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Health alerts coming soon')),
                      );
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
                title: 'Settings updated',
                subtitle: 'Just now',
                icon: Icons.settings,
              ),
              _ActivityTile(
                title: 'Push notification received',
                subtitle: '5 minutes ago',
                icon: Icons.notifications,
              ),
              _ActivityTile(
                title: 'Community selected',
                subtitle: 'Today',
                icon: Icons.group,
              ),
              const SizedBox(height: 32),

              // Quick Actions
              Text(
                'Quick Actions',
                style: GoogleFonts.lato(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              
              // Test notification button
              ElevatedButton.icon(
                onPressed: () async {
                  await SimplePushService().sendTestNotification();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Test notification sent!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                },
                icon: const Icon(Icons.notifications_active),
                label: Text(
                  'Send Test Notification',
                  style: GoogleFonts.lato(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              
              const SizedBox(height: 12),
              
              // Settings shortcut
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.pushNamed(context, '/settings');
                },
                icon: const Icon(Icons.settings),
                label: Text(
                  'Go to Settings',
                  style: GoogleFonts.lato(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      
      // Floating Action Button for new actions
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showActionMenu(context);
        },
        backgroundColor: Colors.black,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
  
  String _getCommunityName(String communityId) {
    final communities = {
      'aboriginal_health': 'Aboriginal Health',
      'torres_strait': 'Torres Strait',
      'remote_communities': 'Remote Communities',
      'urban_indigenous': 'Urban Indigenous',
      'all_communities': 'All Communities',
    };
    return communities[communityId] ?? communityId;
  }
  
  void _showActionMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Quick Actions',
              style: GoogleFonts.lato(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.calendar_today),
              title: Text('Book Appointment', style: GoogleFonts.lato()),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Appointment booking coming soon')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.medical_services),
              title: Text('Health Check', style: GoogleFonts.lato()),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Health check feature coming soon')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.emergency),
              title: Text('Emergency Contact', style: GoogleFonts.lato()),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Emergency contacts coming soon')),
                );
              },
            ),
          ],
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
  final String? badge;

  const _FeatureCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    this.badge,
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
          child: Stack(
            children: [
              Center(
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
              if (badge != null)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      badge!,
                      style: TextStyle(
                        color: color,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
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
