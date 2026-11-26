import 'live/api.dart';
import 'live/live_app.dart';
import 'package:flutter/material.dart';

void main() => runApp(const NadiApp());

// NADI HRIS: pratinjau UI berbasis data demo dan mode terhubung ke API lokal.
// Seluruh data di pratinjau merupakan simulasi, bukan transaksi backend.

class NadiColors {
  static const navy = Color(0xFF12283F);
  static const royal = Color(0xFF245BE8);
  static const red = Color(0xFFE34E54);
  static const white = Colors.white;
  static const canvas = Color(0xFFF6F8FC);
  static const green = Color(0xFF11866B);
  static const amber = Color(0xFFB67813);
  static const muted = Color(0xFF71849A);
  static const border = Color(0xFFE1E8F2);
}

enum NadiRole { karyawan, manajer, kepalaDepartemen, hrd }

extension NadiRoleX on NadiRole {
  String get label => switch (this) {
        NadiRole.karyawan => 'Karyawan',
        NadiRole.manajer => 'Manajer Bagian',
        NadiRole.kepalaDepartemen => 'Kepala Departemen',
        NadiRole.hrd => 'HRD',
      };
}

class NadiRequest {
  final String title;
  final String period;
  String status;
  final String reason;
  NadiRequest(this.title, this.period, this.status, this.reason);
}

class DemoStore extends ChangeNotifier {
  NadiRole role = NadiRole.karyawan;
  int tab = 0;
  bool loggedIn = false;
  bool simulatedCheckIn = false;
  final List<NadiRequest> requests = [
    NadiRequest(
        'Cuti tahunan', '28–29 Okt · 2 hari', 'Menunggu', 'Keperluan keluarga'),
    NadiRequest(
        'Lembur', '21 Okt · 18.00–21.00', 'Disetujui', 'Bantuan proses akhir'),
    NadiRequest('Izin pribadi', '13 Okt · 1 hari', 'Ditolak', 'Urusan pribadi'),
  ];

  void login(NadiRole newRole) {
    role = newRole;
    loggedIn = true;
    tab = 0;
    notifyListeners();
  }

  void logout() {
    loggedIn = false;
    tab = 0;
    notifyListeners();
  }

  void selectTab(int next) {
    tab = next;
    notifyListeners();
  }

  void addRequest(NadiRequest request) {
    requests.insert(0, request);
    tab = 1;
    notifyListeners();
  }

  void changeStatus(NadiRequest request, String status) {
    request.status = status;
    notifyListeners();
  }

  void checkInDemo() {
    simulatedCheckIn = !simulatedCheckIn;
    notifyListeners();
  }
}

class NadiApp extends StatefulWidget {
  const NadiApp({super.key});

  @override
  State<NadiApp> createState() => _NadiAppState();
}

class _NadiAppState extends State<NadiApp> {
  final DemoStore store = DemoStore();
  LiveSession? _session;

  @override
  void dispose() {
    store.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: store,
      builder: (context, _) => MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'NADI HRIS',
        theme: ThemeData(
          useMaterial3: true,
          fontFamily: 'Roboto',
          scaffoldBackgroundColor: NadiColors.canvas,
          colorScheme: ColorScheme.fromSeed(
              seedColor: NadiColors.royal, surface: NadiColors.canvas),
          textTheme: const TextTheme(
            headlineSmall: TextStyle(
                fontSize: 25,
                fontWeight: FontWeight.w800,
                color: NadiColors.navy),
            titleLarge: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: NadiColors.navy),
            titleMedium: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: NadiColors.navy),
            bodyMedium: TextStyle(fontSize: 13, color: NadiColors.navy),
          ),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: Colors.white,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 17),
            hintStyle: const TextStyle(color: NadiColors.muted, fontSize: 13),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: const BorderSide(color: NadiColors.border)),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: const BorderSide(color: NadiColors.border)),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide:
                    const BorderSide(color: NadiColors.royal, width: 1.5)),
          ),
        ),
        home: _session != null
            ? LiveApp(
                session: _session!,
                onLogout: () => setState(() => _session = null))
            : store.loggedIn
                ? MainShell(store: store)
                : LoginScreen(
                    store: store,
                    onConnected: (s) => setState(() => _session = s)),
      ),
    );
  }
}

class UI {
  static Widget gap(double h) => SizedBox(height: h);

  static Widget caption(String text,
          {Color color = NadiColors.muted,
          double size = 12,
          FontWeight weight = FontWeight.w400}) =>
      Text(text,
          style: TextStyle(color: color, fontSize: size, fontWeight: weight));

  static Widget heading(String text, {double size = 24}) => Text(text,
      style: TextStyle(
          color: NadiColors.navy, fontWeight: FontWeight.w800, fontSize: size));

  static Widget card(
          {required Widget child,
          EdgeInsetsGeometry padding = const EdgeInsets.all(16),
          Color bg = Colors.white,
          double radius = 17,
          Color border = NadiColors.border}) =>
      Container(
          width: double.infinity,
          padding: padding,
          decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(radius),
              border: Border.all(color: border)),
          child: child);

  static Widget primary(
    String label,
    VoidCallback onPressed, {
    IconData? icon,
    Color color = NadiColors.royal,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: FilledButton(
        style: FilledButton.styleFrom(
          backgroundColor: color,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onPressed: onPressed,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 17),
              const SizedBox(width: 7),
            ],
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget pill(String label,
          {Color bg = const Color(0xFFEAF0FF), Color fg = NadiColors.royal}) =>
      Container(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
          decoration:
              BoxDecoration(color: bg, borderRadius: BorderRadius.circular(30)),
          child: Text(label,
              style: TextStyle(
                  fontSize: 11, color: fg, fontWeight: FontWeight.w700)));

  static Widget smallIcon(IconData icon,
          {Color bg = const Color(0xFFEAF0FF),
          Color color = NadiColors.royal}) =>
      Container(
          width: 39,
          height: 39,
          alignment: Alignment.center,
          decoration:
              BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, color: color, size: 20));

  static Widget status(String status) {
    final color = status == 'Disetujui'
        ? NadiColors.green
        : status == 'Ditolak'
            ? NadiColors.red
            : NadiColors.amber;
    final bg = status == 'Disetujui'
        ? const Color(0xFFE6F6EF)
        : status == 'Ditolak'
            ? const Color(0xFFFCE8E9)
            : const Color(0xFFFFF2D9);
    return pill(status, bg: bg, fg: color);
  }

  static void notice(BuildContext context, String text) {
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(text), behavior: SnackBarBehavior.floating));
  }
}

