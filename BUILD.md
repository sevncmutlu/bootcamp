# Maki Finance Coach - Build and Compilation Guide

Maki Finance Coach is a cross-platform Flutter application backed by a FastAPI Python server. It features an AI Coach powered by Gemini 3.1, a LightGBM debt simulation classifier, and an anonymous gamified savings leaderboard.

---

## System Requirements

*   Flutter SDK: ^3.9.2
*   Python: 3.10 or higher
*   Android SDK: Platform 34 and Build-Tools 35 (automatically fetched by Flutter on first build)
*   Xcode: Required for building and running iOS Simulators or physical iPhones (macOS only)
*   ADB (Android Debug Bridge): Required for routing connection requests from physical Android devices

---

## Quick Start (Automated Scripts)

We provide pre-configured scripts in the root directory to automate environment setups and build targets.

### 1. Start the FastAPI Backend
This starts the backend, loads live financial datasets, and trains the LightGBM model.
*   Windows: Double-click run_backend.bat
*   macOS / Linux: Run ./run_backend.sh (Grant permissions first with chmod +x run_backend.sh)

Note: On startup, the console will prompt you to enter your Gemini API Key. If left blank, the server will start automatically in Offline / Demo mode with mock responders.

### 2. Start the Flutter Frontend (Physical Device)
Make sure your Android or iOS phone is plugged in with USB Debugging enabled.
*   Windows: Double-click run_frontend_device.bat
*   macOS / Linux: Run ./run_frontend_device.sh (Grant permissions first with chmod +x run_frontend_device.sh)

### 3. Start the Flutter Frontend (Web Browser / Firefox / Chrome)
This boots a web server so you can run the app in any browser.
*   Windows: Double-click run_frontend_web.bat
*   macOS / Linux: Run ./run_frontend_web.sh (Grant permissions first with chmod +x run_frontend_web.sh)

---

## Manual Build and Compilation

If you prefer to configure the environment or build targets manually:

### 1. Backend Server Setup
1.  Navigate to the backend folder:
    cd backend
2.  Install dependencies (using virtual environment):
    python -m venv .venv
    Windows:
    .venv\Scripts\activate
    macOS/Linux:
    source .venv/bin/activate

    pip install -r requirements.txt
3.  Launch the server:
    Windows PowerShell:
    $env:GEMINI_API_KEY="your_api_key"
    python main.py

    macOS/Linux:
    export GEMINI_API_KEY="your_api_key"
    python main.py

### 2. Frontend App Compilation
Ensure your target device is connected. Verify using flutter devices.
1.  Navigate to the frontend folder:
    cd frontend
2.  Install dependencies and generate localization bindings:
    flutter pub get
    flutter gen-l10n
3.  Compile and run:
    flutter run

---

## Cross-Platform Setup and Debugging

### A. Physical Android Device (USB)
1.  Connect your phone to your PC/Mac with USB debugging turned on.
2.  Open a terminal on your computer and run:
    adb reverse tcp:8000 tcp:8000
    (This forwards your phone's localhost requests to your PC's backend server).
3.  Run the app:
    flutter run --dart-define=BACKEND_URL=http://localhost:8000

### B. Physical iPhone (iOS over Wi-Fi)
1.  Ensure your iPhone and macOS computer are on the same Wi-Fi network.
2.  Get your computer's local network IP address (e.g., 192.168.1.50).
3.  Compile the app on the iPhone using the local IP override:
    flutter run --dart-define=BACKEND_URL=http://192.168.1.50:8000

### C. Emulators and Simulators (Zero Config)
*   Android Emulator: Default settings automatically route requests via 10.0.2.2:8000 (which loops back to the PC). No configuration is required.
*   iOS Simulator: Default settings automatically route requests to localhost:8000 (which is shared natively with the host Mac). No configuration is required.

### D. Web Browsers (Firefox / Chrome / Edge / Safari)
1.  Launch the app in web server mode:
    *   Windows: Double-click run_frontend_web.bat
    *   macOS / Linux: Run ./run_frontend_web.sh
    *   Manual: Run `flutter run -d web-server` in the frontend directory.
2.  The script will start a local server and print a URL (e.g. http://localhost:55660). Copy and paste this URL into Firefox or any other browser.
3.  The app uses a WebDatabase compiled down to IndexedDB automatically, requiring no C++ workloads or SQLiteMC installation.

---

## Known Build Limitations

### 1. Special Characters in Directory Paths (Windows Desktop Build Only)
*   If compiling for Windows Desktop, the parent directory path cannot contain special characters (like #). For example, building inside a path like C:\#MyFolder\bootcamp will fail with an MSBuild path restriction error.
*   Solution: Move the project folder to a standard path without special characters (e.g. C:\MyFolder\bootcamp) and recompile.
