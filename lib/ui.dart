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

// --- UTILITY ---
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  const GlassCard({super.key, required this.child, this.padding});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ?? const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E32).withOpacity(0.8),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8))],
      ),
      child: child,
    );
  }
}

// --- MAIN SHELL ---
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});
  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  final List<Widget> _pages = [const DashboardScreen(), const AccountsBaseScreen(), const StatisticsScreen(), const SettingsScreen()];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0D21),
      body: _pages[_currentIndex],
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(border: Border(top: BorderSide(color: Color(0xFF2A2B42), width: 1))),
        child: BottomNavigationBar(
          backgroundColor: const Color(0xFF0B0D21),
          selectedItemColor: const Color(0xFF8C52FF),
          unselectedItemColor: Colors.grey,
          type: BottomNavigationBarType.fixed,
          currentIndex: _currentIndex,
          onTap: (i) => setState(() => _currentIndex = i),
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.dashboard_rounded), label: 'Dashboard'),
            BottomNavigationBarItem(icon: Icon(Icons.people_alt_rounded), label: 'Accounts'),
            BottomNavigationBarItem(icon: Icon(Icons.pie_chart_rounded), label: 'Statistics'),
            BottomNavigationBarItem(icon: Icon(Icons.settings_rounded), label: 'Settings'),
          ],
        ),
      ),
    );
  }
}

// --- DASHBOARD ---
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
    _timer = Timer.periodic(const Duration(seconds: 1), (Timer t) => setState(() => _now = DateTime.now()));
  }

  @override
  void dispose() { _timer.cancel(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final accounts = ref.watch(accountsProvider);
    final activeCount = accounts.where((a) => a.isDeleted == 0).length;
    final trashCount = accounts.where((a) => a.isDeleted == 1).length;

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text('Social Media Manager', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF8C52FF))),
          const SizedBox(height: 24),
          GlassCard(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                const Icon(Icons.access_time_filled, size: 50, color: Color(0xFF8C52FF)),
                const SizedBox(width: 20),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Vault Status: Secured', style: TextStyle(fontSize: 14, color: Colors.white70)),
                    Text(DateFormat('EEEE, MMM d, yyyy').format(_now), style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    const SizedBox(height: 8),
                    Text(DateFormat('HH:mm:ss').format(_now), style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white)),
                  ],
                )
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: GlassCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Icon(Icons.group, color: Color(0xFF00E5FF), size: 28), const SizedBox(height: 12),
                const Text('Active Accounts', style: TextStyle(fontSize: 12, color: Colors.grey)),
                Text(activeCount.toString(), style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
              ]))),
              const SizedBox(width: 12),
              Expanded(child: GlassCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Icon(Icons.delete_outline, color: Colors.redAccent, size: 28), const SizedBox(height: 12),
                const Text('In Trash', style: TextStyle(fontSize: 12, color: Colors.grey)),
                Text(trashCount.toString(), style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
              ]))),
            ],
          ),
        ],
      ),
    );
  }
}

// --- ACCOUNTS BASE & SEARCH ---
class AccountsBaseScreen extends ConsumerStatefulWidget {
  const AccountsBaseScreen({super.key});
  @override
  ConsumerState<AccountsBaseScreen> createState() => _AccountsBaseScreenState();
}

class _AccountsBaseScreenState extends ConsumerState<AccountsBaseScreen> {
  String _searchQuery = '';
  bool _showTrash = false;

