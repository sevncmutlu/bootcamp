@echo off
echo ========================================================
echo Starting Maki Backend (Production / Release Mode)...
echo ========================================================

set "COMMAND_DIR=%~dp0"
for %%I in ("%COMMAND_DIR%..\..") do set "REPO_ROOT=%%~fI"
cd /d "%REPO_ROOT%"

if exist "%REPO_ROOT%\.venv\Scripts\uv.exe" (
    "%REPO_ROOT%\.venv\Scripts\uv.exe" run --project backend uvicorn maki.bootstrap:create_runtime_app --factory --host 0.0.0.0 --port 8000 --workers 4
) else (
    set PYTHONPATH=%REPO_ROOT%\.venv\Lib\site-packages;%REPO_ROOT%\backend\src;%PYTHONPATH%
    "%REPO_ROOT%\.venv\Scripts\python.exe" -m uvicorn --app-dir backend\src maki.bootstrap:create_runtime_app --factory --host 0.0.0.0 --port 8000 --workers 4
)

pause
