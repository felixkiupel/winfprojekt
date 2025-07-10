import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../push_service.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // Settings states
  bool _pushNotificationsEnabled = true;
  String _selectedCommunity = 'all_communities';
  String _selectedLanguage = 'de';
  bool _shareAnonymousData = false;
  bool _locationServicesEnabled = false;
  
  // Enhanced notification settings
  bool _notificationSoundEnabled = true;
  bool _notificationVibrationEnabled = true;
  bool _notificationHeadsUpEnabled = true;
  String _notificationSound = 'default';
  String _notificationImportance = 'high';
  
  // Category settings
  bool _healthAlertsEnabled = true;
  bool _communityUpdatesEnabled = true;
  bool _appointmentRemindersEnabled = true;
  bool _emergencyAlertsEnabled = true;
  
  // Quiet hours
  bool _quietHoursEnabled = false;
  TimeOfDay _quietHoursStart = const TimeOfDay(hour: 22, minute: 0);
  TimeOfDay _quietHoursEnd = const TimeOfDay(hour: 7, minute: 0);
  
  // Available notification sounds
  final List<Map<String, String>> _notificationSounds = [
    {'id': 'default', 'name': 'Standard'},
    {'id': 'notification_1', 'name': 'Sanft'},
    {'id': 'notification_2', 'name': 'Aufmerksamkeit'},
    {'id': 'notification_3', 'name': 'Dringend'},
    {'id': 'emergency', 'name': 'Notfall'},
  ];
  
  // For account deletion
  final TextEditingController _deleteCodeController = TextEditingController();
  bool _deletionInProgress = false;
  
  @override
  void initState() {
    super.initState();
    _loadSettings();
  }
  
  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      // Basic settings
      _pushNotificationsEnabled = prefs.getBool('push_notifications_enabled') ?? true;
      _selectedCommunity = prefs.getString('selected_community') ?? 'all_communities';
      _selectedLanguage = prefs.getString('selected_language') ?? 'de';
      _shareAnonymousData = prefs.getBool('share_anonymous_data') ?? false;
      _locationServicesEnabled = prefs.getBool('location_services_enabled') ?? false;
      
      // Enhanced notification settings
      _notificationSoundEnabled = prefs.getBool('notification_sound_enabled') ?? true;
      _notificationVibrationEnabled = prefs.getBool('notification_vibration_enabled') ?? true;
      _notificationHeadsUpEnabled = prefs.getBool('notification_heads_up_enabled') ?? true;
      _notificationSound = prefs.getString('notification_sound') ?? 'default';
      _notificationImportance = prefs.getString('notification_importance') ?? 'high';
      
      // Category settings
      _healthAlertsEnabled = prefs.getBool('health_alerts_enabled') ?? true;
      _communityUpdatesEnabled = prefs.getBool('community_updates_enabled') ?? true;
      _appointmentRemindersEnabled = prefs.getBool('appointment_reminders_enabled') ?? true;
      _emergencyAlertsEnabled = prefs.getBool('emergency_alerts_enabled') ?? true;
      
      // Quiet hours
      _quietHoursEnabled = prefs.getBool('quiet_hours_enabled') ?? false;
      final startHour = prefs.getInt('quiet_hours_start_hour') ?? 22;
      final startMinute = prefs.getInt('quiet_hours_start_minute') ?? 0;
      final endHour = prefs.getInt('quiet_hours_end_hour') ?? 7;
      final endMinute = prefs.getInt('quiet_hours_end_minute') ?? 0;
      _quietHoursStart = TimeOfDay(hour: startHour, minute: startMinute);
      _quietHoursEnd = TimeOfDay(hour: endHour, minute: endMinute);
    });
  }
  
  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Save all basic settings
    await prefs.setBool('push_notifications_enabled', _pushNotificationsEnabled);
    await prefs.setString('selected_community', _selectedCommunity);
    await prefs.setString('selected_language', _selectedLanguage);
    await prefs.setBool('share_anonymous_data', _shareAnonymousData);
    await prefs.setBool('location_services_enabled', _locationServicesEnabled);
    
    // Save enhanced notification settings
    await prefs.setBool('notification_sound_enabled', _notificationSoundEnabled);
    await prefs.setBool('notification_vibration_enabled', _notificationVibrationEnabled);
    await prefs.setBool('notification_heads_up_enabled', _notificationHeadsUpEnabled);
    await prefs.setString('notification_sound', _notificationSound);
    await prefs.setString('notification_importance', _notificationImportance);
    
    // Save category settings
    await prefs.setBool('health_alerts_enabled', _healthAlertsEnabled);
    await prefs.setBool('community_updates_enabled', _communityUpdatesEnabled);
    await prefs.setBool('appointment_reminders_enabled', _appointmentRemindersEnabled);
    await prefs.setBool('emergency_alerts_enabled', _emergencyAlertsEnabled);
    
    // Save quiet hours
    await prefs.setBool('quiet_hours_enabled', _quietHoursEnabled);
    await prefs.setInt('quiet_hours_start_hour', _quietHoursStart.hour);
    await prefs.setInt('quiet_hours_start_minute', _quietHoursStart.minute);
    await prefs.setInt('quiet_hours_end_hour', _quietHoursEnd.hour);
    await prefs.setInt('quiet_hours_end_minute', _quietHoursEnd.minute);
    
    // Update push service with new settings
    await SimplePushService().saveNotificationSettings({
      'notifications_enabled': _pushNotificationsEnabled,
      'notification_sound_enabled': _notificationSoundEnabled,
      'notification_vibration_enabled': _notificationVibrationEnabled,
      'notification_heads_up_enabled': _notificationHeadsUpEnabled,
      'notification_sound': _notificationSound,
      'notification_importance': _notificationImportance,
      'health_alerts_enabled': _healthAlertsEnabled,
      'community_updates_enabled': _communityUpdatesEnabled,
      'appointment_reminders_enabled': _appointmentRemindersEnabled,
      'emergency_alerts_enabled': _emergencyAlertsEnabled,
      'quiet_hours_enabled': _quietHoursEnabled,
      'quiet_hours_start': '${_quietHoursStart.hour.toString().padLeft(2, '0')}:${_quietHoursStart.minute.toString().padLeft(2, '0')}',
      'quiet_hours_end': '${_quietHoursEnd.hour.toString().padLeft(2, '0')}:${_quietHoursEnd.minute.toString().padLeft(2, '0')}',
    });
    
    if (!_pushNotificationsEnabled) {
      SimplePushService().disconnect();
    } else {
      final userId = prefs.getString('user_id') ?? 'default_user';
      await SimplePushService().initialize(userId: userId);
    }
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _selectedLanguage == 'de' ? 'Einstellungen gespeichert!' : 'Settings saved!',
            style: GoogleFonts.lato(),
          ),
          backgroundColor: Colors.green,
        ),
      );
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _selectedLanguage == 'de' ? 'Einstellungen' : 'Settings',
          style: GoogleFonts.lato(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Colors.black,
      ),
      backgroundColor: const Color(0xFFF3FFF5),
      body: GridView.count(
        crossAxisCount: 2,
        padding: const EdgeInsets.all(16),
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        children: [
          _buildSettingsTile(
            icon: Icons.notifications,
            title: _selectedLanguage == 'de' ? 'Benachrichtigungen' : 'Notifications',
            color: Colors.blue,
            onTap: () => _showEnhancedNotificationSettings(),
          ),
          _buildSettingsTile(
            icon: Icons.group,
            title: _selectedLanguage == 'de' ? 'Community' : 'Community',
            color: Colors.green,
            onTap: () => _showCommunitySelection(),
          ),
          _buildSettingsTile(
            icon: Icons.language,
            title: _selectedLanguage == 'de' ? 'Sprache' : 'Language',
            color: Colors.purple,
            onTap: () => _showLanguageSelection(),
          ),
          _buildSettingsTile(
            icon: Icons.shield,
            title: _selectedLanguage == 'de' ? 'Datenschutz' : 'Privacy',
            color: Colors.orange,
            onTap: () => _showPrivacySettings(),
          ),
          _buildSettingsTile(
            icon: Icons.info,
            title: _selectedLanguage == 'de' ? 'Über' : 'About',
            color: Colors.teal,
            onTap: () => _showAboutDialog(),
          ),
          _buildSettingsTile(
            icon: Icons.delete_forever,
            title: _selectedLanguage == 'de' ? 'Konto löschen' : 'Delete Account',
            color: Colors.red,
            onTap: () => _showDeleteAccountDialog(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          // Logout
          final prefs = await SharedPreferences.getInstance();
          await prefs.clear();
          SimplePushService().disconnect();
          
          if (mounted) {
            Navigator.pushNamedAndRemoveUntil(
              context,
              '/login',
              (route) => false,
            );
          }
        },
        backgroundColor: Colors.red,
        child: const Icon(Icons.logout, color: Colors.white),
        tooltip: _selectedLanguage == 'de' ? 'Abmelden' : 'Logout',
      ),
    );
  }
  
  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 48,
                  color: color,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: GoogleFonts.lato(
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
  
  void _showEnhancedNotificationSettings() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => DraggableScrollableSheet(
          initialChildSize: 0.9,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) => Container(
            padding: const EdgeInsets.all(20),
            child: ListView(
              controller: scrollController,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _selectedLanguage == 'de' ? 'Benachrichtigungen' : 'Notifications',
                      style: GoogleFonts.lato(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                
                // Master switch
                Card(
                  child: SwitchListTile(
                    title: Text(
                      _selectedLanguage == 'de' ? 'Push-Benachrichtigungen' : 'Push Notifications',
                      style: GoogleFonts.lato(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      _selectedLanguage == 'de' 
                        ? 'Hauptschalter für alle Benachrichtigungen'
                        : 'Master switch for all notifications',
                      style: GoogleFonts.lato(),
                    ),
                    value: _pushNotificationsEnabled,
                    onChanged: (value) {
                      setModalState(() {
                        _pushNotificationsEnabled = value;
                      });
                      setState(() {
                        _pushNotificationsEnabled = value;
                      });
                      _saveSettings();
                    },
                    activeColor: Colors.green,
                  ),
                ),
                
                if (_pushNotificationsEnabled) ...[
                  const SizedBox(height: 20),
                  Text(
                    _selectedLanguage == 'de' ? 'Benachrichtigungsverhalten' : 'Notification Behavior',
                    style: GoogleFonts.lato(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  
                  // Sound settings
                  Card(
                    child: Column(
                      children: [
                        SwitchListTile(
                          title: Text(
                            _selectedLanguage == 'de' ? 'Ton' : 'Sound',
                            style: GoogleFonts.lato(),
                          ),
                          subtitle: Text(
                            _selectedLanguage == 'de' 
                              ? 'Benachrichtigungston abspielen'
                              : 'Play notification sound',
                            style: GoogleFonts.lato(fontSize: 12),
                          ),
                          value: _notificationSoundEnabled,
                          onChanged: (value) {
                            setModalState(() {
                              _notificationSoundEnabled = value;
                            });
                            setState(() {
                              _notificationSoundEnabled = value;
                            });
                            _saveSettings();
                          },
                          activeColor: Colors.green,
                        ),
                        if (_notificationSoundEnabled)
                          ListTile(
                            title: Text(
                              _selectedLanguage == 'de' ? 'Benachrichtigungston' : 'Notification Sound',
                              style: GoogleFonts.lato(),
                            ),
                            subtitle: Text(
                              _notificationSounds.firstWhere(
                                (sound) => sound['id'] == _notificationSound,
                                orElse: () => _notificationSounds.first,
                              )['name']!,
                              style: GoogleFonts.lato(),
                            ),
                            trailing: const Icon(Icons.arrow_forward_ios),
                            onTap: () => _showSoundPicker(setModalState),
                          ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 10),
                  
                  // Vibration
                  Card(
                    child: SwitchListTile(
                      title: Text(
                        _selectedLanguage == 'de' ? 'Vibration' : 'Vibration',
                        style: GoogleFonts.lato(),
                      ),
                      subtitle: Text(
                        _selectedLanguage == 'de' 
                          ? 'Bei Benachrichtigungen vibrieren'
                          : 'Vibrate on notifications',
                        style: GoogleFonts.lato(fontSize: 12),
                      ),
                      value: _notificationVibrationEnabled,
                      onChanged: (value) {
                        setModalState(() {
                          _notificationVibrationEnabled = value;
                        });
                        setState(() {
                          _notificationVibrationEnabled = value;
                        });
                        _saveSettings();
                      },
                      activeColor: Colors.green,
                    ),
                  ),
                  
                  const SizedBox(height: 10),
                  
                  // Heads up notifications
                  Card(
                    child: SwitchListTile(
                      title: Text(
                        _selectedLanguage == 'de' ? 'Pop-up Benachrichtigungen' : 'Heads-up Notifications',
                        style: GoogleFonts.lato(),
                      ),
                      subtitle: Text(
                        _selectedLanguage == 'de' 
                          ? 'Benachrichtigungen oben am Bildschirm anzeigen'
                          : 'Show notifications at top of screen',
                        style: GoogleFonts.lato(fontSize: 12),
                      ),
                      value: _notificationHeadsUpEnabled,
                      onChanged: (value) {
                        setModalState(() {
                          _notificationHeadsUpEnabled = value;
                        });
                        setState(() {
                          _notificationHeadsUpEnabled = value;
                        });
                        _saveSettings();
                      },
                      activeColor: Colors.green,
                    ),
                  ),
                  
                  const SizedBox(height: 10),
                  
                  // Importance level
                  Card(
                    child: ListTile(
                      title: Text(
                        _selectedLanguage == 'de' ? 'Priorität' : 'Priority',
                        style: GoogleFonts.lato(),
                      ),
                      subtitle: Text(
                        _getImportanceText(_notificationImportance),
                        style: GoogleFonts.lato(),
                      ),
                      trailing: const Icon(Icons.arrow_forward_ios),
                      onTap: () => _showImportancePicker(setModalState),
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  Text(
                    _selectedLanguage == 'de' ? 'Benachrichtigungskategorien' : 'Notification Categories',
                    style: GoogleFonts.lato(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  
                  // Category switches
                  Card(
                    child: Column(
                      children: [
                        SwitchListTile(
                          title: Text(
                            _selectedLanguage == 'de' ? 'Gesundheitswarnungen' : 'Health Alerts',
                            style: GoogleFonts.lato(),
                          ),
                          subtitle: Text(
                            _selectedLanguage == 'de' 
                              ? 'Wichtige Gesundheitsinformationen'
                              : 'Important health information',
                            style: GoogleFonts.lato(fontSize: 12),
                          ),
                          secondary: const Icon(Icons.health_and_safety, color: Colors.red),
                          value: _healthAlertsEnabled,
                          onChanged: (value) {
                            setModalState(() {
                              _healthAlertsEnabled = value;
                            });
                            setState(() {
                              _healthAlertsEnabled = value;
                            });
                            _saveSettings();
                          },
                          activeColor: Colors.green,
                        ),
                        const Divider(),
                        SwitchListTile(
                          title: Text(
                            _selectedLanguage == 'de' ? 'Community Updates' : 'Community Updates',
                            style: GoogleFonts.lato(),
                          ),
                          subtitle: Text(
                            _selectedLanguage == 'de' 
                              ? 'Neuigkeiten aus Ihrer Community'
                              : 'News from your community',
                            style: GoogleFonts.lato(fontSize: 12),
                          ),
                          secondary: const Icon(Icons.group, color: Colors.blue),
                          value: _communityUpdatesEnabled,
                          onChanged: (value) {
                            setModalState(() {
                              _communityUpdatesEnabled = value;
                            });
                            setState(() {
                              _communityUpdatesEnabled = value;
                            });
                            _saveSettings();
                          },
                          activeColor: Colors.green,
                        ),
                        const Divider(),
                        SwitchListTile(
                          title: Text(
                            _selectedLanguage == 'de' ? 'Terminerinnerungen' : 'Appointment Reminders',
                            style: GoogleFonts.lato(),
                          ),
                          subtitle: Text(
                            _selectedLanguage == 'de' 
                              ? 'Erinnerungen an bevorstehende Termine'
                              : 'Reminders for upcoming appointments',
                            style: GoogleFonts.lato(fontSize: 12),
                          ),
                          secondary: const Icon(Icons.calendar_today, color: Colors.orange),
                          value: _appointmentRemindersEnabled,
                          onChanged: (value) {
                            setModalState(() {
                              _appointmentRemindersEnabled = value;
                            });
                            setState(() {
                              _appointmentRemindersEnabled = value;
                            });
                            _saveSettings();
                          },
                          activeColor: Colors.green,
                        ),
                        const Divider(),
                        SwitchListTile(
                          title: Text(
                            _selectedLanguage == 'de' ? '🚨 Notfallwarnungen' : '🚨 Emergency Alerts',
                            style: GoogleFonts.lato(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            _selectedLanguage == 'de' 
                              ? 'Kritische Notfallbenachrichtigungen (immer aktiv)'
                              : 'Critical emergency notifications (always active)',
                            style: GoogleFonts.lato(fontSize: 12, color: Colors.red),
                          ),
                          secondary: const Icon(Icons.warning, color: Colors.red),
                          value: _emergencyAlertsEnabled,
                          onChanged: (value) {
                            setModalState(() {
                              _emergencyAlertsEnabled = value;
                            });
                            setState(() {
                              _emergencyAlertsEnabled = value;
                            });
                            _saveSettings();
                          },
                          activeColor: Colors.red,
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  Text(
                    _selectedLanguage == 'de' ? 'Ruhezeiten' : 'Quiet Hours',
                    style: GoogleFonts.lato(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  
                  // Quiet hours
                  Card(
                    child: Column(
                      children: [
                        SwitchListTile(
                          title: Text(
                            _selectedLanguage == 'de' ? 'Ruhezeiten aktivieren' : 'Enable Quiet Hours',
                            style: GoogleFonts.lato(),
                          ),
                          subtitle: Text(
                            _selectedLanguage == 'de' 
                              ? 'Keine Benachrichtigungen während der Ruhezeiten'
                              : 'No notifications during quiet hours',
                            style: GoogleFonts.lato(fontSize: 12),
                          ),
                          value: _quietHoursEnabled,
                          onChanged: (value) {
                            setModalState(() {
                              _quietHoursEnabled = value;
                            });
                            setState(() {
                              _quietHoursEnabled = value;
                            });
                            _saveSettings();
                          },
                          activeColor: Colors.green,
                        ),
                        if (_quietHoursEnabled) ...[
                          const Divider(),
                          ListTile(
                            title: Text(
                              _selectedLanguage == 'de' ? 'Beginn' : 'Start',
                              style: GoogleFonts.lato(),
                            ),
                            subtitle: Text(
                              _quietHoursStart.format(context),
                              style: GoogleFonts.lato(),
                            ),
                            trailing: const Icon(Icons.access_time),
                            onTap: () async {
                              final time = await showTimePicker(
                                context: context,
                                initialTime: _quietHoursStart,
                              );
                              if (time != null) {
                                setModalState(() {
                                  _quietHoursStart = time;
                                });
                                setState(() {
                                  _quietHoursStart = time;
                                });
                                _saveSettings();
                              }
                            },
                          ),
                          ListTile(
                            title: Text(
                              _selectedLanguage == 'de' ? 'Ende' : 'End',
                              style: GoogleFonts.lato(),
                            ),
                            subtitle: Text(
                              _quietHoursEnd.format(context),
                              style: GoogleFonts.lato(),
                            ),
                            trailing: const Icon(Icons.access_time),
                            onTap: () async {
                              final time = await showTimePicker(
                                context: context,
                                initialTime: _quietHoursEnd,
                              );
                              if (time != null) {
                                setModalState(() {
                                  _quietHoursEnd = time;
                                });
                                setState(() {
                                  _quietHoursEnd = time;
                                });
                                _saveSettings();
                              }
                            },
                          ),
                        ],
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Test notifications
                  Text(
                    _selectedLanguage == 'de' ? 'Test' : 'Test',
                    style: GoogleFonts.lato(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  
                  Card(
                    child: Column(
                      children: [
                        ListTile(
                          title: Text(
                            _selectedLanguage == 'de' ? 'Test-Benachrichtigung senden' : 'Send Test Notification',
                            style: GoogleFonts.lato(),
                          ),
                          subtitle: Text(
                            _selectedLanguage == 'de' 
                              ? 'Testet Ihre aktuellen Einstellungen'
                              : 'Tests your current settings',
                            style: GoogleFonts.lato(fontSize: 12),
                          ),
                          trailing: const Icon(Icons.send),
                          onTap: () async {
                            await SimplePushService().sendTestNotification(priority: 'normal');
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  _selectedLanguage == 'de' 
                                    ? 'Test-Benachrichtigung gesendet!'
                                    : 'Test notification sent!',
                                ),
                                backgroundColor: Colors.green,
                              ),
                            );
                          },
                        ),
                        const Divider(),
                        ListTile(
                          title: Text(
                            _selectedLanguage == 'de' ? 'Notfall-Test senden' : 'Send Emergency Test',
                            style: GoogleFonts.lato(color: Colors.red),
                          ),
                          subtitle: Text(
                            _selectedLanguage == 'de' 
                              ? 'Testet Notfall-Benachrichtigungen'
                              : 'Tests emergency notifications',
                            style: GoogleFonts.lato(fontSize: 12),
                          ),
                          trailing: const Icon(Icons.warning, color: Colors.red),
                          onTap: () async {
                            await SimplePushService().sendEmergencyNotification(
                              title: 'Test Notfall',
                              body: 'Dies ist eine Test-Notfallbenachrichtigung',
                            );
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  _selectedLanguage == 'de' 
                                    ? 'Notfall-Test gesendet!'
                                    : 'Emergency test sent!',
                                ),
                                backgroundColor: Colors.red,
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
                
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  String _getImportanceText(String importance) {
    switch (importance) {
      case 'max':
        return _selectedLanguage == 'de' ? 'Höchste Priorität' : 'Maximum Priority';
      case 'high':
        return _selectedLanguage == 'de' ? 'Hohe Priorität' : 'High Priority';
      case 'low':
        return _selectedLanguage == 'de' ? 'Niedrige Priorität' : 'Low Priority';
      case 'min':
        return _selectedLanguage == 'de' ? 'Minimale Priorität' : 'Minimum Priority';
      default:
        return _selectedLanguage == 'de' ? 'Standard' : 'Default';
    }
  }
  
  void _showSoundPicker(StateSetter setModalState) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          _selectedLanguage == 'de' ? 'Benachrichtigungston wählen' : 'Choose Notification Sound',
          style: GoogleFonts.lato(),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: _notificationSounds.map((sound) => RadioListTile<String>(
            title: Text(sound['name']!, style: GoogleFonts.lato()),
            value: sound['id']!,
            groupValue: _notificationSound,
            onChanged: (value) {
              setModalState(() {
                _notificationSound = value!;
              });
              setState(() {
                _notificationSound = value!;
              });
              _saveSettings();
              Navigator.pop(context);
              
              // Play preview sound
              SimplePushService().sendTestNotification(priority: 'low');
            },
          )).toList(),
        ),
      ),
    );
  }
  
  void _showImportancePicker(StateSetter setModalState) {
    final importanceLevels = [
      {'id': 'max', 'name': _selectedLanguage == 'de' ? 'Höchste Priorität' : 'Maximum Priority'},
      {'id': 'high', 'name': _selectedLanguage == 'de' ? 'Hohe Priorität' : 'High Priority'},
      {'id': 'default', 'name': _selectedLanguage == 'de' ? 'Standard' : 'Default'},
      {'id': 'low', 'name': _selectedLanguage == 'de' ? 'Niedrige Priorität' : 'Low Priority'},
      {'id': 'min', 'name': _selectedLanguage == 'de' ? 'Minimale Priorität' : 'Minimum Priority'},
    ];
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          _selectedLanguage == 'de' ? 'Priorität wählen' : 'Choose Priority',
          style: GoogleFonts.lato(),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: importanceLevels.map((level) => RadioListTile<String>(
            title: Text(level['name']!, style: GoogleFonts.lato()),
            value: level['id']!,
            groupValue: _notificationImportance,
            onChanged: (value) {
              setModalState(() {
                _notificationImportance = value!;
              });
              setState(() {
                _notificationImportance = value!;
              });
              _saveSettings();
              Navigator.pop(context);
            },
          )).toList(),
        ),
      ),
    );
  }
  
  void _showCommunitySelection() {
    final communities = [
      {'id': 'all_communities', 'name': 'Alle Communities'},
      {'id': 'aboriginal_health', 'name': 'Aboriginal Health'},
      {'id': 'torres_strait', 'name': 'Torres Strait'},
      {'id': 'remote_communities', 'name': 'Remote Communities'},
      {'id': 'urban_indigenous', 'name': 'Urban Indigenous'},
    ];
    
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _selectedLanguage == 'de' ? 'Community wählen' : 'Select Community',
                  style: GoogleFonts.lato(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ...communities.map((community) => ListTile(
              title: Text(community['name']!, style: GoogleFonts.lato()),
              leading: Radio<String>(
                value: community['id']!,
                groupValue: _selectedCommunity,
                onChanged: (value) {
                  setState(() {
                    _selectedCommunity = value!;
                  });
                  _saveSettings();
                  Navigator.pop(context);
                },
                activeColor: Colors.green,
              ),
            )).toList(),
          ],
        ),
      ),
    );
  }
  
  void _showLanguageSelection() {
    final languages = [
      {'code': 'de', 'name': 'Deutsch'},
      {'code': 'en', 'name': 'English'},
      {'code': 'indigenous_au', 'name': 'Indigenous Languages'},
    ];
    
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _selectedLanguage == 'de' ? 'Sprache wählen' : 'Select Language',
                  style: GoogleFonts.lato(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ...languages.map((language) => ListTile(
              title: Text(language['name']!, style: GoogleFonts.lato()),
              leading: Radio<String>(
                value: language['code']!,
                groupValue: _selectedLanguage,
                onChanged: (value) {
                  setState(() {
                    _selectedLanguage = value!;
                  });
                  _saveSettings();
                  Navigator.pop(context);
                },
                activeColor: Colors.green,
              ),
            )).toList(),
          ],
        ),
      ),
    );
  }
  
  void _showPrivacySettings() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _selectedLanguage == 'de' ? 'Datenschutz' : 'Privacy',
                    style: GoogleFonts.lato(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              SwitchListTile(
                title: Text(
                  _selectedLanguage == 'de' 
                    ? 'Anonyme Nutzungsdaten teilen'
                    : 'Share anonymous usage data',
                  style: GoogleFonts.lato(),
                ),
                subtitle: Text(
                  _selectedLanguage == 'de'
                    ? 'Hilft uns, die App zu verbessern'
                    : 'Helps us improve the app',
                  style: GoogleFonts.lato(fontSize: 12),
                ),
                value: _shareAnonymousData,
                onChanged: (value) {
                  setModalState(() {
                    _shareAnonymousData = value;
                  });
                  setState(() {
                    _shareAnonymousData = value;
                  });
                  _saveSettings();
                },
                activeColor: Colors.green,
              ),
              const Divider(),
              SwitchListTile(
                title: Text(
                  _selectedLanguage == 'de' ? 'Standortdienste' : 'Location Services',
                  style: GoogleFonts.lato(),
                ),
                subtitle: Text(
                  _selectedLanguage == 'de'
                    ? 'Für lokale Gesundheitsdienste'
                    : 'For local health services',
                  style: GoogleFonts.lato(fontSize: 12),
                ),
                value: _locationServicesEnabled,
                onChanged: (value) {
                  setModalState(() {
                    _locationServicesEnabled = value;
                  });
                  setState(() {
                    _locationServicesEnabled = value;
                  });
                  _saveSettings();
                },
                activeColor: Colors.green,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _showDataProtectionInfo();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  minimumSize: const Size(double.infinity, 48),
                ),
                child: Text(
                  _selectedLanguage == 'de' 
                    ? 'Datenschutzerklärung lesen'
                    : 'Read Privacy Policy',
                  style: GoogleFonts.lato(color: Colors.white),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
  
  void _showDataProtectionInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          _selectedLanguage == 'de' ? 'Datenschutzerklärung' : 'Privacy Policy',
          style: GoogleFonts.lato(fontWeight: FontWeight.bold),
        ),
        content: SingleChildScrollView(
          child: Text(
            _selectedLanguage == 'de'
              ? '''
MedApp Datenschutzerklärung

1. Datenerhebung
Wir erheben nur die notwendigsten Daten für die Funktionalität der App:
- Registrierungsdaten (Name, E-Mail)
- Gesundheitsbezogene Daten (mit Ihrer Zustimmung)
- Nutzungsdaten (anonymisiert)

2. Datenspeicherung
Ihre Daten werden verschlüsselt und sicher auf Servern in Deutschland gespeichert.

3. Datenweitergabe
Ihre Daten werden niemals ohne Ihre ausdrückliche Zustimmung an Dritte weitergegeben.

4. Ihre Rechte
- Auskunft über gespeicherte Daten
- Berichtigung falscher Daten
- Löschung Ihrer Daten
- Datenportabilität

5. Kontakt
Datenschutzbeauftragter: privacy@medapp.com
              '''
              : '''
MedApp Privacy Policy

1. Data Collection
We only collect necessary data for app functionality:
- Registration data (name, email)
- Health-related data (with your consent)
- Usage data (anonymized)

2. Data Storage
Your data is encrypted and securely stored on servers in Germany.

3. Data Sharing
Your data will never be shared with third parties without your explicit consent.

4. Your Rights
- Access to stored data
- Correction of incorrect data
- Deletion of your data
- Data portability

5. Contact
Data Protection Officer: privacy@medapp.com
              ''',
            style: GoogleFonts.lato(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              _selectedLanguage == 'de' ? 'Schließen' : 'Close',
              style: GoogleFonts.lato(),
            ),
          ),
        ],
      ),
    );
  }
  
  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          _selectedLanguage == 'de' ? 'Über MedApp' : 'About MedApp',
          style: GoogleFonts.lato(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              leading: const Icon(Icons.info),
              title: Text('Version', style: GoogleFonts.lato()),
              subtitle: Text('1.0.0', style: GoogleFonts.lato()),
            ),
            ListTile(
              leading: const Icon(Icons.people),
              title: Text(
                _selectedLanguage == 'de' ? 'Entwickler' : 'Developer',
                style: GoogleFonts.lato(),
              ),
              subtitle: Text('MedApp Team', style: GoogleFonts.lato()),
            ),
            ListTile(
              leading: const Icon(Icons.email),
              title: Text('Support', style: GoogleFonts.lato()),
              subtitle: Text('support@medapp.com', style: GoogleFonts.lato()),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              _selectedLanguage == 'de' ? 'Schließen' : 'Close',
              style: GoogleFonts.lato(),
            ),
          ),
        ],
      ),
    );
  }
  
  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(
          _selectedLanguage == 'de' ? 'Konto löschen' : 'Delete Account',
          style: GoogleFonts.lato(
            fontWeight: FontWeight.bold,
            color: Colors.red,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _selectedLanguage == 'de'
                ? 'WARNUNG: Diese Aktion kann nicht rückgängig gemacht werden!'
                : 'WARNING: This action cannot be undone!',
              style: GoogleFonts.lato(
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _selectedLanguage == 'de'
                ? 'Alle Ihre Daten werden unwiderruflich gelöscht:\n• Persönliche Daten\n• Gesundheitsdaten\n• Nachrichten\n• Einstellungen'
                : 'All your data will be permanently deleted:\n• Personal data\n• Health data\n• Messages\n• Settings',
              style: GoogleFonts.lato(),
            ),
            const SizedBox(height: 16),
            Text(
              _selectedLanguage == 'de'
                ? 'Ein Bestätigungscode wurde an Ihre E-Mail gesendet.'
                : 'A confirmation code has been sent to your email.',
              style: GoogleFonts.lato(fontStyle: FontStyle.italic),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _deleteCodeController,
              decoration: InputDecoration(
                labelText: _selectedLanguage == 'de' 
                  ? 'Bestätigungscode eingeben'
                  : 'Enter confirmation code',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.lock),
              ),
              keyboardType: TextInputType.number,
              maxLength: 6,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: _deletionInProgress ? null : () {
              Navigator.pop(context);
              _deleteCodeController.clear();
            },
            child: Text(
              _selectedLanguage == 'de' ? 'Abbrechen' : 'Cancel',
              style: GoogleFonts.lato(),
            ),
          ),
          ElevatedButton(
            onPressed: _deletionInProgress ? null : () async {
              if (_deleteCodeController.text.length != 6) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      _selectedLanguage == 'de'
                        ? 'Bitte geben Sie den 6-stelligen Code ein'
                        : 'Please enter the 6-digit code',
                    ),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }
              
              setState(() {
                _deletionInProgress = true;
              });
              
              // Call delete endpoint
              await _deleteAccount(_deleteCodeController.text);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: _deletionInProgress
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : Text(
                  _selectedLanguage == 'de' 
                    ? 'Endgültig löschen'
                    : 'Delete permanently',
                  style: GoogleFonts.lato(color: Colors.white),
                ),
          ),
        ],
      ),
    );
  }
  
  Future<void> _deleteAccount(String confirmationCode) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id') ?? '';
      
      // Simulate API call - replace with actual endpoint
      final response = await http.delete(
        Uri.parse('http://localhost:8000/user/delete'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${prefs.getString('auth_token') ?? ''}',
        },
        body: json.encode({
          'user_id': userId,
          'confirmation_code': confirmationCode,
        }),
      );
      
      if (response.statusCode == 200) {
        // Success - clear all data and logout
        await prefs.clear();
        SimplePushService().disconnect();
        
        if (mounted) {
          Navigator.pushNamedAndRemoveUntil(
            context,
            '/login',
            (route) => false,
          );
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                _selectedLanguage == 'de'
                  ? 'Ihr Konto wurde erfolgreich gelöscht'
                  : 'Your account has been successfully deleted',
              ),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        // Error
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                _selectedLanguage == 'de'
                  ? 'Fehler: Ungültiger Code oder Serverprobleme'
                  : 'Error: Invalid code or server issues',
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _selectedLanguage == 'de'
                ? 'Netzwerkfehler: $e'
                : 'Network error: $e',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _deletionInProgress = false;
      });
      _deleteCodeController.clear();
    }
  }
  
  @override
  void dispose() {
    _deleteCodeController.dispose();
    super.dispose();
  }
}