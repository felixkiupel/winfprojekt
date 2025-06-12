# 🚀 MedApp Push Notifications - Einfache Installation (OHNE Docker)

## Schnellstart in 5 Minuten

### 1️⃣ Python Backend einrichten

```bash
# Im app Ordner
cd winfprojekt/app

# Virtual Environment erstellen
python -m venv venv

# Aktivieren (Windows)
venv\Scripts\activate

# Aktivieren (Mac/Linux)
source venv/bin/activate

# Dependencies installieren
pip install fastapi uvicorn firebase-admin python-jose python-multipart python-dotenv

# Server starten
python simple_push_server.py
```

**Das war's! Der Server läuft jetzt auf http://localhost:8000**

### 2️⃣ Firebase einrichten (5 Minuten)

1. Gehe zu https://console.firebase.google.com/
2. Klicke "Projekt erstellen" → Name: "MedApp"
3. Aktiviere Google Analytics (optional)
4. Nach Erstellung:
   - Klicke auf ⚙️ → "Projekteinstellungen"
   - Tab "Dienstkonten"
   - "Neuen privaten Schlüssel generieren"
   - JSON-Datei herunterladen
   - **WICHTIG**: Datei umbenennen zu `firebase-credentials.json`
   - In den `app` Ordner legen (wo auch `simple_push_server.py` ist)

### 3️⃣ Admin Interface öffnen

1. Speichere `push_admin_simple.html` im `app` Ordner
2. Öffne die Datei direkt im Browser (Doppelklick)
3. Fertig! Du kannst jetzt Push-Nachrichten senden

### 4️⃣ Flutter App vorbereiten

**In deinem Flutter Projekt:**

1. **Firebase zu Flutter hinzufügen:**
```bash
# Firebase CLI installieren (einmalig)
npm install -g firebase-tools

# Im Flutter Projekt
cd flutter
flutter pub add firebase_core firebase_messaging flutter_local_notifications

# Firebase konfigurieren
flutterfire configure
```

2. **Push Service hinzufügen:**
   - Kopiere `push_service.dart` in `flutter/lib/`
   - Ersetze `main.dart` mit der neuen Version
   - Passe die Server-URL an:

```dart
// In push_service.dart, Zeile 24-25:
static const String API_BASE_URL = 'http://10.0.2.2:8000'; // Für Android Emulator
// oder
static const String API_BASE_URL = 'http://localhost:8000'; // Für iOS Simulator
// oder  
static const String API_BASE_URL = 'http://DEINE_IP:8000'; // Für echtes Gerät
```

3. **App starten:**
```bash
flutter run
```

## 📱 Push-Benachrichtigung senden

### Option 1: Admin Interface (Empfohlen)
1. Öffne `push_admin_simple.html` im Browser
2. Fülle das Formular aus
3. Klicke "Benachrichtigung senden"

### Option 2: Terminal/Postman
```bash
curl -X POST http://localhost:8000/send-push \
  -H "Content-Type: application/json" \
  -d '{
    "title": "Test Nachricht",
    "body": "Das ist eine Test Push-Benachrichtigung!",
    "broadcast": true
  }'
```

## 🔧 Troubleshooting

### "Firebase nicht initialisiert"
- Stelle sicher, dass `firebase-credentials.json` im `app` Ordner liegt
- Prüfe, ob der Dateiname korrekt ist (ohne Leerzeichen!)

### Push kommt nicht an
1. **Im Browser-Console (F12) prüfen:**
   - Gibt es Fehler?
   - Wurde die Nachricht gesendet?

2. **Server-Logs prüfen:**
   - Schau in das Terminal wo der Server läuft
   - Suche nach Fehlermeldungen

3. **Flutter Debug:**
   ```dart
   // In push_service.dart temporär hinzufügen:
   print('FCM Token: $_fcmToken');
   ```

### "Cannot connect to server"
- Prüfe ob der Server läuft: http://localhost:8000
- Firewall/Antivirus blockiert Port 8000?
- Richtige IP-Adresse in Flutter?

## 🎯 Teste die Integration

1. **Server testen:**
   - Öffne http://localhost:8000
   - Du solltest JSON sehen: `{"status": "running"...}`

2. **WebSocket testen:**
   - Öffne http://localhost:8000/docs
   - Teste den `/ws/{user_id}` Endpoint

3. **Push testen:**
   - Sende eine Test-Nachricht über das Admin Interface
   - Check die Server-Logs
   - Push sollte in der App ankommen

## 📝 Wichtige Dateien

```
winfprojekt/
├── app/
│   ├── simple_push_server.py      # ← Haupt-Server
│   ├── push_admin_simple.html     # ← Admin Interface  
│   ├── firebase-credentials.json  # ← Firebase Key (selbst hinzufügen!)
│   └── requirements.txt           # ← Python Packages
└── flutter/
    └── lib/
        ├── main.dart              # ← Updated mit Push
        ├── push_service.dart      # ← Push Service
        └── [andere screens...]
```

## 🚨 Produktiv-Tipps

1. **Sicherheit:**
   - Füge JWT Authentication hinzu
   - Nutze HTTPS in Produktion
   - Firebase Credentials NIEMALS committen!

2. **Performance:**
   - Nutze eine richtige Datenbank (PostgreSQL)
   - Redis für WebSocket-Scaling
   - Batch-Sending für viele Nutzer

3. **Monitoring:**
   - Logge alle Push-Sends
   - Tracke Erfolgsraten
   - Überwache Server-Health

---

**Das war's! In 5 Minuten hast du ein funktionierendes Push-System! 🎉**

Bei Fragen: Schau in die Server-Logs oder öffne ein Issue.