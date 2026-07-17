@echo off
setlocal enabledelayedexpansion

set KEY_OK=0
if defined GEMINI_API_KEY (
    if not "!GEMINI_API_KEY!"=="YOUR_GEMINI_API_KEY" (
        if not "!GEMINI_API_KEY!"=="" (
            set KEY_OK=1
        )
    )
)

if "!KEY_OK!"=="0" (
    echo ========================================================
    echo WARNING: GEMINI_API_KEY is not configured.
    echo Please enter your Gemini API Key below, or press Enter
    echo to run in OFFLINE / DEMO mode:
    echo ========================================================
    set /p USER_KEY="API Key: "
    if not "!USER_KEY!"=="" (
        set GEMINI_API_KEY=!USER_KEY!
    )
)

echo =========================================
echo Starting Maki Finance API Backend...
echo Model: gemini-3.1-flash-lite
echo =========================================
cd backend
..\.venv\Scripts\python.exe main.py
pause
