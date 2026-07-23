import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dio/dio.dart';
import '../providers/auth_provider.dart';
import '../l10n/app_localizations.dart';
import '../services/report_service.dart';
import '../widgets/language_switcher_button.dart';
import 'report_form.dart';
import 'report_history_screen.dart';

import 'package:shared_preferences/shared_preferences.dart';
import 'citizen_report_details_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadTabAndRestoreRoute();
  }

  Future<void> _loadTabAndRestoreRoute() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _selectedIndex = prefs.getInt('citizen_tab_index') ?? 0;
      });

      await prefs.setString('last_route', 'citizen_dashboard');

      final lastRoute = prefs.getString('last_route_citizen');
      if (lastRoute == 'citizen_report_details') {
        final reportId = prefs.getString('last_report_id_citizen');
        if (reportId != null && mounted) {
          await prefs.setString('last_route_citizen', 'citizen_dashboard');
          if (mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => CitizenReportDetailsScreen(reportId: reportId),
              ),
            );
          }
        }
      }
    }
  }

  Future<void> _saveTabPreference(int index) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('citizen_tab_index', index);
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final List<Widget> pages = [
      DashboardScreen(
        onTabSelected: (index) {
          setState(() => _selectedIndex = index);
          _saveTabPreference(index);
        },
      ),
      const ReportFormScreen(),
      const ReportHistoryScreen(),
      const ProfileScreen(),
    ];
    return Scaffold(
      body: pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() => _selectedIndex = index);
          _saveTabPreference(index);
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF1E3A8A),
        items: [
          BottomNavigationBarItem(
              icon: const Icon(Icons.home_outlined),
              label: loc?.translate('home') ?? 'Home'),
          BottomNavigationBarItem(
              icon: const Icon(Icons.add_circle_outline),
              label: loc?.translate('report') ?? 'Report'),
          BottomNavigationBarItem(
              icon: const Icon(Icons.history_outlined),
              label: loc?.translate('history') ?? 'History'),
          BottomNavigationBarItem(
              icon: const Icon(Icons.person_outline),
              label: loc?.translate('profile') ?? 'Profile'),
        ],
      ),
    );
  }
}

class DashboardScreen extends StatefulWidget {
  final Function(int) onTabSelected;

  const DashboardScreen({super.key, required this.onTabSelected});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _isLoading = true;
  int _activeCount = 0;
  int _resolvedCount = 0;
  int _totalCount = 0;

  @override
  void initState() {
    super.initState();
    _fetchStats();
  }