class LoginScreen extends StatefulWidget {
  final DemoStore store;
  final void Function(LiveSession) onConnected;
  const LoginScreen(
      {super.key, required this.store, required this.onConnected});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final email = TextEditingController(text: 'raka@nadi.test');
  final password = TextEditingController();
  bool hidden = true;
  bool serverMode = true;
  bool submitting = false;
  NadiRole role = NadiRole.karyawan;

  static const _fieldFill = Color(0xFFF8FAFE);
  static const _fieldOutline = Color(0xFFCFDDF1);
  static const _deepBlue = Color(0xFF0B3471);

  @override
  void dispose() {
    email.dispose();
    password.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (submitting) {
      return;
    }
    if (email.text.trim().isEmpty || password.text.trim().isEmpty) {
      UI.notice(context, 'Isi email karyawan dan kata sandi.');
      return;
    }
    if (!serverMode) {
      widget.store.login(role);
      return;
    }

    setState(() => submitting = true);
    try {
      final session = await NadiApi().login(email.text.trim(), password.text);
      if (mounted) {
        widget.onConnected(session);
      }
    } catch (error) {
      if (mounted) {
        UI.notice(context, error.toString());
      }
    } finally {
      if (mounted) {
        setState(() => submitting = false);
      }
    }
  }

  InputDecoration _inputDecoration(
    String placeholder,
    IconData leading, {
    Widget? trailing,
  }) {
    return InputDecoration(
      hintText: placeholder,
      filled: true,
      fillColor: _fieldFill,
      prefixIcon: Icon(leading, size: 21, color: const Color(0xFF526783)),
      suffixIcon: trailing,
      contentPadding: const EdgeInsets.symmetric(
        vertical: 17,
        horizontal: 16,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: _fieldOutline),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: NadiColors.royal, width: 1.7),
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
      ),
    );
  }

  Widget _brandHero({required bool desktop}) {
    return ClipRRect(
      borderRadius: BorderRadius.only(
        topLeft: Radius.circular(desktop ? 28 : 0),
        topRight: Radius.circular(desktop ? 28 : 0),
      ),
      child: SizedBox(
        height: desktop ? 265 : 268,
        child: DecoratedBox(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [NadiColors.navy, Color(0xFF082E61), _deepBlue],
            ),
          ),
          child: Stack(
            clipBehavior: Clip.hardEdge,
            children: [
              Positioned(
                width: 260,
                height: 260,
                right: -74,
                top: -112,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0x332E8DE7),
                      width: 1,
                    ),
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF185B99), Color(0xFF0B376B)],
                    ),
                  ),
                ),
              ),
              Positioned(
                width: 320,
                height: 320,
                right: -182,
                bottom: -254,
                child: const DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0x442D78BB),
                  ),
                ),
              ),
              Positioned(
                right: 20,
                top: 76,
                child: Transform.rotate(
                  angle: -0.23,
                  child: Container(
                    width: 165,
                    height: 66,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(90),
                      color: const Color(0x121D9CFF),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(27, 35, 27, 42),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'N',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -1.2,
                          ),
                        ),
                        SizedBox(width: 6),
                        CircleAvatar(
                          radius: 3,
                          backgroundColor: NadiColors.red,
                        ),
                        SizedBox(width: 9),
                        Text(
                          'nadi',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.7,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    const Text(
                      'Satu ritme.\nUntuk seluruh tim.',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 29,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.6,
                        height: 1.16,
                      ),
                    ),
                    const SizedBox(height: 17),
                    Container(
                      width: 52,
                      height: 4,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        gradient: const LinearGradient(
                          colors: [Color(0xFF8FC7FF), NadiColors.royal],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _modeOption(
    String label,
    IconData icon,
    bool value,
  ) {
    final selected = serverMode == value;
    return Expanded(
      child: Semantics(
        button: true,
        selected: selected,
        child: Material(
          color: selected ? const Color(0xFFE5EDFF) : Colors.transparent,
          borderRadius: BorderRadius.circular(15),
          child: InkWell(
            borderRadius: BorderRadius.circular(15),
            onTap: submitting
                ? null
                : () => setState(() => serverMode = value),
            child: Container(
              height: 46,
              padding: const EdgeInsets.symmetric(horizontal: 6),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                border: selected
                    ? Border.all(color: NadiColors.royal, width: 1.4)
                    : null,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    selected ? Icons.check_circle_rounded : icon,
                    size: 19,
                    color: selected ? NadiColors.royal : NadiColors.muted,
                  ),
                  const SizedBox(width: 7),
                  Flexible(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                        color: selected ? NadiColors.royal : NadiColors.navy,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _loginCard() {
    return Transform.translate(
      offset: const Offset(0, -24),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(25, 30, 25, 32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(29),
          boxShadow: const [
            BoxShadow(
              color: Color(0x160F305C),
              blurRadius: 34,
              offset: Offset(0, 12),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            UI.heading('Masuk ke akun Anda', size: 22),
            const SizedBox(height: 5),
            UI.caption(
              'Kelola waktu kerja dengan lebih pasti.',
              size: 12,
            ),
            const SizedBox(height: 27),
            UI.caption(
              'EMAIL / ID KARYAWAN',
              size: 11,
              weight: FontWeight.w800,
            ),
            const SizedBox(height: 9),
            TextField(
              key: const Key('login_email'),
              controller: email,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.username],
              autocorrect: false,
              decoration: _inputDecoration(
                'nama@perusahaan.co.id',
                Icons.mail_outline_rounded,
              ),
            ),
            const SizedBox(height: 21),
            UI.caption(
              'KATA SANDI',
              size: 11,
              weight: FontWeight.w800,
            ),
            const SizedBox(height: 9),
            TextField(
              key: const Key('login_password'),
              controller: password,
              obscureText: hidden,
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.password],
              onSubmitted: (_) => _handleLogin(),
              decoration: _inputDecoration(
                'Kata sandi',
                Icons.lock_outline_rounded,
                trailing: IconButton(
                  tooltip: hidden ? 'Tampilkan kata sandi' : 'Sembunyikan kata sandi',
                  icon: Icon(
                    hidden
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: NadiColors.navy,
                  ),
                  onPressed: () => setState(() => hidden = !hidden),
                ),
              ),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => UI.notice(
                  context,
                  'Pemulihan kata sandi belum tersedia. Hubungi administrator.',
                ),
                child: const Text(
                  'Lupa kata sandi?',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            UI.caption(
              'PILIH MODE AKSES',
              size: 11,
              weight: FontWeight.w800,
            ),
            const SizedBox(height: 11),
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(19),
                border: Border.all(color: _fieldOutline),
                color: _fieldFill,
              ),
              child: Row(
                children: [
                  _modeOption('Server API', Icons.dns_outlined, true),
                  _modeOption(
                    'Pratinjau UI',
                    Icons.desktop_windows_outlined,
                    false,
                  ),
                ],
              ),
            ),
            if (!serverMode) ...[
              const SizedBox(height: 15),
              DropdownButtonFormField<NadiRole>(
                initialValue: role,
                isExpanded: true,
                decoration: _inputDecoration(
                  'Pilih role untuk pratinjau',
                  Icons.people_outline_rounded,
                ),
                items: NadiRole.values
                    .map(
                      (r) => DropdownMenuItem(
                        value: r,
                        child: Text(r.label),
                      ),
                    )
                    .toList(),
                onChanged: submitting
                    ? null
                    : (value) => setState(() => role = value ?? role),
              ),
            ],
            const SizedBox(height: 24),
            Container(
              width: double.infinity,
              height: 54,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF2586FF), NadiColors.royal, Color(0xFF123BD4)],
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x34245BE8),
                    blurRadius: 19,
                    offset: Offset(0, 9),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(15),
                child: InkWell(
                  borderRadius: BorderRadius.circular(15),
                  onTap: submitting ? null : _handleLogin,
                  child: Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (submitting)
                          const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        else
                          const Icon(
                            Icons.arrow_forward_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        const SizedBox(width: 9),
                        Text(
                          submitting ? 'Menghubungkan...' : 'Masuk',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 22),
            Center(
              child: Text(
                serverMode
                    ? 'Server memakai autentikasi role asli. IP server: lihat README.'
                    : 'Mode ini khusus pratinjau visual tanpa backend.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: NadiColors.muted,
                  fontSize: 10.5,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NadiColors.canvas,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final desktop = constraints.maxWidth > 600;
            return SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: 470,
                    minHeight: constraints.maxHeight,
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: desktop
                          ? const [
                              BoxShadow(
                                color: Color(0x110B2850),
                                blurRadius: 40,
                                offset: Offset(0, 14),
                              ),
                            ]
                          : null,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _brandHero(desktop: desktop),
                        _loginCard(),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class MainShell extends StatefulWidget {
  final DemoStore store;
  const MainShell({super.key, required this.store});
  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  void openExtra(Widget page) =>
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));

  @override
  Widget build(BuildContext context) {
    final role = widget.store.role;
    final pages = <Widget>[
      role == NadiRole.hrd
          ? HrdDashboard(store: widget.store)
          : EmployeeDashboard(
              store: widget.store,
              openAttendance: () =>
                  openExtra(AttendanceScreen(store: widget.store)),
              openApproval: () =>
                  openExtra(ApprovalScreen(store: widget.store))),
      RequestHistory(
          store: widget.store,
          openForm: () => openExtra(RequestForm(store: widget.store))),
      RequestForm(store: widget.store, embedded: true),
      const ScheduleScreen(),
      ProfileScreen(store: widget.store),
    ];
    const labels = ['Beranda', 'Riwayat', 'Pengajuan', 'Jadwal', 'Profil'];
    const icons = [
      Icons.home_outlined,
      Icons.history_rounded,
      Icons.description_outlined,
      Icons.calendar_month_outlined,
      Icons.person_outline
    ];
    const selectedIcons = [
      Icons.home_rounded,
      Icons.history_rounded,
      Icons.description_rounded,
      Icons.calendar_month_rounded,
      Icons.person_rounded
    ];
    return Scaffold(
      body: SafeArea(child: pages[widget.store.tab]),
      bottomNavigationBar: SafeArea(
          top: false,
          child: Container(
              decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(top: BorderSide(color: NadiColors.border))),
              height: 71,
              child: Row(
                  children: List.generate(5, (index) {
                final selected = widget.store.tab == index;
                return Expanded(
                    child: InkWell(
                        key: Key('tab_$index'),
                        onTap: () => widget.store.selectTab(index),
                        child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                  selected
                                      ? selectedIcons[index]
                                      : icons[index],
                                  size: 21,
                                  color: selected
                                      ? NadiColors.royal
                                      : NadiColors.muted),
                              const SizedBox(height: 5),
                              Text(labels[index],
                                  style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: selected
                                          ? FontWeight.w800
                                          : FontWeight.w500,
                                      color: selected
                                          ? NadiColors.royal
                                          : NadiColors.muted))
                            ])));
              })))),
    );
  }
}

class PageBody extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<Widget> children;
  final Widget? trailing;
  const PageBody(
      {super.key,
      required this.title,
      required this.subtitle,
      required this.children,
      this.trailing});
  @override
  Widget build(BuildContext context) =>
      ListView(padding: const EdgeInsets.fromLTRB(20, 27, 20, 28), children: [
        Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                UI.heading(title),
                UI.gap(4),
                UI.caption(subtitle)
              ])),
          if (trailing != null) trailing!
        ]),
        UI.gap(24),
        ...children
      ]);
}

class EmployeeDashboard extends StatelessWidget {
  final DemoStore store;
  final VoidCallback openAttendance;
  final VoidCallback openApproval;
  const EmployeeDashboard(
      {super.key,
      required this.store,
      required this.openAttendance,
      required this.openApproval});

  @override
  Widget build(BuildContext context) =>
      ListView(padding: const EdgeInsets.fromLTRB(20, 20, 20, 28), children: [
        Row(children: [
          Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                  color: NadiColors.navy,
                  borderRadius: BorderRadius.circular(7)),
              alignment: Alignment.center,
              child: const Text('N',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold))),
          const SizedBox(width: 9),
          UI.heading('nadi', size: 20),
          const Spacer(),
          IconButton(
              onPressed: () => UI.notice(
                  context, 'Belum ada notifikasi live dalam frontend demo.'),
              icon: const Icon(Icons.notifications_none))
        ]),
        UI.gap(17),
        UI.caption('Selamat pagi,'),
        UI.gap(2),
        UI.heading('Selamat bekerja, Raka.', size: 22),
        UI.gap(12),
        UI.pill('${store.role.label} · QC'),
        UI.gap(24),
        Container(
            padding: const EdgeInsets.all(19),
            decoration: BoxDecoration(
                color: NadiColors.navy,
                borderRadius: BorderRadius.circular(17),
                border: const Border(
                    top: BorderSide(color: NadiColors.royal, width: 5))),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              UI.caption('PRESENSI HARI INI',
                  color: const Color(0xFFB4C8DD),
                  weight: FontWeight.w800,
                  size: 11),
              UI.gap(7),
              Row(children: [
                const Text('08:41',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 42,
                        fontWeight: FontWeight.w900)),
                const Spacer(),
                UI.caption('Sabtu, 24 Okt 2026',
                    color: const Color(0xFFB4C8DD), size: 11)
              ]),
              UI.gap(8),
              UI.pill('● Di dalam area (contoh)',
                  bg: const Color(0xFF174F52), fg: const Color(0xFF9DF0D1)),
              UI.gap(16),
              Container(height: 1, color: const Color(0xFF294058)),
              UI.gap(14),
              Row(children: [
                Expanded(
                    child: UI.caption('Shift Pagi · 07.00—15.00',
                        color: Colors.white, size: 12)),
                SizedBox(
                    width: 123, child: UI.primary('Check-in', openAttendance))
              ]),
            ])),
        UI.gap(26),
        Row(children: [
          Expanded(child: UI.heading('Ringkasan kerja', size: 16)),
          TextButton(
              onPressed: () => store.selectTab(1),
              child: const Text('Lihat semua', style: TextStyle(fontSize: 11)))
        ]),
        UI.gap(10),
        Row(children: [
          Expanded(
              child: UI.card(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                const Icon(Icons.access_time,
                    color: NadiColors.royal, size: 20),
                UI.gap(6),
                UI.heading('07.00', size: 23),
                UI.caption('Jadwal masuk')
              ]))),
          const SizedBox(width: 9),
          Expanded(
              child: UI.card(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                const Icon(Icons.calendar_month_outlined,
                    color: NadiColors.red, size: 20),
                UI.gap(6),
                UI.heading('24 Okt', size: 23),
                UI.caption('Hari kerja')
              ])))
        ]),
        UI.gap(24),
        UI.heading('Aksi cepat', size: 16),
        UI.gap(12),
        ActionTile(
            icon: Icons.article_outlined,
            title: 'Ajukan cuti / lembur',
            subtitle: 'Proses online, status transparan',
            onTap: () => store.selectTab(2)),
        if (store.role == NadiRole.manajer ||
            store.role == NadiRole.kepalaDepartemen) ...[
          UI.gap(10),
          ActionTile(
              icon: Icons.approval_outlined,
              title: 'Pusat persetujuan',
              subtitle: 'Tinjau pengajuan anggota tim',
              onTap: openApproval),
        ],
        UI.gap(16),
        UI.caption('Mode demonstrasi UI — belum terhubung ke server atau GPS.',
            size: 11),
      ]);
}

