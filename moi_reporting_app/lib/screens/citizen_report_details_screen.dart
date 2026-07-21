import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:video_player/video_player.dart';
import '../models/models.dart';
import '../services/report_service.dart';
import '../providers/auth_provider.dart';
import '../providers/locale_provider.dart';
import '../l10n/app_localizations.dart';
import '../widgets/smart_network_image/smart_network_image.dart';
import 'app_colors.dart';

class CitizenReportDetailsScreen extends StatefulWidget {
  final String reportId;
  final ReportModel? initialReport;

  const CitizenReportDetailsScreen({
    super.key,
    required this.reportId,
    this.initialReport,
  });

  @override
  State<CitizenReportDetailsScreen> createState() => _CitizenReportDetailsScreenState();
}

class _CitizenReportDetailsScreenState extends State<CitizenReportDetailsScreen> {
  late Future<ReportModel> _reportFuture;
  int _selectedAttachmentIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadReport();
  }

  void _loadReport() {
    final auth = context.read<AuthProvider>();
    if (auth.token != null) {
      _reportFuture = ReportService().getReportById(auth.token!, widget.reportId);
    } else if (widget.initialReport != null) {
      _reportFuture = Future.value(widget.initialReport!);
    } else {
      _reportFuture = Future.error('User not authenticated');
    }
  }

  bool _isVideoAttachment(AttachmentModel attachment) {
    final type = attachment.fileType.toLowerCase();
    if (type == 'video') return true;
    final url = attachment.displayUrl.toLowerCase();
    return url.contains('.mp4') ||
        url.contains('.mov') ||
        url.contains('.avi') ||
        url.contains('.webm') ||
        url.contains('.mkv');
  }

  void _openImageLightbox(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.black.withValues(alpha: 0.9),
        insetPadding: const EdgeInsets.all(10),
        child: Stack(
          alignment: Alignment.center,
          children: [
            InteractiveViewer(
              panEnabled: true,
              boundaryMargin: const EdgeInsets.all(20),
              minScale: 0.5,
              maxScale: 4.0,
              child: SmartNetworkImage(
                url: imageUrl,
                fit: BoxFit.contain,
                width: double.infinity,
                height: double.infinity,
                errorBuilder: (c, err, stack) => const Center(
                  child: Icon(Icons.broken_image, color: Colors.white70, size: 64),
                ),
              ),
            ),
            Positioned(
              top: 16,
              right: 16,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 30),
                onPressed: () => Navigator.of(ctx).pop(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final localeProvider = Provider.of<LocaleProvider>(context);

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A), // Dark slate theme
      appBar: AppBar(
        title: Text(
          loc?.translate('reportDetailsTitle') ?? 'تفاصيل البلاغ',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF1E293B),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.language, color: Colors.white),
            tooltip: loc?.translate('toggleLanguage') ?? 'Switch Language',
            onPressed: () => localeProvider.toggleLanguage(),
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () => setState(() => _loadReport()),
          ),
        ],
      ),
      body: FutureBuilder<ReportModel>(
        future: _reportFuture,
        initialData: widget.initialReport,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.skyAqua),
            );
          } else if (snapshot.hasError && !snapshot.hasData) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 54, color: Colors.redAccent),
                    const SizedBox(height: 16),
                    Text(
                      '${loc?.translate('failedToLoadReport') ?? 'فشل في تحميل البلاغ'}: ${snapshot.error}',
                      style: const TextStyle(color: Colors.white70),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.frenchBlue,
                      ),
                      icon: const Icon(Icons.refresh, color: Colors.white),
                      label: Text(loc?.translate('refresh') ?? 'تحديث', style: const TextStyle(color: Colors.white)),
                      onPressed: () => setState(() => _loadReport()),
                    ),
                  ],
                ),
              ),
            );
          }

          final report = snapshot.data!;
          return RefreshIndicator(
            onRefresh: () async {
              setState(() => _loadReport());
            },
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- Header Status Card ---
                  _buildHeaderCard(report, loc),

                  const SizedBox(height: 20),

                  // --- Officer Notes Section (High Priority) ---
                  _buildOfficerNotesSection(report, loc),

                  const SizedBox(height: 20),

                  // --- Report Description & Category Section ---
                  _buildDetailsSection(report, loc),

                  const SizedBox(height: 20),

                  // --- Attachments / Evidence Section ---
                  if (report.attachments.isNotEmpty) _buildEvidenceSection(report, loc),

                  const SizedBox(height: 30),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeaderCard(ReportModel report, AppLocalizations? loc) {
    final dateStr = DateFormat('MMM dd, yyyy • hh:mm a').format(report.createdAt);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF1E293B),
            const Color(0xFF0F172A).withValues(alpha: 0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.skyAqua.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.skyAqua.withValues(alpha: 0.3)),
                ),
                child: Text(
                  '#${report.reportId}',
                  style: const TextStyle(
                    color: AppColors.skyAqua,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
              _buildStatusChip(report.status, loc),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            report.title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.access_time, size: 14, color: Colors.white54),
              const SizedBox(width: 6),
              Text(
                dateStr,
                style: const TextStyle(color: Colors.white54, fontSize: 13),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOfficerNotesSection(ReportModel report, AppLocalizations? loc) {
    final hasNote = report.officerNote != null && report.officerNote!.trim().isNotEmpty;
    final officerNotesTitle = loc?.translate('officerNotes') ?? 'ملاحظات الضابط';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: hasNote ? const Color(0xFF1E3A8A).withValues(alpha: 0.25) : const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: hasNote ? AppColors.skyAqua.withValues(alpha: 0.5) : Colors.white.withValues(alpha: 0.08),
          width: hasNote ? 1.5 : 1.0,
        ),
        boxShadow: hasNote
            ? [
                BoxShadow(
                  color: AppColors.skyAqua.withValues(alpha: 0.1),
                  blurRadius: 12,
                  spreadRadius: 2,
                ),
              ]
            : [],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: hasNote ? AppColors.skyAqua.withValues(alpha: 0.2) : Colors.white10,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.shield,
                  color: hasNote ? AppColors.skyAqua : Colors.white38,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  officerNotesTitle,
                  style: TextStyle(
                    color: hasNote ? Colors.white : Colors.white70,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (hasNote)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.green.shade400, width: 0.8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle, size: 12, color: Colors.green.shade400),
                      const SizedBox(width: 4),
                      Text(
                        loc?.translate('updated') ?? 'تم التحديث',
                        style: TextStyle(color: Colors.green.shade400, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          if (hasNote) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A).withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.skyAqua.withValues(alpha: 0.2)),
              ),
              child: SelectableText(
                report.officerNote!,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  height: 1.5,
                ),
              ),
            ),
          ] else ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.03),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Colors.white38, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      loc?.translate('noOfficerNotesYet') ?? 'لم يقم الضابط بإضافة ملاحظات بعد.',
                      style: const TextStyle(color: Colors.white54, fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailsSection(ReportModel report, AppLocalizations? loc) {
    final catKey = 'cat_${report.categoryId.toLowerCase()}';
    final categoryText = loc?.translate(catKey) ?? report.categoryId;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Category Tag
          Row(
            children: [
              const Icon(Icons.category_outlined, color: AppColors.skyAqua, size: 18),
              const SizedBox(width: 8),
              Text(
                '${loc?.translate('category') ?? 'الفئة'}: ',
                style: const TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w600),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.frenchBlue.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.skyAqua.withValues(alpha: 0.3)),
                ),
                child: Text(
                  categoryText,
                  style: const TextStyle(color: AppColors.skyAqua, fontSize: 13, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),

          if (report.location != null && report.location!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.location_on_outlined, color: Colors.redAccent, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    report.location!,
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ),
              ],
            ),
          ],

          const Divider(height: 28, color: Colors.white10),

          Text(
            loc?.translate('description') ?? 'الوصف',
            style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          SelectableText(
            report.descriptionText,
            style: const TextStyle(color: Colors.white70, fontSize: 15, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildEvidenceSection(ReportModel report, AppLocalizations? loc) {
    final currentAttachment = report.attachments[_selectedAttachmentIndex];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.photo_library_outlined, color: AppColors.skyAqua, size: 20),
              const SizedBox(width: 8),
              Text(
                loc?.translate('evidence') ?? 'الأدلة والمرفقات',
                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              Text(
                '${_selectedAttachmentIndex + 1} ${loc?.translate('of') ?? 'من'} ${report.attachments.length}',
                style: const TextStyle(color: Colors.white54, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Main Preview Box
          Container(
            height: 260,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.black45,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white12),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: _buildAttachmentPreview(currentAttachment),
            ),
          ),

          if (report.attachments.length > 1) ...[
            const SizedBox(height: 14),
            SizedBox(
              height: 64,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: report.attachments.length,
                itemBuilder: (context, index) {
                  final att = report.attachments[index];
                  final isSelected = index == _selectedAttachmentIndex;
                  final isVideo = _isVideoAttachment(att);

                  return GestureDetector(
                    onTap: () => setState(() => _selectedAttachmentIndex = index),
                    child: Container(
                      width: 64,
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSelected ? AppColors.skyAqua : Colors.white24,
                          width: isSelected ? 2.5 : 1.0,
                        ),
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: isVideo
                                ? Container(
                                    color: Colors.black54,
                                    child: const Center(
                                      child: Icon(Icons.videocam, color: Colors.white70, size: 24),
                                    ),
                                  )
                                : SmartNetworkImage(
                                    url: att.displayUrl,
                                    fit: BoxFit.cover,
                                    width: 64,
                                    height: 64,
                                    errorBuilder: (ctx, err, stack) => const Center(
                                      child: Icon(Icons.broken_image, color: Colors.white38, size: 20),
                                    ),
                                  ),
                          ),
                          if (isVideo)
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.black45,
                                shape: BoxShape.circle,
                              ),
                              padding: const EdgeInsets.all(4),
                              child: const Icon(Icons.play_arrow, color: AppColors.skyAqua, size: 18),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAttachmentPreview(AttachmentModel attachment) {
    final url = attachment.displayUrl;
    final isVideo = _isVideoAttachment(attachment);

    if (isVideo) {
      return _InlineVideoPlayer(key: ValueKey(url), url: url);
    }

    return GestureDetector(
      onTap: () => _openImageLightbox(context, url),
      child: Stack(
        alignment: Alignment.bottomRight,
        children: [
          SmartNetworkImage(
            url: url,
            fit: BoxFit.contain,
            width: double.infinity,
            height: double.infinity,
            headers: const {'Accept': 'image/*'},
            loadingBuilder: (context) => const Center(
              child: CircularProgressIndicator(color: AppColors.skyAqua),
            ),
            errorBuilder: (context, error, stackTrace) => Container(
              padding: const EdgeInsets.all(16),
              color: Colors.black26,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.broken_image_outlined, color: Colors.white54, size: 40),
                  const SizedBox(height: 8),
                  Text(
                    error.toString(),
                    style: const TextStyle(color: Colors.white38, fontSize: 11),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
          Container(
            margin: const EdgeInsets.all(10),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white30),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.zoom_in, color: Colors.white, size: 14),
                SizedBox(width: 4),
                Text(
                  'تكبير',
                  style: TextStyle(color: Colors.white, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
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
        color = Colors.redAccent;
        break;
      default:
        color = AppColors.skyAqua;
    }

    final statusText = loc?.translate('status_$lowerStatus') ?? status;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color, width: 1.2),
      ),
      child: Text(
        statusText,
        style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold),
      ),
    );
  }
}

class _InlineVideoPlayer extends StatefulWidget {
  final String url;
  const _InlineVideoPlayer({super.key, required this.url});

  @override
  State<_InlineVideoPlayer> createState() => _InlineVideoPlayerState();
}

class _InlineVideoPlayerState extends State<_InlineVideoPlayer> {
  late VideoPlayerController _controller;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.url))
      ..initialize().then((_) {
        if (mounted) setState(() {});
      }).catchError((error) {
        if (mounted) {
          setState(() {
            _hasError = true;
          });
        }
        debugPrint('Video Player Error: $error');
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.videocam_off, color: Colors.white54, size: 40),
            SizedBox(height: 8),
            Text(
              'تعذر تشغيل الفيديو.',
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ],
        ),
      );
    }

    if (!_controller.value.isInitialized) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.skyAqua),
      );
    }

    return AspectRatio(
      aspectRatio: _controller.value.aspectRatio,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          VideoPlayer(_controller),
          VideoProgressIndicator(
            _controller,
            allowScrubbing: true,
            colors: const VideoProgressColors(
              playedColor: AppColors.turquoiseSurf,
              bufferedColor: Colors.white30,
              backgroundColor: Colors.white12,
            ),
          ),
          Center(
            child: IconButton(
              icon: Icon(
                _controller.value.isPlaying
                    ? Icons.pause_circle_filled
                    : Icons.play_circle_fill,
                color: Colors.white,
                size: 54,
              ),
              onPressed: () => setState(() => _controller.value.isPlaying
                  ? _controller.pause()
                  : _controller.play()),
            ),
          ),
        ],
      ),
    );
  }
}