  @override
  Widget build(BuildContext context) {
    final allAccounts = ref.watch(accountsProvider);
    final sortType = ref.watch(sortProvider);
    
    List<Account> displayedAccounts = allAccounts.where((a) {
      final matchesSearch = a.platform.toLowerCase().contains(_searchQuery.toLowerCase()) || a.username.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesSearch && (_showTrash ? a.isDeleted == 1 : a.isDeleted == 0);
    }).toList();

    displayedAccounts.sort((a, b) {
      switch (sortType) {
        case SortType.newest: return b.updatedAt.compareTo(a.updatedAt);
        case SortType.oldest: return a.updatedAt.compareTo(b.updatedAt);
        case SortType.az: return a.platform.toLowerCase().compareTo(b.platform.toLowerCase());
        case SortType.za: return b.platform.toLowerCase().compareTo(a.platform.toLowerCase());
      }
    });

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      style: const TextStyle(color: Colors.white),
                      onChanged: (val) => setState(() => _searchQuery = val),
                      decoration: InputDecoration(
                        hintText: "Search accounts...", hintStyle: const TextStyle(color: Colors.grey),
                        prefixIcon: const Icon(Icons.search, color: Colors.grey),
                        filled: true, fillColor: const Color(0xFF2A2B42),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                        contentPadding: const EdgeInsets.symmetric(vertical: 0),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  PopupMenuButton<SortType>(
                    icon: const Icon(Icons.filter_list, color: Colors.white),
                    color: const Color(0xFF2A2B42),
                    initialValue: sortType,
                    onSelected: (val) => ref.read(sortProvider.notifier).state = val,
                    itemBuilder: (context) => [
                      const PopupMenuItem(value: SortType.newest, child: Text('Newest First', style: TextStyle(color: Colors.white))),
                      const PopupMenuItem(value: SortType.oldest, child: Text('Oldest First', style: TextStyle(color: Colors.white))),
                      const PopupMenuItem(value: SortType.az, child: Text('Platform (A-Z)', style: TextStyle(color: Colors.white))),
                      const PopupMenuItem(value: SortType.za, child: Text('Platform (Z-A)', style: TextStyle(color: Colors.white))),
                    ],
                  ),
                  IconButton(
                    icon: Icon(_showTrash ? Icons.delete : Icons.delete_outline, color: _showTrash ? Colors.redAccent : Colors.grey),
                    onPressed: () => setState(() => _showTrash = !_showTrash),
                  )
                ],
              ),
            ),
            Expanded(
              child: displayedAccounts.isEmpty
                  ? Center(child: Text(_showTrash ? "Trash is empty" : "No accounts found", style: const TextStyle(color: Colors.grey)))
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: displayedAccounts.length,
                      itemBuilder: (context, index) => AccountCardWidget(account: displayedAccounts[index], isTrash: _showTrash),
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: !_showTrash ? FloatingActionButton(
        backgroundColor: const Color(0xFF8C52FF),
        onPressed: () => _showAccountSheet(context, null),
        child: const Icon(Icons.add, color: Colors.white),
      ) : null,
    );
  }

  void _showAccountSheet(BuildContext context, Account? accountToEdit) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true, // FIX: Memastikan sheet tidak menutupi Navigasi Android
      backgroundColor: const Color(0xFF1D1E33),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => AccountFormSheet(account: accountToEdit),
    );
  }
}

// --- ACCOUNT CARD (PROFESSIONAL UI) ---
class AccountCardWidget extends ConsumerStatefulWidget {
  final Account account;
  final bool isTrash;
  const AccountCardWidget({super.key, required this.account, required this.isTrash});

  @override
  ConsumerState<AccountCardWidget> createState() => _AccountCardWidgetState();
}

class _AccountCardWidgetState extends ConsumerState<AccountCardWidget> {
  bool _isObscured = true;
  late Timer _totpTimer;
  String _currentTotp = "";
  double _totpProgress = 0.0;

  @override
  void initState() {
    super.initState();
    _updateTotp();
    _totpTimer = Timer.periodic(const Duration(seconds: 1), (timer) => _updateTotp());
  }

  @override
  void dispose() { _totpTimer.cancel(); super.dispose(); }

  void _updateTotp() {
    if (widget.account.totpKey != null && widget.account.totpKey!.isNotEmpty) {
      try {
        final now = DateTime.now();
        final time = now.millisecondsSinceEpoch;
        final secondsRemaining = 30 - (now.second % 30);
        setState(() {
          _currentTotp = OTP.generateTOTPCodeString(widget.account.totpKey!, time, algorithm: Algorithm.SHA1, isGoogle: true);
          _totpProgress = secondsRemaining / 30.0;
        });
      } catch (e) { setState(() => _currentTotp = "Invalid Key"); }
    }
  }

  IconData _getIconForPlatform(String platform) {
    String p = platform.toLowerCase();
    if (p.contains('face')) return FontAwesomeIcons.facebook;
    if (p.contains('insta')) return FontAwesomeIcons.instagram;
    if (p.contains('tik')) return FontAwesomeIcons.tiktok;
    if (p.contains('x') || p.contains('twit')) return FontAwesomeIcons.xTwitter;
    if (p.contains('tele')) return FontAwesomeIcons.telegram;
    if (p.contains('disc')) return FontAwesomeIcons.discord;
    if (p.contains('link')) return FontAwesomeIcons.linkedin;
    if (p.contains('yout')) return FontAwesomeIcons.youtube;
    if (p.contains('git')) return FontAwesomeIcons.github;
    if (p.contains('goog')) return FontAwesomeIcons.google;
    return Icons.person;
  }