class ActionTile extends StatelessWidget {
  final IconData icon;
  final String title, subtitle;
  final VoidCallback onTap;
  final Color iconColor;
  const ActionTile(
      {super.key,
      required this.icon,
      required this.title,
      required this.subtitle,
      required this.onTap,
      this.iconColor = NadiColors.royal});
  @override
  Widget build(BuildContext context) => Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(15),
      child: InkWell(
          borderRadius: BorderRadius.circular(15),
          onTap: onTap,
          child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: NadiColors.border)),
              child: Row(children: [
                UI.smallIcon(icon, color: iconColor),
                const SizedBox(width: 13),
                Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      Text(title,
                          style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: NadiColors.navy)),
                      UI.gap(3),
                      UI.caption(subtitle, size: 11)
                    ])),
                const Icon(Icons.chevron_right, color: NadiColors.muted)
              ]))));
}

class AttendanceScreen extends StatefulWidget {
  final DemoStore store;
  const AttendanceScreen({super.key, required this.store});
  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(
          backgroundColor: NadiColors.canvas,
          title: const Text('Presensi',
              style: TextStyle(fontWeight: FontWeight.bold)),
          elevation: 0),
      body: ListView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 25),
          children: [
            UI.caption('Validasi lokasi sebelum mencatat kehadiran'),
            UI.gap(18),
            DemoMap(),
            UI.gap(19),
            UI.heading('Akurasi & keamanan', size: 17),
            UI.gap(12),
            UI.card(
                child: Row(children: [
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    const Icon(Icons.navigation_outlined,
                        color: NadiColors.royal),
                    UI.gap(6),
                    UI.heading('Akurasi GPS', size: 12),
                    UI.caption('Simulasi · ±8 meter', size: 11)
                  ])),
              Container(width: 1, height: 55, color: NadiColors.border),
              const SizedBox(width: 20),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    const Icon(Icons.my_location, color: NadiColors.royal),
                    UI.gap(6),
                    UI.heading('Radius izin', size: 12),
                    UI.caption('Contoh · 100 meter', size: 11)
                  ]))
            ])),
            UI.gap(13),
            UI.card(
                bg: const Color(0xFFE9F7F0),
                border: const Color(0xFFD6EDDF),
                child: Row(children: [
                  const Icon(Icons.verified_user_outlined,
                      color: NadiColors.green),
                  const SizedBox(width: 12),
                  Expanded(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                        const Text('Lokasi terverifikasi (mockup)',
                            style: TextStyle(
                                color: NadiColors.green,
                                fontWeight: FontWeight.w800,
                                fontSize: 13)),
                        UI.caption('Waktu dan posisi belum disimpan ke server',
                            size: 11),
                      ]))
                ])),
            UI.gap(16),
            UI.primary(
                widget.store.simulatedCheckIn
                    ? 'Simulasikan Check-out'
                    : 'Tandai untuk Check-in', () {
              widget.store.checkInDemo();
              UI.notice(context,
                  'Simulasi frontend saja. Tidak ada absensi atau GPS yang dikirim ke server.');
            }),
            UI.gap(15),
            UI.caption(
                'Lokasi kantor, radius, dan peta di layar ini adalah ilustrasi dari desain Pertemuan 6.',
                size: 11),
          ]));
}

