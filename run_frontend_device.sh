#!/bin/bash
echo "========================================================"
echo "Maki Finance Frontend Runner (macOS / Linux)"
echo "========================================================"
echo "Enter your PC/Mac local IP address if running on a physical"
echo "phone (e.g. 192.168.1.50) OR press Enter for localhost/simulator:"
read -r ip_address

cd frontend || exit

if [ -z "$ip_address" ]; then
  echo "Launching with default localhost configuration..."
  flutter run
else
  echo "Launching with custom backend URL: http://$ip_address:8000"
  flutter run --dart-define=BACKEND_URL=http://"$ip_address":8000
fi
