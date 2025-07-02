import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

class SimplePushService {
  static final SimplePushService _instance = SimplePushService._internal();
  factory SimplePushService() => _instance;
  SimplePushService._internal() {
    // Initialize timezone
    tz.initializeTimeZones();
  }

  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  
  WebSocketChannel? _channel;
  String? _currentUserId;
  StreamController<Map<String, dynamic>>? _messageController;
  
  // Notification Settings
  bool _notificationsEnabled = true;
  bool _soundEnabled = true;
  bool _vibrationEnabled = true;
  bool _headsUpEnabled = true;
  String _notificationSound = 'default';
  String _notificationImportance = 'high';
  
  // Category Settings
  bool _healthAlertsEnabled = true;
  bool _communityUpdatesEnabled = true;
  bool _appointmentRemindersEnabled = true;
  bool _emergencyAlertsEnabled = true;
  
  // Quiet Hours
  bool _quietHoursEnabled = false;
  String _quietHoursStart = '22:00';
  String _quietHoursEnd = '07:00';
  
  // API Configuration
  static const String API_BASE_URL = 'http://localhost:8000';
  static String get WS_BASE_URL => API_BASE_URL.replaceFirst('http', 'ws');

  // Notification Channel IDs
  static const String CHANNEL_HIGH = 'medapp_high_importance';
  static const String CHANNEL_DEFAULT = 'medapp_default';
  static const String CHANNEL_LOW = 'medapp_low_importance';
  static const String CHANNEL_EMERGENCY = 'medapp_emergency';

  // Message Stream
  Stream<Map<String, dynamic>> get messageStream {
    _messageController ??= StreamController<Map<String, dynamic>>.broadcast();
    return _messageController!.stream;
  }

  // Initialize push notifications with enhanced settings
  Future<void> initialize({required String userId}) async {
    _currentUserId = userId;
    
    // Load notification preferences
    await _loadNotificationSettings();
    
    // Initialize local notifications with channels
    await _initializeLocalNotifications();
    
    // Request permissions
    await _requestPermissions();
    
    // Setup background message handler
    await _setupBackgroundMessageHandler();
    
    // Connect to WebSocket
    _connectWebSocket();
    
    // Register device
    await _registerDevice();
  }

  // Load notification settings from SharedPreferences
  Future<void> _loadNotificationSettings() async {
    final prefs = await SharedPreferences.getInstance();
    
    _notificationsEnabled = prefs.getBool('notifications_enabled') ?? true;
    _soundEnabled = prefs.getBool('notification_sound_enabled') ?? true;
    _vibrationEnabled = prefs.getBool('notification_vibration_enabled') ?? true;
    _headsUpEnabled = prefs.getBool('notification_heads_up_enabled') ?? true;
    _notificationSound = prefs.getString('notification_sound') ?? 'default';
    _notificationImportance = prefs.getString('notification_importance') ?? 'high';
    
    // Category settings
    _healthAlertsEnabled = prefs.getBool('health_alerts_enabled') ?? true;
    _communityUpdatesEnabled = prefs.getBool('community_updates_enabled') ?? true;
    _appointmentRemindersEnabled = prefs.getBool('appointment_reminders_enabled') ?? true;
    _emergencyAlertsEnabled = prefs.getBool('emergency_alerts_enabled') ?? true;
    
    // Quiet hours
    _quietHoursEnabled = prefs.getBool('quiet_hours_enabled') ?? false;
    _quietHoursStart = prefs.getString('quiet_hours_start') ?? '22:00';
    _quietHoursEnd = prefs.getString('quiet_hours_end') ?? '07:00';
  }

