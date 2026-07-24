@echo off
echo ========================================================
echo Starting Flutter Web Server (Debug Mode)...
echo Open http://localhost:8080 in Firefox or Chrome
echo ========================================================
cd frontend
flutter run -d web-server --web-port 8080 --dart-define=BACKEND_URL=http://localhost:8000
pause
