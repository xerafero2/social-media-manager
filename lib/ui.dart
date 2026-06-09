import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:otp/otp.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path_util;
import 'core.dart';

// --- UI COMPONENTS ---
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final Color? color;
  const GlassCard({super.key, required this.child, this.padding, this.color});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ?? const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color ?? const Color(0xFF1E1E32).withOpacity(0.6),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: child,
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});
  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  final List<Widget> _pages = [const DashboardScreen(), const AccountsBaseScreen(), const SettingsScreen()];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0D21),
      body: _pages[_currentIndex],
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: const BoxDecoration(border: Border(top: BorderSide(color: Color(0xFF2A2B42), width: 1))),
        child: BottomNavigationBar(
          backgroundColor: const Color(0xFF0B0D21),
          selectedItemColor: const Color(0xFF8C52FF),
          unselectedItemColor: Colors.grey,
          type: BottomNavigationBarType.fixed,
          currentIndex: _currentIndex,
          onTap: (i) => setState(() => _currentIndex = i),
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.grid_view_rounded), label: 'Beranda'),
            BottomNavigationBarItem(icon: Icon(Icons.shield_rounded), label: 'Akun'),
            BottomNavigationBarItem(icon: Icon(Icons.settings_rounded), label: 'Pengaturan'),
          ],
        ),
      ),
    );
  }
}

// --- BERANDA (DASHBOARD + ANALYTICS) ---
class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});
  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  late Timer _timer;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) => setState(() => _now = DateTime.now()));
  }

  @override
  void dispose() { _timer.cancel(); super.dispose(); }

  Color _getBrandColor(String p) {
    String pLow = p.toLowerCase();
    if (pLow.contains('face')) return const Color(0xFF1877F2);
    if (pLow.contains('insta')) return const Color(0xFFE4405F);
    if (pLow.contains('goog')) return const Color(0xFFEA4335);
    if (pLow.contains('tik')) return const Color(0xFF00F2FE);
    if (pLow.contains('yout')) return const Color(0xFFFF0000);
    if (pLow.contains('x') || pLow.contains('twit')) return Colors.white;
    return const Color(0xFF8C52FF);
  }

  IconData _getBrandIcon(String p) {
    String pLow = p.toLowerCase();
    if (pLow.contains('face')) return FontAwesomeIcons.facebook;
    if (pLow.contains('insta')) return FontAwesomeIcons.instagram;
    if (pLow.contains('tik')) return FontAwesomeIcons.tiktok;
    if (pLow.contains('goog')) return FontAwesomeIcons.google;
    if (pLow.contains('yout')) return FontAwesomeIcons.youtube;
    return Icons.account_circle;
  }

  @override
  Widget build(BuildContext context) {
    final accounts = ref.watch(accountsProvider);
    final active = accounts.where((a) => a.isDeleted == 0).toList();
    
    Map<String, int> platCount = {};
    for (var a in active) { platCount[a.platform] = (platCount[a.platform] ?? 0) + 1; }

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Brankas Saya', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
              IconButton(icon: const Icon(Icons.power_settings_new_rounded, color: Colors.redAccent), onPressed: () => SystemNavigator.pop()),
            ],
          ),
          const SizedBox(height: 24),
          GlassCard(
            color: const Color(0xFF1D1E33),
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                const Icon(Icons.timer_rounded, size: 40, color: Color(0xFF8C52FF)),
                const SizedBox(width: 20),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(DateFormat('EEEE, d MMM').format(_now), style: const TextStyle(color: Colors.grey)),
                    Text(DateFormat('HH:mm:ss').format(_now), style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text('Aksi Cepat', style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _btn(Icons.add_rounded, "Tambah", const Color(0xFF8C52FF), () => showDialog(context: context, builder: (_) => const AccountFormDialog())),
              _btn(Icons.copy_rounded, "Ekspor", const Color(0xFF00E5FF), () => DataService.exportToClipboard(accounts)),
              _btn(Icons.auto_fix_high_rounded, "Impor", Colors.orangeAccent, () async {
                if (await DataService.importFromClipboard()) ref.read(accountsProvider.notifier).load();
              }),
            ],
          ),
          const SizedBox(height: 32),
          const Text('Analisis Akun', style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          if (active.isNotEmpty) 
            SizedBox(
              height: 180,
              child: PieChart(PieChartData(centerSpaceRadius: 40, sections: platCount.entries.map((e) => PieChartSectionData(color: _getBrandColor(e.key), value: e.value.toDouble(), radius: 40, title: "")).toList())),
            ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 12, runSpacing: 12,
            children: platCount.entries.map((e) => Container(
              width: (MediaQuery.of(context).size.width - 72) / 3,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: const Color(0xFF1E1E32), borderRadius: BorderRadius.circular(16)),
              child: Column(
                children: [
                  Icon(_getBrandIcon(e.key), color: _getBrandColor(e.key), size: 28),
                  const SizedBox(height: 8),
                  Text(e.key, style: const TextStyle(color: Colors.white, fontSize: 12), maxLines: 1),
                  Text("${e.value} Akun", style: const TextStyle(color: Colors.grey, fontSize: 10)),
                ],
              ),
            )).toList(),
          )
        ],
      ),
    );
  }

  Widget _btn(IconData i, String l, Color c, VoidCallback t) => GestureDetector(
    onTap: t,
    child: Column(
      children: [
        Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: c.withOpacity(0.1), borderRadius: BorderRadius.circular(16), border: Border.all(color: c.withOpacity(0.3))), child: Icon(i, color: c)),
        const SizedBox(height: 8),
        Text(l, style: const TextStyle(color: Colors.white, fontSize: 12)),
      ],
    ),
  );
}

