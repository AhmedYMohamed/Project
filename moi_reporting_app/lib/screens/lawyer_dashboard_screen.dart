import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dio/dio.dart';
import '../providers/auth_provider.dart';
import '../l10n/app_localizations.dart';
import '../models/models.dart';
import '../services/report_service.dart';
import '../widgets/language_switcher_button.dart';
import 'lawyer_report_details_screen.dart';

class LawyerDashboardScreen extends StatefulWidget {
  const LawyerDashboardScreen({super.key});

  @override
  State<LawyerDashboardScreen> createState() => _LawyerDashboardScreenState();
}

class _LawyerDashboardScreenState extends State<LawyerDashboardScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final Dio _dio = Dio(BaseOptions(baseUrl: ReportService.baseUrl));

  List<ReportModel> _reports = [];
  List<UserModel> _clients = [];
  UserModel? _profile;
  bool _isLoadingReports = false;
  bool _isLoadingClients = false;
  bool _isLoadingProfile = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchReports();
    _fetchClients();
    _fetchProfile();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchProfile() async {
    final auth = context.read<AuthProvider>();
    if (auth.token == null) return;

    setState(() => _isLoadingProfile = true);
    try {
      final response = await _dio.get(
        '/api/v1/auth/me',
        options: Options(
          headers: {'Authorization': 'Bearer ${auth.token}'},
        ),
      );

      setState(() {
        _profile = UserModel.fromJson(response.data);
        _isLoadingProfile = false;
      });
    } catch (e) {
      setState(() => _isLoadingProfile = false);
    }
  }

  Future<void> _fetchReports() async {
    final auth = context.read<AuthProvider>();
    if (auth.token == null) return;

    setState(() => _isLoadingReports = true);
    try {
      final response = await _dio.get(
        '/api/v1/lawyer/reports',
        options: Options(
          headers: {'Authorization': 'Bearer ${auth.token}'},
        ),
      );

      final List rawReports = response.data['reports'] ?? [];
      setState(() {
        _reports = rawReports.map((r) => ReportModel.fromJson(r)).toList();
        _isLoadingReports = false;
      });
    } catch (e) {
      setState(() => _isLoadingReports = false);
    }
  }

  Future<void> _fetchClients() async {
    final auth = context.read<AuthProvider>();
    if (auth.token == null) return;

    setState(() => _isLoadingClients = true);
    try {
      final response = await _dio.get(
        '/api/v1/users/citizens',
        options: Options(
          headers: {'Authorization': 'Bearer ${auth.token}'},
        ),
      );

      final List rawUsers = response.data ?? [];
      setState(() {
        _clients = rawUsers.map((u) => UserModel.fromJson(u)).toList();
        _isLoadingClients = false;
      });
    } catch (e) {
      setState(() => _isLoadingClients = false);
    }
  }

  void _showQrDialog() {
    final loc = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text(loc?.translate('myAdvocateQrCode') ?? 'My Advocate QR Code'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.qr_code_2, size: 120, color: Color(0xFF1E3A8A)),
              const SizedBox(height: 16),
              Text(
                loc?.translate('shareQrInstruction') ??
                    'Share this QR code string or Syndicate ID with clients to link their accounts:',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SelectableText(
                  _profile?.lawyerQrCode ?? 'QR-CODE-NOT-AVAILABLE',
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${loc?.translate('syndicateId') ?? 'Syndicate ID'}: ${_profile?.syndicateId ?? "N/A"}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(loc?.translate('close') ?? 'Close'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthProvider>();
    final loc = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          loc?.translate('advocatePortal') ?? 'MoI Advocate Portal',
          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: const Color(0xFF1E3A8A),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code, color: Colors.white),
            tooltip: loc?.translate('viewQrCode') ?? 'View QR Code',
            onPressed: _showQrDialog,
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 4.0, vertical: 8.0),
            child: LanguageSwitcherButton(),
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            tooltip: loc?.translate('logout') ?? 'Logout',
            onPressed: () => auth.logout(),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: [
            Tab(icon: const Icon(Icons.gavel), text: loc?.translate('incidents') ?? 'Incidents'),
            Tab(icon: const Icon(Icons.people), text: loc?.translate('myClients') ?? 'My Clients'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildIncidentsTab(loc),
          _buildClientsTab(loc),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF1E3A8A),
        child: const Icon(Icons.refresh, color: Colors.white),
        onPressed: () {
          _fetchReports();
          _fetchClients();
        },
      ),
    );
  }

  Widget _buildIncidentsTab(AppLocalizations? loc) {
    if (_isLoadingReports) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_reports.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.assignment_turned_in_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              loc?.translate('noClientIncidents') ?? 'No client incidents reported yet.',
              style: TextStyle(color: Colors.grey[600], fontSize: 16),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _reports.length,
      itemBuilder: (context, index) {
        final r = _reports[index];
        final bool pendingReview = r.status == 'PendingLawyerReview';

        return Card(
          elevation: pendingReview ? 3 : 1,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: pendingReview
                ? const BorderSide(color: Colors.orangeAccent, width: 1.5)
                : BorderSide(color: Colors.grey[200]!),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            title: Text(
              r.title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                Text(
                  r.descriptionText,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Colors.grey[600], fontSize: 13),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _buildStatusChip(r.status, loc),
                    const SizedBox(width: 8),
                    if (r.isUrgentEscalation)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          loc?.translate('urgentEscalation') ?? 'URGENT ESCALATION',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => LawyerReportDetailsScreen(reportId: r.reportId),
                ),
              );
              _fetchReports(); // Refresh on pop back
            },
          ),
        );
      },
    );
  }

  Widget _buildClientsTab(AppLocalizations? loc) {
    if (_isLoadingClients) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_clients.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              loc?.translate('noClientsLinked') ?? 'No citizens are linked to your profile.',
              style: TextStyle(color: Colors.grey[600], fontSize: 16),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _clients.length,
      itemBuilder: (context, index) {
        final c = _clients[index];
        final phoneLabel = loc?.translate('phone') ?? 'Phone';

        return Card(
          elevation: 1,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.grey[200]!),
          ),
          child: ListTile(
            leading: const CircleAvatar(
              backgroundColor: Color(0xFF1E3A8A),
              child: Icon(Icons.person, color: Colors.white),
            ),
            title: Text(
              c.email ?? (loc?.translate('anonymousEmail') ?? 'Anonymous Email'),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text('$phoneLabel: ${c.phoneNumber ?? "N/A"}'),
          ),
        );
      },
    );
  }

  Widget _buildStatusChip(String status, AppLocalizations? loc) {
    Color color = Colors.grey;
    String key = 'status_${status.toLowerCase()}';
    String label = loc?.translate(key) ?? status;

    switch (status) {
      case 'Submitted':
        color = Colors.blue;
        break;
      case 'PendingLawyerReview':
        color = Colors.orange;
        break;
      case 'ReturnedToCitizen':
        color = Colors.redAccent;
        break;
      case 'Assigned':
        color = Colors.purple;
        break;
      case 'InProgress':
        color = Colors.amber;
        break;
      case 'Resolved':
        color = Colors.green;
        break;
      case 'Rejected':
        color = Colors.red;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
