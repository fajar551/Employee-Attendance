# Troubleshooting Error API Absensi

## Error yang Sering Terjadi

### 1. Error "Gagal mengirim data absensi. Silakan coba lagi."

**Kemungkinan Penyebab:**

- Token tidak valid atau expired
- Tidak ada koneksi internet
- Data yang dikirim tidak lengkap
- Server API tidak bisa diakses

**Solusi:**

1. **Cek Token:**

   ```dart
   // Ganti token di function _loadAuthToken()
   _authToken = "TOKEN_YANG_VALID_DARI_LOGIN";
   ```

2. **Test API dengan cURL:**

   ```bash
   # Test login
   curl --location 'https://hris.qwords.com/backend/public/api/login' \
   --header 'Content-Type: application/json' \
   --data-raw '{
       "email": "admin@gmail.com",
       "password": "admin123"
   }'
   ```

3. **Cek Debug Log:**
   - Buka console/terminal saat menjalankan aplikasi
   - Lihat output debug yang dimulai dengan "Debug:"
   - Pastikan semua data terisi dengan benar

### 2. Error "Token tidak valid"

**Solusi:**

1. Login ulang untuk mendapatkan token baru
2. Pastikan format token benar (Bearer + token)
3. Cek apakah token sudah expired

### 3. Error "Tidak bisa mendapatkan lokasi"

**Solusi:**

1. Pastikan GPS diaktifkan
2. Berikan izin lokasi ke aplikasi
3. Pastikan berada di luar ruangan untuk sinyal GPS yang lebih baik

### 4. Error "Network error"

**Solusi:**

1. Cek koneksi internet
2. Pastikan URL API bisa diakses
3. Cek firewall atau proxy

## Langkah Debugging

### 1. Test API Manual

Gunakan tombol "Test API" di aplikasi untuk test tanpa foto terlebih dahulu.

### 2. Cek Debug Log

```dart
// Log yang akan muncul di console:
Debug: Token: [token_value]
Debug: Position: [latitude, longitude]
Debug: Image: [file_path]
Debug: Sending data to API...
Debug: Response status: [status_code]
Debug: Response body: [response_body]
```

### 3. Test dengan Postman

```json
POST https://hris.qwords.com/backend/public/api/absensi
Headers:
  Authorization: Bearer [token]
  Content-Type: application/json

Body:
{
  "latitude": -6.892399,
  "longitude": 107.592391,
  "foto": "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==",
  "waktu_absen": "2024-06-07 08:00:00"
}
```

## Checklist Debugging

- [ ] Token valid dan tidak expired
- [ ] Koneksi internet stabil
- [ ] GPS aktif dan izin diberikan
- [ ] Kamera aktif dan izin diberikan
- [ ] URL API bisa diakses
- [ ] Format data sesuai dengan yang diharapkan API
- [ ] Response API tidak error

## Contoh Token Valid

```dart
// Contoh token yang valid (ganti dengan token kamu)
_authToken = "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpc3MiOiJodHRwczovL2Fic2Vuc2kucXdvcmRzLmNvbS9iYWNrZW5kL3B1YmxpYy9hcGkvbG9naW4iLCJpYXQiOjE3MzU5MjQwMDAsImV4cCI6MTczNTkyNzYwMCwibmJmIjoxNzM1OTI0MDAwLCJqdGkiOiJ0b2tlbl9pZCIsInN1YiI6MSwicHJ2IjoiMjNiZDVjODk0OWY2MDBhZGIzOWU3MDFjNDAwODcyZGI3YTU5NzZmNyJ9.signature";
```

## Contact Support

Jika masih mengalami error, silakan:

1. Screenshot error message
2. Copy debug log dari console
3. Cek response API dengan Postman/cURL
4. Hubungi tim development
