import json
import os

# Pfad zur JSON-Datei (wird im gleichen Verzeichnis wie auth.py gespeichert)
DATEIPFAD = os.path.join(os.path.dirname(__file__), "users.json")

# Benutzer aus JSON-Datei laden
def lade_benutzer():
    if not os.path.exists(DATEIPFAD):
        return {}
    with open(DATEIPFAD, "r") as f:
        return json.load(f)

# Benutzer in JSON-Datei speichern
def speichere_benutzer(benutzer_daten):
    with open(DATEIPFAD, "w") as f:
        json.dump(benutzer_daten, f, indent=4)

# Registrierung
def registrieren():
    benutzer = lade_benutzer()
    print("\n=== Registrierung ===")
    first_name = input("Vorname: ").strip()
    surname = input("Nachname: ").strip()
    email = input("E-Mail: ").strip()
    username = input("Benutzername: ").strip()
    password = input("Passwort: ").strip()

    if username in benutzer:
        print("❌ Benutzername existiert bereits.")
        return

    benutzer[username] = {
        "first_name": first_name,
        "surname": surname,
        "email": email,
        "password": password  # später durch Hash ersetzen
    }

    speichere_benutzer(benutzer)
    print(f"✅ Benutzer '{username}' erfolgreich registriert.")

# Anmeldung
def anmelden():
    benutzer = lade_benutzer()
    print("\n=== Anmeldung ===")
    username = input("Benutzername: ").strip()
    password = input("Passwort: ").strip()

    if username in benutzer and benutzer[username]["password"] == password:
        print(f"✅ Willkommen zurück, {benutzer[username]['first_name']}!")
    else:
        print("❌ Benutzername oder Passwort falsch.")
