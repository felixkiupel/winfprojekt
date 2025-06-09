#!/usr/bin/env python3
"""
MedApp Universal Setup Script
Installiert automatisch alles für Backend und Flutter
Funktioniert auf Windows, Mac und Linux
"""

import os
import sys
import subprocess
import platform
import json
import time
from pathlib import Path
import shutil

# Farben für Terminal Output
class Colors:
    HEADER = '\033[95m'
    BLUE = '\033[94m'
    GREEN = '\033[92m'
    YELLOW = '\033[93m'
    RED = '\033[91m'
    END = '\033[0m'
    BOLD = '\033[1m'

def print_header(text):
    print(f"\n{Colors.HEADER}{Colors.BOLD}{'='*60}{Colors.END}")
    print(f"{Colors.HEADER}{Colors.BOLD}{text.center(60)}{Colors.END}")
    print(f"{Colors.HEADER}{Colors.BOLD}{'='*60}{Colors.END}\n")

def print_success(text):
    print(f"{Colors.GREEN}✅ {text}{Colors.END}")

def print_error(text):
    print(f"{Colors.RED}❌ {text}{Colors.END}")

def print_warning(text):
    print(f"{Colors.YELLOW}⚠️  {text}{Colors.END}")

def print_info(text):
    print(f"{Colors.BLUE}ℹ️  {text}{Colors.END}")

def run_command(command, shell=True, check=True, cwd=None):
    """Führt einen Befehl aus und zeigt Output"""
    try:
        if isinstance(command, list):
            result = subprocess.run(command, shell=False, check=check, cwd=cwd, capture_output=True, text=True)
        else:
            result = subprocess.run(command, shell=shell, check=check, cwd=cwd, capture_output=True, text=True)
        
        if result.stdout:
            print(result.stdout)
        if result.stderr and result.returncode != 0:
            print(result.stderr)
        
        return result
    except subprocess.CalledProcessError as e:
        print_error(f"Befehl fehlgeschlagen: {e}")
        if e.stdout:
            print(e.stdout)
        if e.stderr:
            print(e.stderr)
        return None

def check_command_exists(command):
    """Prüft ob ein Befehl verfügbar ist"""
    try:
        run_command(f"{command} --version", check=False)
        return True
    except:
        return False

def get_python_command():
    """Findet den richtigen Python Befehl"""
    for cmd in ['python3', 'python']:
        if check_command_exists(cmd):
            return cmd
    return None

def get_venv_activate_command():
    """Gibt den plattform-spezifischen venv Aktivierungsbefehl zurück"""
    if platform.system() == "Windows":
        return os.path.join("backend", "venv", "Scripts", "activate.bat")
    else:
        return f"source {os.path.join('backend', 'venv', 'bin', 'activate')}"

def setup_python_backend():
    """Installiert Python Backend mit allen Dependencies"""
    print_header("Python Backend Setup")
    
    backend_dir = "backend"
    if not os.path.exists(backend_dir):
        print_error(f"Backend Ordner '{backend_dir}' nicht gefunden!")
        return False
    
    os.chdir(backend_dir)
    
    # Python prüfen
    python_cmd = get_python_command()
    if not python_cmd:
        print_error("Python nicht gefunden! Bitte installiere Python 3.8+")
        return False
    
    print_info(f"Verwende Python: {python_cmd}")
    
    # Virtual Environment erstellen
    print_info("Erstelle Virtual Environment...")
    venv_path = "venv"
    
    if os.path.exists(venv_path):
        print_warning("Virtual Environment existiert bereits. Überspringe...")
    else:
        run_command(f"{python_cmd} -m venv {venv_path}")
        print_success("Virtual Environment erstellt!")
    
    # Pip upgraden
    if platform.system() == "Windows":
        pip_cmd = os.path.join(venv_path, "Scripts", "pip")
    else:
        pip_cmd = os.path.join(venv_path, "bin", "pip")
    
    print_info("Upgrade pip...")
    run_command(f"{pip_cmd} install --upgrade pip")
    
    # Dependencies installieren
    print_info("Installiere Python Dependencies...")
    dependencies = [
        "fastapi==0.104.1",
        "uvicorn[standard]==0.24.0",
        "firebase-admin==6.3.0",
        "python-jose[cryptography]==3.3.0",
        "python-multipart==0.0.6",
        "python-dotenv==1.0.0",
        "websockets==12.0",
        "httpx==0.25.2"
    ]
    
    for dep in dependencies:
        print(f"  Installing {dep}...")
        result = run_command(f"{pip_cmd} install {dep}", check=False)
        if result and result.returncode == 0:
            print_success(f"  {dep} installiert")
        else:
            print_warning(f"  Problem bei {dep}")
    
    # Firebase Credentials prüfen
    firebase_file = os.path.join("app", "firebase-credentials.json")
    if not os.path.exists(firebase_file):
        print_warning("firebase-credentials.json nicht gefunden!")
        print_info("Bitte lade die Datei von Firebase Console herunter:")
        print_info("1. Gehe zu https://console.firebase.google.com/")
        print_info("2. Wähle dein Projekt → ⚙️ → Projekteinstellungen")
        print_info("3. Tab 'Dienstkonten' → 'Neuen privaten Schlüssel generieren'")
        print_info(f"4. Speichere die Datei als: {firebase_file}")
        print_warning("Push Notifications funktionieren nur mit dieser Datei!")
    else:
        print_success("Firebase Credentials gefunden!")
    
    os.chdir("..")
    return True

