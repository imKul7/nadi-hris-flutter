# NADI HRIS — QA Matrix (26 November 2026)

## Diverifikasi dalam lingkungan pembuatan paket

| ID | Skenario | Bukti | Status |
|---|---|---|---|
| BE-01 | Liveness endpoint & autentikasi wajib | `npm test` | PASS |
| BE-02 | Login empat role & hash password | `npm test` | PASS |
| BE-03 | Validasi radius dan akurasi GPS | `npm test` | PASS |
| BE-04 | Pengajuan employee → manager → head | `npm test` | PASS |
| BE-05 | Check-in/out, anti-duplikasi | `npm test` | PASS |
| BE-06 | HRD menambah staf, mengatur shift, audit | `npm test` | PASS |
| BE-07 | Logout membatalkan token | `npm test` | PASS |
| BE-08 | Head request → HRD dan validasi tanggal | `npm test` | PASS |
| PKG-01 | Source menyertakan 9 SVG asli | Pemeriksaan file | PASS |
| PKG-02 | Struktur Flutter + Android + Web | Pemeriksaan file | PASS |
| PKG-03 | Local DB `.sqlite` tidak masuk paket | Pemeriksaan arsip | PASS |

## Belum dapat dinyatakan PASS di lingkungan pembuat paket

| ID | Yang perlu diuji | Instruksi |
|---|---|---|
| FL-01 | `flutter pub get` | Laptop pengguna |
| FL-02 | `flutter analyze` | Laptop pengguna |
| FL-03 | `flutter test` | Laptop pengguna |
| FL-04 | `flutter build apk --debug` | Laptop pengguna |
| FL-05 | Login server pada Chrome | Node API aktif; jalankan Flutter Web |
| FL-06 | Login server pada HP Android | IP LAN laptop di `NADI_API_URL`, port privat, izin jaringan |
| FL-07 | GPS izin/lokasi/akurasi | Tes HP fisik, hanya lokasi kantor pengujian terverifikasi |
| FL-08 | 9 UI dibanding SVG acuan 390x844 | Ambil 9 screenshot runtime; periksa ukuran, spacing, overflow |
| FL-09 | Geofence validasi server memakai koordinat kantor nyata | Admin HRD mengisi kantor setelah verifikasi |
| FL-10 | Ketersediaan GitHub CI setelah push | Cek tab Actions repository baru |

**Jangan** menggunakan desain SVG sebagai bukti screenshot runtime. **Jangan** menyebut sistem siap produksi atau Laravel/MySQL telah terimplementasi.
