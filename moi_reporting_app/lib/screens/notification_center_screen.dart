import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../models/notification_model.dart';
import '../services/notification_center_service.dart';
import '../services/report_service.dart';
import '../l10n/app_localizations.dart';

class NotificationCenterScreen extends StatefulWidget {
  const NotificationCenterScreen({super.key});

  @override
  State<NotificationCenterScreen> createState() => _NotificationCenterScreenState();
}

class _NotificationCenterScreenState extends State<NotificationCenterScreen> {
  final NotificationCenterService _service = NotificationCenterService();
  List<NotificationModel> _notifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
  }

  Future<void> _fetchNotifications() async {
    final auth = context.read<AuthProvider>();
    final token = auth.token;
    final userId = auth.userId;
    if (token == null) return;

    setState(() => _isLoading = true);
    try {
      final list = await _service.getNotifications(token);
      
      // Refresh reports cache in the background
      if (userId != null) {
        try {
          await ReportService().getUserReports(token, userId, forceRefresh: true);
        } catch (_) {}
      }

      if (mounted) {
        setState(() {
          _notifications = list;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _markAllRead() async {
    final token = context.read<AuthProvider>().token;
    if (token == null) return;

    await _service.markAllAsRead(token);
    _fetchNotifications();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          loc?.translate('notificationCenter') ?? 'Notification Center',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF1E3A8A),
        actions: [
          IconButton(
            icon: const Icon(Icons.done_all, color: Colors.white),
            tooltip: loc?.translate('markAllAsRead') ?? 'Mark All as Read',
            onPressed: _notifications.isEmpty ? null : _markAllRead,
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _fetchNotifications,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _notifications.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.notifications_none, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        loc?.translate('noNotifications') ?? 'No notifications yet.',
                        style: TextStyle(color: Colors.grey[600], fontSize: 16),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _fetchNotifications,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: _notifications.length,
                    itemBuilder: (context, index) {
                      final item = _notifications[index];
                      return Card(
                        elevation: item.isRead ? 1 : 3,
                        color: item.isRead ? Colors.white : Colors.blue.shade50,
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: item.isRead ? Colors.grey.shade300 : const Color(0xFF1E3A8A),
                            child: Icon(
                              Icons.notifications,
                              color: item.isRead ? Colors.grey.shade700 : Colors.white,
                              size: 20,
                            ),
                          ),
                          title: Text(
                            item.title,
                            style: TextStyle(
                              fontWeight: item.isRead ? FontWeight.normal : FontWeight.bold,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text(item.body),
                              const SizedBox(height: 6),
                              Text(
                                item.createdAt.toLocal().toString().split('.')[0],
                                style: const TextStyle(fontSize: 11, color: Colors.grey),
                              ),
                            ],
                          ),
                          onTap: () async {
                            if (!item.isRead) {
                              final token = context.read<AuthProvider>().token;
                              if (token != null) {
                                await _service.markAsRead(token, item.notificationId);
                                _fetchNotifications();
                              }
                            }
                          },
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
