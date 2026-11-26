# Target migrasi Laravel + MySQL

**Fakta:** rancangan Pertemuan 6 menyebut backend Laravel API dan MySQL. Paket saat ini menggunakan backend **Node.js + SQLite** agar fungsi dapat diuji secara lokal tanpa Composer atau layanan eksternal. Jangan menyebut paket ini Laravel/MySQL.

## Peta migrasi

| Prototipe sekarang | Laravel yang disarankan |
|---|---|
| `users` + `sessions` | Model `User`, Laravel Sanctum, Policies |
| `office_locations` | Migration + `OfficeLocationController` |
| `attendance` | Migration, `AttendanceService` dan `AttendanceController` |
| `requests` dan `request_approvals` | Model `LeaveRequest`, `Approval`, state machine dan Policies |
| `schedules` dan `shifts` | Model `Shift`, `Schedule`, HRD Controller |
| `audit_logs` | Activity/Audit service server-side |

## Tahap migrasi aman

1. Buat proyek Laravel 12 baru dengan `composer create-project laravel/laravel backend-laravel` di direktori terpisah.
2. Siapkan MySQL/MariaDB lokal dan kredensial hanya dalam `.env` (tidak dipush).
3. Implementasikan migration, seeder, model dan endpoint berdasarkan `docs/API.md`.
4. Pasang Sanctum untuk token (jangan migrasikan token demo lama sebagai token produksi).
5. Implementasikan Laravel Policies untuk keempat role dan cakupan departemen.
6. Buat feature test untuk login, RBAC, validasi Geofencing, double check-in, approval stages, shift dan audit trail.
7. Jalankan test Laravel dan audit keamanan sebelum memindahkan URL Flutter ke API Laravel.
8. Jangan mengubah Flutter UI sembarangan; API contract dipertahankan.

Status: **roadmap, belum diimplementasikan**.
