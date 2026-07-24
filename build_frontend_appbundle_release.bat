@echo off
echo ========================================================
echo Building Release App Bundle (AAB) for Google Play...
echo ========================================================
cd frontend
flutter build appbundle --release --dart-define=BACKEND_URL=http://localhost:8000
echo ========================================================
echo Build complete. Output AAB location:
echo frontend\build\app\outputs\bundle\release\app-release.aab
echo ========================================================
pause
