import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

/// Avatar images use deliberately small payloads for the local NADI API.
const maxAvatarBytes = 150000;

Future<String?> chooseProfilePhoto() async {
  final file = await ImagePicker().pickImage(
    source: ImageSource.gallery,
    maxWidth: 400,
    maxHeight: 400,
    imageQuality: 65,
  );
  if (file == null) return null;
  if (await file.length() > maxAvatarBytes) {
    throw const FormatException(
      'Foto terlalu besar. Pilih foto JPG/PNG di bawah 150 KB.',
    );
  }
  final bytes = await file.readAsBytes();
  if (bytes.isEmpty || bytes.length > maxAvatarBytes) {
    throw const FormatException('Foto harus berukuran maksimal 150 KB.');
  }
  final png = bytes.length >= 8 &&
      bytes[0] == 137 && bytes[1] == 80 && bytes[2] == 78 &&
      bytes[3] == 71 && bytes[4] == 13 && bytes[5] == 10 &&
      bytes[6] == 26 && bytes[7] == 10;
  final jpeg = bytes.length >= 3 &&
      bytes[0] == 255 && bytes[1] == 216 && bytes[2] == 255;
  if (!png && !jpeg) {
    throw const FormatException('Gunakan foto JPG atau PNG.');
  }
  final format = png ? 'png' : 'jpeg';
  return 'data:image/$format;base64,${base64Encode(bytes)}';
}

Uint8List? profilePhotoBytes(String? data) {
  if (data == null || data.isEmpty || !data.startsWith('data:image/')) {
    return null;
  }
  try {
    return base64Decode(data.substring(data.indexOf(',') + 1));
  } catch (_) {
    return null;
  }
}

Widget profileAvatar({
  required String name,
  String? data,
  double radius = 37,
}) {
  final bytes = profilePhotoBytes(data);
  final initials = name.trim().split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .take(2).map((part) => part[0].toUpperCase()).join();
  return CircleAvatar(
    radius: radius,
    backgroundColor: const Color(0xFFDFE9FB),
    backgroundImage: bytes == null ? null : MemoryImage(bytes),
    child: bytes == null
        ? Text(
            initials.isEmpty ? '?' : initials,
            style: const TextStyle(
              color: Color(0xFF245BE8),
              fontWeight: FontWeight.w800,
            ),
          )
        : null,
  );
}
