#!/bin/bash

# API Testing Script untuk Employee Attendance App
# Base URL
BASE_URL="https://hris.qwords.com/backend/public/api"
FALLBACK_URL="https://43.252.137.238/backend/public/api"

# Colors untuk output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== Employee Attendance API Testing ===${NC}"

# Function untuk test login
test_login() {
    echo -e "\n${YELLOW}Testing Login...${NC}"
    
    response=$(curl -s -w "\n%{http_code}" --location "$BASE_URL/login" \
  --header 'Content-Type: application/json' \
  --data-raw '{
    "email": "admin@gmail.com",
    "password": "admin123"
  }')

    http_code=$(echo "$response" | tail -n1)
    response_body=$(echo "$response" | head -n -1)
    
    if [ "$http_code" -eq 200 ]; then
        echo -e "${GREEN}✓ Login berhasil${NC}"
        echo "Response: $response_body"
        
        # Extract token
        token=$(echo "$response_body" | grep -o '"access_token":"[^"]*"' | cut -d'"' -f4)
        if [ ! -z "$token" ]; then
            echo -e "${GREEN}Token: $token${NC}"
            echo "$token" > .token
        fi
    else
        echo -e "${RED}✗ Login gagal (HTTP $http_code)${NC}"
        echo "Response: $response_body"
    fi
}

# Function untuk test getRole
test_get_role() {
    echo -e "\n${YELLOW}Testing Get Role...${NC}"
    
    if [ ! -f .token ]; then
        echo -e "${RED}Token tidak ditemukan. Jalankan test_login terlebih dahulu.${NC}"
        return
    fi
    
    token=$(cat .token)
    
    response=$(curl -s -w "\n%{http_code}" --location "$BASE_URL/izin/getRole" \
        --header "Authorization: Bearer $token" \
        --header 'Content-Type: application/json')
    
    http_code=$(echo "$response" | tail -n1)
    response_body=$(echo "$response" | head -n -1)
    
    if [ "$http_code" -eq 200 ]; then
        echo -e "${GREEN}✓ Get Role berhasil${NC}"
        echo "Response: $response_body"
    else
        echo -e "${RED}✗ Get Role gagal (HTTP $http_code)${NC}"
        echo "Response: $response_body"
    fi
}

# Function untuk test approve izin
test_approve_izin() {
    echo -e "\n${YELLOW}Testing Approve Izin...${NC}"
    
    if [ ! -f .token ]; then
        echo -e "${RED}Token tidak ditemukan. Jalankan test_login terlebih dahulu.${NC}"
        return
    fi
    
    token=$(cat .token)
    izin_id=${1:-49}  # Default izin ID 49, bisa diubah
    
    response=$(curl -s -w "\n%{http_code}" --location "$BASE_URL/izin/approve/$izin_id" \
        --header "Authorization: Bearer $token" \
        --header 'Content-Type: application/json')
    
    http_code=$(echo "$response" | tail -n1)
    response_body=$(echo "$response" | head -n -1)
    
    if [ "$http_code" -eq 200 ]; then
        echo -e "${GREEN}✓ Approve Izin berhasil${NC}"
        echo "Response: $response_body"
    else
        echo -e "${RED}✗ Approve Izin gagal (HTTP $http_code)${NC}"
        echo "Response: $response_body"
    fi
}

# Function untuk test reject izin
test_reject_izin() {
    echo -e "\n${YELLOW}Testing Reject Izin...${NC}"
    
    if [ ! -f .token ]; then
        echo -e "${RED}Token tidak ditemukan. Jalankan test_login terlebih dahulu.${NC}"
        return
    fi
    
    token=$(cat .token)
    izin_id=${1:-49}  # Default izin ID 49, bisa diubah
    keterangan=${2:-"Alasan penolakan test"}
    
    response=$(curl -s -w "\n%{http_code}" --location "$BASE_URL/izin/reject/$izin_id" \
        --header "Authorization: Bearer $token" \
          --header 'Content-Type: application/json' \
        --data-raw "{
            \"keterangan\": \"$keterangan\"
        }")
    
    http_code=$(echo "$response" | tail -n1)
    response_body=$(echo "$response" | head -n -1)
    
    if [ "$http_code" -eq 200 ]; then
        echo -e "${GREEN}✓ Reject Izin berhasil${NC}"
        echo "Response: $response_body"
    else
        echo -e "${RED}✗ Reject Izin gagal (HTTP $http_code)${NC}"
        echo "Response: $response_body"
    fi
}

