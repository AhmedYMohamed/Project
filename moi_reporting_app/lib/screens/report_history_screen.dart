import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../services/report_service.dart';
import '../providers/auth_provider.dart';
import '../providers/locale_provider.dart';
import '../l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import 'citizen_report_details_screen.dart';

class ReportHistoryScreen extends StatefulWidget {
  const ReportHistoryScreen({super.key});

  @override
  State<ReportHistoryScreen> createState() => _ReportHistoryScreenState();
}

class _ReportHistoryScreenState extends State<ReportHistoryScreen> {
  late Future<List<ReportModel>> _reportsFuture;

  @override
  void initState() {
    super.initState();
    _loadReports();
  }

  void _loadReports() {
    final auth = context.read<AuthProvider>();
    _reportsFuture = ReportService().getUserReports(auth.token!, auth.userId!);
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final localeProvider = Provider.of<LocaleProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(loc?.translate('myReports') ?? 'My Reports', style: const TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF1E3A8A),
        actions: [
          IconButton(
            icon: const Icon(Icons.language, color: Colors.white),
            tooltip: loc?.translate('toggleLanguage') ?? 'Switch Language',
            onPressed: () => localeProvider.toggleLanguage(),
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            tooltip: loc?.translate('refresh') ?? 'Refresh',
            onPressed: () => setState(() => _loadReports()),
          ),
        ],
      ),
      body: FutureBuilder<List<ReportModel>>(
        future: _reportsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 48, color: Colors.red),
                    const SizedBox(height: 16),
                    Text('${loc?.translate('errorLoadingReports') ?? 'Error loading reports'}: ${snapshot.error}', textAlign: TextAlign.center),
                  ],
                ),
              ),
            );
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text(loc?.translate('noReportsFound') ?? 'No reports found.'));
          }

          final reports = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: reports.length,
            itemBuilder: (context, index) {
              final report = reports[index];
              return _buildReportCard(report, loc);
            },
          );
        },
      ),
    );
  }

  Widget _buildReportCard(ReportModel report, AppLocalizations? loc) {
    final dateStr = DateFormat('MMM dd, yyyy • hh:mm a').format(report.createdAt);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CitizenReportDetailsScreen(
                reportId: report.reportId,
                initialReport: report,
              ),
            ),
          ).then((_) => setState(() => _loadReports()));
        },
        title: Text(report.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Text(report.descriptionText, maxLines: 2, overflow: TextOverflow.ellipsis),
            if (report.officerNote != null && report.officerNote!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.shield, size: 14, color: Colors.blue.shade800),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        '${loc?.translate('officerNotes') ?? 'ملاحظات الضابط'}: ${report.officerNote}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: Colors.blue.shade900, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(dateStr, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                _buildStatusChip(report.status, loc),
              ],
            ),
          ],
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
      ),
    );
  }

  Widget _buildStatusChip(String status, AppLocalizations? loc) {
    Color color;
    final lowerStatus = status.toLowerCase();
    switch (lowerStatus) {
      case 'resolved':
        color = Colors.green;
        break;
      case 'inprogress':
        color = Colors.orange;
        break;
      case 'rejected':
        color = Colors.red;
        break;
      default:
        color = Colors.blue;
    }

    final statusText = loc?.translate('status_$lowerStatus') ?? status;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color),
      ),
      child: Text(
        statusText,
        style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold),
      ),
    );
  }
}
