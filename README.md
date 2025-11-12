# Password Vault - Flutter Password Management App

<details><summary>Preview APP</summary>


<details><summary>Login Page /  Registration </summary>
<img width="1080" height="2436" alt="image" src="https://github.com/user-attachments/assets/d7f0a6e2-818b-47ac-884b-a968a3994812" />

</details>

<details><summary>Backup & Restore</summary>
<img width="567" height="1280" alt="image" src="https://github.com/user-attachments/assets/aee7544e-f46e-4a84-94b2-f50bb9bfbf60" />

</details>

<details><summary>Main Home</summary>
<img width="567" height="1280" alt="image" src="https://github.com/user-attachments/assets/80a97839-e604-4f3f-a2d7-7633e83d7ad1" />

</details>

<details><summary>Data Form</summary>
<img width="567" height="1280" alt="image" src="https://github.com/user-attachments/assets/2adb8bd2-6a58-4c72-a35a-eeb2bc08ffcc" />


</details>

</details>




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



