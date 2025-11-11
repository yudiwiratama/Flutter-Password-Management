# Password Vault - Flutter Password Management App

Aplikasi manajemen password berbasis Flutter menggunakan SQFLite untuk penyimpanan data lokal.

## Fitur

- ✅ **CRUD Lengkap**: Create, Read, Update, Delete password
- 🔍 **Pencarian**: Cari password berdasarkan judul, username, atau website
- 🔒 **Keamanan**: Password disembunyikan secara default + proteksi PIN
- 📋 **Copy to Clipboard**: Salin password, username, dan data lainnya dengan mudah
- 🎲 **Generate Password**: Generate password acak secara otomatis
- 🛡️ **Lock Seketika**: Tombol "Kunci Sekarang" untuk re-lock manual
- 🩹 **Forgot PIN**: Reset PIN (mengosongkan data) saat lupa PIN
- 🔐 **Enkripsi Data**: Password, username, website, dan catatan terenkripsi AES‑GCM (kunci dari PIN via PBKDF2)
- 📦 **Backup & Restore (File)**: Ekspor/Impor file JSON terenkripsi + hash & salt PIN
- 💾 **Penyimpanan Lokal**: Data disimpan menggunakan SQFLite database

## Struktur Project

```
lib/
├── main.dart                          # Entry point aplikasi
├── models/
│   └── password_model.dart            # Model data password
├── database/
│   └── database_helper.dart           # Helper untuk operasi database SQFLite
├── services/
│   ├── pin_service.dart               # Logika penyimpanan/verifikasi PIN
│   ├── security_service.dart          # Derivasi kunci & enkripsi AES-GCM
│   └── backup_service.dart            # Ekspor & impor data (terenkripsi)
└── screens/
    ├── password_list_screen.dart      # Halaman daftar password
    ├── add_edit_password_screen.dart  # Halaman tambah/edit password
    ├── password_detail_screen.dart    # Halaman detail password
    ├── pin_unlock_screen.dart         # Halaman verifikasi PIN
    ├── pin_setup_screen.dart          # Halaman pembuatan/ubah PIN
    └── backup_restore_screen.dart     # Halaman backup & restore
```

## Instalasi

1. Pastikan Flutter sudah terinstall di sistem Anda
2. Install dependencies:
   ```bash
   flutter pub get
   ```

3. Jalankan aplikasi:
   - **Android** (emulator/device):
     ```bash
     flutter run -d android
     ```
   - **iOS** (simulator/device, butuh macOS & Xcode):
     ```bash
     flutter run -d ios
     ```
   - **Linux desktop**:
     ```bash
     flutter run -d linux
     ```
   - **Windows desktop**:
     ```bash
     flutter run -d windows
     ```
   - **macOS desktop**:
     ```bash
     flutter run -d macos
     ```
   - **Web (Chrome)**:
     ```bash
     flutter run -d chrome
     ```

   > Jika project baru dibuat dari repo ini dan folder platform belum ada, jalankan `flutter create .` untuk mengenerate folder `android`, `ios`, `linux`, `macos`, `windows`, dan `web`.

## Dependencies

- `sqflite`: ^2.3.0 - Database SQLite untuk Flutter
- `path`: ^1.8.3 - Utility untuk path manipulation
- `intl`: ^0.20.2 - Internationalization dan formatting
- `shared_preferences`: ^2.2.3 - Menyimpan hash PIN serta status terkunci
- `crypto`: ^3.0.3 - SHA-256 untuk hashing PIN
- `sqflite_common_ffi`: ^2.3.0 - Dukungan SQFLite di platform desktop
- `sqflite_common_ffi_web`: ^1.0.1+2 - Shim SQLite berbasis IndexedDB untuk Web
- `cryptography`: ^2.5.0 - PBKDF2 + AES-GCM untuk enkripsi data vault
- `file_picker`: ^10.3.3 - Dialog pilih file (restore)
- `file_saver`: ^0.3.1 - Simpan file (export) lintas platform
- `share_plus`: ^12.0.1 - Share file (Android/iOS)
- `path_provider`: ^2.1.4 - Direktori sementara (share/export)

## Penggunaan

### Menambah Password Baru
1. Klik tombol "Tambah Password" di pojok kanan bawah
2. Isi form dengan data yang diperlukan (Judul, Username, Password)
3. Opsional: Isi Website dan Catatan
4. Klik "Simpan Password"

### Melihat Daftar Password
- Semua password ditampilkan di halaman utama
- Gunakan search bar untuk mencari password tertentu
- Klik pada card password untuk melihat detail

### Mengedit Password
1. Buka detail password
2. Klik icon edit di AppBar
3. Atau gunakan menu popup (3 titik) di card password
4. Edit data yang diperlukan
5. Klik "Perbarui Password"

### Menghapus Password
1. Buka detail password atau gunakan menu popup
2. Klik icon delete
3. Konfirmasi penghapusan

