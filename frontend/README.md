# 🏥 MedApp - Push Notification System

Einfaches Push-Benachrichtigungssystem für die MedApp - funktioniert mit WebSocket.

## 🚀 Schnellstart (3 Minuten)

### 1. Backend starten

```bash
# Terminal 1
cd backend/app
python3 simple_push_server.py

# Server läuft auf http://localhost:8000
```

### 2. Admin Interface öffnen

```bash
# Terminal 2
cd backend/app
python3 -m http.server 8080

# Browser: http://localhost:8080/push_admin_simple.html
```

### 3. Flutter App starten

```bash
# Terminal 3
cd frontend
flutter run -d chrome

# Für andere Geräte:
# flutter run -d macos
# flutter run -d ios
# flutter run -d android
```

## 📦 Installation (einmalig)

### Python Backend
```bash
cd backend
python3 -m venv venv
source venv/bin/activate  # Mac/Linux
# oder
venv\Scripts\activate     # Windows

pip install fastapi uvicorn websockets
```

### Flutter Frontend
```bash
cd frontend
flutter pub get
```

## 💡 Verwendung

1. **Push senden**: Öffne Admin Interface → Nachricht eingeben → Senden
2. **Login überspringen**: Klick auf "Login" Button (keine Eingabe nötig)
3. **Test Push**: In der App auf den Floating Action Button klicken

## 🎯 Test-Ablauf

1. Alle 3 Services starten (Backend, Admin, Flutter)
2. Im Admin Interface eine Nachricht senden
3. Die Nachricht erscheint sofort in der Flutter App
4. Tap auf Nachricht → wird als gelesen markiert

## ⚠️ Troubleshooting

**"Server Offline" im Admin?**
- Prüfe ob Backend läuft: `curl http://localhost:8000/`
- Nutze den Python HTTP Server (Schritt 2)

**WebSocket Fehler?**
- Normal beim Start, ignorieren
- Backend muss VOR Flutter gestartet werden

**Login funktioniert nicht?**
- Einfach auf "Login" klicken (keine Daten nötig)
- Oder in `main.dart`: `initialRoute: '/home'` setzen

## 🛠️ Entwicklung

- **Keine Datenbank** - alles im Speicher
- **Später**: MongoDB Integration geplant

---