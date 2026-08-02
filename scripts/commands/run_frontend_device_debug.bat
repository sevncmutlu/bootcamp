@echo off
echo ========================================================
echo Setting up ADB reverse tunnel for port 8000...
echo ========================================================
adb reverse tcp:8000 tcp:8000 >nul 2>&1

set "COMMAND_DIR=%~dp0"
for %%I in ("%COMMAND_DIR%..\..") do set "REPO_ROOT=%%~fI"
cd /d "%REPO_ROOT%\frontend"

if not exist "lib\core\database\database.g.dart" (
    echo Generating database code via build_runner...
    call dart run build_runner build
)

echo ========================================================
echo Launching Flutter App on connected device (Debug)...
echo ========================================================
flutter run --debug --dart-define=BACKEND_URL=http://localhost:8000
pause
