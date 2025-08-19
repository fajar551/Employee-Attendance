# Qwords Absensi - Employee Attendance System

Aplikasi absensi karyawan berbasis Flutter yang terintegrasi dengan sistem HR Qwords. Aplikasi ini memungkinkan karyawan untuk melakukan absen masuk dan keluar dengan foto selfie dan verifikasi lokasi GPS.

## 🚀 Fitur Utama

- **Absensi dengan Foto**: Selfie wajah untuk verifikasi kehadiran
- **Verifikasi Lokasi**: GPS tracking untuk memastikan lokasi absen
- **Sistem Login**: Autentikasi karyawan dengan email dan password
- **Dashboard HR**: Tampilan fitur-fitur HR yang lengkap
- **Pengajuan Izin**: Sistem pengajuan cuti dan izin
- **Profil Karyawan**: Manajemen data profil dan pengaturan
- **Workspace**: Akses ke workspace dan tools perusahaan
- **Posts**: Informasi dan pengumuman internal

## 📱 Screenshots

Aplikasi terdiri dari beberapa screen utama:

- **Splash Screen**: Loading screen dengan branding Qwords
- **Login Screen**: Halaman autentikasi karyawan
- **Home Screen**: Dashboard utama dengan fitur absensi
- **Features Screen**: Menu fitur-fitur HR
- **Izin Screen**: Pengajuan dan manajemen izin
- **Profile Screen**: Profil dan pengaturan karyawan
- **Workspace Screen**: Akses workspace
- **Posts Screen**: Informasi dan pengumuman

## 🛠️ Teknologi yang Digunakan

- **Framework**: Flutter 3.0+
- **Language**: Dart
- **State Management**: Provider/SetState
- **HTTP Client**: http package
- **Local Storage**: SharedPreferences
- **Image Picker**: image_picker package
- **Location Services**: geolocator & geocoding
- **Device Info**: device_info_plus

## 📦 Dependencies

```yaml
dependencies:
  flutter:
    sdk: flutter
  image_picker: ^1.1.2
  geolocator: ^11.0.0
  geocoding: ^3.0.0
  http: ^1.1.0
  shared_preferences: ^2.2.2
  device_info_plus: ^9.1.2
  flutter_launcher_icons: ^0.13.1
  cupertino_icons: ^1.0.6
```

## 🔧 Instalasi dan Setup

### Prerequisites

- Flutter SDK 3.0.0 atau lebih baru
- Dart SDK
- Android Studio / VS Code
- Android SDK (untuk Android)
- Xcode (untuk iOS)

### Langkah Instalasi

1. **Clone repository**

   ```bash
   git clone [repository-url]
   cd Employee-Attendance
   ```

2. **Install dependencies**

   ```bash
   flutter pub get
   ```

3. **Setup environment**

   - Pastikan semua dependencies terinstall
   - Konfigurasi API endpoint di `lib/services/`

4. **Run aplikasi**
   ```bash
   flutter run
   ```

## 🔌 Integrasi API

Aplikasi terintegrasi dengan API backend untuk:

- **Login**: `POST /api/login`
- **Absensi**: `POST /api/absensi`
- **Data Karyawan**: `GET /api/profile`

### Format Data Absensi

```json
{
  "latitude": -6.892399,
  "longitude": 107.592391,
  "foto": "data:image/png;base64,...",
  "waktu_absen": "2024-06-07 08:00:00"
}
```

## 📁 Struktur Project

```
lib/
├── main.dart                 # Entry point aplikasi
├── screens/                  # Halaman-halaman aplikasi
│   ├── splash_screen.dart
│   ├── login_screen.dart
│   ├── home_screen.dart
│   ├── features_screen.dart
│   ├── izin_screen.dart
│   ├── profile_screen.dart
│   ├── workspace_screen.dart
│   └── posts_screen.dart
├── widgets/                  # Komponen UI yang dapat digunakan ulang
├── services/                 # Layanan API dan business logic
├── models/                   # Data models
└── utils/                    # Utility functions
```

## 🎨 UI/UX Features

- **Material Design**: Menggunakan Material Design 3
- **Responsive**: Mendukung berbagai ukuran layar
- **Dark/Light Mode**: Tema yang dapat disesuaikan
- **Loading States**: Indikator loading yang informatif
- **Error Handling**: Penanganan error yang user-friendly

## 🔒 Keamanan

- **Token-based Authentication**: Menggunakan JWT token
- **Secure Storage**: Token disimpan di SharedPreferences
- **HTTPS**: Semua komunikasi API menggunakan HTTPS
- **Input Validation**: Validasi input user

## 🧪 Testing

Untuk testing aplikasi:

```bash
flutter test
```

## 📄 Lisensi

Project ini dikembangkan untuk Qwords sebagai sistem absensi internal.

## 👥 Kontribusi

Untuk kontribusi atau pertanyaan, silakan hubungi tim development Qwords.

## 📞 Support

Jika mengalami masalah, silakan buat issue di repository ini atau hubungi tim IT Qwords.

---

**Version**: 1.0.0  
**Last Updated**: 2024  
**Developer**: Qwords Development Team
