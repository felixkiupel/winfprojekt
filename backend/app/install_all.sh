#!/bin/bash
# install_all.sh - Für Mac/Linux
# Einfaches Install Script als Alternative zu setup_medapp.py

echo "🚀 MedApp Installation startet..."

# Backend Setup
echo "📦 Python Backend Setup..."
cd backend
python3 -m venv venv
source venv/bin/activate
pip install fastapi uvicorn firebase-admin python-jose python-multipart python-dotenv
echo "✅ Backend Dependencies installiert!"

# Flutter Setup  
cd ../flutter
echo "📱 Flutter Setup..."
flutter pub get
flutter doctor

# Firebase Config
echo "🔥 Firebase Setup..."
echo "Führe aus: flutterfire configure"

cd ..
echo "✅ Installation abgeschlossen!"
echo "Starte Server mit: cd backend/app && ../venv/bin/python simple_push_server.py"

# ===== WINDOWS VERSION (install_all.bat) =====
: '
@echo off
REM install_all.bat - Für Windows
REM Einfaches Install Script als Alternative zu setup_medapp.py

echo 🚀 MedApp Installation startet...

REM Backend Setup
echo 📦 Python Backend Setup...
cd backend
python -m venv venv
call venv\Scripts\activate.bat
pip install fastapi uvicorn firebase-admin python-jose python-multipart python-dotenv
echo ✅ Backend Dependencies installiert!

REM Flutter Setup
cd ..\flutter
echo 📱 Flutter Setup...
flutter pub get
flutter doctor

REM Firebase Config
echo 🔥 Firebase Setup...
echo Führe aus: flutterfire configure

cd ..
echo ✅ Installation abgeschlossen!
echo Starte Server mit: cd backend\app && ..\venv\Scripts\python.exe simple_push_server.py
pause
'