  // Save notification settings
  Future<void> saveNotificationSettings(Map<String, dynamic> settings) async {
    final prefs = await SharedPreferences.getInstance();
    
    // Update local variables and save to preferences
    settings.forEach((key, value) async {
      switch (key) {
        case 'notifications_enabled':
          _notificationsEnabled = value as bool;
          await prefs.setBool(key, value);
          break;
        case 'notification_sound_enabled':
          _soundEnabled = value as bool;
          await prefs.setBool(key, value);
          break;
        case 'notification_vibration_enabled':
          _vibrationEnabled = value as bool;
          await prefs.setBool(key, value);
          break;
        case 'notification_heads_up_enabled':
          _headsUpEnabled = value as bool;
          await prefs.setBool(key, value);
          break;
        case 'notification_sound':
          _notificationSound = value as String;
          await prefs.setString(key, value);
          break;
        case 'notification_importance':
          _notificationImportance = value as String;
          await prefs.setString(key, value);
          break;
        default:
          if (value is bool) {
            await prefs.setBool(key, value);
          } else if (value is String) {
            await prefs.setString(key, value);
          }
      }
    });
    
    // Reinitialize notifications with new settings
    await _initializeLocalNotifications();
  }

  // Initialize local notifications with multiple channels
  Future<void> _initializeLocalNotifications() async {
    // Android initialization with multiple notification channels
    const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    
    // iOS/macOS initialization
    const DarwinInitializationSettings iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    
    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
      macOS: iosSettings,
    );
    
    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
      onDidReceiveBackgroundNotificationResponse: _onBackgroundNotificationTapped,
    );
    
    // Create notification channels for Android
    if (!kIsWeb && Platform.isAndroid) {
      await _createNotificationChannels();
    }
    
    print('✅ Enhanced local notifications initialized');
  }

  // Create Android notification channels
  Future<void> _createNotificationChannels() async {
    final androidPlugin = _localNotifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    
    if (androidPlugin != null) {
      // High importance channel
      await androidPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          CHANNEL_HIGH,
          'Wichtige Benachrichtigungen',
          description: 'Gesundheitswarnungen und wichtige Updates',
          importance: Importance.high,
          playSound: true,
          enableVibration: true,
          enableLights: true,
          ledColor: Color(0xFFFF0000),
        ),
      );
      
      // Default channel
      await androidPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          CHANNEL_DEFAULT,
          'Allgemeine Benachrichtigungen',
          description: 'Community Updates und allgemeine Informationen',
          importance: Importance.defaultImportance,
          playSound: true,
          enableVibration: true,
        ),
      );
      
      // Low importance channel
      await androidPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          CHANNEL_LOW,
          'Stille Benachrichtigungen',
          description: 'Weniger wichtige Updates',
          importance: Importance.low,
          playSound: false,
          enableVibration: false,
        ),
      );
      
      // Emergency channel
      await androidPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          CHANNEL_EMERGENCY,
          'Notfall-Benachrichtigungen',
          description: 'Kritische Notfallwarnungen',
          importance: Importance.max,
          playSound: true,
          enableVibration: true,
          enableLights: true,
          ledColor: Color(0xFFFF0000),
        ),
      );
    }
  }

  // Request notification permissions
  Future<void> _requestPermissions() async {
    if (!kIsWeb) {
      if (Platform.isIOS || Platform.isMacOS) {
        await _localNotifications
            .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
            ?.requestPermissions(
              alert: true,
              badge: true,
              sound: true,
              critical: true, // For emergency notifications
            );
      } else if (Platform.isAndroid) {
        final AndroidFlutterLocalNotificationsPlugin? androidPlugin =
            _localNotifications.resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>();
        
        // Request exact alarm permission for scheduled notifications
        await androidPlugin?.requestExactAlarmsPermission();
        
        // Request notification permission (Android 13+)
        await androidPlugin?.requestNotificationsPermission();
      }
    }
  }

  // Setup background message handler
  Future<void> _setupBackgroundMessageHandler() async {
    // This would integrate with firebase_messaging or similar
    // For now, we'll handle background through WebSocket reconnection
  }

  // Handle notification tap
  void _onNotificationTapped(NotificationResponse response) {
    if (response.payload != null) {
      try {
        final data = json.decode(response.payload!);
        print('Notification tapped: $data');
        
        // Broadcast tap event
        _messageController?.add({
          'type': 'notification_tapped',
          'data': data,
        });
        
        // TODO: Navigate to specific screen based on data
      } catch (e) {
        print('Error parsing notification payload: $e');
      }
    }
  }

  // Handle background notification tap
  @pragma('vm:entry-point')
  static void _onBackgroundNotificationTapped(NotificationResponse response) {
    // Handle notification tap when app is terminated
    print('Background notification tapped: ${response.payload}');
  }

  // Check if within quiet hours
  bool _isInQuietHours() {
    if (!_quietHoursEnabled) return false;
    
    final now = DateTime.now();
    final currentTime = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    
    // Simple comparison (doesn't handle overnight quiet hours perfectly)
    if (_quietHoursStart.compareTo(_quietHoursEnd) < 0) {
      // Same day quiet hours (e.g., 09:00 - 17:00)
      return currentTime.compareTo(_quietHoursStart) >= 0 && 
             currentTime.compareTo(_quietHoursEnd) <= 0;
    } else {
      // Overnight quiet hours (e.g., 22:00 - 07:00)
      return currentTime.compareTo(_quietHoursStart) >= 0 || 
             currentTime.compareTo(_quietHoursEnd) <= 0;
    }
  }

  // Should show notification based on category
  bool _shouldShowNotification(String category) {
    if (!_notificationsEnabled) return false;
    
    // Always show emergency alerts unless completely disabled
    if (category == 'emergency' && _emergencyAlertsEnabled) {
      return true;
    }
    
    // Check quiet hours for non-emergency
    if (_isInQuietHours()) {
      return false;
    }
    
    // Check category settings
    switch (category) {
      case 'health':
        return _healthAlertsEnabled;
      case 'community':
        return _communityUpdatesEnabled;
      case 'appointment':
        return _appointmentRemindersEnabled;
      default:
        return true;
    }
  }

  // Get notification channel based on priority and settings
  String _getNotificationChannel(String priority, String category) {
    if (category == 'emergency') {
      return CHANNEL_EMERGENCY;
    }
    
    switch (_notificationImportance) {
      case 'high':
        return CHANNEL_HIGH;
      case 'low':
        return CHANNEL_LOW;
      default:
        return CHANNEL_DEFAULT;
    }
  }

  // Register device
  Future<void> _registerDevice() async {
    try {
      final deviceId = DateTime.now().millisecondsSinceEpoch.toString();
      
      final response = await http.post(
        Uri.parse('$API_BASE_URL/register-device'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'user_id': _currentUserId,
          'device_id': deviceId,
          'platform': kIsWeb ? 'web' : Platform.operatingSystem,
          'notification_settings': {
            'enabled': _notificationsEnabled,
            'sound': _soundEnabled,
            'vibration': _vibrationEnabled,
          }
        }),
      );
      
      if (response.statusCode == 200) {
        print('✅ Device registered successfully');
      }
    } catch (e) {
      print('Error registering device: $e');
    }
  }

  // Connect to WebSocket
  void _connectWebSocket() {
    if (_currentUserId == null) return;
    
    try {
      final wsUrl = '$WS_BASE_URL/ws/$_currentUserId';
      print('🔌 Connecting to WebSocket: $wsUrl');
      
      _channel = WebSocketChannel.connect(Uri.parse(wsUrl));
      
      _channel!.stream.listen(
        (message) {
          print('📨 WebSocket message: $message');
          try {
            final data = json.decode(message);
            _handleWebSocketMessage(data);
          } catch (e) {
            print('Error parsing WebSocket message: $e');
          }
        },
        onError: (error) {
          print('❌ WebSocket error: $error');
          // Reconnect after delay
          Future.delayed(const Duration(seconds: 5), _connectWebSocket);
        },
        onDone: () {
          print('WebSocket connection closed');
          // Reconnect after delay
          Future.delayed(const Duration(seconds: 5), _connectWebSocket);
        },
      );
      
      // Start ping timer
      _startPingTimer();
      
    } catch (e) {
      print('Error connecting to WebSocket: $e');
      Future.delayed(const Duration(seconds: 5), _connectWebSocket);
    }
  }

  // Handle WebSocket messages
  void _handleWebSocketMessage(Map<String, dynamic> data) {
    final String? messageType = data['type'];
    
    // Broadcast to stream
    _messageController?.add(data);
    
    switch (messageType) {
      case 'push_notification':
        // Show local notification
        final notification = data['notification'];
        if (notification != null) {
          final category = notification['data']?['category'] ?? 'general';
          final priority = notification['data']?['priority'] ?? 'normal';
          
          if (_shouldShowNotification(category)) {
            _showEnhancedNotification(
              title: notification['title'] ?? 'MedApp',
              body: notification['body'] ?? '',
              payload: notification,
              category: category,
              priority: priority,
            );
          }
        }
        break;
        
      case 'connected':
        print('✅ WebSocket connected: ${data['message']}');
        break;
        
      case 'unread_count':
        print('📊 Unread count: ${data['count']}');
        // Update badge if supported
        _updateBadge(data['count'] ?? 0);
        break;
        
      default:
        print('Unknown message type: $messageType');
    }
  }

  // Show enhanced notification with all settings
  Future<void> _showEnhancedNotification({
    required String title,
    required String body,
    Map<String, dynamic>? payload,
    String category = 'general',
    String priority = 'normal',
  }) async {
    final channelId = _getNotificationChannel(priority, category);
    
    // Android specific settings
    final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      channelId,
      channelId == CHANNEL_EMERGENCY ? 'Notfall-Benachrichtigungen' : 'MedApp Benachrichtigungen',
      channelDescription: 'Gesundheitsupdates und wichtige Nachrichten',
      importance: _getAndroidImportance(),
      priority: _getAndroidPriority(priority),
      playSound: _soundEnabled && !_isInQuietHours(),
      enableVibration: _vibrationEnabled,
      enableLights: true,
      showWhen: true,
      styleInformation: BigTextStyleInformation(
        body,
        contentTitle: title,
        summaryText: category == 'emergency' ? '🚨 NOTFALL' : null,
      ),
      // Custom sound (place sound file in android/app/src/main/res/raw/)
      sound: _notificationSound == 'default' 
        ? null 
        : RawResourceAndroidNotificationSound(_notificationSound),
      // Actions
      actions: category == 'appointment' 
        ? <AndroidNotificationAction>[
            const AndroidNotificationAction(
              'confirm',
              'Bestätigen',
              showsUserInterface: true,
            ),
            const AndroidNotificationAction(
              'cancel',
              'Absagen',
              cancelNotification: true,
            ),
          ]
        : null,
    );
    
    // iOS specific settings
    final DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: _headsUpEnabled,
      presentBadge: true,
      presentSound: _soundEnabled && !_isInQuietHours(),
      sound: _notificationSound == 'default' ? null : '$_notificationSound.aiff',
      badgeNumber: null, // Will be set separately
      threadIdentifier: category, // Groups notifications by category
      categoryIdentifier: category == 'appointment' ? 'APPOINTMENT_CATEGORY' : null,
      interruptionLevel: category == 'emergency' 
        ? InterruptionLevel.critical 
        : InterruptionLevel.active,
    );
    
    final NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
      macOS: iosDetails,
    );
    
    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      notificationDetails,
      payload: payload != null ? json.encode(payload) : null,
    );
  }

  // Get Android importance based on settings
  Importance _getAndroidImportance() {
    switch (_notificationImportance) {
      case 'max':
        return Importance.max;
      case 'high':
        return Importance.high;
      case 'low':
        return Importance.low;
      case 'min':
        return Importance.min;
      default:
        return Importance.defaultImportance;
    }
  }

  // Get Android priority based on notification priority
  Priority _getAndroidPriority(String priority) {
    switch (priority) {
      case 'urgent':
      case 'emergency':
        return Priority.max;
      case 'high':
        return Priority.high;
      case 'low':
        return Priority.low;
      default:
        return Priority.defaultPriority;
    }
  }

  // Update app badge
  Future<void> _updateBadge(int count) async {
    if (!kIsWeb && (Platform.isIOS || Platform.isMacOS)) {
      // iOS/macOS badge update
      await _localNotifications
          .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(badge: true);
    }
    // Note: Android badges are handled automatically by the system
  }

  // Start ping timer
  void _startPingTimer() {
    Timer.periodic(const Duration(seconds: 30), (timer) {
      if (_channel != null) {
        try {
          _channel!.sink.add(json.encode({"type": "ping"}));
        } catch (e) {
          print('Error sending ping: $e');
          timer.cancel();
        }
      } else {
        timer.cancel();
      }
    });
  }

  // Schedule a notification
  Future<void> scheduleNotification({
    required String title,
    required String body,
    required DateTime scheduledDate,
    String category = 'appointment',
    Map<String, dynamic>? payload,
  }) async {
    if (!_shouldShowNotification(category)) return;
    
    // Convert DateTime to TZDateTime
    final tz.TZDateTime tzScheduledDate = tz.TZDateTime.from(
      scheduledDate,
      tz.local,
    );
    
    await _localNotifications.zonedSchedule(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      tzScheduledDate,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _getNotificationChannel('high', category),
          'Geplante Benachrichtigungen',
          channelDescription: 'Terminerinnerungen und geplante Updates',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: const DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: payload != null ? json.encode(payload) : null,
    );
  }

  // Cancel a scheduled notification
  Future<void> cancelScheduledNotification(int id) async {
    await _localNotifications.cancel(id);
  }

  // Get pending notifications
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    return await _localNotifications.pendingNotificationRequests();
  }

  // Test notification with different priorities
  Future<void> sendTestNotification({String priority = 'normal'}) async {
    await _showEnhancedNotification(
      title: 'Test Notification',
      body: 'Dies ist eine Test-Benachrichtigung mit Priorität: $priority',
      payload: {
        'type': 'test',
        'priority': priority,
        'timestamp': DateTime.now().toIso8601String()
      },
      category: 'test',
      priority: priority,
    );
  }

  // Send emergency notification
  Future<void> sendEmergencyNotification({
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    // Emergency notifications bypass all settings except global disable
    if (!_emergencyAlertsEnabled) return;
    
    await _showEnhancedNotification(
      title: '🚨 NOTFALL: $title',
      body: body,
      payload: {
        ...?data,
        'type': 'emergency',
        'priority': 'emergency',
        'timestamp': DateTime.now().toIso8601String(),
      },
      category: 'emergency',
      priority: 'emergency',
    );
  }

  // Get messages from API
  Future<List<Map<String, dynamic>>> getMessages({int limit = 20}) async {
    try {
      final response = await http.get(
        Uri.parse('$API_BASE_URL/messages?limit=$limit'),
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return List<Map<String, dynamic>>.from(data['messages']);
      }
    } catch (e) {
      print('Error fetching messages: $e');
    }
    return [];
  }

  // Mark message as read
  Future<void> markMessageAsRead(String messageId) async {
    try {
      final response = await http.post(
        Uri.parse('$API_BASE_URL/messages/$messageId/read'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(_currentUserId),
      );
      
      if (response.statusCode == 200) {
        print('✅ Message marked as read');
      }
    } catch (e) {
      print('Error marking message as read: $e');
    }
  }

  // Get unread count
  Future<int> getUnreadCount() async {
    if (_channel != null && _currentUserId != null) {
      _channel!.sink.add(json.encode({"type": "get_unread_count"}));
    }
    return 0;
  }

  // Disconnect
  void disconnect() {
    _channel?.sink.close();
    _channel = null;
    _messageController?.close();
    _messageController = null;
  }

  // Clean up resources
  void dispose() {
    disconnect();
  }
}