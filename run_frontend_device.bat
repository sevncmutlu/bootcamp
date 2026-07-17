@echo off
echo ========================================================
echo Setting up ADB reverse tunnel for port 8000...
echo ========================================================
adb reverse tcp:8000 tcp:8000

echo ========================================================
echo Launching Flutter App on connected device...
echo ========================================================
cd frontend
flutter run --dart-define=BACKEND_URL=http://localhost:8000
pause
