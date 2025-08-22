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

#### `getProfileKaryawan()`

- Mendapatkan data profil karyawan
- Endpoint: `GET /api/izin/getProfileKaryawan`
- Response: Data lengkap profil karyawan

### 4. Update Function `_pickImage()`

- Menambahkan loading indicator
- Mengambil foto dari kamera
- Mengambil lokasi GPS
- Mengirim data ke API
- Menampilkan feedback sukses/error

## API Endpoints

### 1. Login

- **URL**: `POST /login`
- **Body**:
  ```json
  {
    "email": "user@example.com",
    "password": "password"
  }
  ```
- **Response**:
  ```json
  {
    "access_token": "token_string",
    "data": {
      "id": 1,
      "email": "user@example.com",
      "nama": "User Name"
    }
  }
  ```

### 2. Get Role

- **URL**: `GET /izin/getRole`
- **Headers**: `Authorization: Bearer {token}`
- **Response**:
  ```json
  {
    "data": {
      "role_name": "HRD"
    },
    "message": "Data Success"
  }
  ```

### 3. Get Profile Karyawan

- **URL**: `GET /izin/getProfileKaryawan`
- **Headers**: `Authorization: Bearer {token}`
- **Response**:
  ```json
  {
    "data": {
      "nip": "123456789",
      "nama": "John Doe",
      "departemen_id": 1,
      "jabatan_id": 1,
      "tempat_lahir": "Jakarta",
      "tanggal_lahir": "1990-01-01",
      "gender": "L",
      "alamat": "Jl. Contoh No. 123",
      "npwp": "12.345.678.9-123.456",
      "no_rekening": "1234567890",
      "bank_id": 1,
      "status_perkawinan": "Menikah",
      "jumlah_anak": 2,
      "pendidikan": "S1",
      "no_telepon": "08123456789",
      "pemilik_rekening": "John Doe",
      "nik": "1234567890123456",
      "agama": "Islam",
      "kewarganegaraan": "Indonesia",
      "tanggal_masuk": "2020-01-01",
      "status_kerja": "Aktif",
      "lokasi_kerja": "Jakarta",
      "alamat_domisili": "Jl. Domisili No. 456",
      "nama_departemen": "IT",
      "nama_jabatan": "Software Engineer",
      "nama_bank": "BCA"
    },
    "message": "Data Success"
  }
  ```

### 4. Send Attendance

- **URL**: `POST /absensiAndroid`
- **Headers**: `Authorization: Bearer {token}`
- **Body**:
  ```json
  {
    "latitude": -6.2088,
    "longitude": 106.8456,
    "foto": "data:image/png;base64,{base64_image}",
    "waktu_absen": "2024-01-01 08:00:00",
    "flag": "1"
  }
  ```

### 5. Get Attendance History

- **URL**: `GET /getAbsensiHistoryAndroid`
- **Headers**: `Authorization: Bearer {token}`
- **Response**:
  ```json
  {
    "data": {
      "2024-01-01": {
        "absensi": [
          {
            "waktu_absen": "2024-01-01 08:00:00",
            "foto": "photo_filename.jpg",
            "latitude": -6.2088,
            "longitude": 106.8456,
            "flag": 1
          }
        ]
      }
    }
  }
  ```

### 6. Get Dashboard Data

- **URL**: `GET /dashboardAndroid`
- **Headers**: `Authorization: Bearer {token}`
- **Response**:
  ```json
  {
    "data": {
      "id": 1,
      "email": "user@example.com",
      "nama": "User Name"
    }
  }
  ```

### 7. Get Sisa Cuti

- **URL**: `GET /izin/getSisaCuti`
- **Headers**: `Authorization: Bearer {token}`
- **Response**:
  ```json
  {
    "data": 12,
    "message": "Data Success"
  }
  ```

### 8. Get List Cuti

- **URL**: `GET /izin`
- **Headers**: `Authorization: Bearer {token}`
- **Response**:
  ```json
  {
    "data": [
      {
        "id": 1,
        "tanggal_awal": "2024-01-01",
        "tanggal_akhir": "2024-01-03",
        "status_hadir_id": 1,
        "keterangan": "Cuti tahunan",
        "validasi_personalia": true
      }
    ]
  }
  ```

### 9. Get All Izin (HRD Only)

