#!/bin/bash
# Git History Cleanup Script

echo "🧹 Git Repository aufräumen..."

# 1. Backup erstellen (WICHTIG!)
echo "📦 Erstelle Backup..."
cp -r .git .git_backup_$(date +%Y%m%d_%H%M%S)

# 2. Dateien aus Git entfernen (aber lokal behalten)
echo "🗑️  Entferne sensitive Dateien aus Git..."

# Virtual Environments
git rm -r --cached backend/venv/ 2>/dev/null || true
git rm -r --cached venv/ 2>/dev/null || true

# User Data
git rm --cached users.json 2>/dev/null || true
git rm --cached backend/app/users.json 2>/dev/null || true

# Firebase Credentials
git rm --cached firebase-credentials.json 2>/dev/null || true
git rm --cached google-services.json 2>/dev/null || true
git rm --cached GoogleService-Info.plist 2>/dev/null || true

# Environment Files
git rm --cached .env 2>/dev/null || true
git rm --cached .env.* 2>/dev/null || true

# Flutter Generated
git rm --cached .flutter-plugins-dependencies 2>/dev/null || true
git rm --cached .flutter-plugins 2>/dev/null || true

# IDE Files
git rm -r --cached .idea/ 2>/dev/null || true
git rm -r --cached .vscode/ 2>/dev/null || true

# Python Cache
git rm -r --cached __pycache__/ 2>/dev/null || true
git rm -r --cached backend/app/__pycache__/ 2>/dev/null || true

# 3. Commit die Änderungen
echo "💾 Committe Änderungen..."
git add .gitignore
git commit -m "chore: update .gitignore and remove sensitive files from tracking"

# 4. Optional: Komplette History bereinigen (VORSICHT!)
echo ""
echo "⚠️  WARNUNG: Die folgenden Befehle ändern die Git-History!"
echo "Das solltest du nur machen wenn:"
echo "- Du der einzige Entwickler bist"
echo "- Oder nach Absprache mit dem Team"
echo ""
echo "Möchtest du die Git-History komplett bereinigen? (y/N)"
read -r response

if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
    echo "🔥 Bereinige Git-History..."
    
    # Option 1: Mit git filter-branch (traditionell)
    # git filter-branch --force --index-filter \
    #     'git rm -r --cached --ignore-unmatch backend/venv/ venv/ users.json firebase-credentials.json .env' \
    #     --prune-empty --tag-name-filter cat -- --all

    # Option 2: Mit BFG Repo-Cleaner (schneller, muss installiert sein)
    # bfg --delete-files users.json
    # bfg --delete-files firebase-credentials.json
    # bfg --delete-folders venv

    # Option 3: Mit git filter-repo (empfohlen, muss installiert sein)
    pip install git-filter-repo 2>/dev/null || true
    
    git filter-repo --force \
        --path backend/venv --invert-paths \
        --path venv --invert-paths \
        --path users.json --invert-paths \
        --path firebase-credentials.json --invert-paths \
        --path .env --invert-paths \
        --path __pycache__ --invert-paths

    echo "✅ History bereinigt!"
    echo ""
    echo "⚠️  WICHTIG: Du musst jetzt force-pushen:"
    echo "git push origin --force --all"
    echo "git push origin --force --tags"
else
    echo "✅ Nur lokale Änderungen durchgeführt."
    echo "Die Dateien sind jetzt untracked, aber noch in der History."
fi

echo ""
echo "📋 Status:"
git status --short

echo ""
echo "✅ Fertig! Vergiss nicht zu pushen:"
echo "git push origin $(git branch --show-current)"