# 📱 MedApp – Flutter Project

A modern Flutter application for mobile platforms featuring push notifications, map integration, QR code functionality, and secure communication via HTTP/WebSocket.

---

## 🧱 Requirements

Make sure the following tools are installed:

### 🔧 1. Install Flutter SDK

* [Flutter SDK](https://docs.flutter.dev/get-started/install)
* Version: **>=3.27.0**
* Dart SDK: **^3.7.2** is included by default

```bash
flutter --version
```

### 💻 2. Dependencies

| Tool                     | Required For       |
| ------------------------ | ------------------ |
| Android Studio or VSCode | Emulator/Debugging |
| Xcode (macOS only)       | iOS Development    |
| Git                      | Version control    |

---

## 🚀 Project Setup

### 1. Navigate into the Project Directory

```bash
cd medapp
```

### 2. Install Flutter Packages

```bash
flutter pub get
```

### 3. Create `.env` File

Create a file named `.env` in the root directory with the following content:

```env
API_URL=http://10.0.2.2:8000
MONGO_URI=mongodb+srv://dbUser:dbUserPassword@medapp.tdtpszy.mongodb.net/MedApp?retryWrites=true&w=majority
JWT_SECRET=RyiYP7ng6iZIFtNGKww5EWyqcs6BdmKaegxbWjsCIWPGqspiXEJRvaRkOsHYw3G74QbtAhnW7Hq97qWSEtYt8g
```

> ⚠️ Important: Never push `.env` to public repositories. Make sure to add it to `.gitignore`.

---

## 🧪 Launching the App

### Android Emulator

```bash
flutter emulators --launch <emulator_id>
flutter run
```

### iOS Simulator (macOS only)

```bash
open -a Simulator
flutter run
```

### Web (optional)

```bash
flutter run -d chrome
```

---

## 📁 Assets

Ensure the following assets are present:

```text
assets/
└── lottie/
    └── location.json
.env
```

---

## 🧪 Run Tests

```bash
flutter test
```

---

## ✅ Key Packages Used

* **State Management**: `provider`, `shared_preferences`
* **Security**: `flutter_secure_storage`, `dotenv`
* **Maps & Location**: `flutter_map`, `geolocator`, `latlong2`
* **API & Auth**: `http`, `dio`, `web_socket_channel`
* **UI & Animation**: `lottie`, `flutter_animate`, `google_fonts`, `awesome_snackbar_content`
* **QR**: `qr_code_scanner`, `qr_code_tools`
* **PDF & Files**: `flutter_cached_pdfview`, `file_picker`, `path_provider`
* **Notification**: `flutter_local_notifications`

---

## 📌 Troubleshooting

| Problem                              | Solution                                                            |
| ------------------------------------ | ------------------------------------------------------------------- |
| `.env` variables not loading         | Ensure `flutter_dotenv` is properly initialized                     |
| Android can't connect to `localhost` | Use `10.0.2.2` instead of `localhost` in the emulator               |
| Missing permissions                  | Add necessary permissions in `AndroidManifest.xml` and `Info.plist` |
| iOS: Notifications not working       | Configure `UNUserNotificationCenter` in `AppDelegate.swift`         |