- **URL**: `GET /allIzin`
- **Headers**: `Authorization: Bearer {token}`
- **Response**: Same as Get List Cuti but for all users

### 10. Get Detail Cuti

- **URL**: `GET /izin/{id}`
- **Headers**: `Authorization: Bearer {token}`
- **Response**:
  ```json
  {
    "data": {
      "id": 1,
      "tanggal_awal": "2024-01-01",
      "tanggal_akhir": "2024-01-03",
      "nama_status_hadir": "Cuti Tahunan",
      "name_user_acc": "HRD User"
    }
  }
  ```

### 11. Get Status Hadir

- **URL**: `GET /izin/getDataStatusHadir`
- **Headers**: `Authorization: Bearer {token}`
- **Response**:
  ```json
  {
    "data": [
      {
        "id": 1,
        "nama": "Cuti Tahunan",
        "kode": "IC"
      }
    ]
  }
  ```

### 12. Submit Izin

- **URL**: `POST /izin`
- **Headers**: `Authorization: Bearer {token}`
- **Body**: Multipart form data
  - `tanggal_awal`: "2024-01-01"
  - `tanggal_akhir`: "2024-01-03"
  - `status_hadir_id`: "1"
  - `keterangan`: "Cuti tahunan"
  - `dokumen`: File (optional)

### 13. Approve Izin (HRD Only)

- **URL**: `POST /izin/approve/{id}`
- **Headers**: `Authorization: Bearer {token}`
- **Response**:
  ```json
  {
    "data": {
      "id": 1,
      "validasi_personalia": true,
      "tanggal_approve": "2024-01-01 10:00:00"
    },
    "message": "Approve Success"
  }
  ```

### 14. Reject Izin (HRD Only)

- **URL**: `POST /izin/reject/{id}`
- **Headers**: `Authorization: Bearer {token}`
- **Body**:
  ```json
  {
    "keterangan": "Alasan penolakan"
  }
  ```
- **Response**:
  ```json
  {
    "data": {
      "id": 1,
      "validasi_personalia": false,
      "keterangan_tolak_personalia": "Alasan penolakan",
      "tanggal_reject": "2024-01-01 10:00:00"
    },
    "message": "Reject Success"
  }
  ```

### 15. Get User HRD Account

- **URL**: `GET /izin/getUserHrdAcc`
- **Headers**: `Authorization: Bearer {token}`
- **Response**:
  ```json
  {
    "data": {
      "id": 1,
      "nama": "HRD User",
      "no_telepon": "08123456789"
    },
    "message": "Data Success"
  }
  ```

### 8. Get All Karyawan

- **URL**: `GET /izin/getAllKaryawan`
- **Headers**:
  ```
  Authorization: Bearer {token}
  Content-Type: application/json
  ```
- **Response**:
  ```json
  {
    "data": [
      {
        "id": 1,
        "nip": "123456",
        "nama": "Nama Karyawan 1",
        "departemen_id": 1,
        "jabatan_id": 1,
        "tempat_lahir": "Jakarta",
        "tanggal_lahir": "1990-01-01",
        "gender": "L",
        "alamat": "Alamat lengkap",
        "npwp": "123456789",
        "no_rekening": "1234567890",
        "bank_id": 1,
        "status_perkawinan": "Menikah",
        "jumlah_anak": 2,
        "pendidikan": "S1",
        "no_telepon": "08123456789",
        "pemilik_rekening": "Nama Pemilik",
        "nik": "1234567890123456",
        "agama": "Islam",
        "kewarganegaraan": "Indonesia",
        "tanggal_masuk": "2020-01-01",
        "status_kerja": "Aktif",
        "lokasi_kerja": "Jakarta"
      },
      {
        "id": 2,
        "nip": "123457",
        "nama": "Nama Karyawan 2"
        // ... data lainnya
      }
    ],
    "message": "Data Success"
  }
  ```

### 9. Get Karyawan By ID

- **URL**: `GET /getKaryawanById/{id}`
- **Headers**:
  ```
  Authorization: Bearer {token}
  Content-Type: application/json
  ```
- **Parameters**:
  - `{id}`: ID karyawan yang ingin diambil datanya
