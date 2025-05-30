
# MedApp – Community Health App

Eine Flutter-App zur Unterstützung von Aboriginal & Torres Strait Islander Communities.  
Sie bietet sichere Anmeldung, QR-basierte Registrierung, Community-Nachrichten und Push-Benachrichtigungen.

---

## ⚙️ Voraussetzungen & Setup

### 📦 Flutter installieren

#### macOS / Linux / Windows:
1. [Flutter SDK herunterladen](https://docs.flutter.dev/get-started/install)
2. Entpacken und Pfad zur `flutter/bin` zu `PATH` hinzufügen
3. Terminal öffnen und ausführen:
   ```bash
   flutter doctor
   ```

> Damit werden alle Systemabhängigkeiten (z. B. Android Studio, Xcode etc.) geprüft.

---

## 🚀 Projekt starten

```bash
flutter pub get          # Abhängigkeiten installieren
flutter run -d chrome    # App im Browser starten
```

Weitere Geräte:
```bash
flutter devices          # Verfügbare Geräte anzeigen
flutter run -d <device>  # z. B. -d android, -d ios, -d web
```

---

## 🧠 Funktionsüberblick

### 🔐 `LoginScreen`
- E-Mail + Passwort
- Leitet nach Klick auf "Login" zum `/dashboard`

### 📸 `QRScannerScreen`
- Placeholder-Screen für QR-Code-Erfassung (wird später erweitert)

### 🏠 `WelcomeScreen`
- Einstiegspunkt nach Splash
- Buttons für "Sign In" und "Create account"

### 📊 `DashboardScreen`
- Community-Nachrichten als Liste
- Push-Banner mit Lesestatus (nach 2s simuliert)

### 🔔 `NotificationBanner`
- Zeigt Push-Benachrichtigung
- Callback zur Markierung als gelesen

### 📦 `Message`-Modell
```dart
Message(String content, DateTime timestamp, bool read);
```

---

## 🛠 Routen (in `main.dart`)

| Route       | Ziel-Screen        |
|-------------|--------------------|
| `/login`    | `LoginScreen`      |
| `/qr`       | `QRScannerScreen`  |
| `/dashboard`| `DashboardScreen`  |
