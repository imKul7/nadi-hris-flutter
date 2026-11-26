# NADI HRIS — REST API Reference

Base URL local: `http://localhost:3000`. Endpoint mengembalikan JSON dan `Cache-Control: no-store`.

## Autentikasi

| Method | Path | Hak akses | Body |
|---|---|---|---|
| POST | `/api/login` | Publik | `{ "email": "raka@nadi.test", "password": "..." }` |
| GET | `/api/me` | Login | – |
| POST | `/api/logout` | Login | – |

Request setelah login memakai `Authorization: Bearer <token>`. Token tidak dikirim di query string.

## Presensi / Geofencing

| Method | Endpoint | Keterangan |
|---|---|---|
| GET | `/api/office` | Titik, nama dan radius kantor |
| PATCH | `/api/office` | Hanya HRD: `{name, latitude, longitude, radius_m}` |
| GET | `/api/attendance/today` | Presensi pengguna pada hari Jakarta |
| GET | `/api/attendance` | Riwayat presensi milik pengguna |
| POST | `/api/attendance/check-in` | Body `{latitude, longitude, accuracy_m}` |
| POST | `/api/attendance/check-out` | Body sama; perlu check-in sebelumnya |

Validasi server menolak GPS jika akurasi >100 meter atau `distance_to_office + accuracy > radius_m`. Data berasal dari klien sehingga anti-spoofing belum tersedia.

## Permohonan, review, dan jadwal

| Method | Endpoint | Keterangan |
|---|---|---|
| GET/POST | `/api/requests` | Riwayat sendiri / membuat permohonan |
| GET | `/api/approvals` | Daftar review sesuai tahap dan departemen |
| POST | `/api/requests/{id}/approve` | Manajer, kepala departemen, HRD sesuai status |
| POST | `/api/requests/{id}/reject` | Sama, penolakan final |
| GET | `/api/schedules` | Jadwal shift akun saat ini; opsional query `from`, `to` |
| GET | `/api/shifts` | Katalog shift |
| POST | `/api/schedules/assign` | HRD `{user_id, shift_id, work_date}` |

Body POST `/api/requests`:

```json
{
  "kind": "cuti",
  "start_date": "2026-12-02",
  "end_date": "2026-12-03",
  "reason": "Keperluan keluarga"
}
```

Tahap: `menunggu_manajer` → `menunggu_kepala` → `disetujui`. Manajer pemohon langsung ke tahap kepala, kepala departemen pemohon ke tahap HRD. Permohonan HRD sendiri belum aktif sampai organisasi menetapkan penyetuju HRD yang sah.

## HRD dan Dashboard

| Method | Endpoint | Keterangan |
|---|---|---|
| GET/POST | `/api/staff` | Daftar staf (role tertentu) / tambah staf (HRD) |
| GET | `/api/dashboard` | Statistik ringkas disesuaikan role |
| GET | `/api/audit` | Log aktivitas (HRD) |
| GET | `/health` | Liveness lokal tanpa rahasia |

Kesalahan memakai JSON `{ "error": "pesan" }` dan kode HTTP 400/401/403/404/409/413/422/429/500 sesuai konteks.

## Database

Dikelola oleh `server/src/database.mjs` menggunakan SQLite: `departments`, `users`, `sessions`, `office_locations`, `shifts`, `schedules`, `attendance`, `requests`, `request_approvals`, `audit_logs`.

Tidak ada cloud backend atau biaya Google Maps. Data tersimpan di `server/data/nadi.sqlite`, diabaikan Git. Jangan mengunggah database ke repository publik.
