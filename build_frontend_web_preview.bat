@echo off
set SCRIPT_DIR=%~dp0
cd /d "%SCRIPT_DIR%frontend"
flutter build web --release --dart-define=MAKI_ENV=preview --dart-define=WEB_DEMO_MODE=true
if errorlevel 1 exit /b %errorlevel%
echo Web preview ready: frontend\build\web
