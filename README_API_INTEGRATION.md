# Integrasi API Absensi Flutter

## Deskripsi

Aplikasi Flutter ini sudah terintegrasi dengan API absensi untuk mengirim data foto, lokasi, dan waktu absen ke server.

## Fitur yang Sudah Ditambahkan

### 1. Import Dependencies

```dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
```

### 2. Variabel yang Ditambahkan

- `_authToken`: Menyimpan token autentikasi
- `_currentPosition`: Menyimpan posisi GPS saat ini
- `_isLoading`: State loading saat mengirim data

### 3. Function yang Ditambahkan

#### `_loadAuthToken()`

- Load token dari SharedPreferences
- Dipanggil saat aplikasi dimulai

#### `_saveAuthToken(String token)`

- Menyimpan token ke SharedPreferences
- Dipanggil setelah login berhasil

#### `_loginAndGetToken(String email, String password)`

- Login ke API dan mendapatkan token
- Endpoint: `POST /api/login`
- Response: `{"message": "Login success", "access_token": "...", "token_type": "Bearer"}`

#### `_sendAttendanceToAPI()`

- Mengirim data absensi ke API
- Endpoint: `POST /api/absensi`
- Data yang dikirim:
  - `latitude`: Posisi latitude
  - `longitude`: Posisi longitude
  - `foto`: Foto dalam format base64
  - `waktu_absen`: Waktu absen

### 4. Update Function `_pickImage()`

- Menambahkan loading indicator
- Mengambil foto dari kamera
- Mengambil lokasi GPS
- Mengirim data ke API
- Menampilkan feedback sukses/error

## Cara Penggunaan

### 1. Flow Token Management

Token akan dikelola secara otomatis:

- **Auto Login**: Jika tidak ada token, aplikasi akan login otomatis
- **Token Storage**: Token disimpan di SharedPreferences
- **Token Clear**: Token dihapus saat logout

### 2. Login untuk Mendapatkan Token

```dart
bool success = await _loginAndGetToken("admin@gmail.com", "admin123");
if (success) {
  print("Login berhasil, access token tersimpan");
}
```

### 3. Ambil Foto dan Kirim Absensi

- Tekan tombol "Rekam Waktu"
- Aplikasi akan membuka kamera
- Setelah foto diambil, data akan dikirim otomatis ke API
- Loading indicator akan muncul selama proses pengiriman

### 4. Testing (Debug Mode)

Aplikasi memiliki tombol testing untuk debugging:

- **Test Login**: Test login dan dapatkan token baru
- **Test API**: Test API absensi tanpa foto
- **Clear Token**: Hapus token untuk test ulang

## Format Data yang Dikirim

```json
{
  "latitude": -6.892399,
  "longitude": 107.592391,
  "foto": "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAA...",
  "waktu_absen": "2024-06-07 08:00:00"
}
```

## Response API

### Sukses (200)

```json
{
  "data": {
    "id": 1,
    "user_id": 1,
    "latitude": -6.892399,
    "longitude": 107.592391,
    "foto": "absensi_1234567890.png",
    "waktu_absen": "2024-06-07 08:00:00"
  },
  "message": "Absensi berhasil"
}
```

### Error (403) - Di luar jangkauan

```json
{
  "message": "Anda di luar jangkauan kantor",
  "jarak": 50.5,
  "radius": 25
}
```

### Error (422) - Validasi gagal

```json
{
  "latitude": ["The latitude field is required."],
  "longitude": ["The longitude field is required."]
}
```

## Testing dengan cURL

### Login

```bash
curl --location 'https://absensi.qwords.com/backend/public/api/login' \
--header 'Content-Type: application/json' \
--data-raw '{
    "email": "admin@gmail.com",
    "password": "admin123"
}'
```

### Absensi

```bash
curl --location 'https://absensi.qwords.com/backend/public/api/absensi' \
--header 'Authorization: Bearer {TOKEN_KAMU}' \
--header 'Content-Type: application/json' \
--data-raw '{
    "latitude": -6.892399,
    "longitude": 107.592391,
    "foto": "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAA...",
    "waktu_absen": "2024-06-07 08:00:00"
}'
```

## Catatan Penting

1. **Token Management**: Token disimpan di SharedPreferences dan akan hilang jika aplikasi di-uninstall
2. **GPS Permission**: Aplikasi membutuhkan izin lokasi untuk mengambil koordinat
3. **Camera Permission**: Aplikasi membutuhkan izin kamera untuk mengambil foto
4. **Network**: Pastikan ada koneksi internet untuk mengirim data ke API
5. **Base64 Image**: Foto dikonversi ke base64 sebelum dikirim ke API

## Troubleshooting

### Error "Token tidak valid"

- Pastikan token belum expired
- Login ulang untuk mendapatkan token baru

### Error "Gagal mengirim data absensi"

- Cek koneksi internet
- Pastikan semua field terisi (latitude, longitude, foto, waktu_absen)
- Cek response API untuk detail error

### Error "Anda di luar jangkauan kantor"

- Pastikan berada dalam radius 25 meter dari kantor
- Koordinat kantor: -6.892399, 107.592391