class DemoMap extends StatelessWidget {
  const DemoMap({super.key});
  @override
  Widget build(BuildContext context) => ClipRRect(
      borderRadius: BorderRadius.circular(17),
      child: Container(
        height: 280,
        color: const Color(0xFFEAF2F8),
        child: Stack(children: [
          CustomPaint(
              size: const Size(double.infinity, 280), painter: _MapPainter()),
          Positioned(
              left: 16,
              top: 15,
              child: UI.pill('● Area kantor aktif',
                  bg: Colors.white, fg: NadiColors.green)),
          Center(
              child: Container(
                  width: 215,
                  height: 215,
                  decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: NadiColors.royal.withValues(alpha: 0.11),
                      border: Border.all(color: NadiColors.royal, width: 1.5)),
                  child: Center(
                      child: Container(
                          width: 55,
                          height: 55,
                          decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: NadiColors.royal.withValues(alpha: 0.19)),
                          child: const Icon(Icons.my_location,
                              size: 25, color: NadiColors.royal))))),
          Positioned(
              bottom: 13,
              left: 14,
              right: 14,
              child: UI.card(
                  padding: const EdgeInsets.all(11),
                  child: Row(children: [
                    const Icon(Icons.location_on_outlined,
                        color: NadiColors.royal),
                    const SizedBox(width: 7),
                    Expanded(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                          UI.heading('Kantor Utama', size: 12),
                          UI.caption('Jarak 38 m dari titik kantor · DEMO',
                              size: 10)
                        ])),
                    UI.pill('CONTOH',
                        bg: const Color(0xFFE7F5EA), fg: NadiColors.green)
                  ]))),
        ]),
      ));
}

