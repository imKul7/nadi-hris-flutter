# Keamanan dan batasan pemakaian

**Peringatan:** NADI HRIS adalah prototipe akademik dengan API lokal fungsional. Belum siap produksi atau mengelola data karyawan sungguhan.

## Sudah diimplementasikan

- Password menggunakan `scrypt` dan salt acak; hash disimpan di SQLite.
- Token sesi acak 256-bit, hanya hash SHA-256 token disimpan di DB, kedaluwarsa setelah 12 jam.
- Hak akses dicek di server pada setiap endpoint, termasuk departemen dan tahap persetujuan.
- SQL menggunakan prepared statements.
- Validasi payload dan batas request 1 MB.
- Login memiliki rate limit sederhana per IP (in-memory).
- Log audit tindakan dasar.
- CORS origins eksplisit untuk production, localhost fleksibel hanya development.
- Tidak ada password nyata atau `.env`/SQLite dalam repository.
- Android debug mengizinkan HTTP lokal demi pengujian; build release tidak menambah pengecualian tersebut.

## Belum siap untuk production

1. HTTPS wajib dengan reverse proxy dan sertifikat terpercaya. Jangan menggunakan HTTP untuk kredensial di jaringan umum.
2. Migrasikan database/backup ke sistem yang didukung production (mis. Laravel + MySQL sesuai rancangan).
3. Ganti seluruh akun dan password contoh. Jangan jalankan `NADI_DEMO_SEED=1` pada production.
4. Gunakan token storage terenkripsi perangkat; saat ini token hanya ada dalam state memori selama aplikasi berjalan.
5. Tambahkan account lockout terdistribusi, CSRF sesuai deployment, secret management, audit immutability, monitoring, backups, dan prosedur pemulihan.
6. Pastikan kebijakan waktu lintas tengah malam untuk shift malam, cuti bersama, zona waktu, dan approval perusahaan nyata.
7. GPS yang dilaporkan ponsel dapat dipalsukan. Tambahkan attestation perangkat, deteksi mock location, audit anomali, dan kebijakan manual.
8. Lokasi kantor demo di Kelurahan Pejuang hanya **referensi contoh**, bukan lokasi kerja yang diverifikasi.
9. Lampiran medis dan data pribadi sensitif tidak ditangani oleh prototipe ini; jangan memasukkan data sensitif.
10. Belum ada password reset, MFA, email notifikasi, SSO, atau privacy retention policy.
11. GitHub publik hanya untuk source fiktif, jangan sertakan identitas karyawan/perusahaan nyata.

## Menghapus data demo

Matikan server, backup bila diperlukan, lalu hapus `server/data/nadi.sqlite` untuk membuat DB demonstrasi baru. Sebelum reset pastikan tidak ada data yang perlu dipertahankan.
