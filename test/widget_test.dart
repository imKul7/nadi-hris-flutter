import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nadi_hris/main.dart';

void main() {
  testWidgets('login demo membuka dashboard karyawan', (tester) async {
    await tester.pumpWidget(const NadiApp());
    expect(find.text('Masuk ke akun Anda'), findsOneWidget);
    await tester.ensureVisible(find.text('Pratinjau UI'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Pratinjau UI'));
    await tester.enterText(find.byKey(const Key('login_password')), 'demo1234');
    await tester.ensureVisible(find.text('Masuk'));
    await tester.tap(find.text('Masuk'));
    await tester.pumpAndSettle();
    expect(find.text('Selamat bekerja, Raka.'), findsOneWidget);
    expect(find.text('Beranda'), findsOneWidget);
  });

  testWidgets('navigasi pengajuan membuka formulir demo', (tester) async {
    await tester.pumpWidget(const NadiApp());
    await tester.ensureVisible(find.text('Pratinjau UI'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Pratinjau UI'));
    await tester.enterText(find.byKey(const Key('login_password')), 'demo1234');
    await tester.ensureVisible(find.text('Masuk'));
    await tester.tap(find.text('Masuk'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('tab_2')));
    await tester.pumpAndSettle();

    expect(find.text('Pengajuan baru'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Kirim Pengajuan'),
      200.0,
      scrollable: find.byType(Scrollable).last,
    );

    expect(find.text('Kirim Pengajuan'), findsOneWidget);
  });
}