# Function untuk test get all izin
test_get_all_izin() {
    echo -e "\n${YELLOW}Testing Get All Izin...${NC}"
    
    if [ ! -f .token ]; then
        echo -e "${RED}Token tidak ditemukan. Jalankan test_login terlebih dahulu.${NC}"
        return
    fi
    
    token=$(cat .token)
    
    response=$(curl -s -w "\n%{http_code}" --location "$BASE_URL/allIzin" \
        --header "Authorization: Bearer $token" \
        --header 'Content-Type: application/json')
    
    http_code=$(echo "$response" | tail -n1)
    response_body=$(echo "$response" | head -n -1)
    
    if [ "$http_code" -eq 200 ]; then
        echo -e "${GREEN}✓ Get All Izin berhasil${NC}"
        echo "Response: $response_body"
    else
        echo -e "${RED}✗ Get All Izin gagal (HTTP $http_code)${NC}"
        echo "Response: $response_body"
    fi
}

# Function untuk test get sisa cuti
test_get_sisa_cuti() {
    echo -e "\n${YELLOW}Testing Get Sisa Cuti...${NC}"
    
    if [ ! -f .token ]; then
        echo -e "${RED}Token tidak ditemukan. Jalankan test_login terlebih dahulu.${NC}"
        return
    fi
    
    token=$(cat .token)
    
    response=$(curl -s -w "\n%{http_code}" --location "$BASE_URL/izin/getSisaCuti" \
        --header "Authorization: Bearer $token" \
        --header 'Content-Type: application/json')
    
    http_code=$(echo "$response" | tail -n1)
    response_body=$(echo "$response" | head -n -1)
    
    if [ "$http_code" -eq 200 ]; then
        echo -e "${GREEN}✓ Get Sisa Cuti berhasil${NC}"
        echo "Response: $response_body"
    else
        echo -e "${RED}✗ Get Sisa Cuti gagal (HTTP $http_code)${NC}"
        echo "Response: $response_body"
    fi
}

# Function untuk test get profile karyawan
test_get_profile_karyawan() {
    echo -e "\n${YELLOW}Testing Get Profile Karyawan...${NC}"
    
    if [ ! -f .token ]; then
        echo -e "${RED}Token tidak ditemukan. Jalankan test_login terlebih dahulu.${NC}"
        return
    fi
    
    token=$(cat .token)
    
    response=$(curl -s -w "\n%{http_code}" --location "$BASE_URL/izin/getProfileKaryawan" \
        --header "Authorization: Bearer $token" \
        --header 'Content-Type: application/json')
    
    http_code=$(echo "$response" | tail -n1)
    response_body=$(echo "$response" | head -n -1)
    
    if [ "$http_code" -eq 200 ]; then
        echo -e "${GREEN}✓ Get Profile Karyawan berhasil${NC}"
        echo "Response: $response_body"
    else
        echo -e "${RED}✗ Get Profile Karyawan gagal (HTTP $http_code)${NC}"
        echo "Response: $response_body"
    fi
}