class _MapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 10
      ..style = PaintingStyle.stroke;
    for (var x = -70.0; x < size.width + 120; x += 52) {
      canvas.drawLine(Offset(x, 0), Offset(x + 60, size.height), paint);
    }
    for (var y = 33.0; y < size.height; y += 53) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y + 28), paint);
    }
  }

  @override
  bool shouldRepaint(_MapPainter oldDelegate) => false;
}

class RequestForm extends StatefulWidget {
  final DemoStore store;
  final bool embedded;
  const RequestForm({super.key, required this.store, this.embedded = false});
  @override
  State<RequestForm> createState() => _RequestFormState();
}

class _RequestFormState extends State<RequestForm> {
  String requestType = 'Cuti';
  String reason = '';
  String leaveType = 'Cuti tahunan';
  DateTime start = DateTime(2026, 10, 28);
  DateTime end = DateTime(2026, 10, 29);

  Future<void> selectDate(bool isStart) async {
    final value = await showDatePicker(
        context: context,
        firstDate: DateTime(2025),
        lastDate: DateTime(2031),
        initialDate: isStart ? start : end);
    if (value != null) {
      setState(() {
        if (isStart) {
          start = value;
        } else {
          end = value;
        }
      });
    }
  }

  String date(DateTime d) => '${d.day} ${const [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'Mei',
        'Jun',
        'Jul',
        'Agu',
        'Sep',
        'Okt',
        'Nov',
        'Des'
      ][d.month - 1]} ${d.year}';

  @override
  Widget build(BuildContext context) {
    final content =
        ListView(padding: const EdgeInsets.fromLTRB(20, 27, 20, 25), children: [
      UI.heading('Pengajuan baru'),
      UI.gap(4),
      UI.caption('Pilih jenis pengajuan yang dibutuhkan'),
      UI.gap(17),
      Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: NadiColors.border)),
          child: Row(
              children: ['Cuti', 'Izin', 'Sakit', 'Lembur']
                  .map((label) => Expanded(
                      child: GestureDetector(
                          onTap: () => setState(() {
                                requestType = label;
                                leaveType = label == 'Cuti'
                                    ? 'Cuti tahunan'
                                    : '${label.toLowerCase()} khusus';
                              }),
                          child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 11),
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                  color: requestType == label
                                      ? NadiColors.royal
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(11)),
                              child: Text(label,
                                  style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: requestType == label
                                          ? Colors.white
                                          : NadiColors.muted))))))
                  .toList())),
      UI.gap(26),
      UI.heading('Detail pengajuan', size: 17),
      UI.gap(15),
      UI.caption('JENIS $requestType', size: 10, weight: FontWeight.w800),
      UI.gap(8),
      DropdownButtonFormField<String>(
          initialValue: leaveType,
          isExpanded: true,
          items: {leaveType, '${requestType.toLowerCase()} khusus'}
              .map((e) => DropdownMenuItem(
                  value: e,
                  child: Text(e, style: const TextStyle(fontSize: 12))))
              .toList(),
          onChanged: (v) => setState(() => leaveType = v ?? leaveType)),
      UI.gap(18),
      Row(children: [
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          UI.caption('TANGGAL MULAI', size: 10, weight: FontWeight.w800),
          UI.gap(7),
          InkWell(
              onTap: () => selectDate(true),
              child: UI.card(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 17),
                  child: Row(children: [
                    const Icon(Icons.calendar_today_outlined,
                        size: 16, color: NadiColors.royal),
                    const SizedBox(width: 5),
                    Flexible(
                        child: Text(date(start),
                            style: const TextStyle(fontSize: 11),
                            overflow: TextOverflow.ellipsis))
                  ])))
        ])),
        const SizedBox(width: 9),
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          UI.caption('TANGGAL SELESAI', size: 10, weight: FontWeight.w800),
          UI.gap(7),
          InkWell(
              onTap: () => selectDate(false),
              child: UI.card(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 17),
                  child: Row(children: [
                    const Icon(Icons.calendar_today_outlined,
                        size: 16, color: NadiColors.royal),
                    const SizedBox(width: 5),
                    Flexible(
                        child: Text(date(end),
                            style: const TextStyle(fontSize: 11),
                            overflow: TextOverflow.ellipsis))
                  ])))
        ]))
      ]),
      UI.gap(19),
      UI.caption('ALASAN', size: 10, weight: FontWeight.w800),
      UI.gap(8),
      TextField(
          key: const Key('request_reason'),
          minLines: 3,
          maxLines: 4,
          onChanged: (v) => reason = v,
          decoration: const InputDecoration(
              hintText: 'Tuliskan alasan secara singkat')),
      UI.gap(21),
      UI.caption('LAMPIRAN', size: 10, weight: FontWeight.w800),
      UI.gap(7),
      ActionTile(
          icon: Icons.add,
          title: 'Tambahkan dokumen',
          subtitle: 'PDF/JPG/PNG · fitur unggah memerlukan backend',
          onTap: () => UI.notice(context,
              'Pemilihan/unggah file belum tersedia pada prototipe frontend.')),
      UI.gap(21),
      UI.primary('Kirim Pengajuan', () {
        if (end.isBefore(start)) {
          UI.notice(
              context, 'Tanggal selesai tidak boleh sebelum tanggal mulai.');
          return;
        }
        if (reason.trim().isEmpty) {
          UI.notice(context, 'Alasan wajib diisi dalam prototipe.');
          return;
        }
        widget.store.addRequest(NadiRequest(
            requestType == 'Cuti' ? leaveType : requestType,
            '${date(start)} – ${date(end)}',
            'Menunggu',
            reason));
        UI.notice(context,
            'Pengajuan tersimpan sementara di memori aplikasi (demo).');
        if (!widget.embedded && Navigator.canPop(context)) {
          Navigator.pop(context);
        }
      }),
      UI.gap(7),
      Center(
          child:
              UI.caption('Simulasi UI, belum terhubung ke server.', size: 11)),
    ]);
    if (widget.embedded) return content;
    return Scaffold(
        appBar: AppBar(
            title: const Text('Pengajuan baru'),
            backgroundColor: NadiColors.canvas),
        body: content);
  }
}

