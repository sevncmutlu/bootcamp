@echo off
echo ========================================================
echo Starting Maki Backend (Production / Release Mode)...
echo ========================================================

set SCRIPT_DIR=%~dp0
cd /d "%SCRIPT_DIR%"

if exist "%SCRIPT_DIR%.venv\Scripts\uv.exe" (
    "%SCRIPT_DIR%.venv\Scripts\uv.exe" run --project backend uvicorn maki.bootstrap:create_runtime_app --factory --host 0.0.0.0 --port 8000 --workers 4
) else (
    set PYTHONPATH=%SCRIPT_DIR%.venv\Lib\site-packages;%SCRIPT_DIR%backend\src;%PYTHONPATH%
    "%SCRIPT_DIR%.venv\Scripts\python.exe" -m uvicorn --app-dir backend\src maki.bootstrap:create_runtime_app --factory --host 0.0.0.0 --port 8000 --workers 4
)

pause
