@echo off
cd backend
call venv\Scripts\activate.bat
cd app
echo.
echo MedApp Push Server startet...
echo Admin Interface: Öffne push_admin_simple.html
echo API: http://localhost:8000
echo.
python simple_push_server.py
pause