### Fitur Tambahan
- **Generate Password**: Klik icon refresh di field password untuk generate password acak
- **Copy Password**: Klik icon copy untuk menyalin password ke clipboard
- **Show/Hide Password**: Klik icon mata untuk menampilkan/menyembunyikan password
- **Proteksi PIN**:
  - Pertama kali dijalankan, pengguna diminta membuat PIN
  - Setiap kali aplikasi dibuka kembali atau dikunci manual, layar PIN akan muncul
  - Tombol `Kunci Sekarang` di AppBar mengembalikan aplikasi ke layar PIN
- **Forgot PIN**:
  - Opsi ini akan menghapus semua data tersimpan dan meminta pengguna membuat PIN baru
  - Pastikan melakukan backup eksternal jika data penting dan PIN berpotensi lupa
- **Backup & Restore**:
  - Gunakan tombol `Backup & Restore` di AppBar
  - Export menghasilkan file JSON terenkripsi (ciphertext + hash & salt PIN) dan disimpan sebagai `vault_backup_*.json`
  - Android (scoped storage): gunakan “Share Backup” lalu pilih aplikasi (Drive/Files) untuk memilih lokasi (mis. Downloads)
  - Restore: pilih file backup tersebut dan masukkan PIN yang sama seperti saat backup dibuat
  - Restore mengganti seluruh data lokal lalu mengunci aplikasi kembali
  - Simpan file backup di lokasi aman (sebaiknya media terenkripsi)

## Database Schema

Tabel `passwords` memiliki struktur:
- `id`: INTEGER PRIMARY KEY AUTOINCREMENT
- `title`: TEXT NOT NULL
- `username`: TEXT NOT NULL
- `password`: TEXT NOT NULL
- `website`: TEXT (nullable)
- `notes`: TEXT (nullable)
- `created_at`: TEXT NOT NULL
- `updated_at`: TEXT NOT NULL

## Catatan Keamanan

⚠️ **Peringatan**:
- Data vault disimpan terenkripsi AES‑GCM; keamanan tetap bergantung pada kekuatan PIN. Gunakan PIN kuat.
- PIN disimpan sebagai hash SHA‑256 + salt; jika PIN lupa, opsi *Forgot PIN* akan menghapus data untuk mencegah akses ilegal.
- Pertimbangkan metode recovery (mis. backup terenkripsi ganda, master password/biometrik) bila kehilangan data tidak diinginkan.
- Backup JSON berisi ciphertext + hash & salt PIN; simpan di media aman dan pertimbangkan enkripsi tambahan saat membagikan.

## Lisensi

Project ini dibuat untuk keperluan pembelajaran dan development.

## Build & Deploy

### Persiapan umum
- Pastikan dependencies terinstall:
  ```bash
  flutter pub get
  ```
- Jika target Web (Chrome), lakukan setup worker database sekali:
  ```bash
  dart run sqflite_common_ffi_web:setup
  ```
  Ini menyalin `sqflite_sw.js` dan `sqlite3.wasm` ke folder `web/`.

### Android (APK)
1. Pastikan Android SDK siap (`flutter doctor -v`). Set `ANDROID_SDK_ROOT`/`ANDROID_HOME` bila diperlukan.
2. Build release:
   ```bash
   flutter build apk --release
   ```
3. Hasil APK:
   - `build/app/outputs/flutter-apk/app-release.apk`
4. Catatan:
   - Untuk rilis ke Play Store, lakukan penandatanganan (keystore + `key.properties`). Dokumentasi: `flutter.dev` → “Signing the app”.

### Web (Static Hosting)
1. Pastikan setup web sudah dilakukan:
   ```bash
   flutter pub get
   dart run sqflite_common_ffi_web:setup
   ```
2. Build release:
   ```bash
   flutter build web --release
   ```
3. Hasil build ada di:
   - `build/web/`
4. Deploy ke static hosting apa pun (Nginx, Apache, GitHub Pages, Netlify, Vercel, dll.) dengan mengunggah isi folder `build/web/`.
5. Contoh serve lokal cepat:
   ```bash
   cd build/web
   python3 -m http.server 5000
   # buka http://localhost:5000
   ```
6. Catatan penting Web:
   - Data tersimpan di IndexedDB (melalui `sqflite_common_ffi_web`) dan terikat ke origin (domain+port). Gunakan domain/port tetap agar data tidak “hilang”.
   - Saat development, jalankan dengan port tetap:
     ```bash
     flutter run -d chrome --web-port 5000 --web-hostname localhost
     ```
   - Setelah setup `sqflite_common_ffi_web`, pastikan file `sqflite_sw.js` dan `sqlite3.wasm` tersedia di folder `web/`.

### Backup & Restore Berbasis File
- Export:
  - Buka `Backup & Restore` → klik `Export ke File`
  - File akan disimpan sebagai `vault_backup_YYYYMMDDTHHMMSS.json` (lokasi default: Downloads/unduhan atau sesuai sistem)
  - Anda juga bisa langsung membagikan file via `Share Backup` (Drive, email, dsb.)
- Restore:
  - Buka `Backup & Restore` → pilih `Restore dari File`
  - Pilih file `.json` hasil export dan masukkan PIN yang sama saat backup dibuat
  - Proses akan mengganti seluruh data lokal dan aplikasi dikunci kembali



