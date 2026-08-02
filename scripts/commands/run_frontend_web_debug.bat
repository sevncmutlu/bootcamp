@echo off
set "COMMAND_DIR=%~dp0"
for %%I in ("%COMMAND_DIR%..\..") do set "REPO_ROOT=%%~fI"
cd /d "%REPO_ROOT%\frontend"

if not exist "lib\core\database\database.g.dart" (
    echo Generating database code via build_runner...
    call dart run build_runner build
)

echo ========================================================
echo Starting Flutter Web Server (Debug Mode)...
echo Open http://localhost:8080 in Firefox or Chrome
echo ========================================================
flutter run -d web-server --web-port 8080 --dart-define=MAKI_ENV=preview --dart-define=WEB_DEMO_MODE=true
pause
