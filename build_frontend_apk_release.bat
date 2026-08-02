@echo off
echo ========================================================
echo Building Release APK for Android...
echo ========================================================
set SCRIPT_DIR=%~dp0
cd /d "%SCRIPT_DIR%frontend"
call "%SCRIPT_DIR%scripts\validate_frontend_release.bat"
if errorlevel 1 exit /b %errorlevel%
flutter build apk --release %MAKI_DART_DEFINES%
if errorlevel 1 exit /b %errorlevel%
echo ========================================================
echo Build complete. Output APK location:
echo frontend\build\app\outputs\flutter-apk\app-release.apk
echo ========================================================
pause