  @override
  Widget build(BuildContext context) {
    final acc = widget.account;
    final dateStr = DateFormat('MMM d, yyyy - HH:mm').format(DateTime.fromMillisecondsSinceEpoch(acc.updatedAt));

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: GlassCard(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 22, backgroundColor: const Color(0xFF2A2B42),
                  backgroundImage: acc.customIconPath != null && acc.customIconPath!.isNotEmpty ? FileImage(File(acc.customIconPath!)) : null,
                  child: acc.customIconPath == null || acc.customIconPath!.isEmpty ? Icon(_getIconForPlatform(acc.platform), color: Colors.white, size: 20) : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(acc.platform, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18, letterSpacing: 0.5)),
                      const SizedBox(height: 2),
                      Text("Updated: $dateStr", style: const TextStyle(color: Colors.grey, fontSize: 11)),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, color: Colors.white),
                  color: const Color(0xFF2A2B42),
                  onSelected: (val) {
                    final notifier = ref.read(accountsProvider.notifier);
                    if (val == 'trash') notifier.moveToTrash(acc);
                    if (val == 'restore') notifier.restore(acc);
                    if (val == 'perm_delete') notifier.deletePermanent(acc.id!);
                    if (val == 'edit') {
                      showModalBottomSheet(context: context, isScrollControlled: true, useSafeArea: true, backgroundColor: const Color(0xFF1D1E33), shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))), builder: (ctx) => AccountFormSheet(account: acc));
                    }
                  },
                  itemBuilder: (context) => widget.isTrash 
                    ? [
                        const PopupMenuItem(value: 'restore', child: Text('Restore', style: TextStyle(color: Colors.white))),
                        const PopupMenuItem(value: 'perm_delete', child: Text('Delete Permanently', style: TextStyle(color: Colors.redAccent))),
                      ]
                    : [
                        const PopupMenuItem(value: 'edit', child: Text('Edit', style: TextStyle(color: Colors.white))),
                        const PopupMenuItem(value: 'trash', child: Text('Move to Trash', style: TextStyle(color: Colors.redAccent))),
                      ],
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildDataBox(Icons.email_outlined, acc.username, false),
            const SizedBox(height: 12),
            _buildDataBox(Icons.lock_outline, acc.password, true),
            
            if (acc.totpKey != null && acc.totpKey!.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(color: const Color(0xFF00E5FF).withOpacity(0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFF00E5FF).withOpacity(0.3))),
                child: Row(
                  children: [
                    const Icon(Icons.security, color: Color(0xFF00E5FF), size: 20),
                    const SizedBox(width: 12),
                    Expanded(child: Text(_currentTotp, style: const TextStyle(color: Color(0xFF00E5FF), fontSize: 22, letterSpacing: 4, fontWeight: FontWeight.bold))),
                    SizedBox(width: 16, height: 16, child: CircularProgressIndicator(value: _totpProgress, strokeWidth: 2, color: const Color(0xFF00E5FF), backgroundColor: Colors.transparent)),
                    const SizedBox(width: 16),
                    GestureDetector(
                      onTap: () {
                        Clipboard.setData(ClipboardData(text: _currentTotp));
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("TOTP Copied!"), backgroundColor: Color(0xFF8C52FF)));
                      },
                      child: const Icon(Icons.copy, color: Color(0xFF00E5FF), size: 20),
                    ),
                  ],
                ),
              )
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildDataBox(IconData icon, String text, bool isPassword) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(color: const Color(0xFF2A2B42).withOpacity(0.5), borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey, size: 18),
          const SizedBox(width: 12),
          Expanded(child: Text(isPassword && _isObscured ? "••••••••••••" : text, style: const TextStyle(color: Colors.white, fontSize: 14))),
          if (isPassword) 
            GestureDetector(
              onTap: () => setState(() => _isObscured = !_isObscured),
              child: Icon(_isObscured ? Icons.visibility_off : Icons.visibility, color: Colors.grey, size: 20),
            ),
          if (isPassword) const SizedBox(width: 16),
          GestureDetector(
            onTap: () {
              Clipboard.setData(ClipboardData(text: text));
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Copied to clipboard"), backgroundColor: Color(0xFF8C52FF)));
            },
            child: const Icon(Icons.copy, color: Colors.grey, size: 20),
          )
        ],
      ),
    );
  }
}

