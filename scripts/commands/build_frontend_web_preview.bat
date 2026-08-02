@echo off
set "COMMAND_DIR=%~dp0"
for %%I in ("%COMMAND_DIR%..\..") do set "REPO_ROOT=%%~fI"
cd /d "%REPO_ROOT%\frontend"
flutter build web --release --dart-define=MAKI_ENV=preview --dart-define=WEB_DEMO_MODE=true
if errorlevel 1 exit /b %errorlevel%
echo Web preview ready: frontend\build\web
