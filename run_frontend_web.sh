#!/bin/bash
echo "========================================================"
echo "Starting Flutter Web Server..."
echo "Copy the URL below and paste it into Firefox or any browser."
echo "========================================================"
cd frontend || exit
flutter run -d web-server