// --- FORM SHEET (ADD/EDIT) ---
class AccountFormSheet extends ConsumerStatefulWidget {
  final Account? account;
  const AccountFormSheet({super.key, this.account});
  @override
  ConsumerState<AccountFormSheet> createState() => _AccountFormSheetState();
}

class _AccountFormSheetState extends ConsumerState<AccountFormSheet> {
  late TextEditingController _platformCtrl;
  late TextEditingController _usernameCtrl;
  late TextEditingController _passwordCtrl;
  late TextEditingController _totpCtrl;
  String? _customIconPath;

  final List<Map<String, dynamic>> _presetIcons = [
    {'name': 'Facebook', 'icon': FontAwesomeIcons.facebook, 'color': const Color(0xFF1877F2)},
    {'name': 'Instagram', 'icon': FontAwesomeIcons.instagram, 'color': const Color(0xFFE4405F)},
    {'name': 'Google', 'icon': FontAwesomeIcons.google, 'color': Colors.redAccent},
    {'name': 'TikTok', 'icon': FontAwesomeIcons.tiktok, 'color': Colors.white},
    {'name': 'X (Twitter)', 'icon': FontAwesomeIcons.xTwitter, 'color': Colors.white},
    {'name': 'YouTube', 'icon': FontAwesomeIcons.youtube, 'color': const Color(0xFFFF0000)},
    {'name': 'LinkedIn', 'icon': FontAwesomeIcons.linkedin, 'color': const Color(0xFF0A66C2)},
    {'name': 'Github', 'icon': FontAwesomeIcons.github, 'color': Colors.white},
  ];

  @override
  void initState() {
    super.initState();
    _platformCtrl = TextEditingController(text: widget.account?.platform ?? '');
    _usernameCtrl = TextEditingController(text: widget.account?.username ?? '');
    _passwordCtrl = TextEditingController(text: widget.account?.password ?? '');
    _totpCtrl = TextEditingController(text: widget.account?.totpKey ?? '');
    _customIconPath = widget.account?.customIconPath;
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      final directory = await getApplicationDocumentsDirectory();
      final fileName = path_util.basename(pickedFile.path);
      final savedImage = await File(pickedFile.path).copy('${directory.path}/$fileName');
      setState(() { _customIconPath = savedImage.path; _platformCtrl.text = "Custom Account"; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      // Padding dinamis untuk mengatasi keyboard
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 20, right: 20, top: 20),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.withOpacity(0.5), borderRadius: BorderRadius.circular(10)))),
            const SizedBox(height: 20),
            Text(widget.account == null ? "Add New Account" : "Edit Account", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 20),
            
            // Icon Presets Horizontal List
            SizedBox(
              height: 60,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  GestureDetector(
                    onTap: _pickImage,
                    child: Container(
                      width: 50, height: 50, margin: const EdgeInsets.only(right: 12),
                      decoration: BoxDecoration(color: const Color(0xFF2A2B42), borderRadius: BorderRadius.circular(12), image: _customIconPath != null ? DecorationImage(image: FileImage(File(_customIconPath!)), fit: BoxFit.cover) : null),
                      child: _customIconPath == null ? const Icon(Icons.add_a_photo, color: Colors.white70) : null,
                    ),
                  ),
                  ..._presetIcons.map((preset) => GestureDetector(
                    onTap: () { setState(() { _platformCtrl.text = preset['name']; _customIconPath = null; }); },
                    child: Container(
                      width: 50, height: 50, margin: const EdgeInsets.only(right: 12),
                      decoration: BoxDecoration(color: const Color(0xFF2A2B42), borderRadius: BorderRadius.circular(12)),
                      child: Icon(preset['icon'], color: preset['color']),
                    ),
                  )).toList()
                ],
              ),
            ),
            const SizedBox(height: 24),
            _buildTextField(_platformCtrl, "Platform Name"),
            const SizedBox(height: 16),
            _buildTextField(_usernameCtrl, "Username or Email"),
            const SizedBox(height: 16),
            _buildTextField(_passwordCtrl, "Password"),
            const SizedBox(height: 16),
            _buildTextField(_totpCtrl, "2FA Secret Key (Optional)"),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF8C52FF), padding: const EdgeInsets.symmetric(vertical: 18), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                onPressed: () {
                  final acc = Account(id: widget.account?.id, platform: _platformCtrl.text.isEmpty ? 'Unknown' : _platformCtrl.text, username: _usernameCtrl.text, password: _passwordCtrl.text, totpKey: _totpCtrl.text.trim(), customIconPath: _customIconPath, updatedAt: DateTime.now().millisecondsSinceEpoch);
                  if (widget.account == null) ref.read(accountsProvider.notifier).addAccount(acc);
                  else ref.read(accountsProvider.notifier).updateAccount(acc);
                  Navigator.pop(context);
                },
                child: const Text("Save Account", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
            const SizedBox(height: 24), // Memberikan jarak pernapasan ekstra di bagian paling bawah
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController ctrl, String hint) {
    return TextField(
      controller: ctrl, style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: hint, labelStyle: const TextStyle(color: Colors.grey),
        filled: true, fillColor: const Color(0xFF2A2B42),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
      ),
    );
  }
}

