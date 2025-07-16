import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'dart:async';
import 'dart:io' show Platform;

class SimplePushService {
  static final SimplePushService _instance = SimplePushService._internal();
  factory SimplePushService() => _instance;
  SimplePushService._internal();

  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  
  WebSocketChannel? _channel;
  String? _currentUserId;
  String? _currentCommunity;
  StreamController<Map<String, dynamic>>? _messageController;
  bool _isConnected = false;
  Timer? _pingTimer;
  Timer? _reconnectTimer;
  
  // API Configuration
  static String get API_BASE_URL {
    if (Platform.isAndroid) {
      return 'http://10.0.2.2:8000';
    } else if (Platform.isIOS) {
      return 'http://localhost:8000';
    } else {
      return 'http://localhost:8000';
    }
  }
  
  static String get WS_BASE_URL => API_BASE_URL.replaceFirst('http', 'ws');

  // Connection status
  bool get isConnected => _isConnected;
  
  // Message Stream
  Stream<Map<String, dynamic>> get messageStream {
    _messageController ??= StreamController<Map<String, dynamic>>.broadcast();
    return _messageController!.stream;
  }

  // Initialize push notifications with community support
  Future<void> initialize({required String userId, String? communityId}) async {
    _currentUserId = userId;
    
    // Get community from preferences if not provided
    if (communityId == null) {
      final prefs = await SharedPreferences.getInstance();
      communityId = prefs.getString('selected_community') ?? 'all_communities';
    }
    _currentCommunity = communityId;
    
    // Initialize local notifications
    await _initializeLocalNotifications();
    
    // Wait before WebSocket connection
    await Future.delayed(const Duration(seconds: 1));
    
    // Connect to WebSocket
    _connectWebSocket();
    
    // Register device with community
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
        
        // Broadcast tap event
        _messageController?.add({
          'type': 'notification_tapped',
          'data': data,
          'timestamp': DateTime.now().toIso8601String()
        });
      } catch (e) {
        print('Error parsing notification payload: $e');
      }
    }
  }

  // Register device with community
  Future<void> _registerDevice() async {
    try {
      final deviceId = DateTime.now().millisecondsSinceEpoch.toString();
      
      final response = await http.post(
        Uri.parse('$API_BASE_URL/register-device'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'user_id': _currentUserId,
          'device_id': deviceId,
          'community_id': _currentCommunity,
        }),
      );
      
      if (response.statusCode == 200) {
        print('✅ Device registered successfully for community: $_currentCommunity');
      }
    } catch (e) {
      print('Error registering device: $e');
    }
  }

  // Update user community
  Future<void> updateUserCommunity(String userId, String communityId) async {
    _currentCommunity = communityId;
    
    try {
      // Send update via WebSocket if connected
      if (_channel != null && _isConnected) {
        _channel!.sink.add(json.encode({
          "type": "update_community",
          "community_id": communityId,
        }));
      }
      
      // Also update via API
      final response = await http.put(
        Uri.parse('$API_BASE_URL/user/community'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer test_token', // Add proper auth in production
        },
        body: json.encode({
          'user_id': userId,
          'community_id': communityId,
        }),
      );
      
      if (response.statusCode == 200) {
        print('✅ Community updated to: $communityId');
      }
    } catch (e) {
      print('Error updating community: $e');
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
          _isConnected = true;
          
          try {
            final data = json.decode(message);
            _handleWebSocketMessage(data);
          } catch (e) {
            print('Error parsing WebSocket message: $e');
          }
        },
        onError: (error) {
          print('❌ WebSocket error: $error');
          _isConnected = false;
          _scheduleReconnect();
        },
        onDone: () {
          print('WebSocket connection closed');
          _isConnected = false;
          _scheduleReconnect();
        },
      );
      
      // Start ping timer
      _startPingTimer();
      
    } catch (e) {
      print('Error connecting to WebSocket: $e');
      _scheduleReconnect();
    }
  }

  // Schedule reconnection
  void _scheduleReconnect() {
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 5), () {
      if (!_isConnected) {
        _connectWebSocket();
      }
    });
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
          // Check if notification is for user's community
          final msgCommunity = notification['community_id'] ?? 'all_communities';
          if (msgCommunity == 'all_communities' || msgCommunity == _currentCommunity || _currentCommunity == 'all_communities') {
            _showNotification(
              title: notification['title'] ?? 'MedApp',
              body: notification['body'] ?? '',
              payload: notification,
            );
          }
        }
        break;
        
      case 'connected':
        print('✅ WebSocket connected: ${data['message']}');
        _isConnected = true;
        break;
        
      case 'unread_count':
        print('📊 Unread count: ${data['count']}');
        break;
        
      case 'community_updated':
        print('👥 Community updated: ${data['community_id']}');
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
    _pingTimer?.cancel();
    _pingTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (_channel != null && _isConnected) {
        try {
          _channel!.sink.add(json.encode({"type": "ping"}));
        } catch (e) {
          print('Error sending ping: $e');
          timer.cancel();
        }
      }
    });
  }

  // Get messages with community filter
  Future<List<Map<String, dynamic>>> getMessages({int limit = 20}) async {
    try {
      final response = await http.get(
        Uri.parse('$API_BASE_URL/messages?limit=$limit&user_id=$_currentUserId'),
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
    if (_channel != null && _currentUserId != null && _isConnected) {
      _channel!.sink.add(json.encode({"type": "get_unread_count"}));
    }
    return 0;
  }

  // Send test notification
  Future<void> sendTestNotification() async {
    await _showNotification(
      title: 'Test Notification',
      body: 'Dies ist eine Test-Benachrichtigung von MedApp für Community: $_currentCommunity',
      payload: {
        'type': 'test',
        'community_id': _currentCommunity,
        'timestamp': DateTime.now().toIso8601String()
      },
    );
  }

  // Disconnect
  void disconnect() {
    _pingTimer?.cancel();
    _reconnectTimer?.cancel();
    _channel?.sink.close();
    _channel = null;
    _messageController?.close();
    _messageController = null;
    _isConnected = false;
  }

  // Clean up resources
  void dispose() {
    disconnect();
  }
}