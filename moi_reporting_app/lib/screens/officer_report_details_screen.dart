import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';
import '../services/officer_service.dart';
import '../services/auth_service.dart';
import '../providers/locale_provider.dart';
import '../l10n/app_localizations.dart';
import '../screens/app_colors.dart';
import '../widgets/smart_network_image/smart_network_image.dart';

class OfficerReportDetailsScreen extends StatefulWidget {
  final String reportId;
  const OfficerReportDetailsScreen({super.key, required this.reportId});

  @override
  State<OfficerReportDetailsScreen> createState() =>
      _OfficerReportDetailsScreenState();
}

class _OfficerReportDetailsScreenState
    extends State<OfficerReportDetailsScreen> {
  final OfficerService _officerService = OfficerService();
  String _selectedStatus = 'InProgress';
  final _noteController = TextEditingController();

  bool _isLoading = true;
  bool _isSubmitting = false;
  Map<String, dynamic>? _report;

  // Tracks which attachment is shown in the inline preview panel.
  int _selectedAttachmentIndex = 0;

  @override
  void initState() {
    super.initState();
    _fetchReportDetails();
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _fetchReportDetails() async {
    final loc = AppLocalizations.of(context);
    try {
      final reportData =
          await _officerService.getReportDetails(widget.reportId);
      if (mounted) {
        setState(() {
          _report = reportData;
          _selectedStatus = reportData['status'] ?? 'InProgress';
          if (reportData['officerNote'] != null) {
            _noteController.text = reportData['officerNote'];
          }
          _selectedAttachmentIndex = 0;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${loc?.translate('failedToLoadReport') ?? 'Failed to load report'}: $e')));
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _submitUpdate() async {
    final loc = AppLocalizations.of(context);
    setState(() => _isSubmitting = true);
    try {
      await _officerService.updateReportStatus(
          widget.reportId, _selectedStatus, _noteController.text);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(loc?.translate('statusUpdatedSuccess') ?? 'Status updated successfully!'),
            backgroundColor: AppColors.statusResolved));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('${loc?.translate('updateFailed') ?? 'Update failed'}: $e'),
            backgroundColor: AppColors.statusRejected));
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  String _resolveUrl(String url) {
    if (url.startsWith('http')) return url;
    final baseUrl = AuthService.baseUrl.endsWith('/')
        ? AuthService.baseUrl.substring(0, AuthService.baseUrl.length - 1)
        : AuthService.baseUrl;
    final path = url.startsWith('/') ? url : '/$url';
    return '$baseUrl$path';
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final localeProvider = Provider.of<LocaleProvider>(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('${loc?.translate('reportDetailsTitle') ?? 'Report'} #${widget.reportId}',
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.w600)),
        flexibleSpace: Container(
          decoration: const BoxDecoration(gradient: AppColors.headerGradient),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.language, color: Colors.white),
            tooltip: loc?.translate('toggleLanguage') ?? 'Switch Language',
            onPressed: () => localeProvider.toggleLanguage(),
          ),
        ],
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.brightTealBlue))
          : _report == null
              ? Center(
                  child: Text(loc?.translate('reportNotFound') ?? 'Report not found.',
                      style: const TextStyle(color: AppColors.textSecondary)))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Location Header
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.lightCyan,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.frostedBlue),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.location_on,
                                color: AppColors.brightTealBlue, size: 30),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(loc?.translate('location') ?? 'Location',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.frenchBlue)),
                                  Text(
                                      _report!['location'] ??
                                          (loc?.translate('locationUnknown') ?? 'Location unknown'),
                                      style: const TextStyle(
                                          color: AppColors.textPrimary)),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.map,
                                  color: AppColors.brightTealBlue),
                              onPressed: () async {
                                final location = _report!['location'] ?? '';
                                final Uri url = Uri.parse(
                                    "https://www.google.com/maps/search/?api=1&query=$location");
                                if (!await launchUrl(url,
                                    mode: LaunchMode.externalApplication)) {
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                            content: Text(loc?.translate('couldNotOpenMaps') ??
                                                'Could not open maps')));
                                  }
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Description
                      Text(loc?.translate('description') ?? 'Description',
                          style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary)),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                                color: AppColors.brightTealBlue
                                    .withValues(alpha: 0.08),
                                blurRadius: 10)
                          ],
                        ),
                        child: Text(
                            _report!['descriptionText'] ?? '',
                            style: const TextStyle(
                                fontSize: 16, color: AppColors.textPrimary)),
                      ),
                      const SizedBox(height: 24),

                      // Evidence
                      Text(loc?.translate('evidence') ?? 'Evidence',
                          style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary)),
                      const SizedBox(height: 8),
                      _buildEvidenceSection(loc),

                      const SizedBox(height: 32),

                      // Status Update Section
                      Text(loc?.translate('updateStatus') ?? 'Update Status',
                          style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary)),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: [
                          'Submitted',
                          'InProgress',
                          'Resolved',
                          'Rejected'
                        ].contains(_selectedStatus)
                            ? _selectedStatus
                            : 'Submitted',
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                  color: AppColors.frostedBlue)),
                          enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                  color: AppColors.frostedBlue)),
                          focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                  color: AppColors.brightTealBlue, width: 2)),
                          filled: true,
                          fillColor: AppColors.surface,
                        ),
                        items: [
                          'Submitted',
                          'InProgress',
                          'Resolved',
                          'Rejected'
                        ]
                            .map((s) => DropdownMenuItem(
                                  value: s,
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 10,
                                        height: 10,
                                        margin: const EdgeInsets.only(right: 8),
                                        decoration: BoxDecoration(
                                            color: AppColors.statusColor(s),
                                            shape: BoxShape.circle),
                                      ),
                                      Text(loc?.translate('status_${s.toLowerCase()}') ?? s),
                                    ],
                                  ),
                                ))
                            .toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() => _selectedStatus = val);
                          }
                        },
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _noteController,
                        maxLines: 4,
                        style: const TextStyle(color: AppColors.textPrimary),
                        decoration: InputDecoration(
                          hintText: loc?.translate('officerNotesHint') ??
                              'Write officer notes here...',
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                  color: AppColors.frostedBlue)),
                          enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                  color: AppColors.frostedBlue)),
                          focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                  color: AppColors.brightTealBlue, width: 2)),
                          filled: true,
                          fillColor: AppColors.surface,
                        ),
                      ),
                      const SizedBox(height: 24),
                      DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: AppColors.headerGradient,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color:
                                  AppColors.deepTwilight.withValues(alpha: 0.3),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: _isSubmitting ? null : _submitUpdate,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                          ),
                          child: _isSubmitting
                              ? const SizedBox(
                                  height: 22,
                                  width: 22,
                                  child: CircularProgressIndicator(
                                      color: Colors.white, strokeWidth: 2.5))
                              : Text(loc?.translate('submitUpdate') ?? 'Submit Update',
                                  style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold)),
                        ),
                      )
                    ],
                  ),
                ),
    );
  }

  Widget _buildEvidenceSection(AppLocalizations? loc) {
    final attachments = (_report!['attachments'] as List?) ?? [];

    if (attachments.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.frostedBlue),
        ),
        child: Text(
          loc?.translate('noEvidence') ?? 'No evidence attached to this report.',
          style: const TextStyle(
              color: AppColors.textSecondary, fontStyle: FontStyle.italic),
        ),
      );
    }

    final safeIndex = _selectedAttachmentIndex.clamp(0, attachments.length - 1);
    final selected = attachments[safeIndex] as Map<String, dynamic>;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Container(
            color: AppColors.deepTwilight,
            constraints: const BoxConstraints(minHeight: 220, maxHeight: 340),
            child: _buildPreview(selected),
          ),
        ),
        const SizedBox(height: 12),
        if (attachments.length > 1)
          SizedBox(
            height: 64,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: attachments.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                final att = attachments[index] as Map<String, dynamic>;
                final bool isSelected = index == safeIndex;
                final bool isVideo = att['fileType'] == 'video';
                return GestureDetector(
                  onTap: () => setState(() => _selectedAttachmentIndex = index),
                  child: Container(
                    width: 64,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.brightTealBlue
                            : AppColors.frostedBlue,
                        width: isSelected ? 2.5 : 1.5,
                      ),
                      color: AppColors.lightCyan,
                    ),
                    child: Center(
                      child: Icon(
                        isVideo ? Icons.videocam : Icons.image,
                        color: isSelected
                            ? AppColors.brightTealBlue
                            : AppColors.textSecondary,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        const SizedBox(height: 4),
        Text(
          '${loc?.translate('attachment') ?? 'Attachment'} ${safeIndex + 1} ${loc?.translate('of') ?? 'of'} ${attachments.length} · ${selected['fileType'] ?? 'file'}',
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
        ),
      ],
    );
  }

  String? _getAttachmentUrl(Map<String, dynamic> attachment) {
    final downloadUrl = attachment['downloadUrl'] as String?;
    if (downloadUrl != null && downloadUrl.trim().isNotEmpty) {
      return downloadUrl;
    }
    final blobUri = attachment['blobStorageUri'] as String?;
    if (blobUri != null && blobUri.trim().isNotEmpty) {
      return blobUri;
    }
    final filePath = attachment['filePath'] as String? ?? attachment['url'] as String?;
    if (filePath != null && filePath.trim().isNotEmpty) {
      return filePath;
    }
    return null;
  }

  Widget _buildPreview(Map<String, dynamic> attachment) {
    final bool isVideo = attachment['fileType'] == 'video';
    final primaryRawUrl = _getAttachmentUrl(attachment);

    if (primaryRawUrl == null) {
      return const Center(
        child: Text('Attachment URL unavailable.',
            style: TextStyle(color: Colors.white70)),
      );
    }

    final primaryUrl = _resolveUrl(primaryRawUrl);

    if (isVideo) {
      return _InlineVideoPlayer(key: ValueKey(primaryUrl), url: primaryUrl);
    }

    final fallbackRawUrl = attachment['blobStorageUri'] as String?;
    final fallbackUrl = (fallbackRawUrl != null && fallbackRawUrl.isNotEmpty) 
        ? _resolveUrl(fallbackRawUrl) 
        : null;

    return SmartNetworkImage(
      url: primaryUrl,
      fit: BoxFit.contain,
      width: double.infinity,
      headers: const {'Accept': 'image/*'},
      loadingBuilder: (context) => const Center(
        child: CircularProgressIndicator(color: AppColors.skyAqua),
      ),
      errorBuilder: (context, error, stackTrace) {
        debugPrint('Failed to load image from primaryUrl: $primaryUrl. Error: $error');
        
        if (fallbackUrl != null && fallbackUrl != primaryUrl) {
          return SmartNetworkImage(
            url: fallbackUrl,
            fit: BoxFit.contain,
            width: double.infinity,
            headers: const {'Accept': 'image/*'},
            loadingBuilder: (ctx) => const Center(
              child: CircularProgressIndicator(color: AppColors.skyAqua),
            ),
            errorBuilder: (ctx, err, stack) => _buildImageErrorWidget(error.toString()),
          );
        }

        return _buildImageErrorWidget(error.toString());
      },
    );
  }

  Widget _buildImageErrorWidget(String errorDetails) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.broken_image_outlined, color: Colors.white70, size: 44),
          const SizedBox(height: 8),
          const Text(
            'Failed to load image.',
            style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 13),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            errorDetails,
            style: const TextStyle(color: Colors.white38, fontSize: 10),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
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
        child: Text('Failed to load video.',
            style: TextStyle(color: Colors.white70)),
      );
    }

    if (!_controller.value.isInitialized) {
      return const Center(
          child: CircularProgressIndicator(color: AppColors.skyAqua));
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
          IconButton(
            icon: Icon(
                _controller.value.isPlaying
                    ? Icons.pause_circle_filled
                    : Icons.play_circle_fill,
                color: Colors.white,
                size: 44),
            onPressed: () => setState(() => _controller.value.isPlaying
                ? _controller.pause()
                : _controller.play()),
          ),
        ],
      ),
    );
  }
}
