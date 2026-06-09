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

// --- UTILITY CONTAINER GRADIENT & GLASSMORPHISM ---
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
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8))],
      ),
      child: child,
    );
  }
}

// --- MAIN NAVIGATIONAL SHELL (3 TAB) ---
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});
  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  final List<Widget> _pages = [
    const DashboardScreen(),
    const AccountsBaseScreen(),
    const SettingsScreen()
  ];

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
            BottomNavigationBarItem(icon: Icon(Icons.shield_outlined), label: 'Accounts'),
            BottomNavigationBarItem(icon: Icon(Icons.settings_rounded), label: 'Settings'),
          ],
        ),
      ),
    );
  }
}

// --- DASHBOARD WITH INTEGRATED ANALYTICS ---
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

  IconData _getBrandIcon(String p) {
    String pLow = p.toLowerCase();
    if (pLow.contains('face')) return FontAwesomeIcons.facebook;
    if (pLow.contains('insta')) return FontAwesomeIcons.instagram;
    if (pLow.contains('tik')) return FontAwesomeIcons.tiktok;
    if (pLow.contains('x') || pLow.contains('twit')) return FontAwesomeIcons.xTwitter;
    if (pLow.contains('goog')) return FontAwesomeIcons.google;
    if (pLow.contains('yout')) return FontAwesomeIcons.youtube;
    if (pLow.contains('git')) return FontAwesomeIcons.github;
    if (pLow.contains('tele')) return FontAwesomeIcons.telegram;
    if (pLow.contains('disc')) return FontAwesomeIcons.discord;
    return Icons.public;
  }

  Color _getBrandColor(String p) {
    String pLow = p.toLowerCase();
    if (pLow.contains('face')) return const Color(0xFF1877F2);
    if (pLow.contains('insta')) return const Color(0xFFE4405F);
    if (pLow.contains('goog')) return const Color(0xFFEA4335);
    if (pLow.contains('yout')) return const Color(0xFFFF0000);
    if (pLow.contains('tele')) return const Color(0xFF26A5E4);
    if (pLow.contains('disc')) return const Color(0xFF5865F2);
    if (pLow.contains('link')) return const Color(0xFF0A66C2);
    return Colors.white;
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

    // Pie Chart Configurations
    List<PieChartSectionData> sections = [];
    int colorIndex = 0;
    final chartColors = [const Color(0xFF8C52FF), const Color(0xFF00E5FF), const Color(0xFFE4405F), Colors.orange, Colors.green];
    platformCount.forEach((key, value) {
      sections.add(PieChartSectionData(
        color: chartColors[colorIndex % chartColors.length],
        value: value.toDouble(),
        title: "$value",
        radius: 40,
        titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
      ));
      colorIndex++;
    });

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Social Manager', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
              IconButton(
                icon: const Icon(Icons.lock_outline, color: Colors.redAccent),
                onPressed: () => SystemNavigator.pop(),
              )
            ],
          ),
          const SizedBox(height: 20),
          
          // Clock Card
          GlassCard(
            padding: const EdgeInsets.all(24),
            gradientColors: [const Color(0xFF1D1E33), const Color(0xFF1A1B2F)],
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: const Color(0xFF8C52FF).withOpacity(0.15), shape: BoxShape.circle),
                  child: const Icon(Icons.access_time_filled, size: 36, color: Color(0xFF8C52FF)),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(DateFormat('EEEE, MMMM d, yyyy').format(_now), style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    const SizedBox(height: 2),
                    Text(DateFormat('HH:mm:ss').format(_now), style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 1)),
                  ],
                )
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Quick Actions
          const Text('Quick Actions', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white70)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildActionItem(Icons.add, "Add Account", const Color(0xFF8C52FF), () => showDialog(context: context, builder: (_) => const AccountFormDialog())),
              _buildActionItem(Icons.download, "Export", const Color(0xFF00E5FF), () async {
                 await DataService.exportToClipboard(ref.read(accountsProvider));
                 ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Backup Copied!"), backgroundColor: Color(0xFF8C52FF)));
              }),
              _buildActionItem(Icons.upload, "Import", Colors.orangeAccent, () async {
                 bool ok = await DataService.importFromClipboard();
                 if (ok) ref.read(accountsProvider.notifier).loadAccounts();
                 ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ok ? "Backup Restored Successfully!" : "Invalid Format"), backgroundColor: ok ? Colors.green : Colors.red));
              }),
            ],
          ),
          const SizedBox(height: 24),

          // Numeric Info Cards
          Row(
            children: [
              Expanded(child: GlassCard(padding: const EdgeInsets.all(16), child: Row(children: [
                const Icon(Icons.people_alt, color: Color(0xFF8C52FF), size: 22), const SizedBox(width: 12),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(activeAccounts.length.toString(), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                  const Text('Active Vaults', style: TextStyle(fontSize: 11, color: Colors.grey)),
                ])
              ]))),
              const SizedBox(width: 12),
              Expanded(child: GlassCard(padding: const EdgeInsets.all(16), child: Row(children: [
                const Icon(Icons.delete_sweep, color: Colors.redAccent, size: 22), const SizedBox(width: 12),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(trashCount.toString(), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                  const Text('Trash Bin', style: TextStyle(fontSize: 11, color: Colors.grey)),
                ])
              ]))),
            ],
          ),
          const SizedBox(height: 24),

          // Integrated Chart Analytics
          if (activeAccounts.isNotEmpty) ...[
            const Text('Account Distribution', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white70)),
            const SizedBox(height: 12),
            GlassCard(
              padding: const EdgeInsets.all(16),
              child: SizedBox(height: 140, child: PieChart(PieChartData(sectionsSpace: 3, centerSpaceRadius: 40, sections: sections))),
            ),
            const SizedBox(height: 24),
          ],

          // Platform Grid List With Authentic Brand Colors
          const Text('Accounts by Platform', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white70)),
          const SizedBox(height: 12),
          if (platformCount.isEmpty) const Text("Vault database is currently empty.", style: TextStyle(color: Colors.grey, fontSize: 13)),
          GridView.builder(
            shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 1),
            itemCount: platformCount.entries.length,
            itemBuilder: (context, idx) {
              final item = platformCount.entries.elementAt(idx);
              return Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: const Color(0xFF1E1E32).withOpacity(0.5), borderRadius: BorderRadius.circular(16)),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(_getBrandIcon(item.key), color: _getBrandColor(item.key), size: 24),
                    const SizedBox(height: 8),
                    Text(item.key, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                    Text("${item.value} Storage", style: const TextStyle(color: Colors.grey, fontSize: 10)),
                  ],
                ),
              );
            },
          )
        ],
      ),
    );
  }

  Widget _buildActionItem(IconData icon, String label, Color accentColor, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: (MediaQuery.of(context).size.width - 64) / 3,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(color: const Color(0xFF1E1E32), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white.withOpacity(0.03))),
        child: Column(
          children: [
            Icon(icon, color: accentColor, size: 22),
            const SizedBox(height: 6),
            Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

// --- ACCOUNTS BASE WITH PILL SHAPED SEGMENTED CONTROL ---
class AccountsBaseScreen extends ConsumerStatefulWidget {
  const AccountsBaseScreen({super.key});
  @override
  ConsumerState<AccountsBaseScreen> createState() => _AccountsBaseScreenState();
}

class _AccountsBaseScreenState extends ConsumerState<AccountsBaseScreen> {
  String _searchQuery = '';
  int _selectedSegmentIndex = 0; // 0: Active, 1: Trash

  @override
  Widget build(BuildContext context) {
    final allAccounts = ref.watch(accountsProvider);
    final sortType = ref.watch(sortProvider);
    
    List<Account> displayedAccounts = allAccounts.where((a) {
      final matchesSearch = a.platform.toLowerCase().contains(_searchQuery.toLowerCase()) || a.username.toLowerCase().contains(_searchQuery.toLowerCase());
      final isTrashTarget = (_selectedSegmentIndex == 1);
      return matchesSearch && (isTrashTarget ? a.isDeleted == 1 : a.isDeleted == 0);
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
            // Search & Sort Header Row
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 46,
                      child: TextField(
                        style: const TextStyle(color: Colors.white, fontSize: 14),
                        onChanged: (val) => setState(() => _searchQuery = val),
                        decoration: InputDecoration(
                          hintText: "Search secure records...", hintStyle: const TextStyle(color: Colors.grey),
                          prefixIcon: const Icon(Icons.search, color: Colors.grey, size: 18),
                          filled: true, fillColor: const Color(0xFF2A2B42).withOpacity(0.6),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
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
                      const PopupMenuItem(value: SortType.newest, child: Text('Newest Records', style: TextStyle(color: Colors.white))),
                      const PopupMenuItem(value: SortType.oldest, child: Text('Oldest Records', style: TextStyle(color: Colors.white))),
                      const PopupMenuItem(value: SortType.az, child: Text('Alphabetical A-Z', style: TextStyle(color: Colors.white))),
                      const PopupMenuItem(value: SortType.za, child: Text('Alphabetical Z-A', style: TextStyle(color: Colors.white))),
                    ],
                  ),
                ],
              ),
            ),

            // Pill Segmented Control Layout
            Padding(
              padding: const EdgeInsets.only(left: 20, right: 20, bottom: 16),
              child: Container(
                height: 44, padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(color: const Color(0xFF1E1E32), borderRadius: BorderRadius.circular(12)),
                child: Row(
                  children: [
                    _buildPillTab(0, "Active Vaults"),
                    _buildPillTab(1, "Trash Archive"),
                  ],
                ),
              ),
            ),

            // Accounts Dynamic List Execution
            Expanded(
              child: displayedAccounts.isEmpty
                  ? Center(child: Text(_selectedSegmentIndex == 1 ? "Trash folder is empty" : "No data discovered", style: const TextStyle(color: Colors.grey)))
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: displayedAccounts.length,
                      itemBuilder: (context, index) => AccountCardWidget(
                        key: ValueKey(displayedAccounts[index].id),
                        account: displayedAccounts[index], 
                        isTrash: _selectedSegmentIndex == 1
                      ),
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: _selectedSegmentIndex == 0 ? FloatingActionButton(
        backgroundColor: const Color(0xFF8C52FF),
        onPressed: () => showDialog(context: context, builder: (_) => const AccountFormDialog()),
        child: const Icon(Icons.add, color: Colors.white),
      ) : null,
    );
  }

  Widget _buildPillTab(int index, String title) {
    bool isSelected = _selectedSegmentIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedSegmentIndex = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF8C52FF) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(title, style: TextStyle(color: isSelected ? Colors.white : Colors.grey, fontSize: 13, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }
}

// --- ACCOUNT CARD (COMPACT RADIAL SYSTEM) ---
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
    if (oldWidget.account.totpKey != widget.account.totpKey) { _updateTotp(); }
  }

  @override
  void dispose() { _totpTimer.cancel(); super.dispose(); }

  void _updateTotp() {
    if (widget.account.totpKey != null && widget.account.totpKey!.isNotEmpty) {
      try {
        final now = DateTime.now();
        final secondsRemaining = 30 - (now.second % 30);
        setState(() {
          _currentTotp = OTP.generateTOTPCodeString(widget.account.totpKey!, now.millisecondsSinceEpoch, algorithm: Algorithm.SHA1, isGoogle: true);
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
    if (p.contains('x') || p.contains('twit')) return FontAwesomeIcons.xTwitter;
    if (p.contains('goog')) return FontAwesomeIcons.google;
    if (p.contains('yout')) return FontAwesomeIcons.youtube;
    if (p.contains('git')) return FontAwesomeIcons.github;
    return Icons.person;
  }

  Color _getBrandColor(String p) {
    String pLow = p.toLowerCase();
    if (pLow.contains('face')) return const Color(0xFF1877F2);
    if (pLow.contains('insta')) return const Color(0xFFE4405F);
    if (pLow.contains('goog')) return const Color(0xFFEA4335);
    if (pLow.contains('yout')) return const Color(0xFFFF0000);
    return Colors.white;
  }

  @override
  Widget build(BuildContext context) {
    final acc = widget.account;
    final dateStr = DateFormat('dd MMM yyyy').format(DateTime.fromMillisecondsSinceEpoch(acc.updatedAt));
    final hasTotp = acc.totpKey != null && acc.totpKey!.isNotEmpty;

    bool hasValidImage = false;
    if (acc.customIconPath != null && acc.customIconPath!.isNotEmpty) {
      hasValidImage = File(acc.customIconPath!).existsSync();
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassCard(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 14, backgroundColor: Colors.transparent,
                  backgroundImage: hasValidImage ? FileImage(File(acc.customIconPath!)) : null,
                  child: !hasValidImage ? Icon(_getIconForPlatform(acc.platform), color: _getBrandColor(acc.platform), size: 16) : null,
                ),
                const SizedBox(width: 10),
                Expanded(child: Text(acc.platform, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15))),
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
                          const PopupMenuItem(value: 'restore', child: Text('Restore Vault', style: TextStyle(color: Colors.white))),
                          const PopupMenuItem(value: 'perm_delete', child: Text('Delete Permanently', style: TextStyle(color: Colors.redAccent))),
                        ]
                      : [
                          const PopupMenuItem(value: 'edit', child: Text('Edit Record', style: TextStyle(color: Colors.white))),
                          const PopupMenuItem(value: 'trash', child: Text('Archive to Trash', style: TextStyle(color: Colors.redAccent))),
                        ],
                  ),
                ),
              ],
            ),
            const Divider(color: Color(0xFF2A2B42), height: 14),
            _buildCompactRow(Icons.email_outlined, acc.username, false),
            const SizedBox(height: 6),
            _buildCompactRow(Icons.lock_outline, acc.password, true),
            
            if (hasTotp) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.security, color: Color(0xFF00E5FF), size: 14),
                  const SizedBox(width: 8),
                  Text(_currentTotp, style: const TextStyle(color: Color(0xFF00E5FF), fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 2)),
                  const SizedBox(width: 12),
                  SizedBox(width: 10, height: 10, child: CircularProgressIndicator(value: _totpProgress, strokeWidth: 1.5, color: const Color(0xFF00E5FF), backgroundColor: Colors.transparent)),
                  const Spacer(),
                  GestureDetector(
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: _currentTotp));
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("TOTP Copied"), backgroundColor: Color(0xFF8C52FF)));
                    },
                    child: const Icon(Icons.copy, color: Colors.grey, size: 14),
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
        Expanded(
          child: Text(
            isPassword && _isObscured ? "••••••••••••" : text,
            style: TextStyle(color: Colors.white70, fontSize: 13, fontSizeFactor: isPassword && _isObscured ? 1.4 : 1.0),
            maxLines: 1, overflow: TextOverflow.ellipsis
          ),
        ),
        if (isPassword)
          GestureDetector(
            onTap: () => setState(() => _isObscured = !_isObscured),
            child: Padding(padding: const EdgeInsets.symmetric(horizontal: 8), child: Icon(_isObscured ? Icons.visibility_off : Icons.visibility, color: Colors.grey, size: 15)),
          ),
        GestureDetector(
          onTap: () {
            Clipboard.setData(ClipboardData(text: text));
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Copied"), backgroundColor: Color(0xFF8C52FF)));
          },
          child: const Icon(Icons.copy, color: Colors.grey, size: 14),
        )
      ],
    );
  }
}

