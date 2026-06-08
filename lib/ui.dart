import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'core.dart';

// --- UTILITY WIDGETS ---
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
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
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
    const AllAccountsScreen(),
    const Scaffold(body: Center(child: Text("Statistics - Implementation"))), // Placeholder simplified
    const Scaffold(body: Center(child: Text("Settings - Implementation"))), // Placeholder simplified
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: Color(0xFF2A2B42), width: 1)),
        ),
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
      floatingActionButton: _currentIndex == 1
          ? FloatingActionButton(
              backgroundColor: const Color(0xFF8C52FF),
              onPressed: () => _showAddAccountSheet(context),
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
    );
  }

  void _showAddAccountSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1D1E33),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => const AddAccountSheet(),
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
    _timer = Timer.periodic(const Duration(seconds: 1), (Timer t) {
      setState(() => _now = DateTime.now());
    });
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Social Media Manager',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF8C52FF)),
              ),
              IconButton(icon: const Icon(Icons.search, color: Colors.white), onPressed: () {}),
            ],
          ),
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
                    const Text('Good Morning!', style: TextStyle(fontSize: 16, color: Colors.white70)),
                    Text(DateFormat('EEEE, MMM d, yyyy').format(_now), style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    const SizedBox(height: 8),
                    Text(DateFormat('HH:mm:ss a').format(_now), style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
                  ],
                )
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _buildStatCard(Icons.group, 'Total Accounts', activeCount.toString())),
              const SizedBox(width: 12),
              Expanded(child: _buildStatCard(Icons.delete_outline, 'In Trash', trashCount.toString(), color: Colors.redAccent)),
            ],
          ),
          const SizedBox(height: 24),
          const Text('Accounts by Platform', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 16),
          _buildPlatformGrid(),
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

  Widget _buildPlatformGrid() {
    final platforms = [
      {'name': 'Facebook', 'icon': FontAwesomeIcons.facebook, 'color': const Color(0xFF1877F2)},
      {'name': 'Instagram', 'icon': FontAwesomeIcons.instagram, 'color': const Color(0xFFE4405F)},
      {'name': 'X', 'icon': FontAwesomeIcons.xTwitter, 'color': Colors.white},
      {'name': 'TikTok', 'icon': FontAwesomeIcons.tiktok, 'color': const Color(0xFF00F2FE)},
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 0.85,
      ),
      itemCount: platforms.length,
      itemBuilder: (context, index) {
        final p = platforms[index];
        return GlassCard(
          padding: const EdgeInsets.all(8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(p['icon'] as IconData, color: p['color'] as Color, size: 28),
              const SizedBox(height: 8),
              Text(p['name'] as String, style: const TextStyle(fontSize: 10, color: Colors.white), overflow: TextOverflow.ellipsis),
            ],
          ),
        );
      },
    );
  }
}

// --- ACCOUNTS LIST ---
class AllAccountsScreen extends ConsumerWidget {
  const AllAccountsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accounts = ref.watch(accountsProvider).where((a) => a.isDeleted == 0).toList();

    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                const Icon(Icons.arrow_back, color: Colors.white),
                const SizedBox(width: 16),
                const Text('All Accounts', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                const Spacer(),
                const Icon(Icons.search, color: Colors.white),
                const SizedBox(width: 16),
                const Icon(Icons.filter_list, color: Colors.white),
              ],
            ),
          ),
          Expanded(
            child: accounts.isEmpty
                ? const Center(child: Text("No accounts added yet", style: TextStyle(color: Colors.grey)))
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: accounts.length,
                    itemBuilder: (context, index) {
                      final acc = accounts[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: GlassCard(
                          child: ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: const CircleAvatar(
                              backgroundColor: Color(0xFF2A2B42),
                              child: Icon(Icons.person, color: Colors.white),
                            ),
                            title: Text(acc.platform, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            subtitle: Text(acc.username, style: const TextStyle(color: Colors.grey)),
                            trailing: PopupMenuButton<String>(
                              icon: const Icon(Icons.more_vert, color: Colors.white),
                              color: const Color(0xFF2A2B42),
                              onSelected: (val) {
                                if (val == 'delete') ref.read(accountsProvider.notifier).moveToTrash(acc);
                              },
                              itemBuilder: (context) => [
                                const PopupMenuItem(value: 'edit', child: Text('Edit', style: TextStyle(color: Colors.white))),
                                const PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(color: Colors.redAccent))),
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
    );
  }
}

// --- ADD ACCOUNT SHEET ---
class AddAccountSheet extends ConsumerStatefulWidget {
  const AddAccountSheet({super.key});
  @override
  ConsumerState<AddAccountSheet> createState() => _AddAccountSheetState();
}

class _AddAccountSheetState extends ConsumerState<AddAccountSheet> {
  final _platformCtrl = TextEditingController();
  final _usernameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 20, right: 20, top: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text("Add New Account", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 20),
          _buildTextField(_platformCtrl, "Platform (e.g. Facebook)"),
          const SizedBox(height: 12),
          _buildTextField(_usernameCtrl, "Username / Email"),
          const SizedBox(height: 12),
          _buildTextField(_passwordCtrl, "Password", obscure: true),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8C52FF),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                final acc = Account(
                  platform: _platformCtrl.text,
                  username: _usernameCtrl.text,
                  password: _passwordCtrl.text,
                );
                ref.read(accountsProvider.notifier).addAccount(acc);
                Navigator.pop(context);
              },
              child: const Text("Save Account", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