class RequestHistory extends StatefulWidget {
  final DemoStore store;
  final VoidCallback openForm;
  const RequestHistory(
      {super.key, required this.store, required this.openForm});
  @override
  State<RequestHistory> createState() => _RequestHistoryState();
}

class _RequestHistoryState extends State<RequestHistory> {
  String filter = 'Semua';
  @override
  Widget build(BuildContext context) {
    final visible = widget.store.requests
        .where((r) => filter == 'Semua' || r.status == filter)
        .toList();
    return PageBody(
        title: 'Pengajuan',
        subtitle: 'Pantau setiap keputusan dengan jelas',
        children: [
          SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                  children: ['Semua', 'Menunggu', 'Disetujui', 'Ditolak']
                      .map((e) => Padding(
                          padding: const EdgeInsets.only(right: 7),
                          child: ChoiceChip(
                              label:
                                  Text(e, style: const TextStyle(fontSize: 11)),
                              selected: filter == e,
                              onSelected: (_) => setState(() => filter = e),
                              selectedColor: NadiColors.navy,
                              labelStyle: TextStyle(
                                  color: filter == e
                                      ? Colors.white
                                      : NadiColors.muted))))
                      .toList())),
          UI.gap(25),
          UI.heading('Oktober 2026', size: 16),
          UI.gap(15),
          if (visible.isEmpty)
            UI.card(
                child: UI.caption('Belum ada pengajuan dengan status ini.')),
          ...visible.map((r) {
            final color = r.status == 'Disetujui'
                ? NadiColors.green
                : r.status == 'Ditolak'
                    ? NadiColors.red
                    : NadiColors.amber;
            return Padding(
                padding: const EdgeInsets.only(bottom: 11),
                child: Container(
                    padding: const EdgeInsets.fromLTRB(14, 13, 14, 10),
                    decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border(
                            left: BorderSide(color: color, width: 4),
                            top: const BorderSide(color: NadiColors.border),
                            right: const BorderSide(color: NadiColors.border),
                            bottom:
                                const BorderSide(color: NadiColors.border))),
                    child: Column(children: [
                      Row(children: [
                        Expanded(
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                              UI.heading(r.title, size: 13),
                              UI.caption(r.period, size: 11)
                            ])),
                        UI.status(r.status)
                      ]),
                      UI.gap(15),
                      Container(height: 1, color: NadiColors.border),
                      UI.gap(11),
                      Row(children: [
                        Expanded(child: UI.caption(r.reason, size: 11)),
                        const Icon(Icons.chevron_right,
                            size: 16, color: NadiColors.muted)
                      ])
                    ])));
          }),
          UI.gap(14),
          UI.primary('Buat Pengajuan Baru', widget.openForm),
        ]);
  }
}

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});
  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  int selected = 24;
  @override
  Widget build(BuildContext context) => PageBody(
          title: 'Jadwal kerja',
          subtitle: 'Jadwal terhubung langsung dengan presensi',
          children: [
            UI.card(
                bg: NadiColors.navy,
                border: NadiColors.navy,
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      UI.caption('SHIFT HARI INI',
                          color: const Color(0xFFB6C9D8),
                          weight: FontWeight.bold,
                          size: 10),
                      UI.gap(10),
                      const Text('Pagi · 07.00 — 15.00',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 21)),
                      UI.gap(9),
                      UI.pill('Aktif sekarang (contoh)',
                          bg: const Color(0xFF19584E),
                          fg: const Color(0xFF95E8C8))
                    ])),
            UI.gap(26),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              UI.heading('Oktober 2026', size: 17),
              const Row(children: [
                Icon(Icons.chevron_left, color: NadiColors.royal),
                Icon(Icons.chevron_right, color: NadiColors.royal)
              ])
            ]),
            UI.gap(15),
            Row(
                children: List.generate(7, (i) {
              final n = 19 + i;
              final isSelected = selected == n;
              return Expanded(
                  child: InkWell(
                      onTap: () => setState(() => selected = n),
                      child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 2),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                              color:
                                  isSelected ? NadiColors.navy : Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: isSelected
                                      ? NadiColors.navy
                                      : NadiColors.border)),
                          child: Column(children: [
                            Text(const ['S', 'S', 'R', 'K', 'J', 'S', 'M'][i],
                                style: TextStyle(
                                    fontSize: 10,
                                    color: isSelected
                                        ? Colors.white
                                        : NadiColors.muted)),
                            UI.gap(8),
                            Text('$n',
                                style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: isSelected
                                        ? Colors.white
                                        : NadiColors.navy))
                          ]))));
            })),
            UI.gap(25),
            UI.heading('Rincian minggu ini', size: 17),
            UI.gap(14),
            const ScheduleTile(
                day: 'Sabtu, 24 Okt',
                shift: 'Shift pagi',
                time: '07.00–15.00',
                color: NadiColors.royal),
            UI.gap(10),
            const ScheduleTile(
                day: 'Minggu, 25 Okt',
                shift: 'Libur',
                time: 'Tidak ada jadwal',
                color: NadiColors.muted),
            UI.gap(10),
            const ScheduleTile(
                day: 'Senin, 26 Okt',
                shift: 'Shift malam',
                time: '23.00–07.00',
                color: NadiColors.red),
            UI.gap(17),
            UI.caption(
                'Kalender menggunakan data ilustrasi UI, belum terhubung database shift.',
                size: 11),
          ]);
}

