import 'package:flutter/material.dart';

const profileNavy = Color(0xFF12283F);
const profileMuted = Color(0xFF71849A);
const profileBlue = Color(0xFF245BE8);

Future<void> showProfileSheet(
  BuildContext context, {
  required String title,
  required List<Widget> children,
}) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
    ),
    builder: (sheetContext) => Padding(
      padding: EdgeInsets.fromLTRB(
        23, 8, 23, MediaQuery.viewInsetsOf(sheetContext).bottom + 28,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(title, style: const TextStyle(
                    color: profileNavy,
                    fontSize: 21,
                    fontWeight: FontWeight.w800,
                  )),
                ),
                IconButton(
                  tooltip: 'Tutup',
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.of(sheetContext).pop(),
                ),
              ],
            ),
            const SizedBox(height: 18),
            ...children,
          ],
        ),
      ),
    ),
  );
}

class ProfileDetailRow extends StatelessWidget {
  final String label;
  final String value;
  const ProfileDetailRow({
    super.key,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 17),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(), style: const TextStyle(
          fontSize: 10,
          color: profileMuted,
          fontWeight: FontWeight.w800,
        )),
        const SizedBox(height: 5),
        SelectableText(value, style: const TextStyle(
          color: profileNavy,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        )),
      ],
    ),
  );
}

Widget profileHelpContent() => const Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    ProfileDetailRow(
      label: 'Masuk',
      value: 'Gunakan akun HRIS sesuai role. Mode Pratinjau UI hanya menampilkan data simulasi.',
    ),
    ProfileDetailRow(
      label: 'Presensi',
      value: 'Di mode Server API, izinkan lokasi GPS. Server memeriksa radius dan akurasi sebelum check-in/check-out.',
    ),
    ProfileDetailRow(
      label: 'Pengajuan',
      value: 'Ajukan cuti, izin, sakit, atau lembur. Manajer lalu Kepala Departemen memproses sesuai kewenangan.',
    ),
    ProfileDetailRow(
      label: 'Foto profil',
      value: 'Opsional. Pilih PNG/JPG maksimal 150 KB. Foto di Server API tersimpan pada database lokal NADI.',
    ),
    ProfileDetailRow(
      label: 'Dukungan',
      value: 'Dokumentasi tersedia di README.md dan docs/SECURITY.md repository NADI HRIS.',
    ),
  ],
);
