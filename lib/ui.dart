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
  final VoidCallback? onTap;

  const GlassCard({super.key, required this.child, this.padding, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: padding ?? const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E32).withOpacity(0.6),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: child,
      ),
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

// --- DASHBOARD (Sama seperti sebelumnya) ---
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
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accounts = ref.watch(accountsProvider);
    final activeCount = accounts.where((a) => a.isDeleted == 0).length;
    final trashCount = accounts.where((a) => a.isDeleted == 1).length;

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text('Social Media Manager', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF8C52FF))),
          const SizedBox(height: 20),
          GlassCard(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                const Icon(Icons.access_time_filled, size: 60, color: Color(0xFF8C52FF)),
                const SizedBox(width: 20),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Vault Status: Secured', style: TextStyle(fontSize: 14, color: Colors.white70)),
                    Text(DateFormat('EEEE, MMM d, yyyy').format(_now), style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    const SizedBox(height: 8),
                    Text(DateFormat('HH:mm:ss').format(_now), style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
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
    final isNewestFirst = ref.watch(sortProvider);
    
    List<Account> displayedAccounts = allAccounts.where((a) {
      final matchesSearch = a.platform.toLowerCase().contains(_searchQuery.toLowerCase()) || 
                            a.username.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesTab = _showTrash ? a.isDeleted == 1 : a.isDeleted == 0;
      return matchesSearch && matchesTab;
    }).toList();

    displayedAccounts.sort((a, b) => isNewestFirst ? b.updatedAt.compareTo(a.updatedAt) : a.updatedAt.compareTo(b.updatedAt));

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
                        hintText: "Search accounts...",
                        hintStyle: const TextStyle(color: Colors.grey),
                        prefixIcon: const Icon(Icons.search, color: Colors.grey),
                        filled: true, fillColor: const Color(0xFF2A2B42),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        contentPadding: const EdgeInsets.symmetric(vertical: 0),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: Icon(isNewestFirst ? Icons.sort : Icons.sort_by_alpha, color: Colors.white),
                    onPressed: () => ref.read(sortProvider.notifier).state = !isNewestFirst,
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
      backgroundColor: const Color(0xFF1D1E33),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => AccountFormSheet(account: accountToEdit),
    );
  }
}

// --- ACCOUNT CARD (WITH TOTP & EYE VISIBILITY) ---
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
  void dispose() {
    _totpTimer.cancel();
    super.dispose();
  }

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
      } catch (e) {
        setState(() => _currentTotp = "Invalid Key");
      }
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
    return Icons.person;
  }

  @override
  Widget build(BuildContext context) {
    final acc = widget.account;
    final dateStr = DateFormat('MMM d, yyyy - HH:mm').format(DateTime.fromMillisecondsSinceEpoch(acc.updatedAt));

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: GlassCard(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: const Color(0xFF2A2B42),
                  backgroundImage: acc.customIconPath != null && acc.customIconPath!.isNotEmpty ? FileImage(File(acc.customIconPath!)) : null,
                  child: acc.customIconPath == null || acc.customIconPath!.isEmpty
                      ? Icon(_getIconForPlatform(acc.platform), color: Colors.white, size: 18) : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(acc.platform, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                      Text("Updated: $dateStr", style: const TextStyle(color: Colors.grey, fontSize: 10)),
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
                      showModalBottomSheet(
                        context: context, isScrollControlled: true,
                        backgroundColor: const Color(0xFF1D1E33),
                        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
                        builder: (ctx) => AccountFormSheet(account: acc),
                      );
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
            const SizedBox(height: 16),
            _buildInfoRow(Icons.email_outlined, acc.username, isCopyable: true),
            const SizedBox(height: 8),
            _buildInfoRow(Icons.lock_outline, _isObscured ? "••••••••" : acc.password, isCopyable: true, isPassword: true),
            
            if (acc.totpKey != null && acc.totpKey!.isNotEmpty) ...[
              const Divider(color: Color(0xFF2A2B42), height: 24),
              Row(
                children: [
                  const Icon(Icons.security, color: Color(0xFF00E5FF), size: 18),
                  const SizedBox(width: 8),
                  Text(_currentTotp, style: const TextStyle(color: Color(0xFF00E5FF), fontSize: 18, letterSpacing: 2, fontWeight: FontWeight.bold)),
                  const Spacer(),
                  SizedBox(
                    width: 20, height: 20,
                    child: CircularProgressIndicator(value: _totpProgress, strokeWidth: 2, color: const Color(0xFF00E5FF), backgroundColor: const Color(0xFF2A2B42)),
                  ),
                  IconButton(
                    padding: EdgeInsets.zero, constraints: const BoxConstraints(),
                    icon: const Icon(Icons.copy, color: Colors.grey, size: 16),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: _currentTotp));
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("TOTP Copied!"), backgroundColor: Color(0xFF8C52FF)));
                    },
                  ),
                ],
              )
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text, {bool isCopyable = false, bool isPassword = false}) {
    return Row(
      children: [
        Icon(icon, color: Colors.grey, size: 16),
        const SizedBox(width: 8),
        Expanded(child: Text(text, style: const TextStyle(color: Colors.white70, fontSize: 14))),
        if (isPassword) 
          IconButton(
            icon: Icon(_isObscured ? Icons.visibility_off : Icons.visibility, color: Colors.grey, size: 18),
            onPressed: () => setState(() => _isObscured = !_isObscured),
          ),
        if (isCopyable)
          IconButton(
            icon: const Icon(Icons.copy, color: Colors.grey, size: 18),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: isPassword ? widget.account.password : text));
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Copied to clipboard"), backgroundColor: Color(0xFF8C52FF)));
            },
          )
      ],
    );
  }
}

