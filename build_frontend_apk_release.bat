@echo off
echo ========================================================
echo Building Release APK for Android...
echo ========================================================
cd frontend
flutter build apk --release --dart-define=BACKEND_URL=http://localhost:8000
echo ========================================================
echo Build complete. Output APK location:
echo frontend\build\app\outputs\flutter-apk\app-release.apk
echo ========================================================
pause
