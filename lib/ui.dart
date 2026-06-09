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
  final List<Color>? gradientColors;
  const GlassCard({super.key, required this.child, this.padding, this.gradientColors});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ?? const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: gradientColors == null ? const Color(0xFF1E1E32).withOpacity(0.6) : null,
        gradient: gradientColors != null ? LinearGradient(colors: gradientColors!, begin: Alignment.topLeft, end: Alignment.bottomRight) : null,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 4))],
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
            BottomNavigationBarItem(icon: Icon(Icons.list_alt_rounded), label: 'Accounts'),
            BottomNavigationBarItem(icon: Icon(Icons.pie_chart_rounded), label: 'Analytics'),
            BottomNavigationBarItem(icon: Icon(Icons.settings_rounded), label: 'Settings'),
          ],
        ),
      ),
    );
  }
}

// --- DASHBOARD (MEWAH & PADAT) ---
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

  IconData _getIcon(String p) {
    String pLow = p.toLowerCase();
    if (pLow.contains('face')) return FontAwesomeIcons.facebook;
    if (pLow.contains('insta')) return FontAwesomeIcons.instagram;
    if (pLow.contains('tik')) return FontAwesomeIcons.tiktok;
    if (pLow.contains('twit') || pLow.contains('x')) return FontAwesomeIcons.xTwitter;
    if (pLow.contains('goog')) return FontAwesomeIcons.google;
    if (pLow.contains('yout')) return FontAwesomeIcons.youtube;
    if (pLow.contains('git')) return FontAwesomeIcons.github;
    if (pLow.contains('tele')) return FontAwesomeIcons.telegram;
    if (pLow.contains('disc')) return FontAwesomeIcons.discord;
    return Icons.public;
  }

  @override
  Widget build(BuildContext context) {
    final accounts = ref.watch(accountsProvider);
    final activeAccounts = accounts.where((a) => a.isDeleted == 0).toList();
    final trashCount = accounts.where((a) => a.isDeleted == 1).length;

    Map<String, int> platformCount = {};
    for (var acc in activeAccounts) {
      platformCount[acc.platform] = (platformCount[acc.platform] ?? 0) + 1;
    }

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Social Manager', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
              CircleAvatar(backgroundColor: const Color(0xFF2A2B42), child: IconButton(icon: const Icon(Icons.lock, color: Color(0xFF00E5FF), size: 18), onPressed: () => SystemNavigator.pop())),
            ],
          ),
          const SizedBox(height: 24),
          
          // Glowing Clock Card
          GlassCard(
            padding: const EdgeInsets.all(24),
            gradientColors: [const Color(0xFF1D1E33), const Color(0xFF2A2B42)],
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: const Color(0xFF8C52FF).withOpacity(0.2), shape: BoxShape.circle),
                  child: const Icon(Icons.access_time_filled, size: 40, color: Color(0xFF8C52FF)),
                ),
                const SizedBox(width: 20),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(DateFormat('EEEE, MMM d').format(_now), style: const TextStyle(fontSize: 14, color: Colors.grey)),
                    const SizedBox(height: 4),
                    Text(DateFormat('HH:mm:ss').format(_now), style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 1.5)),
                  ],
                )
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Quick Actions
          const Text('Quick Actions', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white70)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildActionBtn(Icons.add, "Add", const Color(0xFF8C52FF), () => showDialog(context: context, builder: (_) => const AccountFormDialog())),
              _buildActionBtn(Icons.download, "Export", const Color(0xFF00E5FF), () async {
                 await DataService.exportToClipboard(ref.read(accountsProvider));
                 ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Backup Copied!"), backgroundColor: Color(0xFF8C52FF)));
              }),
              _buildActionBtn(Icons.upload, "Import", Colors.orangeAccent, () async {
                 bool ok = await DataService.importFromClipboard();
                 if (ok) ref.read(accountsProvider.notifier).loadAccounts();
                 ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ok ? "Data Restored!" : "Failed"), backgroundColor: ok ? Colors.green : Colors.red));
              }),
              _buildActionBtn(Icons.delete_outline, "Trash ($trashCount)", Colors.redAccent, null),
            ],
          ),
          const SizedBox(height: 24),

          // Total Stats
          Row(
            children: [
              Expanded(child: GlassCard(padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16), child: Column(children: [
                const Icon(Icons.people_alt, color: Color(0xFF8C52FF), size: 24), const SizedBox(height: 8),
                Text(activeAccounts.length.toString(), style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
                const Text('Total Accounts', style: TextStyle(fontSize: 12, color: Colors.grey)),
              ]))),
              const SizedBox(width: 16),
              Expanded(child: GlassCard(padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16), child: Column(children: [
                const Icon(Icons.layers, color: Color(0xFF00E5FF), size: 24), const SizedBox(height: 8),
                Text(platformCount.keys.length.toString(), style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
                const Text('Platforms', style: TextStyle(fontSize: 12, color: Colors.grey)),
              ]))),
            ],
          ),
          const SizedBox(height: 24),

          // Platforms Grid
          const Text('Accounts by Platform', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white70)),
          const SizedBox(height: 12),
          if (platformCount.isEmpty) const Text("No platforms added yet.", style: TextStyle(color: Colors.grey)),
          Wrap(
            spacing: 12, runSpacing: 12,
            children: platformCount.entries.map((e) => Container(
              width: (MediaQuery.of(context).size.width - 64) / 3, // 3 columns
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: const Color(0xFF2A2B42).withOpacity(0.6), borderRadius: BorderRadius.circular(12)),
              child: Column(
                children: [
                  Icon(_getIcon(e.key), color: Colors.white, size: 24),
                  const SizedBox(height: 8),
                  Text(e.key, style: const TextStyle(color: Colors.white, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
                  Text("${e.value} Accounts", style: const TextStyle(color: Colors.grey, fontSize: 10)),
                ],
              ),
            )).toList(),
          )
        ],
      ),
    );
  }

  Widget _buildActionBtn(IconData icon, String label, Color color, VoidCallback? onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: const Color(0xFF1E1E32), borderRadius: BorderRadius.circular(16), border: Border.all(color: color.withOpacity(0.3))),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(color: Colors.white, fontSize: 12)),
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
                    child: SizedBox(
                      height: 48,
                      child: TextField(
                        style: const TextStyle(color: Colors.white, fontSize: 14),
                        onChanged: (val) => setState(() => _searchQuery = val),
                        decoration: InputDecoration(
                          hintText: "Search vault...", hintStyle: const TextStyle(color: Colors.grey),
                          prefixIcon: const Icon(Icons.search, color: Colors.grey, size: 20),
                          filled: true, fillColor: const Color(0xFF2A2B42),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  PopupMenuButton<SortType>(
                    icon: const Icon(Icons.sort, color: Colors.white), color: const Color(0xFF2A2B42),
                    initialValue: sortType,
                    onSelected: (val) => ref.read(sortProvider.notifier).state = val,
                    itemBuilder: (context) => [
                      const PopupMenuItem(value: SortType.newest, child: Text('Newest First', style: TextStyle(color: Colors.white))),
                      const PopupMenuItem(value: SortType.oldest, child: Text('Oldest First', style: TextStyle(color: Colors.white))),
                      const PopupMenuItem(value: SortType.az, child: Text('A - Z', style: TextStyle(color: Colors.white))),
                      const PopupMenuItem(value: SortType.za, child: Text('Z - A', style: TextStyle(color: Colors.white))),
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
                      itemBuilder: (context, index) => AccountCardWidget(
                        key: ValueKey(displayedAccounts[index].id), // FIX 1: Memastikan UI tidak tertukar saat disortir
                        account: displayedAccounts[index], 
                        isTrash: _showTrash
                      ),
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: !_showTrash ? FloatingActionButton(
        backgroundColor: const Color(0xFF8C52FF),
        onPressed: () => showDialog(context: context, builder: (_) => const AccountFormDialog()),
        child: const Icon(Icons.add, color: Colors.white),
      ) : null,
    );
  }
}

// --- ACCOUNT CARD (COMPACT & PROFESSIONAL) ---
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
  void didUpdateWidget(covariant AccountCardWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.account.totpKey != widget.account.totpKey) {
      _updateTotp();
    }
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
      } catch (e) { setState(() => _currentTotp = "ERR"); }
    }
  }

  IconData _getIconForPlatform(String platform) {
    String p = platform.toLowerCase();
    if (p.contains('face')) return FontAwesomeIcons.facebook;
    if (p.contains('insta')) return FontAwesomeIcons.instagram;
    if (p.contains('tik')) return FontAwesomeIcons.tiktok;
    if (p.contains('twit') || p.contains('x')) return FontAwesomeIcons.xTwitter;
    if (p.contains('goog')) return FontAwesomeIcons.google;
    if (p.contains('yout')) return FontAwesomeIcons.youtube;
    if (p.contains('git')) return FontAwesomeIcons.github;
    return Icons.person;
  }

  @override
  Widget build(BuildContext context) {
    final acc = widget.account;
    final dateStr = DateFormat('dd MMM yyyy').format(DateTime.fromMillisecondsSinceEpoch(acc.updatedAt));
    final hasTotp = acc.totpKey != null && acc.totpKey!.isNotEmpty;

    // FIX 2: Validasi eksistensi gambar langsung saat akan di-render (Anti bug nge-blank)
    bool hasValidImage = false;
    if (acc.customIconPath != null && acc.customIconPath!.isNotEmpty) {
      hasValidImage = File(acc.customIconPath!).existsSync();
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassCard(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // HEADER ROW
            Row(
              children: [
                CircleAvatar(
                  radius: 14, backgroundColor: Colors.transparent,
                  backgroundImage: hasValidImage ? FileImage(File(acc.customIconPath!)) : null,
                  child: !hasValidImage ? Icon(_getIconForPlatform(acc.platform), color: Colors.white, size: 16) : null,
                ),
                const SizedBox(width: 10),
                Expanded(child: Text(acc.platform, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16))),
                Text(dateStr, style: const TextStyle(color: Colors.grey, fontSize: 10)),
                const SizedBox(width: 8),
                SizedBox(
                  width: 24, height: 24,
                  child: PopupMenuButton<String>(
                    padding: EdgeInsets.zero,
                    icon: const Icon(Icons.more_vert, color: Colors.grey, size: 18),
                    color: const Color(0xFF2A2B42),
                    onSelected: (val) {
                      final notifier = ref.read(accountsProvider.notifier);
                      if (val == 'trash') notifier.moveToTrash(acc);
                      if (val == 'restore') notifier.restore(acc);
                      if (val == 'perm_delete') notifier.deletePermanent(acc.id!);
                      if (val == 'edit') showDialog(context: context, builder: (_) => AccountFormDialog(account: acc));
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
                ),
              ],
            ),
            const Divider(color: Color(0xFF2A2B42), height: 16),
            
            // EMAIL ROW
            _buildCompactRow(Icons.email_outlined, acc.username, false),
            const SizedBox(height: 8),
            
            // PASSWORD ROW
            _buildCompactRow(Icons.lock_outline, acc.password, true),
            
            // TOTP ROW (If Exists)
            if (hasTotp) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.security, color: Color(0xFF00E5FF), size: 14),
                  const SizedBox(width: 8),
                  Text(_currentTotp, style: const TextStyle(color: Color(0xFF00E5FF), fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 2)),
                  const SizedBox(width: 12),
                  SizedBox(width: 12, height: 12, child: CircularProgressIndicator(value: _totpProgress, strokeWidth: 1.5, color: const Color(0xFF00E5FF))),
                  const Spacer(),
                  GestureDetector(
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: _currentTotp));
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("TOTP Copied!"), backgroundColor: Color(0xFF8C52FF)));
                    },
                    child: const Icon(Icons.copy, color: Colors.grey, size: 16),
                  )
                ],
              )
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildCompactRow(IconData icon, String text, bool isPassword) {
    return Row(
      children: [
        Icon(icon, color: Colors.grey, size: 14),
        const SizedBox(width: 8),
        Expanded(child: Text(isPassword && _isObscured ? "••••••••••" : text, style: const TextStyle(color: Colors.white, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis)),
        if (isPassword)
          GestureDetector(
            onTap: () => setState(() => _isObscured = !_isObscured),
            child: Padding(padding: const EdgeInsets.symmetric(horizontal: 8), child: Icon(_isObscured ? Icons.visibility_off : Icons.visibility, color: Colors.grey, size: 16)),
          ),
        GestureDetector(
          onTap: () {
            Clipboard.setData(ClipboardData(text: text));
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Copied!"), backgroundColor: Color(0xFF8C52FF)));
          },
          child: const Icon(Icons.copy, color: Colors.grey, size: 16),
        )
      ],
    );
  }
}

