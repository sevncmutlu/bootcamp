@echo off
set SCRIPT_DIR=%~dp0
cd /d "%SCRIPT_DIR%frontend"

if not exist "lib\database\database.g.dart" (
    echo Generating database code via build_runner...
    call dart run build_runner build
)

echo ========================================================
echo Starting Flutter Web Server (Debug Mode)...
echo Open http://localhost:8080 in Firefox or Chrome
echo ========================================================
flutter run -d web-server --web-port 8080 --dart-define=BACKEND_URL=http://localhost:8000
pause
