@echo off
echo ========================================================
echo Starting Maki Backend (Development / Debug Mode)...
echo ========================================================

set SCRIPT_DIR=%~dp0
cd /d "%SCRIPT_DIR%"

if exist "%SCRIPT_DIR%.venv\Scripts\uv.exe" (
    "%SCRIPT_DIR%.venv\Scripts\uv.exe" run --project backend uvicorn maki.bootstrap:create_runtime_app --factory --reload --port 8000
) else (
    set PYTHONPATH=%SCRIPT_DIR%.venv\Lib\site-packages;%SCRIPT_DIR%backend\src;%PYTHONPATH%
    "%SCRIPT_DIR%.venv\Scripts\python.exe" -m uvicorn --app-dir backend\src maki.bootstrap:create_runtime_app --factory --reload --port 8000
)

pause
