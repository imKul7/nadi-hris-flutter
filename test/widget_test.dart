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

  testWidgets('login responsive mobile 390x844 tanpa layout overflow', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const NadiApp());
    await tester.pumpAndSettle();

    expect(find.text('Satu ritme.\nUntuk seluruh tim.'), findsOneWidget);
    expect(find.text('Masuk ke akun Anda'), findsOneWidget);
    expect(find.byKey(const Key('login_email')), findsOneWidget);
    expect(find.byKey(const Key('login_password')), findsOneWidget);
    expect(find.text('Server API'), findsOneWidget);
    expect(find.text('Pratinjau UI'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('Pratinjau UI'));
    await tester.pumpAndSettle();
    expect(find.text('Mode ini khusus pratinjau visual tanpa backend.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('login narrow viewport 320px tidak overflow', (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const NadiApp());
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('login_email')), findsOneWidget);
    expect(find.byKey(const Key('login_password')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
