import 'package:flutter/material.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final TextEditingController emailController = TextEditingController();
    final TextEditingController passwordController = TextEditingController();

    // Test-User für schnellen Login
    final testUsers = [
      {'email': 'test@medapp.com', 'password': 'test123', 'name': 'Test User'},
      {'email': 'admin@medapp.com', 'password': 'admin123', 'name': 'Admin'},
      {'email': 'demo@demo.com', 'password': 'demo', 'name': 'Demo User'},
    ];

    void handleLogin() {
      final email = emailController.text;
      final password = passwordController.text;

      // Einfache Validierung mit Test-Usern
      bool loginSuccess = false;
      String userName = '';

      for (var user in testUsers) {
        if (user['email'] == email && user['password'] == password) {
          loginSuccess = true;
          userName = user['name']!;
          break;
        }
      }

      if (loginSuccess) {
        // Erfolgreicher Login
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Willkommen, $userName!'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Navigate to HomeScreen
        Navigator.pushReplacementNamed(context, '/home');
      } else {
        // Login fehlgeschlagen
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ungültige Anmeldedaten!'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sign In', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.black,
      ),
      backgroundColor: const Color(0xFFF3FFF5),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Test User Info Box
            Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '🧪 Test-Benutzer:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  ...testUsers.map((user) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      children: [
                        const Icon(Icons.person, size: 16, color: Colors.grey),
                        const SizedBox(width: 8),
                        Text('${user['email']} / ${user['password']}'),
                      ],
                    ),
                  )).toList(),
                ],
              ),
            ),
            
            TextField(
              controller: emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.email),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Password',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.lock),
              ),
              onSubmitted: (_) => handleLogin(),
            ),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {
                  // Quick fill for testing
                  emailController.text = 'test@medapp.com';
                  passwordController.text = 'test123';
                },
                child: const Text(
                  'Quick Fill Test User',
                  style: TextStyle(color: Colors.blue),
                ),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: handleLogin,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(horizontal: 80, vertical: 16),
              ),
              child: const Text('Login', style: TextStyle(color: Colors.white)),
            ),
            const SizedBox(height: 20),
            // Skip Login Button für schnelles Testen
            TextButton(
              onPressed: () {
                Navigator.pushReplacementNamed(context, '/home');
              },
              child: const Text(
                'Skip Login (Dev Mode)',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          ],
        ),
      ),
    );
  }
}