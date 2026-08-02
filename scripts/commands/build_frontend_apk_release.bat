@echo off
echo ========================================================
echo Building Release APK for Android...
echo ========================================================
set "COMMAND_DIR=%~dp0"
for %%I in ("%COMMAND_DIR%..\..") do set "REPO_ROOT=%%~fI"
cd /d "%REPO_ROOT%\frontend"
call "%REPO_ROOT%\scripts\validate_frontend_release.bat"
if errorlevel 1 exit /b %errorlevel%
flutter build apk --release %MAKI_DART_DEFINES%
if errorlevel 1 exit /b %errorlevel%
echo ========================================================
echo Build complete. Output APK location:
echo frontend\build\app\outputs\flutter-apk\app-release.apk
echo ========================================================
pause
