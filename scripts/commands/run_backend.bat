@echo off
echo ========================================================
echo Starting Maki Backend (Development / Debug Mode)...
echo ========================================================

set "COMMAND_DIR=%~dp0"
for %%I in ("%COMMAND_DIR%..\..") do set "REPO_ROOT=%%~fI"
cd /d "%REPO_ROOT%"

if exist "%REPO_ROOT%\.venv\Scripts\uv.exe" (
    "%REPO_ROOT%\.venv\Scripts\uv.exe" run --project backend uvicorn maki.bootstrap:create_runtime_app --factory --reload --port 8000
) else (
    set PYTHONPATH=%REPO_ROOT%\.venv\Lib\site-packages;%REPO_ROOT%\backend\src;%PYTHONPATH%
    "%REPO_ROOT%\.venv\Scripts\python.exe" -m uvicorn --app-dir backend\src maki.bootstrap:create_runtime_app --factory --reload --port 8000
)

pause