// --- DAFTAR AKUN (SEGMENTED CONTROL) ---
class AccountsBaseScreen extends ConsumerStatefulWidget {
  const AccountsBaseScreen({super.key});
  @override
  ConsumerState<AccountsBaseScreen> createState() => _AccountsBaseScreenState();
}

class _AccountsBaseScreenState extends ConsumerState<AccountsBaseScreen> {
  String _search = '';
  int _tab = 0; // 0: Aktif, 1: Sampah

  @override
  Widget build(BuildContext context) {
    final accounts = ref.watch(accountsProvider);
    final sort = ref.watch(sortProvider);
    List<Account> filtered = accounts.where((a) => (a.isDeleted == _tab) && (a.platform.toLowerCase().contains(_search.toLowerCase()))).toList();

    filtered.sort((a, b) {
      if (sort == SortType.newest) return b.updatedAt.compareTo(a.updatedAt);
      if (sort == SortType.az) return a.platform.compareTo(b.platform);
      return 0;
    });

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  TextField(
                    style: const TextStyle(color: Colors.white),
                    onChanged: (v) => setState(() => _search = v),
                    decoration: InputDecoration(
                      hintText: "Cari Brankas...", prefixIcon: const Icon(Icons.search, color: Colors.grey),
                      filled: true, fillColor: const Color(0xFF1E1E32), border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(color: const Color(0xFF1E1E32), borderRadius: BorderRadius.circular(12)),
                    child: Row(
                      children: [
                        _tabBtn(0, "Aktif"),
                        _tabBtn(1, "Sampah"),
                      ],
                    ),
                  )
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                itemCount: filtered.length,
                itemBuilder: (c, i) => AccountCardWidget(key: ValueKey(filtered[i].id), account: filtered[i], isTrash: _tab == 1),
              ),
            )
          ],
        ),
      ),
      floatingActionButton: _tab == 0 ? FloatingActionButton(backgroundColor: const Color(0xFF8C52FF), onPressed: () => showDialog(context: context, builder: (_) => const AccountFormDialog()), child: const Icon(Icons.add, color: Colors.white)) : null,
    );
  }

  Widget _tabBtn(int idx, String label) => Expanded(
    child: GestureDetector(
      onTap: () => setState(() => _tab = idx),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(color: _tab == idx ? const Color(0xFF8C52FF) : Colors.transparent, borderRadius: BorderRadius.circular(10)),
        child: Center(child: Text(label, style: TextStyle(color: _tab == idx ? Colors.white : Colors.grey, fontWeight: FontWeight.bold))),
      ),
    ),
  );
}

// --- CARD AKUN PROFESIONAL ---
class AccountCardWidget extends ConsumerStatefulWidget {
  final Account account;
  final bool isTrash;
  const AccountCardWidget({super.key, required this.account, required this.isTrash});
  @override
  ConsumerState<AccountCardWidget> createState() => _AccountCardWidgetState();
}

class _AccountCardWidgetState extends ConsumerState<AccountCardWidget> {
  bool _hide = true;
  String _code = "";
  double _prog = 0.0;
  Timer? _t;

  @override
  void initState() {
    super.initState();
    _startTotp();
  }

  void _startTotp() {
    if (widget.account.totpKey?.isNotEmpty ?? false) {
      _t = Timer.periodic(const Duration(seconds: 1), (timer) {
        final now = DateTime.now();
        setState(() {
          _code = OTP.generateTOTPCodeString(widget.account.totpKey!, now.millisecondsSinceEpoch, isGoogle: true);
          _prog = (30 - (now.second % 30)) / 30.0;
        });
      });
    }
  }

