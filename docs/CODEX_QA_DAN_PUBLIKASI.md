# SOP QA Frontend NADI HRIS — Pertemuan 8

Ini bukan bagian yang sudah teruji otomatis. Gunakan setelah source diekstrak dan dibuka di VS Code pada Windows dengan Flutter.

## Langkah

1. Audit `pubspec.yaml`, `lib/main.dart`, `test/widget_test.dart`, dan sembilan file SVG pada `assets/designs`.
2. Jalankan `flutter pub get`, `dart format lib test`, `flutter analyze`, `flutter test` dan catat hasil benar-benar dari terminal.
3. Buka aplikasi di Chrome dengan viewport 390×844 dan di HP Android bila tersedia; periksa sembilan layar dan bandingkan dengan frame SVG asli. Perbaiki overflow, perbedaan spacing/typography, alur tombol, serta kesalahan sintaks yang ditemukan. Jangan menambahkan backend, GPS sesungguhnya, atau database tanpa tugas baru.
4. Ambil screenshot runtime sembilan layar dan simpan pada `docs/screenshots/` dengan nama 01-login.png sampai 09-profil.png. Jangan memakai screenshot desain SVG sebagai pengganti bukti runtime.
5. Jalankan `flutter build apk --debug` bila lingkungan mendukung. Catat hasil PASS/FAIL tanpa mengarang.
6. Uji role Manajer Bagian dan HRD, pengajuan, kalender, approval, logout. Ingat semua interaksi demonstrasi bersifat data lokal sementara.
7. Perbarui laporan PDF dengan bukti screenshot runtime (jika diminta). Pastikan PDF hanya satu berkas final sesuai instruksi Pertemuan 8.
8. GitHub: Pastikan login akun `imKul7` dan repository dibuat. Jalankan `gh repo create nadi-hris-flutter --public --source=. --remote=origin --push` hanya jika belum ada repo dan pengguna sudah memilih nama/public. Tambahkan URL yang benar ke README/laporan setelah berhasil.

## Aturan kejujuran

- Tidak ada backend Laravel/MySQL/GPS live pada paket ini.
- Jangan mengklaim UI pixel-perfect sebelum dibuktikan dengan perbandingan desain/runtime.
- Jangan mengklaim GitHub repository sudah tersedia sebelum URL remote benar-benar ada.
- Jangan mengubah proyek Smart Village Health; proyek ini terpisah.
