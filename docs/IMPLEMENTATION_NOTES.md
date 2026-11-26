# Implementasi visual & interaksi

## Referensi visual Pertemuan 6

Acuan desain berada pada `assets/designs/01_Login.svg` sampai `09_Profil.svg`.

- Frame desain: 390 × 844 px.
- Brand: Navy `#12283F`, Royal Blue `#245BE8`, merah `#E34E54`.
- UI menggunakan Flutter Material 3 dengan card radius 12–20 px, spacing modular, tombol cukup besar untuk sentuhan.
- Sembilan desain lama tetap dapat dipratinjau melalui mode **Pratinjau UI**; tidak diubah menjadi gambar statis.
- Mode **Server API** mempertahankan hirarki desain dan menambahkan state dinamis: konfirmasi, loading, empty/error states, status request, role-specific modules.
- Motion: `AnimatedSwitcher` fade + translasi pendek untuk tab dan `AnimatedContainer` untuk indikator tab. Tujuannya memberikan respons halus tanpa efek mencolok berlebihan.

## Pembeda demo vs live

Demo dari PDF sengaja mempertahankan ilustrasi UI (misal peta berbasis CustomPainter). Mode Server menggunakan geolocator HP dan validasi ulang API. Backend tidak dapat menentukan keaslian GPS dan tidak memiliki anti-spoofing kelas enterprise.

## Perbedaan implementasi terhadap desain

Mode Server menambahkan kontrol pengambilan lokasi, layar master data HRD, serta state error yang tidak digambar pada sembilan SVG Pertemuan 6. Ini adalah perluasan fungsional, bukan bukti *pixel-perfect* dengan seluruh desain awal. Kesesuaian visual harus diuji di Flutter runtime dan diperbaiki pada viewport 390×844 sebelum klaim 100%.
