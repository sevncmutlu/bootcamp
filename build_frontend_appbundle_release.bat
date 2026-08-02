@echo off
echo ========================================================
echo Building Release App Bundle (AAB) for Google Play...
echo ========================================================
set SCRIPT_DIR=%~dp0
cd /d "%SCRIPT_DIR%frontend"
call "%SCRIPT_DIR%scripts\validate_frontend_release.bat"
if errorlevel 1 exit /b %errorlevel%
flutter build appbundle --release %MAKI_DART_DEFINES%
if errorlevel 1 exit /b %errorlevel%
echo ========================================================
echo Build complete. Output AAB location:
echo frontend\build\app\outputs\bundle\release\app-release.aab
echo ========================================================
pause