  Future<void> _fetchStats() async {
    setState(() => _isLoading = true);
    try {
      final auth = context.read<AuthProvider>();
      final reports =
          await ReportService().getUserReports(auth.token!, auth.userId!);
      if (mounted) {
        setState(() {
          _totalCount = reports.length;
          _resolvedCount =
              reports.where((r) => r.status.toLowerCase() == 'resolved').length;
          _activeCount = _totalCount - _resolvedCount;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _activeCount = 0;
          _resolvedCount = 0;
          _totalCount = 0;
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(loc?.translate('dashboard') ?? 'Dashboard',
            style: const TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF1E3A8A),
        actions: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 4.0, vertical: 8.0),
            child: LanguageSwitcherButton(),
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            tooltip: loc?.translate('refresh') ?? 'Refresh',
            onPressed: _fetchStats,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              loc?.translate('welcomeBackUser') ?? 'Welcome back,',
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
            Text(
              loc?.translate('citizen') ?? 'Citizen',
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 32),
            _buildQuickStats(context, loc),
            const SizedBox(height: 32),
            Text(
              loc?.translate('quickActions') ?? 'Quick Actions',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildActionCard(
              context,
              title: loc?.translate('fileNewReport') ?? 'File a New Report',
              icon: Icons.add_circle,
              color: const Color(0xFF1E3A8A),
              onTap: () => widget.onTabSelected(1),
            ),
            const SizedBox(height: 16),
            _buildActionCard(
              context,
              title: loc?.translate('viewGuidelines') ?? 'View Guidelines',
              icon: Icons.info_outline,
              color: Colors.orange,
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(loc?.translate('guidelinesSoon') ?? 'Guidelines coming soon!'),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStats(BuildContext context, AppLocalizations? loc) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E3A8A), Color(0xFF3B82F6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _StatItem(
                    label: loc?.translate('active') ?? 'Active',
                    count: _activeCount.toString()),
                _StatItem(
                    label: loc?.translate('resolved') ?? 'Resolved',
                    count: _resolvedCount.toString()),
                _StatItem(
                    label: loc?.translate('total') ?? 'Total',
                    count: _totalCount.toString()),
              ],
            ),
    );
  }

  Widget _buildActionCard(BuildContext context,
      {required String title,
      required IconData icon,
      required Color color,
      required VoidCallback onTap}) {
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey[200]!),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
            leading: Icon(icon, color: color, size: 32),
            title: Text(title,
                style: const TextStyle(fontWeight: FontWeight.bold)),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          ),
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String count;
  const _StatItem({required this.label, required this.count});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(count,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold)),
        Text(label,
            style: const TextStyle(color: Colors.white70, fontSize: 12)),
      ],
    );
  }
}

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  void _showLinkLawyerDialog(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text(loc?.translate('linkPrimaryLawyer') ?? 'Link Primary Lawyer'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                loc?.translate('enterSyndicateIdInstruction') ??
                    'Enter your lawyer\'s Syndicate ID or Bar ID to establish the link:',
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                decoration: InputDecoration(
                  labelText: loc?.translate('syndicateId') ?? 'Syndicate ID',
                  prefixIcon: const Icon(Icons.gavel),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(loc?.translate('cancel') ?? 'Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final syndicateId = controller.text.trim();
                if (syndicateId.isEmpty) return;

                Navigator.pop(ctx);
                _linkLawyer(context, syndicateId);
              },
              child: Text(loc?.translate('link') ?? 'Link'),
            ),
          ],
        );
      },
    );
  }

  void _linkLawyer(BuildContext context, String syndicateId) async {
    final auth = context.read<AuthProvider>();
    final loc = AppLocalizations.of(context);
    try {
      final dio = Dio(BaseOptions(baseUrl: ReportService.baseUrl));
      await dio.post(
        '/api/v1/users/link-lawyer',
        data: {'syndicateId': syndicateId},
        options: Options(
          headers: {'Authorization': 'Bearer ${auth.token}'},
        ),
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(loc?.translate('lawyerLinkedSuccess') ?? 'Lawyer linked successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        final errorMsg = loc?.translate('failedLinkLawyer', params: {'error': e.toString()}) ??
            'Failed to link lawyer: ${e.toString()}';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMsg),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthProvider>();
    final loc = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(loc?.translate('profile') ?? 'Profile',
            style: const TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF1E3A8A),
        actions: const [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
            child: LanguageSwitcherButton(),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Center(
            child: CircleAvatar(
              radius: 50,
              backgroundColor: Color(0xFF1E3A8A),
              child: Icon(Icons.person, size: 50, color: Colors.white),
            ),
          ),
          const SizedBox(height: 24),
          Center(
            child: Text(
              loc?.translate('citizenAccount') ?? 'Citizen Account',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 48),
          ListTile(
            leading: const Icon(Icons.language),
            title: Text(loc?.translate('language') ?? 'Language'),
            trailing: const LanguageSwitcherButton(),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.gavel),
            title: Text(loc?.translate('associatedLawyer') ?? 'Associated Lawyer'),
            subtitle: Text(
              loc?.translate('linkLawyerSub') ?? 'Link your primary lawyer using their Syndicate ID',
            ),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => _showLinkLawyerDialog(context),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.settings_outlined),
            title: Text(loc?.translate('accountSettings') ?? 'Account Settings'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(loc?.translate('settingsSoon') ?? 'Settings coming soon!')),
              );
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.help_outline),
            title: Text(loc?.translate('helpSupport') ?? 'Help & Support'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(loc?.translate('helpSoon') ?? 'Help & Support coming soon!')),
              );
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: Text(loc?.translate('logout') ?? 'Logout',
                style: const TextStyle(color: Colors.red)),
            onTap: () => auth.logout(),
          ),
        ],
      ),
    );
  }
}