# Function untuk test get all karyawan
test_get_all_karyawan() {
    echo -e "\n${YELLOW}Testing Get All Karyawan...${NC}"
    
    if [ ! -f .token ]; then
        echo -e "${RED}Token tidak ditemukan. Jalankan test_login terlebih dahulu.${NC}"
        return
    fi
    
    token=$(cat .token)
    
    response=$(curl -s -w "\n%{http_code}" --location "$BASE_URL/izin/getAllKaryawan" \
        --header "Authorization: Bearer $token" \
        --header 'Content-Type: application/json')
    
    http_code=$(echo "$response" | tail -n1)
    response_body=$(echo "$response" | head -n -1)
    
    if [ "$http_code" -eq 200 ]; then
        echo -e "${GREEN}✓ Get All Karyawan berhasil${NC}"
        echo "Response: $response_body"
    else
        echo -e "${RED}✗ Get All Karyawan gagal (HTTP $http_code)${NC}"
        echo "Response: $response_body"
    fi
}

# Function untuk test get karyawan by ID
test_get_karyawan_by_id() {
    echo -e "\n${YELLOW}Testing Get Karyawan By ID...${NC}"
    
    if [ ! -f .token ]; then
        echo -e "${RED}Token tidak ditemukan. Jalankan test_login terlebih dahulu.${NC}"
        return
    fi
    
    token=$(cat .token)
    karyawan_id=${1:-1}  # Default karyawan ID 1, bisa diubah
    
    response=$(curl -s -w "\n%{http_code}" --location "$BASE_URL/izin/getKaryawanById/$karyawan_id" \
        --header "Authorization: Bearer $token" \
        --header 'Content-Type: application/json')
    
    http_code=$(echo "$response" | tail -n1)
    response_body=$(echo "$response" | head -n -1)
    
    if [ "$http_code" -eq 200 ]; then
        echo -e "${GREEN}✓ Get Karyawan By ID berhasil${NC}"
        echo "Response: $response_body"
    else
        echo -e "${RED}✗ Get Karyawan By ID gagal (HTTP $http_code)${NC}"
        echo "Response: $response_body"
    fi
}

# Function untuk cleanup
cleanup() {
    if [ -f .token ]; then
        rm .token
        echo -e "\n${BLUE}Token file cleaned up${NC}"
    fi
}

# Main menu
show_menu() {
    echo -e "\n${BLUE}Pilih test yang ingin dijalankan:${NC}"
    echo "1) Test Login"
    echo "2) Test Get Role"
    echo "3) Test Approve Izin"
    echo "4) Test Reject Izin"
    echo "5) Test Get All Izin"
    echo "6) Test Get Sisa Cuti"
    echo "7) Test Get Profile Karyawan"
    echo "8) Test Get All Karyawan"
    echo "9) Test Get Karyawan By ID"
    echo "10) Test Semua"
    echo "11) Cleanup"
    echo "12) Exit"
    echo -n "Masukkan pilihan (1-12): "
}

# Main loop
while true; do
    show_menu
    read -r choice
    
    case $choice in
        1)
            test_login
            ;;
        2)
            test_get_role
            ;;
        3)
            echo -n "Masukkan ID izin (default: 49): "
            read -r izin_id
            test_approve_izin "${izin_id:-49}"
            ;;
        4)
            echo -n "Masukkan ID izin (default: 49): "
            read -r izin_id
            echo -n "Masukkan keterangan penolakan (default: 'Alasan penolakan'): "
            read -r keterangan
            test_reject_izin "${izin_id:-49}" "${keterangan:-Alasan penolakan}"
            ;;
        5)
            test_get_all_izin
            ;;
        6)
            test_get_sisa_cuti
            ;;
        7)
            test_get_profile_karyawan
            ;;
        8)
            test_get_all_karyawan
            ;;
        9)
            echo -n "Masukkan ID karyawan (default: 1): "
            read -r karyawan_id
            test_get_karyawan_by_id "${karyawan_id:-1}"
            ;;
        10)
            test_login
            test_get_role
            test_get_all_izin
            test_get_sisa_cuti
            test_get_profile_karyawan
            test_get_all_karyawan
            test_get_karyawan_by_id 1
            ;;
        11)
            cleanup
            ;;
        12)
            echo -e "${GREEN}Terima kasih!${NC}"
            exit 0
            ;;
        *)
            echo -e "${RED}Pilihan tidak valid!${NC}"
            ;;
    esac
done 