class ScheduleTile extends StatelessWidget {
  final String day, shift, time;
  final Color color;
  const ScheduleTile(
      {super.key,
      required this.day,
      required this.shift,
      required this.time,
      required this.color});
  @override
  Widget build(BuildContext context) => UI.card(
          child: Row(children: [
        Container(
            width: 4,
            height: 47,
            decoration: BoxDecoration(
                color: color, borderRadius: BorderRadius.circular(4))),
        const SizedBox(width: 12),
        Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              UI.caption(day, size: 11),
              UI.gap(5),
              UI.heading(shift, size: 14)
            ])),
        Text(time,
            style: TextStyle(
                color: color, fontWeight: FontWeight.w700, fontSize: 11))
      ]));
}

class ApprovalScreen extends StatefulWidget {
  final DemoStore store;
  const ApprovalScreen({super.key, required this.store});
  @override
  State<ApprovalScreen> createState() => _ApprovalScreenState();
}

class _ApprovalScreenState extends State<ApprovalScreen> {
  final List<NadiRequest> approvals = [
    NadiRequest('Maya Putri', 'Cuti tahunan · 28–29 Okt · 2 hari', 'Menunggu',
        'Keperluan keluarga'),
    NadiRequest('Fajar Pratama', 'Lembur · 26 Okt · 17.00–20.00', 'Menunggu',
        'Keperluan tim')
  ];
  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(
          title: const Text('Pusat persetujuan'),
          backgroundColor: NadiColors.canvas),
      body: PageBody(
          title: 'Pusat persetujuan',
          subtitle: widget.store.role.label,
          children: [
            UI.card(
                bg: NadiColors.navy,
                border: NadiColors.navy,
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      UI.caption('Menunggu keputusan',
                          color: const Color(0xFFB6C9D8), size: 11),
                      UI.gap(10),
                      Row(children: [
                        Text(
                            approvals
                                .where((a) => a.status == 'Menunggu')
                                .length
                                .toString()
                                .padLeft(2, '0'),
                            style: const TextStyle(
                                fontSize: 36,
                                fontWeight: FontWeight.w900,
                                color: Colors.white)),
                        const SizedBox(width: 12),
                        UI.caption('Pengajuan dari tim',
                            color: Colors.white, size: 12),
                        const Spacer(),
                        UI.pill('Atasan 1',
                            bg: const Color(0xFF1A496D), fg: Colors.white)
                      ])
                    ])),
            UI.gap(25),
            UI.heading('Butuh tindakan Anda', size: 16),
            UI.gap(12),
            ...approvals.map((a) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: UI.card(
                    child: Column(children: [
                  Row(children: [
                    CircleAvatar(
                        radius: 20,
                        backgroundColor: const Color(0xFFE5ECFF),
                        child: Text(a.title.split(' ').map((s) => s[0]).join(),
                            style: const TextStyle(
                                fontSize: 11, color: NadiColors.royal))),
                    const SizedBox(width: 12),
                    Expanded(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                          UI.heading(a.title, size: 13),
                          UI.caption(a.period, size: 11)
                        ]))
                  ]),
                  UI.gap(15),
                  Container(height: 1, color: NadiColors.border),
                  UI.gap(13),
                  if (a.status == 'Menunggu')
                    Row(children: [
                      Expanded(
                          child: SizedBox(
                              height: 42,
                              child: FilledButton(
                                  onPressed: () =>
                                      setState(() => a.status = 'Ditolak'),
                                  style: FilledButton.styleFrom(
                                      backgroundColor: const Color(0xFFFCE8E9)),
                                  child: const Text('Tolak',
                                      style: TextStyle(
                                          color: NadiColors.red,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w800))))),
                      const SizedBox(width: 10),
                      Expanded(
                          child: SizedBox(
                              height: 42,
                              child: FilledButton(
                                  onPressed: () =>
                                      setState(() => a.status = 'Disetujui'),
                                  style: FilledButton.styleFrom(
                                      backgroundColor: NadiColors.royal),
                                  child: const Text('Setujui',
                                      style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w800)))))
                    ])
                  else
                    Align(
                        alignment: Alignment.centerRight,
                        child: UI.status(a.status)),
                ])))),
            UI.gap(10),
            UI.caption(
                'Keputusan pada layar ini hanya simulasi lokal, belum dikirim ke HRD.',
                size: 11),
          ]));
}