def setup_flutter():
    """Installiert Flutter Dependencies"""
    print_header("Flutter Setup")
    
    flutter_dir = "flutter"
    if not os.path.exists(flutter_dir):
        print_error(f"Flutter Ordner '{flutter_dir}' nicht gefunden!")
        return False
    
    # Flutter prüfen
    if not check_command_exists("flutter"):
        print_error("Flutter nicht gefunden!")
        print_info("Bitte installiere Flutter: https://flutter.dev/docs/get-started/install")
        return False
    
    os.chdir(flutter_dir)
    
    # Flutter doctor
    print_info("Prüfe Flutter Installation...")
    run_command("flutter doctor", check=False)
    
    # Dependencies installieren
    print_info("Installiere Flutter Dependencies...")
    run_command("flutter pub get")
    
    # Firebase prüfen
    if not check_command_exists("flutterfire"):
        print_info("Installiere FlutterFire CLI...")
        run_command("dart pub global activate flutterfire_cli")
    
    # Firebase konfigurieren
    print_info("Konfiguriere Firebase für Flutter...")
    print_warning("Folge den Anweisungen im Terminal:")
    result = run_command("flutterfire configure", check=False)
    
    if result and result.returncode == 0:
        print_success("Firebase für Flutter konfiguriert!")
    else:
        print_warning("Firebase Konfiguration übersprungen oder fehlgeschlagen")
        print_info("Du kannst später 'flutterfire configure' manuell ausführen")
    
    os.chdir("..")
    return True

def create_start_scripts():
    """Erstellt Start-Scripts für alle Plattformen"""
    print_header("Erstelle Start-Scripts")
    
    # Windows Batch Script
    windows_script = """@echo off
cd backend
call venv\\Scripts\\activate.bat
cd app
echo.
echo MedApp Push Server startet...
echo Admin Interface: Öffne push_admin_simple.html
echo API: http://localhost:8000
echo.
python simple_push_server.py
pause
"""
    
    # Unix Shell Script
    unix_script = """#!/bin/bash
cd backend
source venv/bin/activate
cd app
echo ""
echo "MedApp Push Server startet..."
echo "Admin Interface: Öffne push_admin_simple.html"
echo "API: http://localhost:8000"
echo ""
python3 simple_push_server.py
"""
    
    # Scripts speichern
    with open("start_server.bat", "w") as f:
        f.write(windows_script)
    print_success("start_server.bat erstellt")
    
    with open("start_server.sh", "w") as f:
        f.write(unix_script)
    
    if platform.system() != "Windows":
        os.chmod("start_server.sh", 0o755)
    
    print_success("start_server.sh erstellt")
    
    return True

def show_final_instructions():
    """Zeigt finale Anweisungen"""
    print_header("✨ Setup Abgeschlossen! ✨")
    
    print_info("So startest du die App:")
    print()
    
    if platform.system() == "Windows":
        print("1. Backend Server starten:")
        print(f"   {Colors.BOLD}Doppelklick auf start_server.bat{Colors.END}")
        print("   ODER:")
        print(f"   {Colors.BOLD}cd backend\\app && ..\\venv\\Scripts\\python.exe simple_push_server.py{Colors.END}")
    else:
        print("1. Backend Server starten:")
        print(f"   {Colors.BOLD}./start_server.sh{Colors.END}")
        print("   ODER:")
        print(f"   {Colors.BOLD}cd backend/app && ../venv/bin/python simple_push_server.py{Colors.END}")
    
    print()
    print("2. Admin Interface öffnen:")
    print(f"   {Colors.BOLD}Öffne backend/app/push_admin_simple.html im Browser{Colors.END}")
    
    print()
    print("3. Flutter App starten:")
    print(f"   {Colors.BOLD}cd flutter && flutter run{Colors.END}")
    
    print()
    print_warning("Wichtige URLs:")
    print("   API Server: http://localhost:8000")
    print("   API Docs:   http://localhost:8000/docs")
    print("   Admin UI:   Datei push_admin_simple.html öffnen")
    
    print()
    print_success("Happy Coding! 🚀")

def main():
    """Hauptfunktion"""
    print_header("MedApp Universal Setup")
    print_info(f"Platform: {platform.system()}")
    print_info(f"Python: {sys.version}")
    
    # Prüfe ob wir im richtigen Verzeichnis sind
    if not os.path.exists("backend") or not os.path.exists("flutter"):
        print_error("Dieses Script muss im Root-Verzeichnis (winfprojekt/) ausgeführt werden!")
        print_info("Aktuelle Verzeichnisstruktur:")
        for item in os.listdir("."):
            print(f"  - {item}")
        
        sys.exit(1)
    
    # Setup durchführen
    success = True
    
    if not setup_python_backend():
        success = False
    
    if not setup_flutter():
        print_warning("Flutter Setup fehlgeschlagen, aber Backend kann trotzdem funktionieren")
    
    if not create_start_scripts():
        success = False
    
    # Finale Anweisungen
    if success:
        show_final_instructions()
    else:
        print_error("Setup hatte Fehler. Bitte prüfe die Ausgaben oben.")
    
    print()
    input("Drücke Enter zum Beenden...")

if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        print("\n\nSetup abgebrochen.")
    except Exception as e:
        print_error(f"Unerwarteter Fehler: {e}")
        import traceback
        traceback.print_exc()