// --- FORM SHEET (ADD/EDIT) DENGAN FIX KEYBOARD OVERLAP ---
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
      setState(() => _customIconPath = savedImage.path);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      // Padding +30 ini akan memastikan tombol tidak terpotong oleh navigation bar OS Android
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom + 30, left: 20, right: 20, top: 20),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(widget.account == null ? "Add Account" : "Edit Account", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 20),
            Row(
              children: [
                GestureDetector(
                  onTap: _pickImage,
                  child: CircleAvatar(
                    radius: 28, backgroundColor: const Color(0xFF2A2B42),
                    backgroundImage: _customIconPath != null ? FileImage(File(_customIconPath!)) : null,
                    child: _customIconPath == null ? const Icon(Icons.add_a_photo, color: Colors.white70) : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(child: _buildTextField(_platformCtrl, "Platform (e.g. Facebook)")),
              ],
            ),
            const SizedBox(height: 12),
            _buildTextField(_usernameCtrl, "Username/Email"),
            const SizedBox(height: 12),
            _buildTextField(_passwordCtrl, "Password"),
            const SizedBox(height: 12),
            _buildTextField(_totpCtrl, "2FA Setup Key (Optional)"),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF8C52FF), padding: const EdgeInsets.symmetric(vertical: 16)),
                onPressed: () {
                  final acc = Account(
                    id: widget.account?.id, platform: _platformCtrl.text, username: _usernameCtrl.text, 
                    password: _passwordCtrl.text, totpKey: _totpCtrl.text.trim(), 
                    customIconPath: _customIconPath, updatedAt: DateTime.now().millisecondsSinceEpoch
                  );
                  if (widget.account == null) {
                    ref.read(accountsProvider.notifier).addAccount(acc);
                  } else {
                    ref.read(accountsProvider.notifier).updateAccount(acc);
                  }
                  Navigator.pop(context);
                },
                child: const Text("Save", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController ctrl, String hint) {
    return TextField(
      controller: ctrl,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint, hintStyle: const TextStyle(color: Colors.grey),
        filled: true, fillColor: const Color(0xFF2A2B42),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      ),
    );
  }
}

// --- STATISTICS & SETTINGS SAMA SEPERTI SEBELUMNYA ---
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
          const Padding(padding: EdgeInsets.all(20), child: Align(alignment: Alignment.centerLeft, child: Text('Analytics', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)))),
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
          const Text('Settings', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 20),
          GlassCard(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.download, color: Colors.white), title: const Text('Export Backup', style: TextStyle(color: Colors.white)),
                  subtitle: const Text('Copy encrypted vault to clipboard', style: TextStyle(color: Colors.grey, fontSize: 12)),
                  onTap: () async {
                    await DataService.exportToClipboard(ref.read(accountsProvider));
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Encrypted backup copied!"), backgroundColor: Color(0xFF8C52FF)));
                  },
                ),
                const Divider(color: Color(0xFF2A2B42)),
                ListTile(
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
          GlassCard(child: ListTile(leading: const Icon(Icons.security, color: Colors.white), title: const Text('Force Lock Vault', style: TextStyle(color: Colors.white)), onTap: () => SystemNavigator.pop()))
        ],
      ),
    );
  }
}
