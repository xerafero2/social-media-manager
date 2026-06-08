import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
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
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 4))
          ],
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
  final List<Widget> _pages = [
    const DashboardScreen(),
    const AccountsBaseScreen(),
    const StatisticsScreen(),
    const SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
              Expanded(child: _buildStatCard(Icons.group, 'Active Accounts', activeCount.toString())),
              const SizedBox(width: 12),
              Expanded(child: _buildStatCard(Icons.delete_outline, 'In Trash', trashCount.toString(), color: Colors.redAccent)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(IconData icon, String title, String value, {Color color = const Color(0xFF00E5FF)}) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 12),
          Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
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
    final displayedAccounts = allAccounts.where((a) {
      final matchesSearch = a.platform.toLowerCase().contains(_searchQuery.toLowerCase()) || 
                            a.username.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesTab = _showTrash ? a.isDeleted == 1 : a.isDeleted == 0;
      return matchesSearch && matchesTab;
    }).toList();

    return SafeArea(
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
                      filled: true,
                      fillColor: const Color(0xFF2A2B42),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
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
                    itemBuilder: (context, index) {
                      final acc = displayedAccounts[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: GlassCard(
                          child: ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: CircleAvatar(
                              backgroundColor: const Color(0xFF2A2B42),
                              child: Icon(_getIconForPlatform(acc.platform), color: Colors.white, size: 18),
                            ),
                            title: Text(acc.platform, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            subtitle: Text(acc.username, style: const TextStyle(color: Colors.grey)),
                            trailing: PopupMenuButton<String>(
                              icon: const Icon(Icons.more_vert, color: Colors.white),
                              color: const Color(0xFF2A2B42),
                              onSelected: (val) => _handleAction(val, acc),
                              itemBuilder: (context) => _showTrash 
                                ? [
                                    const PopupMenuItem(value: 'restore', child: Text('Restore', style: TextStyle(color: Colors.white))),
                                    const PopupMenuItem(value: 'perm_delete', child: Text('Delete Permanently', style: TextStyle(color: Colors.redAccent))),
                                  ]
                                : [
                                    const PopupMenuItem(value: 'copy', child: Text('Copy Password', style: TextStyle(color: Colors.white))),
                                    const PopupMenuItem(value: 'edit', child: Text('Edit', style: TextStyle(color: Colors.white))),
                                    const PopupMenuItem(value: 'trash', child: Text('Move to Trash', style: TextStyle(color: Colors.redAccent))),
                                  ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: !_showTrash ? FloatingActionButton(
        backgroundColor: const Color(0xFF8C52FF),
        onPressed: () => _showAccountSheet(context, null),
        child: const Icon(Icons.add, color: Colors.white),
      ) : null,
    );
  }

  IconData _getIconForPlatform(String platform) {
    String p = platform.toLowerCase();
    if (p.contains('face')) return FontAwesomeIcons.facebook;
    if (p.contains('insta')) return FontAwesomeIcons.instagram;
    if (p.contains('tik')) return FontAwesomeIcons.tiktok;
    if (p.contains('x') || p.contains('twit')) return FontAwesomeIcons.xTwitter;
    return Icons.person;
  }

  void _handleAction(String action, Account acc) {
    final notifier = ref.read(accountsProvider.notifier);
    if (action == 'trash') notifier.moveToTrash(acc);
    if (action == 'restore') notifier.restore(acc);
    if (action == 'perm_delete') notifier.deletePermanent(acc.id!);
    if (action == 'copy') {
      Clipboard.setData(ClipboardData(text: acc.password));
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Password copied!"), backgroundColor: Color(0xFF8C52FF)));
    }
    if (action == 'edit') _showAccountSheet(context, acc);
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

  @override
  void initState() {
    super.initState();
    _platformCtrl = TextEditingController(text: widget.account?.platform ?? '');
    _usernameCtrl = TextEditingController(text: widget.account?.username ?? '');
    _passwordCtrl = TextEditingController(text: widget.account?.password ?? '');
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 20, right: 20, top: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(widget.account == null ? "Add Account" : "Edit Account", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 20),
          _buildTextField(_platformCtrl, "Platform"),
          const SizedBox(height: 12),
          _buildTextField(_usernameCtrl, "Username/Email"),
          const SizedBox(height: 12),
          _buildTextField(_passwordCtrl, "Password", obscure: true),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF8C52FF), padding: const EdgeInsets.symmetric(vertical: 16)),
              onPressed: () {
                final acc = Account(id: widget.account?.id, platform: _platformCtrl.text, username: _usernameCtrl.text, password: _passwordCtrl.text);
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
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildTextField(TextEditingController ctrl, String hint, {bool obscure = false}) {
    return TextField(
      controller: ctrl,
      obscureText: obscure,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.grey),
        filled: true,
        fillColor: const Color(0xFF2A2B42),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      ),
    );
  }
}

// --- STATISTICS ---
class StatisticsScreen extends ConsumerWidget {
  const StatisticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accounts = ref.watch(accountsProvider).where((a) => a.isDeleted == 0).toList();
    
    Map<String, int> platformCount = {};
    for (var acc in accounts) {
      platformCount[acc.platform] = (platformCount[acc.platform] ?? 0) + 1;
    }

    List<PieChartSectionData> sections = [];
    int colorIndex = 0;
    final colors = [const Color(0xFF8C52FF), const Color(0xFF00E5FF), const Color(0xFFE4405F), Colors.orange, Colors.green];

    platformCount.forEach((key, value) {
      sections.add(PieChartSectionData(
        color: colors[colorIndex % colors.length],
        value: value.toDouble(),
        title: value.toString(),
        radius: 50,
        titleStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
      ));
      colorIndex++;
    });

    return SafeArea(
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(20),
            child: Align(alignment: Alignment.centerLeft, child: Text('Analytics', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white))),
          ),
          if (accounts.isEmpty) const Expanded(child: Center(child: Text("Not enough data", style: TextStyle(color: Colors.grey)))),
          if (accounts.isNotEmpty) ...[
            SizedBox(
              height: 250,
              child: PieChart(
                PieChartData(sectionsSpace: 2, centerSpaceRadius: 60, sections: sections),
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(20),
                itemCount: platformCount.keys.length,
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

// --- SETTINGS ---
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
                  leading: const Icon(Icons.download, color: Colors.white),
                  title: const Text('Export Backup', style: TextStyle(color: Colors.white)),
                  subtitle: const Text('Copy encrypted vault to clipboard', style: TextStyle(color: Colors.grey, fontSize: 12)),
                  onTap: () async {
                    final accs = ref.read(accountsProvider);
                    await DataService.exportToClipboard(accs);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Encrypted backup copied!"), backgroundColor: Color(0xFF8C52FF)));
                  },
                ),
                const Divider(color: Color(0xFF2A2B42)),
                ListTile(
                  leading: const Icon(Icons.upload, color: Colors.white),
                  title: const Text('Import Backup', style: TextStyle(color: Colors.white)),
                  subtitle: const Text('Restore from copied text', style: TextStyle(color: Colors.grey, fontSize: 12)),
                  onTap: () async {
                    bool success = await DataService.importFromClipboard();
                    ref.read(accountsProvider.notifier).loadAccounts();
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text(success ? "Data Restored!" : "Invalid Backup Data"), 
                      backgroundColor: success ? Colors.green : Colors.red,
                    ));
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          GlassCard(
            child: ListTile(
              leading: const Icon(Icons.security, color: Colors.white),
              title: const Text('Force Lock Vault', style: TextStyle(color: Colors.white)),
              onTap: () => SystemNavigator.pop(),
            ),
          )
        ],
      ),
    );
  }
}