  @override
  void dispose() { _t?.cancel(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final a = widget.account;
    final imgOk = a.customIconPath != null && File(a.customIconPath!).existsSync();

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: GlassCard(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(radius: 16, backgroundColor: const Color(0xFF2A2B42), backgroundImage: imgOk ? FileImage(File(a.customIconPath!)) : null, child: !imgOk ? Icon(Icons.person, color: Colors.white, size: 16) : null),
                const SizedBox(width: 12),
                Expanded(child: Text(a.platform, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                Text(DateFormat('dd/MM').format(DateTime.fromMillisecondsSinceEpoch(a.updatedAt)), style: const TextStyle(color: Colors.grey, fontSize: 10)),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, color: Colors.grey, size: 18),
                  onSelected: (v) {
                    final n = ref.read(accountsProvider.notifier);
                    if (v == 'trash') n.toTrash(a);
                    if (v == 'restore') n.restore(a);
                    if (v == 'delete') n.permDelete(a.id!);
                  },
                  itemBuilder: (c) => widget.isTrash ? [const PopupMenuItem(value: 'restore', child: Text('Pulihkan')), const PopupMenuItem(value: 'delete', child: Text('Hapus Permanen'))] : [const PopupMenuItem(value: 'trash', child: Text('Hapus'))],
                )
              ],
            ),
            const Divider(color: Color(0xFF2A2B42), height: 20),
            _row(Icons.alternate_email_rounded, a.username, false),
            const SizedBox(height: 8),
            _row(Icons.lock_outline_rounded, a.password, true),
            if (_code.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(color: const Color(0xFF00E5FF).withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                child: Row(
                  children: [
                    const Icon(Icons.security_rounded, color: Color(0xFF00E5FF), size: 16),
                    const SizedBox(width: 12),
                    Text(_code, style: const TextStyle(color: Color(0xFF00E5FF), fontWeight: FontWeight.bold, letterSpacing: 3)),
                    const Spacer(),
                    SizedBox(width: 12, height: 12, child: CircularProgressIndicator(value: _prog, strokeWidth: 2, color: const Color(0xFF00E5FF))),
                  ],
                ),
              )
            ]
          ],
        ),
      ),
    );
  }

  Widget _row(IconData i, String t, bool p) => Row(
    children: [
      Icon(i, color: Colors.grey, size: 14),
      const SizedBox(width: 10),
      Expanded(child: Text(p && _hide ? "••••••••" : t, style: const TextStyle(color: Colors.white70, fontSize: 13))),
      if (p) IconButton(icon: Icon(_hide ? Icons.visibility_off : Icons.visibility, size: 16, color: Colors.grey), onPressed: () => setState(() => _hide = !_hide)),
      IconButton(icon: const Icon(Icons.copy_rounded, size: 16, color: Colors.grey), onPressed: () => Clipboard.setData(ClipboardData(text: t))),
    ],
  );
}

// --- DIALOG FORM ---
class AccountFormDialog extends ConsumerStatefulWidget {
  final Account? account;
  const AccountFormDialog({super.key, this.account});
  @override
  ConsumerState<AccountFormDialog> createState() => _AccountFormDialogState();
}

class _AccountFormDialogState extends ConsumerState<AccountFormDialog> {
  final _p = TextEditingController();
  final _u = TextEditingController();
  final _s = TextEditingController();
  final _t = TextEditingController();
  String? _path;

  @override
  void initState() {
    super.initState();
    if (widget.account != null) {
      _p.text = widget.account!.platform; _u.text = widget.account!.username; _s.text = widget.account!.password; _t.text = widget.account!.totpKey ?? ""; _path = widget.account!.customIconPath;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF1D1E33),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Tambah Akun", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
              const SizedBox(height: 20),
              TextField(controller: _p, decoration: const InputDecoration(labelText: "Platform", labelStyle: TextStyle(color: Colors.grey))),
              TextField(controller: _u, decoration: const InputDecoration(labelText: "Username", labelStyle: TextStyle(color: Colors.grey))),
              TextField(controller: _s, decoration: const InputDecoration(labelText: "Password", labelStyle: TextStyle(color: Colors.grey))),
              TextField(controller: _t, decoration: const InputDecoration(labelText: "TOTP Key (Opsional)", labelStyle: TextStyle(color: Colors.grey))),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(child: TextButton(onPressed: () => Navigator.pop(context), child: const Text("Batal"))),
                  Expanded(child: ElevatedButton(onPressed: () {
                    final acc = Account(id: widget.account?.id, platform: _p.text, username: _u.text, password: _s.text, totpKey: _t.text, customIconPath: _path, updatedAt: DateTime.now().millisecondsSinceEpoch);
                    if (widget.account == null) ref.read(accountsProvider.notifier).add(acc); else ref.read(accountsProvider.notifier).edit(acc);
                    Navigator.pop(context);
                  }, child: const Text("Simpan"))),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}

// --- PENGATURAN ---
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(languageProvider);

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Text('Pengaturan', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 24),
          GlassCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.language_rounded, color: Colors.white),
                  title: const Text('Bahasa'),
                  trailing: Text(lang, style: const TextStyle(color: Color(0xFF8C52FF))),
                  onTap: () {
                    ref.read(languageProvider.notifier).state = lang == "English" ? "Bahasa Indonesia" : "English";
                  },
                ),
                const Divider(color: Color(0xFF2A2B42), height: 1),
                ListTile(leading: const Icon(Icons.cloud_upload_rounded), title: const Text("Ekspor Cadangan"), onTap: () => DataService.exportToClipboard(ref.read(accountsProvider))),
                const Divider(color: Color(0xFF2A2B42), height: 1),
                ListTile(leading: const Icon(Icons.lock_reset_rounded), title: const Text("Kunci Aplikasi"), onTap: () => SystemNavigator.pop()),
              ],
            ),
          )
        ],
      ),
    );
  }
}
