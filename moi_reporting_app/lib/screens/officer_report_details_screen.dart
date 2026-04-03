import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';
import '../services/officer_service.dart';
import '../services/location_service.dart';

class OfficerReportDetailsScreen extends StatefulWidget {
  final String reportId;
  const OfficerReportDetailsScreen({super.key, required this.reportId});

  @override
  State<OfficerReportDetailsScreen> createState() => _OfficerReportDetailsScreenState();
}

class _OfficerReportDetailsScreenState extends State<OfficerReportDetailsScreen> {
  final OfficerService _officerService = OfficerService();
  String _selectedStatus = 'InProgress';
  final _noteController = TextEditingController();
  
  bool _isLoading = true;
  bool _isSubmitting = false;
  Map<String, dynamic>? _report;

  @override
  void initState() {
    super.initState();
    _fetchReportDetails();
  }
  
  Future<void> _fetchReportDetails() async {
    try {
      final reportData = await _officerService.getReportDetails(widget.reportId);
      if (mounted) {
        setState(() {
          _report = reportData;
          _selectedStatus = reportData['status'] ?? 'InProgress';
          if (reportData['officerNote'] != null) {
            _noteController.text = reportData['officerNote'];
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to load report: \$e')));
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _submitUpdate() async {
    setState(() => _isSubmitting = true);
    try {
      await _officerService.updateReportStatus(widget.reportId, _selectedStatus, _noteController.text);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Status updated successfully!'), backgroundColor: Colors.green));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Update failed: \$e'), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Report \${widget.reportId}', style: const TextStyle(color: Colors.white)),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF0F2027), Color(0xFF203A43)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator()) 
        : _report == null 
          ? const Center(child: Text('Report not found.'))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Location Header
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blueGrey.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blueGrey.shade200),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.location_on, color: Colors.blueGrey, size: 30),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Location', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey)),
                              Text(_report!['location'] ?? 'Location unknown'),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.map, color: Colors.blue),
                          onPressed: () async {
                            final location = _report!['location'] ?? '';
                            final Uri url = Uri.parse("https://www.google.com/maps/search/?api=1&query=$location");
                            if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not open maps')));
                              }
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Description
                  const Text('Description', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
                    ),
                    child: Text(_report!['descriptionText'] ?? 'No Description provided.', style: const TextStyle(fontSize: 16)),
                  ),
                  const SizedBox(height: 24),

                  // Evidence Player
                  const Text('Evidence', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  if (_report!['attachments'] != null && (_report!['attachments'] as List).isNotEmpty)
                    ...(_report!['attachments'] as List).map((att) => 
                      _buildMediaTile(att)
                    ).toList()
                  else
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8.0),
                      child: Text('No evidence attached to this report.', style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic)),
                    ),
                    
                  const SizedBox(height: 32),

                  // Status Update Section
                  const Text('Update Status', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: ['Submitted', 'InProgress', 'Resolved', 'Rejected'].contains(_selectedStatus) ? _selectedStatus : 'Submitted',
                    decoration: InputDecoration(
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    items: ['Submitted', 'InProgress', 'Resolved', 'Rejected']
                        .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedStatus = val);
                    },
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _noteController,
                    maxLines: 4,
                    textDirection: TextDirection.rtl, // Support Arabic natively
                    decoration: InputDecoration(
                      hintText: 'اكتب ملاحظاتك هنا...', // Arabic Instruction
                      hintTextDirection: TextDirection.rtl,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _isSubmitting ? null : _submitUpdate,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2C5364),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _isSubmitting 
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('Submit Update', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  )
                ],
              ),
            ),
    );
  }

  Widget _buildMediaTile(Map<String, dynamic> att) {
    bool isVideo = att['fileType'] == 'video';
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade100),
      ),
      child: ListTile(
        leading: Icon(
          isVideo ? Icons.video_library : Icons.image,
          color: Colors.blue.shade800,
        ),
        title: Text('Attachment: ${att["fileType"]}'),
        subtitle: const Text('Tap to view evidence'),
        trailing: const Icon(Icons.play_circle_fill, color: Colors.blue),
        onTap: () => _showMediaDialog(att['downloadUrl'], isVideo),
      ),
    );
  }

  void _showMediaDialog(String url, bool isVideo) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        contentPadding: EdgeInsets.zero,
        content: isVideo ? _VideoPlayerWidget(url: url) : Image.network(url),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
        ],
      ),
    );
  }
}

class _VideoPlayerWidget extends StatefulWidget {
  final String url;
  const _VideoPlayerWidget({required this.url});

  @override
  State<_VideoPlayerWidget> createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<_VideoPlayerWidget> {
  late VideoPlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.url))
      ..initialize().then((_) => setState(() {}));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _controller.value.isInitialized
        ? AspectRatio(
            aspectRatio: _controller.value.aspectRatio,
            child: Stack(
              alignment: Alignment.bottomCenter,
              children: [
                VideoPlayer(_controller),
                VideoProgressIndicator(_controller, allowScrubbing: true),
                IconButton(
                  icon: Icon(_controller.value.isPlaying ? Icons.pause : Icons.play_arrow, color: Colors.white, size: 40),
                  onPressed: () => setState(() => _controller.value.isPlaying ? _controller.pause() : _controller.play()),
                ),
              ],
            ),
          )
        : const SizedBox(height: 200, child: Center(child: CircularProgressIndicator()));
  }
}