// --- CENTERED SECURITY FORM DIALOG ---
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
              Text(widget.account == null ? "Secure Account Registration" : "Modify Record Data", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 16),
              
              // Icon Selection Row
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
                        child: Icon(preset['icon'], color: preset['color'], size: 18),
                      ),
                    )).toList()
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _buildCompactTextField(_platformCtrl, "Platform Destination"),
              const SizedBox(height: 12),
              _buildCompactTextField(_usernameCtrl, "Identity Email/Username"),
              const SizedBox(height: 12),
              _buildCompactTextField(_passwordCtrl, "Secret Cryptic Password"),
              const SizedBox(height: 12),
              _buildCompactTextField(_totpCtrl, "2FA Google Seed Key (Optional)"),
              const SizedBox(height: 24),
              
              Row(
                children: [
                  Expanded(child: TextButton(onPressed: () => Navigator.pop(context), child: const Text("Abort", style: TextStyle(color: Colors.grey)))),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF8C52FF), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                      onPressed: () {
                        final acc = Account(id: widget.account?.id, platform: _platformCtrl.text.isEmpty ? 'Unknown' : _platformCtrl.text, username: _usernameCtrl.text, password: _passwordCtrl.text, totpKey: _totpCtrl.text.trim(), customIconPath: _customIconPath, updatedAt: DateTime.now().millisecondsSinceEpoch);
                        if (widget.account == null) ref.read(accountsProvider.notifier).addAccount(acc);
                        else ref.read(accountsProvider.notifier).updateAccount(acc);
                        Navigator.pop(context);
                      },
                      child: const Text("Commit", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
        controller: ctrl, style: const TextStyle(color: Colors.white, fontSize: 13),
        decoration: InputDecoration(
          labelText: hint, labelStyle: const TextStyle(color: Colors.grey, fontSize: 11),
          filled: true, fillColor: const Color(0xFF2A2B42),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
        ),
      ),
    );
  }
}

// --- SETTINGS VIEW ---
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
                  leading: const Icon(Icons.download, color: Colors.white), title: const Text('Database Extraction', style: TextStyle(color: Colors.white, fontSize: 15)),
                  subtitle: const Text('Export encrypted master file to clipboard', style: TextStyle(color: Colors.grey, fontSize: 11)),
                  onTap: () async {
                    await DataService.exportToClipboard(ref.read(accountsProvider));
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Database Backup Copied"), backgroundColor: Color(0xFF8C52FF)));
                  },
                ),
                const Divider(color: Color(0xFF2A2B42), height: 1),
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  leading: const Icon(Icons.upload, color: Colors.white), title: const Text('Database Integration', style: TextStyle(color: Colors.white, fontSize: 15)),
                  subtitle: const Text('Inject data records from valid clipboard text', style: TextStyle(color: Colors.grey, fontSize: 11)),
                  onTap: () async {
                    bool success = await DataService.importFromClipboard();
                    ref.read(accountsProvider.notifier).loadAccounts();
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(success ? "Database Merged Successfully!" : "Decryption Failure"), backgroundColor: success ? Colors.green : Colors.red));
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