// --- FORM DIALOG (CENTERED POPUP) ---
class AccountFormDialog extends ConsumerStatefulWidget {
  final Account? account;
  const AccountFormDialog({super.key, this.account});
  @override
  ConsumerState<AccountFormDialog> createState() => _AccountFormDialogState();
}

class _AccountFormDialogState extends ConsumerState<AccountFormDialog> {
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
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(20),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(color: const Color(0xFF1D1E33), borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFF8C52FF).withOpacity(0.3))),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.account == null ? "Add Account" : "Edit Account", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 16),
              
              SizedBox(
                height: 40,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        width: 40, height: 40, margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(color: const Color(0xFF2A2B42), borderRadius: BorderRadius.circular(10), image: _customIconPath != null ? DecorationImage(image: FileImage(File(_customIconPath!)), fit: BoxFit.cover) : null),
                        child: _customIconPath == null ? const Icon(Icons.add_a_photo, color: Colors.white70, size: 16) : null,
                      ),
                    ),
                    ..._presetIcons.map((preset) => GestureDetector(
                      onTap: () { setState(() { _platformCtrl.text = preset['name']; _customIconPath = null; }); },
                      child: Container(
                        width: 40, height: 40, margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(color: const Color(0xFF2A2B42), borderRadius: BorderRadius.circular(10)),
                        child: Icon(preset['icon'], color: preset['color'], size: 20),
                      ),
                    )).toList()
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _buildCompactTextField(_platformCtrl, "Platform"),
              const SizedBox(height: 12),
              _buildCompactTextField(_usernameCtrl, "Username/Email"),
              const SizedBox(height: 12),
              _buildCompactTextField(_passwordCtrl, "Password"),
              const SizedBox(height: 12),
              _buildCompactTextField(_totpCtrl, "2FA Key (Optional)"),
              const SizedBox(height: 24),
              
              Row(
                children: [
                  Expanded(child: TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel", style: TextStyle(color: Colors.grey)))),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF8C52FF), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                      onPressed: () {
                        final acc = Account(id: widget.account?.id, platform: _platformCtrl.text.isEmpty ? 'Unknown' : _platformCtrl.text, username: _usernameCtrl.text, password: _passwordCtrl.text, totpKey: _totpCtrl.text.trim(), customIconPath: _customIconPath, updatedAt: DateTime.now().millisecondsSinceEpoch);
                        if (widget.account == null) ref.read(accountsProvider.notifier).addAccount(acc);
                        else ref.read(accountsProvider.notifier).updateAccount(acc);
                        Navigator.pop(context);
                      },
                      child: const Text("Save", style: TextStyle(color: Colors.white)),
                    ),
                  )
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompactTextField(TextEditingController ctrl, String hint) {
    return SizedBox(
      height: 48,
      child: TextField(
        controller: ctrl, style: const TextStyle(color: Colors.white, fontSize: 14),
        decoration: InputDecoration(
          labelText: hint, labelStyle: const TextStyle(color: Colors.grey, fontSize: 12),
          filled: true, fillColor: const Color(0xFF2A2B42),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
        ),
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
