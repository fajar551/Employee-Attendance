#!/bin/bash

echo "=== Testing Login API ==="
echo "URL: https://hris.qwords.com/backend/public/api/login"
echo ""

# Test Login
echo "1. Testing Login..."
LOGIN_RESPONSE=$(curl -s -w "\n%{http_code}" \
  --location 'https://hris.qwords.com/backend/public/api/login' \
  --header 'Content-Type: application/json' \
  --data-raw '{
    "email": "admin@gmail.com",
    "password": "admin123"
  }')

# Split response and status code
LOGIN_BODY=$(echo "$LOGIN_RESPONSE" | head -n -1)
LOGIN_STATUS=$(echo "$LOGIN_RESPONSE" | tail -n 1)

echo "Status Code: $LOGIN_STATUS"
echo "Response Body: $LOGIN_BODY"
echo ""

if [ "$LOGIN_STATUS" -eq 200 ]; then
    echo "✅ Login berhasil!"
    
    # Extract access_token from response (bukan token)
    TOKEN=$(echo "$LOGIN_BODY" | grep -o '"access_token":"[^"]*"' | cut -d'"' -f4)
    
    if [ -n "$TOKEN" ]; then
        echo "Access Token: $TOKEN"
        echo ""
        
        echo "=== Testing Absensi API ==="
        echo "2. Testing Absensi with token..."
        
        # Test Absensi
        ABSENSI_RESPONSE=$(curl -s -w "\n%{http_code}" \
          --location 'https://hris.qwords.com/backend/public/api/absensi' \
          --header "Authorization: Bearer $TOKEN" \
          --header 'Content-Type: application/json' \
          --data-raw '{
            "latitude": -6.892399,
            "longitude": 107.592391,
            "foto": "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==",
            "waktu_absen": "'$(date +"%Y-%m-%d %H:%M:%S")'"
          }')
        
        # Split response and status code
        ABSENSI_BODY=$(echo "$ABSENSI_RESPONSE" | head -n -1)
        ABSENSI_STATUS=$(echo "$ABSENSI_RESPONSE" | tail -n 1)
        
        echo "Status Code: $ABSENSI_STATUS"
        echo "Response Body: $ABSENSI_BODY"
        
        if [ "$ABSENSI_STATUS" -eq 200 ]; then
            echo "✅ Absensi berhasil!"
        else
            echo "❌ Absensi gagal!"
        fi
    else
        echo "❌ Access token tidak ditemukan dalam response"
    fi
else
    echo "❌ Login gagal!"
fi

echo ""
echo "=== Test Selesai ===" 