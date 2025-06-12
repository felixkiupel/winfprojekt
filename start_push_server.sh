#!/bin/bash
# start_push_server.sh - Für Mac/Linux

echo "🚀 MedApp Push Server starten..."

# Prüfe ob venv existiert
if [ ! -d "venv" ]; then
    echo "📦 Virtual Environment erstellen..."
    python3 -m venv venv
fi

# Aktiviere venv
echo "🔌 Virtual Environment aktivieren..."
source venv/bin/activate

# Installiere Dependencies
echo "📚 Dependencies installieren..."
pip install -q fastapi uvicorn firebase-admin python-jose python-multipart python-dotenv

# Prüfe ob Firebase Credentials existieren
if [ ! -f "firebase-credentials.json" ]; then
    echo "⚠️  WARNUNG: firebase-credentials.json nicht gefunden!"
    echo "📝 Bitte lade die Datei von Firebase Console herunter"
    echo "   und speichere sie als 'firebase-credentials.json'"
    echo ""
    echo "🔥 Server startet trotzdem (nur WebSocket funktioniert)..."
fi

# Server starten
echo ""
echo "✅ Server startet..."
echo "📱 Admin Interface: Öffne push_admin_simple.html im Browser"
echo "🔌 API läuft auf: http://localhost:8000"
echo ""
echo "Drücke Ctrl+C zum Beenden"
echo "----------------------------------------"

python simple_push_server.py

# --- Windows Batch Version (start_push_server.bat) ---
: '
@echo off
echo 🚀 MedApp Push Server starten...

REM Prüfe ob venv existiert
if not exist "venv" (
    echo 📦 Virtual Environment erstellen...
    python -m venv venv
)

REM Aktiviere venv
echo 🔌 Virtual Environment aktivieren...
call venv\Scripts\activate.bat

REM Installiere Dependencies
echo 📚 Dependencies installieren...
pip install -q fastapi uvicorn firebase-admin python-jose python-multipart python-dotenv

REM Prüfe ob Firebase Credentials existieren
if not exist "firebase-credentials.json" (
    echo ⚠️  WARNUNG: firebase-credentials.json nicht gefunden!
    echo 📝 Bitte lade die Datei von Firebase Console herunter
    echo    und speichere sie als firebase-credentials.json
    echo.
    echo 🔥 Server startet trotzdem - nur WebSocket funktioniert...
)

REM Server starten
echo.
echo ✅ Server startet...
echo 📱 Admin Interface: Öffne push_admin_simple.html im Browser
echo 🔌 API läuft auf: http://localhost:8000
echo.
echo Drücke Ctrl+C zum Beenden
echo ----------------------------------------

python simple_push_server.py
'