class HrdDashboard extends StatelessWidget {
  final DemoStore store;
  const HrdDashboard({super.key, required this.store});
  @override
  Widget build(BuildContext context) => PageBody(
          title: 'Operasional HRD',
          subtitle: 'Pantau tim, aturan lokasi, dan penjadwalan.',
          children: [
            UI.card(
                bg: NadiColors.navy,
                border: NadiColors.navy,
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      UI.caption('TENAGA KERJA AKTIF',
                          color: const Color(0xFFB6C9D8),
                          size: 11,
                          weight: FontWeight.w800),
                      UI.gap(10),
                      Row(children: [
                        const Text('128',
                            style: TextStyle(
                                fontSize: 42,
                                fontWeight: FontWeight.w900,
                                color: Colors.white)),
                        const Spacer(),
                        UI.pill('● 4 Divisi',
                            bg: const Color(0xFF1E5869),
                            fg: const Color(0xFFB9F2DD))
                      ]),
                      UI.gap(12),
                      Align(
                          alignment: Alignment.centerRight,
                          child: UI.caption('Data ilustrasi, bukan data live',
                              color: const Color(0xFFB6C9D8), size: 10))
                    ])),
            UI.gap(25),
            UI.heading('Kelola sistem', size: 17),
            UI.gap(15),
            ActionTile(
                icon: Icons.person_outline,
                title: 'Data karyawan',
                subtitle: 'Kelola pengguna dan peran',
                onTap: () => UI.notice(context,
                    'Manajemen data karyawan adalah modul backend tahap lanjut.')),
            UI.gap(12),
            ActionTile(
                icon: Icons.location_on_outlined,
                title: 'Lokasi geofencing',
                subtitle: 'Koordinat, radius, akurasi',
                iconColor: NadiColors.green,
                onTap: () => UI.notice(context,
                    'Pengaturan geofencing memerlukan API dan database.')),
            UI.gap(12),
            ActionTile(
                icon: Icons.calendar_month_outlined,
                title: 'Shift & jadwal',
                subtitle: 'Atur jam kerja tiap karyawan',
                iconColor: NadiColors.red,
                onTap: () => store.selectTab(3)),
            UI.gap(12),
            ActionTile(
                icon: Icons.pie_chart_outline,
                title: 'Laporan kehadiran',
                subtitle: 'Rekap berdasarkan tanggal',
                iconColor: NadiColors.amber,
                onTap: () => UI.notice(
                    context, 'Laporan kehadiran memerlukan data backend.')),
          ]);
}

class ProfileScreen extends StatelessWidget {
  final DemoStore store;
  const ProfileScreen({super.key, required this.store});
  @override
  Widget build(BuildContext context) => PageBody(
          title: 'Profil',
          subtitle: 'Informasi akun & preferensi Anda',
          children: [
            UI.card(
                child: Row(children: [
              const CircleAvatar(
                  radius: 38,
                  backgroundColor: Color(0xFFDFE9FB),
                  child: Text('RP',
                      style: TextStyle(
                          color: NadiColors.royal,
                          fontWeight: FontWeight.bold))),
              const SizedBox(width: 15),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    UI.heading('Raka Pratama', size: 17),
                    UI.caption('Karyawan · Quality Control', size: 11),
                    UI.gap(9),
                    UI.pill('ID: EMP-00042')
                  ]))
            ])),
            UI.gap(28),
            UI.heading('Pengaturan akun', size: 17),
            UI.gap(13),
            ActionTile(
                icon: Icons.person_outline,
                title: 'Data pribadi',
                subtitle: 'Informasi karyawan',
                onTap: () => UI.notice(
                    context, 'Halaman detail akun belum tersambung backend.')),
            UI.gap(10),
            ActionTile(
                icon: Icons.shield_outlined,
                title: 'Keamanan akun',
                subtitle: 'Kata sandi dan akses',
                onTap: () => UI.notice(
                    context, 'Manajemen kata sandi memerlukan backend.')),
            UI.gap(10),
            ActionTile(
                icon: Icons.tune_outlined,
                title: 'Preferensi',
                subtitle: 'Notifikasi dan tampilan',
                onTap: () =>
                    UI.notice(context, 'Preferensi belum disimpan permanen.')),
            UI.gap(10),
            ActionTile(
                icon: Icons.article_outlined,
                title: 'Bantuan & dukungan',
                subtitle: 'Panduan penggunaan',
                onTap: () => UI.notice(
                    context, 'NADI HRIS — prototype frontend Pertemuan 8.')),
            UI.gap(24),
            UI.primary('Keluar dari simulasi', store.logout,
                icon: Icons.logout, color: NadiColors.navy),
          ]);
}
