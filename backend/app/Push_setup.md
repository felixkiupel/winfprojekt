# MedApp Push Notification Setup Guide

## 📱 Übersicht

Dieses System ermöglicht es, Push-Benachrichtigungen an alle MedApp-Nutzer zu senden. Es besteht aus:

1. **Python FastAPI Backend** - REST API & WebSocket Server
2. **Firebase Cloud Messaging** - Push Notification Delivery
3. **Admin UI** - Web-Interface zum Senden von Benachrichtigungen
4. **Flutter Integration** - Mobile App Push-Empfang

## 🚀 Quick Start

### 1. Firebase Setup

1. Gehe zu [Firebase Console](https://console.firebase.google.com/)
2. Erstelle ein neues Projekt oder wähle ein bestehendes
3. Aktiviere Cloud Messaging
4. Generiere einen privaten Schlüssel:
   - Projekt-Einstellungen → Dienstkonten → Neuen privaten Schlüssel generieren
   - Speichere die JSON-Datei als `firebase-credentials.json`

### 2. Backend Setup

```bash
# Clone repo und navigiere zum Backend
cd winfprojekt/app

# Erstelle .env Datei
cat > .env << EOF
SECRET_KEY=your-super-secret-key-change-this-in-production
FIREBASE_CREDENTIALS_PATH=firebase-credentials.json
DATABASE_URL=postgresql://medapp:medapp_secret_2024@localhost:5432/medapp_db
REDIS_URL=redis://localhost:6379
ADMIN_TOKEN=your-admin-jwt-token
EOF

# Mit Docker Compose starten
docker-compose up -d

# Oder manuell mit pip
pip install -r requirements.txt
uvicorn main:app --reload
```

### 3. Admin UI Zugriff

- URL: `http://localhost:8501`
- Features:
  - Push-Benachrichtigungen senden
  - Health Messages erstellen
  - Analytics Dashboard
  - Versand-Historie

### 4. Flutter App Integration

1. **Firebase zu Flutter hinzufügen:**

```bash
# Firebase CLI installieren
npm install -g firebase-tools

# Im Flutter-Projekt
cd flutter
flutterfire configure
```

2. **Dependencies in pubspec.yaml:**

```yaml
dependencies:
  firebase_core: ^2.24.0
  firebase_messaging: ^14.7.6
  flutter_local_notifications: ^16.2.0
  http: ^1.1.0
  web_socket_channel: ^2.4.0
  shared_preferences: ^2.2.2
```

3. **Push Service initialisieren (in main.dart):**

```dart
import 'push_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  
  // Nach erfolgreichem Login
  await PushNotificationService().initialize(userId: 'user123');
  
  runApp(MyApp());
}
```

## 📤 Push-Benachrichtigungen senden

### Via Admin UI (Empfohlen)

1. Öffne `http://localhost:8501`
2. Gehe zum Tab "Send Push"
3. Fülle Titel und Nachricht aus
4. Wähle Zielgruppe (Alle User, Community, oder spezifische User)
5. Klicke "Send Notification"

### Via API (Programmatisch)

```python
import requests

# JWT Token holen (nach Login)
auth_token = "your-jwt-token"

# Push senden
response = requests.post(
    "http://localhost:8000/admin/send-push",
    headers={"Authorization": f"Bearer {auth_token}"},
    json={
        "title": "Wichtige Gesundheitsinformation",
        "body": "Neue COVID-19 Impftermine verfügbar",
        "broadcast": True,  # An alle User
        "data": {
            "type": "health_update",
            "action": "open_appointments"
        }
    }
)
```

### Via WebSocket (Real-time)

```javascript
// JavaScript/Flutter WebSocket Client
const ws = new WebSocket('ws://localhost:8000/ws/user123');

ws.onmessage = (event) => {
  const data = JSON.parse(event.data);
  console.log('Neue Nachricht:', data);
};
```

## 🏥 Health Messages

Health Messages sind spezielle Nachrichten mit Priorität und Community-Targeting:

```python
# Health Message erstellen und Push senden
response = requests.post(
    "http://localhost:8000/admin/health-message",
    headers={"Authorization": f"Bearer {auth_token}"},
    json={
        "title": "Diabetes Vorsorge",
        "content": "Kostenlose Blutzuckermessung im Community Center...",
        "community_id": "aboriginal_health",
        "priority": "high"  # normal, high, urgent
    }
)
```

## 🔧 Erweiterte Konfiguration

### Produktions-Deployment

1. **Umgebungsvariablen anpassen:**
```bash
SECRET_KEY=production-secret-key-very-long-and-random
DATABASE_URL=postgresql://user:pass@production-db:5432/medapp
FIREBASE_CREDENTIALS_PATH=/secure/path/to/firebase-creds.json
```

2. **HTTPS aktivieren:**
- Nginx Konfiguration anpassen
- SSL-Zertifikate einrichten (Let's Encrypt)

3. **Skalierung:**
- Mehrere Backend-Instanzen mit Load Balancer
- Redis Cluster für WebSocket-Synchronisation
- PostgreSQL Replikation

### Monitoring & Logging

```python
# In main.py für Logging
import logging

logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
```

## 📊 API Endpoints

| Endpoint | Method | Beschreibung |
|----------|--------|--------------|
| `/register-fcm-token` | POST | FCM Token registrieren |
| `/admin/send-push` | POST | Push-Benachrichtigung senden |
| `/admin/health-message` | POST | Health Message erstellen |
| `/messages` | GET | Alle Nachrichten abrufen |
| `/messages/read` | POST | Nachricht als gelesen markieren |
| `/ws/{user_id}` | WS | WebSocket Verbindung |

## 🐛 Troubleshooting

### Push kommt nicht an

1. **FCM Token prüfen:**
```bash
# In Flutter Debug Console
print('FCM Token: $_fcmToken');
```

2. **Backend Logs prüfen:**
```bash
docker logs medapp_backend
```

3. **Firebase Console:**
- Teste Push über Firebase Console
- Prüfe Projekt-Konfiguration

### WebSocket Verbindungsprobleme

1. **CORS prüfen:**
- Frontend URL in Backend CORS erlauben

2. **Firewall/Proxy:**
- WebSocket Ports (8000) freigeben
- Nginx WebSocket Upgrade headers

### Performance Optimierung

1. **Batch-Sending für viele User:**
```python
# Statt einzeln, in Batches von 500
fcm_tokens_batch = tokens[i:i+500]
```

2. **Caching mit Redis:**
- User-Token Mapping
- Message Templates

## 🔐 Sicherheit

1. **Authentication:**
- JWT Tokens mit kurzer Laufzeit
- Refresh Token Mechanismus

2. **Authorization:**
- Admin-Rolle für Push-Sending
- Community-basierte Berechtigungen

3. **Datenschutz:**
- Verschlüsselte Verbindungen (HTTPS/WSS)
- Minimale Datensammlung
- DSGVO-konform

## 📞 Support

Bei Fragen oder Problemen:
- Erstelle ein Issue im GitLab
- Kontaktiere das Dev-Team
- Dokumentation: `/docs` Endpoint

---

**Viel Erfolg mit dem Push Notification System! 🚀**