- **Response**:
  ```json
  {
    "data": {
      "id": 582,
      "nip": "000003",
      "nama": "Fajar",
      "departemen_id": null,
      "jabatan_id": null,
      "tempat_lahir": null,
      "tanggal_lahir": "2025-07-31",
      "gender": null,
      "alamat": null,
      "npwp": null,
      "no_rekening": null,
      "bank_id": 0,
      "status_perkawinan": null,
      "jumlah_anak": 0,
      "pendidikan": null,
      "no_telepon": "082130697168",
      "pemilik_rekening": null,
      "nik": "000000000003",
      "agama": null,
      "kewarganegaraan": null,
      "tanggal_masuk": "2025-07-31",
      "status_kerja": null,
      "lokasi_kerja": null,
      "status": true
    },
    "message": "Data Success"
  }
  ```
- **Error Response (404)**:
  ```json
  {
    "data": null,
    "message": "Karyawan dengan ID tersebut tidak ditemukan"
  }
  ```

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

### 4. Get Profile Karyawan

```dart
final responseData = await ApiService.getProfileKaryawan(token);
if (responseData['data'] != null) {
  final profile = responseData['data'];
  print('Nama: ${profile['nama']}');
  print('NIP: ${profile['nip']}');
  print('Departemen: ${profile['nama_departemen']}');
  print('Jabatan: ${profile['nama_jabatan']}');
}
```

### 6. Get Karyawan By ID

```dart
// Mendapatkan data karyawan dengan ID 1
final responseData = await ApiService.getKaryawanById(token, 1);
if (responseData['data'] != null) {
  final karyawan = responseData['data'];
  print('Nama: ${karyawan['nama']}');
  print('NIP: ${karyawan['nip']}');
  print('Departemen ID: ${karyawan['departemen_id']}');
  print('Jabatan ID: ${karyawan['jabatan_id']}');
  print('No Telepon: ${karyawan['no_telepon']}');
} else {
  print('Karyawan tidak ditemukan');
}
```

### 7. Implementasi di Profile Screen

Fitur menampilkan data karyawan telah diimplementasikan di `ProfileScreen` dengan desain yang modern dan menarik:

- **Auto Load**: Data karyawan dimuat otomatis saat halaman dibuka (ID 582)
- **Modern UI**: Desain card dengan gradient, shadow, dan rounded corners
- **Profile Header**: Menampilkan nama dan NIP karyawan dengan desain yang menarik
- **Detail Card**: Menampilkan detail lengkap karyawan dengan icon dan layout yang rapi
- **Loading State**: Loading indicator yang menarik saat memuat data
- **Refresh Button**: Tombol refresh yang stylish untuk memuat ulang data
- **Logout Section**: Hanya menu logout yang tersisa dengan desain yang menarik
- **Error Handling**: Menangani error dengan baik

#### Fitur UI yang Ditambahkan:

- **Gradient Background**: Header profile dengan gradient biru
- **Card Design**: Detail karyawan dalam card dengan shadow dan border radius
- **Icon Integration**: Setiap detail memiliki icon yang sesuai
- **Color Coding**: Status aktif/tidak aktif dengan warna yang berbeda
- **Responsive Layout**: Layout yang responsif dan mudah dibaca

#### Cara Penggunaan:

1. Buka halaman Profile
2. Data karyawan akan dimuat otomatis (ID 582)
3. Nama dan NIP akan ditampilkan di header profile dengan desain menarik
4. Detail lengkap karyawan ditampilkan dalam card yang modern
5. Tap icon refresh untuk memuat ulang data
6. Tap tombol "Keluar" untuk logout

### 5. Testing (Debug Mode)

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
curl --location 'https://hris.qwords.com/backend/public/api/login' \
--header 'Content-Type: application/json' \
--data-raw '{
    "email": "admin@gmail.com",
    "password": "admin123"
}'
```

### Get Profile Karyawan

```bash
curl --location --request GET 'https://hris.qwords.com/backend/public/api/izin/getProfileKaryawan' \
--header 'Authorization: Bearer YOUR_TOKEN_HERE' \
--header 'Content-Type: application/json'
```

### Absensi

```bash
curl --location 'https://hris.qwords.com/backend/public/api/absensi' \
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
6. **Profile Data**: Data profil karyawan diambil berdasarkan `karyawan_id` dari user yang sedang login

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

### Error "Profil karyawan tidak ditemukan"

- Pastikan user memiliki `karyawan_id` yang valid
- Pastikan data karyawan ada di tabel `karyawan`
- Cek relasi antara tabel `hr_users` dan `karyawan`