// --- STATISTICS & SETTINGS ---
class StatisticsScreen extends ConsumerWidget {
  const StatisticsScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accounts = ref.watch(accountsProvider).where((a) => a.isDeleted == 0).toList();
    Map<String, int> platformCount = {};
    for (var acc in accounts) { platformCount[acc.platform] = (platformCount[acc.platform] ?? 0) + 1; }
    List<PieChartSectionData> sections = [];
    int colorIndex = 0;
    final colors = [const Color(0xFF8C52FF), const Color(0xFF00E5FF), const Color(0xFFE4405F), Colors.orange, Colors.green];
    platformCount.forEach((key, value) {
      sections.add(PieChartSectionData(color: colors[colorIndex % colors.length], value: value.toDouble(), title: value.toString(), radius: 50, titleStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)));
      colorIndex++;
    });

    return SafeArea(
      child: Column(
        children: [
          const Padding(padding: EdgeInsets.all(20), child: Align(alignment: Alignment.centerLeft, child: Text('Analytics', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)))),
          if (accounts.isEmpty) const Expanded(child: Center(child: Text("Not enough data", style: TextStyle(color: Colors.grey)))),
          if (accounts.isNotEmpty) ...[
            SizedBox(height: 250, child: PieChart(PieChartData(sectionsSpace: 2, centerSpaceRadius: 60, sections: sections))),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(20), itemCount: platformCount.keys.length,
                itemBuilder: (context, index) {
                  String key = platformCount.keys.elementAt(index);
                  return ListTile(
                    leading: CircleAvatar(backgroundColor: colors[index % colors.length], radius: 8),
                    title: Text(key, style: const TextStyle(color: Colors.white)),
                    trailing: Text(platformCount[key].toString(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  );
                },
              ),
            )
          ]
        ],
      ),
    );
  }
}

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text('Settings', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 24),
          GlassCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  leading: const Icon(Icons.download, color: Colors.white), title: const Text('Export Backup', style: TextStyle(color: Colors.white)),
                  subtitle: const Text('Copy encrypted vault to clipboard', style: TextStyle(color: Colors.grey, fontSize: 12)),
                  onTap: () async {
                    await DataService.exportToClipboard(ref.read(accountsProvider));
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Encrypted backup copied!"), backgroundColor: Color(0xFF8C52FF)));
                  },
                ),
                const Divider(color: Color(0xFF2A2B42), height: 1),
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  leading: const Icon(Icons.upload, color: Colors.white), title: const Text('Import Backup', style: TextStyle(color: Colors.white)),
                  subtitle: const Text('Restore from copied text', style: TextStyle(color: Colors.grey, fontSize: 12)),
                  onTap: () async {
                    bool success = await DataService.importFromClipboard();
                    ref.read(accountsProvider.notifier).loadAccounts();
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(success ? "Data Restored!" : "Invalid Backup Data"), backgroundColor: success ? Colors.green : Colors.red));
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          GlassCard(
            padding: EdgeInsets.zero,
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              leading: const Icon(Icons.security, color: Colors.white), title: const Text('Force Lock Vault', style: TextStyle(color: Colors.white)), onTap: () => SystemNavigator.pop()
            )
          )
        ],
      ),
    );
  }
}
