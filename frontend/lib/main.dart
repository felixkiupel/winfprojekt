import 'package:flutter/material.dart';
import 'push_service_simple.dart';  // Vereinfachter Service
import 'welcome_screen.dart';
import 'login_screen.dart';
import 'QRScannerScreen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MedApp',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      initialRoute: '/home',  // Temporär: Direkt zur HomeScreen
      routes: {
        '/': (context) => const WelcomeScreen(),
        '/login': (context) => const LoginScreen(),
        '/qr': (context) => const QRScannerScreen(),
        '/home': (context) => const HomeScreen(),
      },
    );
  }
}

// Splash Screen aus main
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 2), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const WelcomeScreen()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3FFF5),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Text(
              'MedApp',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Your Health is our priority',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Dein verbessertes HomeScreen mit Push-Integration
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final SimplePushService _pushService = SimplePushService();
  List<Map<String, dynamic>> _messages = [];
  int _unreadCount = 0;
  
  @override
  void initState() {
    super.initState();
    _initializePush();
    _loadMessages();
    
    // Listen to WebSocket messages
    _pushService.messageStream.listen((message) {
      if (message['type'] == 'push_notification') {
        setState(() {
          _messages.insert(0, message['notification']);
        });
      }
    });
  }
  
  Future<void> _initializePush() async {
    await _pushService.initialize(userId: 'user123');
    final count = await _pushService.getUnreadCount();
    setState(() {
      _unreadCount = count;
    });
  }
  
  Future<void> _loadMessages() async {
    final messages = await _pushService.getMessages();
    setState(() {
      _messages = messages;
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('MedApp Dashboard'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications),
                onPressed: () {
                  // Navigate to notifications
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
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      '$_unreadCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await _loadMessages();
        },
        child: _messages.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.inbox, size: 64, color: Colors.grey),
                    const SizedBox(height: 16),
                    const Text(
                      'Keine Nachrichten',
                      style: TextStyle(fontSize: 18, color: Colors.grey),
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton.icon(
                      onPressed: () async {
                        await _pushService.sendTestNotification();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Test Push gesendet!')),
                        );
                      },
                      icon: const Icon(Icons.notifications_active),
                      label: const Text('Test Push senden'),
                    ),
                  ],
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _messages.length + 2,
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return Card(
                      elevation: 2,
                      margin: const EdgeInsets.only(bottom: 16),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Willkommen zurück!',
                              style: Theme.of(context).textTheme.headlineSmall,
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Bleiben Sie über wichtige Gesundheitsinformationen auf dem Laufenden.',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    );
                  } else if (index == 1) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8, top: 8),
                      child: Text(
                        'Aktuelle Nachrichten',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    );
                  }
                  
                  final message = _messages[index - 2];
                  return _buildMessageCard(message: message);
                },
              ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await _pushService.sendTestNotification();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Test Push gesendet!')),
          );
        },
        child: const Icon(Icons.notifications_active),
        tooltip: 'Test Push senden',
      ),
    );
  }
  
  Widget _buildMessageCard({required Map<String, dynamic> message}) {
    final priority = message['data']?['priority'] ?? 'normal';
    final timestamp = DateTime.tryParse(message['timestamp'] ?? '');
    final timeAgo = timestamp != null ? _getTimeAgo(timestamp) : 'Unbekannt';
    
    Color priorityColor = priority == 'high' 
      ? Colors.orange 
      : priority == 'urgent' 
        ? Colors.red 
        : Colors.green;
    
    final isRead = message['read_by']?.contains('user123') ?? false;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: isRead ? null : Colors.blue.shade50,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: priorityColor.withOpacity(0.2),
          child: Icon(
            Icons.health_and_safety,
            color: priorityColor,
          ),
        ),
        title: Text(
          message['title'] ?? 'Keine Überschrift',
          style: TextStyle(
            fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(message['body'] ?? ''),
            const SizedBox(height: 4),
            Text(
              timeAgo,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        trailing: const IconButton(
          icon: Icon(Icons.arrow_forward_ios, size: 16),
          onPressed: null,
        ),
        onTap: () async {
          if (!isRead && message['id'] != null) {
            await _pushService.markMessageAsRead(message['id']);
            await _loadMessages();
          }
        },
      ),
    );
  }
  
  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inDays > 0) {
      return 'vor ${difference.inDays} Tag${difference.inDays > 1 ? 'en' : ''}';
    } else if (difference.inHours > 0) {
      return 'vor ${difference.inHours} Stunde${difference.inHours > 1 ? 'n' : ''}';
    } else if (difference.inMinutes > 0) {
      return 'vor ${difference.inMinutes} Minute${difference.inMinutes > 1 ? 'n' : ''}';
    } else {
      return 'gerade eben';
    }
  }
  
  @override
  void dispose() {
    _pushService.dispose();
    super.dispose();
  }
}