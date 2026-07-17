#!/bin/bash

if [ -z "$GEMINI_API_KEY" ] || [ "$GEMINI_API_KEY" = "YOUR_GEMINI_API_KEY" ]; then
  echo "========================================================"
  echo "WARNING: GEMINI_API_KEY is not configured."
  echo "Please enter your Gemini API Key below, or press Enter"
  echo "to run in OFFLINE / DEMO mode:"
  echo "========================================================"
  read -r user_key
  if [ -n "$user_key" ]; then
    export GEMINI_API_KEY="$user_key"
  fi
fi

echo "========================================="
echo "Starting Maki Finance API Backend..."
echo "Model: gemini-3.1-flash-lite"
echo "========================================="
cd backend || exit
../.venv/bin/python main.py
