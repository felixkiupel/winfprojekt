// push_service.dart - Vereinfachter Push Service OHNE Firebase
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'dart:async';

class SimplePushService {
  static final SimplePushService _instance = SimplePushService._internal();
  factory SimplePushService() => _instance;
  SimplePushService._internal();

  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  
  WebSocketChannel? _channel;
  String? _currentUserId;
  StreamController<Map<String, dynamic>>? _messageController;
  
  // API Configuration - ÄNDERE DIESE FÜR DEIN SETUP
  static const String API_BASE_URL = 'http://localhost:8000'; // Für Web/Desktop
  // static const String API_BASE_URL = 'http://10.0.2.2:8000'; // Für Android Emulator
  // static const String API_BASE_URL = 'http://DEINE_IP:8000'; // Für echtes Gerät
  
  static String get WS_BASE_URL => API_BASE_URL.replaceFirst('http', 'ws');

  // Message Stream
  Stream<Map<String, dynamic>> get messageStream {
    _messageController ??= StreamController<Map<String, dynamic>>.broadcast();
    return _messageController!.stream;
  }

  // Initialize push notifications
  Future<void> initialize({required String userId}) async {
    _currentUserId = userId;
    
    // Initialize local notifications
    await _initializeLocalNotifications();
    
    // Warte kurz bevor WebSocket verbindet (Server muss ready sein)
    await Future.delayed(const Duration(seconds: 1));
    
    // Connect to WebSocket
    _connectWebSocket();
    
    // Register device (für später)
    await _registerDevice();
  }

  // Initialize local notifications
  Future<void> _initializeLocalNotifications() async {
    const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    
    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    
    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );
    
    print('✅ Local notifications initialized');
  }

  // Handle notification tap
  void _onNotificationTapped(NotificationResponse response) {
    if (response.payload != null) {
      try {
        final data = json.decode(response.payload!);
        print('Notification tapped: $data');
        // TODO: Navigate to specific screen based on data
      } catch (e) {
        print('Error parsing notification payload: $e');
      }
    }
  }

  // Register device
  Future<void> _registerDevice() async {
    try {
      final deviceId = DateTime.now().millisecondsSinceEpoch.toString(); // Simple device ID
      
      final response = await http.post(
        Uri.parse('$API_BASE_URL/register-device'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'user_id': _currentUserId,
          'device_id': deviceId,
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
      // Retry nach 5 Sekunden
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
          _showNotification(
            title: notification['title'] ?? 'MedApp',
            body: notification['body'] ?? '',
            payload: notification,
          );
        }
        break;
        
      case 'connected':
        print('✅ WebSocket connected: ${data['message']}');
        break;
        
      case 'unread_count':
        print('📊 Unread count: ${data['count']}');
        break;
        
      default:
        print('Unknown message type: $messageType');
    }
  }

  // Show local notification
  Future<void> _showNotification({
    required String title,
    required String body,
    Map<String, dynamic>? payload,
  }) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'medapp_channel',
      'MedApp Notifications',
      channelDescription: 'Health updates and important messages',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
    );
    
    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    
    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );
    
    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      notificationDetails,
      payload: payload != null ? json.encode(payload) : null,
    );
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
    // Return cached value or fetch from API
    return 0;
  }

  // Send test notification (für Testing)
  Future<void> sendTestNotification() async {
    await _showNotification(
      title: 'Test Notification',
      body: 'Dies ist eine Test-Benachrichtigung von MedApp',
      payload: {'type': 'test', 'timestamp': DateTime.now().toIso8601String()},
    );
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