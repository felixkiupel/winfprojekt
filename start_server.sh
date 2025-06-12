#!/bin/bash
cd backend
source venv/bin/activate
cd app
echo ""
echo "MedApp Push Server startet..."
echo "Admin Interface: Öffne push_admin_simple.html"
echo "API: http://localhost:8000"
echo ""
python3 simple_push_server.py
