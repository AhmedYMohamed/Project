import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dio/dio.dart';
import 'package:intl/intl.dart';
import '../providers/auth_provider.dart';
import '../l10n/app_localizations.dart';
import '../models/models.dart';
import '../services/report_service.dart';
import '../widgets/smart_network_image/smart_network_image.dart';
import '../widgets/report_chat_widget.dart';
import '../widgets/language_switcher_button.dart';

class LawyerReportDetailsScreen extends StatefulWidget {
  final String reportId;

  const LawyerReportDetailsScreen({super.key, required this.reportId});

  @override
  State<LawyerReportDetailsScreen> createState() => _LawyerReportDetailsScreenState();
}

class _LawyerReportDetailsScreenState extends State<LawyerReportDetailsScreen> {
  late Future<ReportModel> _reportFuture;
  final Dio _dio = Dio(BaseOptions(baseUrl: ReportService.baseUrl));

  @override
  void initState() {
    super.initState();
    _loadReport();
  }

  void _loadReport() {
    final auth = context.read<AuthProvider>();
    if (auth.token != null) {
      _reportFuture = ReportService().getReportById(auth.token!, widget.reportId);
    } else {
      _reportFuture = Future.error('User not authenticated');
    }
  }

  Future<void> _submitAction(String action, {String? signature, String? feedback}) async {
    final auth = context.read<AuthProvider>();
    final loc = AppLocalizations.of(context);
    if (auth.token == null) return;

    try {
      await _dio.post(
        '/api/v1/lawyer/reports/${widget.reportId}/action',
        data: {
          'action': action,
          'lawyerSignature': signature,
          'lawyerFeedback': feedback,
        },
        options: Options(
          headers: {'Authorization': 'Bearer ${auth.token}'},
        ),
      );

      if (mounted) {
        final successMsg = loc?.translate('actionExecutedSuccess', params: {'action': action}) ??
            'Action "$action" executed successfully!';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(successMsg),
            backgroundColor: Colors.green,
          ),
        );
        setState(() {
          _loadReport();
        });
      }
    } catch (e) {
      if (mounted) {
        final errorMsg = loc?.translate('failedExecuteAction', params: {'error': e.toString()}) ??
            'Failed to execute action: ${e.toString()}';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMsg),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showReturnDialog() {
    final loc = AppLocalizations.of(context);
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text(loc?.translate('returnToCitizen') ?? 'Return to Citizen'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                loc?.translate('returnFeedbackInstruction') ??
                    'Please provide specific feedback on what the client needs to correct or add to this incident report:',
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: loc?.translate('legalFeedback') ?? 'Legal Feedback / Requirements',
                  border: const OutlineInputBorder(),
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
              onPressed: () {
                final feedback = controller.text.trim();
                if (feedback.isEmpty) return;
                Navigator.pop(ctx);
                _submitAction('return', feedback: feedback);
              },
              child: Text(loc?.translate('returnToCitizen') ?? 'Return to Citizen'),
            ),
          ],
        );
      },
    );
  }

  void _showApproveDialog() {
    final loc = AppLocalizations.of(context);
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text(loc?.translate('approveAndEndorse') ?? 'Approve & Endorse'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                loc?.translate('digitalSignatureUrl') ??
                    'Enter digital signature seal/text (Optional, default signature will be used if left blank):',
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                decoration: InputDecoration(
                  labelText: loc?.translate('digitalSignatureUrl') ?? 'Digital Signature Seal',
                  border: const OutlineInputBorder(),
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
              onPressed: () {
                final signature = controller.text.trim();
                Navigator.pop(ctx);
                _submitAction('approve', signature: signature.isNotEmpty ? signature : null);
              },
              child: Text(loc?.translate('approveAndEndorse') ?? 'Approve & Forward'),
            ),
          ],
        );
      },
    );
  }

  void _showEscalateDialog() {
    final loc = AppLocalizations.of(context);
    final sigController = TextEditingController();
    final feedController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text(loc?.translate('urgentEscalation') ?? 'Urgently Escalate Incident'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                loc?.translate('directEscalation') ??
                    'Urgently escalate to MoI officers. This flags high priority risk.',
              ),
              const SizedBox(height: 16),
              TextField(
                controller: feedController,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: loc?.translate('legalFeedback') ?? 'Escalation Legal Reason',
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: sigController,
                decoration: InputDecoration(
                  labelText: loc?.translate('digitalSignatureUrl') ?? 'Digital Signature Seal',
                  border: const OutlineInputBorder(),
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
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () {
                final signature = sigController.text.trim();
                final feedback = feedController.text.trim();
                Navigator.pop(ctx);
                _submitAction(
                  'escalate',
                  signature: signature.isNotEmpty ? signature : null,
                  feedback: feedback.isNotEmpty ? feedback : null,
                );
              },
              child: Text(
                loc?.translate('urgentEscalation') ?? 'Urgently Escalate',
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          loc?.translate('reportDetailsTitle') ?? 'Incident Review',
          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: const Color(0xFF1E3A8A),
        actions: const [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 4.0, vertical: 8.0),
            child: LanguageSwitcherButton(),
          ),
          SizedBox(width: 8),
        ],
      ),
      body: FutureBuilder<ReportModel>(
        future: _reportFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData) {
            return Center(child: Text(loc?.translate('reportNotFound') ?? 'Report not found'));
          }

          final report = snapshot.data!;
          final dateStr = DateFormat('MMM dd, yyyy • hh:mm a').format(report.createdAt);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header details
                Card(
                  elevation: 1,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${loc?.translate('report') ?? "Incident"} #${report.reportId}',
                              style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A)),
                            ),
                            _buildStatusChip(report.status, loc),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          report.title,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${loc?.translate('submitted') ?? "Submitted"}: $dateStr',
                          style: const TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Review actions block
                if (report.status == 'PendingLawyerReview') ...[
                  Text(
                    loc?.translate('quickActions') ?? 'Advocate Review Action Required',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.check, size: 16),
                          label: Text(loc?.translate('approveAndEndorse') ?? 'Approve'),
                          onPressed: _showApproveDialog,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                          icon: const Icon(Icons.reply, size: 16),
                          label: Text(loc?.translate('returnToCitizen') ?? 'Return'),
                          onPressed: _showReturnDialog,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                      icon: const Icon(Icons.warning_amber, size: 16),
                      label: Text(
                        loc?.translate('urgentEscalation') ?? 'Urgently Escalate to MoI',
                        style: const TextStyle(color: Colors.white),
                      ),
                      onPressed: _showEscalateDialog,
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                // Incident Description
                Text(
                  loc?.translate('description') ?? 'Incident Description',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 8),
                Text(report.descriptionText, style: const TextStyle(fontSize: 14)),
                const SizedBox(height: 16),

                // Attachments/Evidence
                if (report.attachments.isNotEmpty) ...[
                  Text(
                    loc?.translate('evidence') ?? 'Attachments & Evidence',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 120,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: report.attachments.length,
                      itemBuilder: (context, idx) {
                        final att = report.attachments[idx];
                        return Container(
                          width: 120,
                          margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey[300]!),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: SmartNetworkImage(
                              url: att.displayUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => Container(
                                color: Colors.grey[200],
                                child: const Icon(Icons.broken_image, color: Colors.grey),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                // Live Legal Counsel Chat
                Text(
                  loc?.translate('legalDiscussionChat') ?? 'Legal Counsel Communications',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E3A8A),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 350,
                  child: ReportChatWidget(
                    reportId: report.reportId,
                    token: context.read<AuthProvider>().token!,
                    currentUserId: context.read<AuthProvider>().userId!,
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
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
        style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold),
      ),
    );
  }
}
