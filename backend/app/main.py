from auth import registrieren, anmelden

def main():
    while True:
        print("\n📋 Menü:")
        print("1. Registrieren")
        print("2. Anmelden")
        print("3. Beenden")

        wahl = input("Wähle eine Option: ").strip()

        if wahl == "1":
            registrieren()
        elif wahl == "2":
            anmelden()
        elif wahl == "3":
            print("🚪 Programm wird beendet.")
            break
        else:
            print("❗ Ungültige Auswahl.")

if __name__ == "__main__":
    main()
