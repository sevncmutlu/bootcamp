@echo off
echo ========================================================
echo Starting Maki Backend (Development / Debug Mode)...
echo ========================================================
cd backend
uv run uvicorn maki.api.main:app --reload --port 8000
pause
