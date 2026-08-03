import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'dart:typed_data';
import 'package:geolocator/geolocator.dart';
import 'package:record/record.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io' as io;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import '../services/report_service.dart';
import '../providers/auth_provider.dart';
import '../l10n/app_localizations.dart';
import '../services/location_service.dart';
import '../widgets/language_switcher_button.dart';

class ReportFormScreen extends StatefulWidget {
  const ReportFormScreen({super.key});

  @override
  State<ReportFormScreen> createState() => _ReportFormScreenState();
}

class _ReportFormScreenState extends State<ReportFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _manualLocationController = TextEditingController();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _selectedCategory = 'environmental';
  bool _sendToLawyer = false;

  List<Uint8List> _selectedFileBytes = [];
  List<String> _selectedFileNames = [];
  bool _isLoading = false;
  bool _useCurrentLocation = true;
  String? _currentLocationText;

  // Voice recording
  final AudioRecorder _audioRecorder = AudioRecorder();
  bool _isRecording = false;
  bool _isTranscribing = false;

  final List<String> _categoryKeys = const [
    'environmental',
    'infrastructure',
    'utilities',
    'crime',
    'traffic',
    'public_nuisance',
    'other',
  ];

  Future<void> _pickFile() async {
    final loc = AppLocalizations.of(context);
    final ImagePicker picker = ImagePicker();
    final List<XFile> pickedFiles = await picker.pickMultipleMedia();

    if (pickedFiles.isNotEmpty) {
      for (var file in pickedFiles) {
        final bytes = await file.readAsBytes();
        final fileName = file.name;
        final fileSize = await file.length();

        if (_selectedFileNames.contains(fileName)) continue;

        if (_selectedFileNames.length >= 5) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(loc?.translate('maxFilesAllowed') ?? 'Maximum 5 files allowed'),
                backgroundColor: Colors.red,
              ),
            );
          }
          break;
        }

        const maxFileSize = 10 * 1024 * 1024; // 10MB limit
        if (fileSize > maxFileSize) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(loc?.translate('fileTooLarge') ?? 'File is too large. Max size: 10MB'),
                backgroundColor: Colors.red,
              ),
            );
          }
          continue;
        }

        setState(() {
          _selectedFileBytes.add(bytes);
          _selectedFileNames.add(fileName);
        });
      }
    }
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isLoading = true);
    try {
      Position position = await LocationService.getCurrentLocation();
      setState(() {
        _currentLocationText = "${position.latitude}, ${position.longitude}";
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error getting location: $e'),
              backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _submitReport() async {
    final loc = AppLocalizations.of(context);
    if (!_formKey.currentState!.validate()) return;

    final auth = context.read<AuthProvider>();
    if (!auth.isAuthenticated) return;

    setState(() => _isLoading = true);

    String finalLocation = _useCurrentLocation
        ? (_currentLocationText ?? 'Unknown Location')
        : _manualLocationController.text;

    if (_useCurrentLocation && _currentLocationText == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(loc?.translate('fetchLocationFirst') ??
              'Please fetch current location first'),
          backgroundColor: Colors.orange,
        ),
      );
      setState(() => _isLoading = false);
      return;
    }

    try {
      await ReportService().createReport(
        title: _titleController.text,
        description: _descriptionController.text,
        categoryId: _selectedCategory,
        token: auth.token!,
        location: finalLocation,
        sendToLawyer: _sendToLawyer,
        fileBytesList:
            _selectedFileBytes.isNotEmpty ? _selectedFileBytes : null,
        fileNamesList:
            _selectedFileNames.isNotEmpty ? _selectedFileNames : null,
      );

      // Refresh reports cache in background
      try {
        await ReportService().getUserReports(auth.token!, auth.userId!);
      } catch (_) {}

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(loc?.translate('reportSubmittedSuccess') ??
                'Report submitted successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        _formKey.currentState!.reset();
        _manualLocationController.clear();
        setState(() {
          _selectedFileBytes = [];
          _selectedFileNames = [];
          _currentLocationText = null;
          _sendToLawyer = false;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        String errorMsg = e.toString();
        if (errorMsg.contains('No lawyer linked') ||
            errorMsg.contains('do not have a linked lawyer')) {
          errorMsg = loc?.translate('noLawyerLinkedWarning') ??
              'No lawyer linked to your account. Please link a lawyer in your profile or select Officer.';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMsg), backgroundColor: Colors.red),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _audioRecorder.dispose();
    _manualLocationController.dispose();
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _startRecording() async {
    try {
      if (!kIsWeb) {
        var status = await Permission.microphone.request();
        if (status != PermissionStatus.granted) {
          throw 'Microphone permission denied';
        }
      }

      if (await _audioRecorder.hasPermission()) {
        const config = RecordConfig();
        setState(() => _isRecording = true);
        String recordPath = '';
        if (!kIsWeb) {
          final tempDir = await getTemporaryDirectory();
          recordPath = '${tempDir.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
        }
        await _audioRecorder.start(config, path: recordPath);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error starting recording: $e')),
      );
    }
  }

  Future<void> _stopRecording() async {
    final loc = AppLocalizations.of(context);
    try {
      final path = await _audioRecorder.stop();
      setState(() {
        _isRecording = false;
        _isTranscribing = true;
      });

      if (path != null) {
        Uint8List audioBytes;
        if (kIsWeb) {
          final response = await http.get(Uri.parse(path));
          audioBytes = response.bodyBytes;
        } else {
          audioBytes = await io.File(path).readAsBytes();
        }

        final auth = context.read<AuthProvider>();
        String transcribedText = await ReportService()
            .transcribeVoice(audioBytes, 'voice_recording.m4a', auth.token!);

        setState(() {
          _descriptionController.text =
              "${_descriptionController.text} $transcribedText".trim();
          _isTranscribing = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(loc?.translate('voiceTranscribedSuccess') ??
                'Voice transcribed successfully'),
          ),
        );
      }
    } catch (e) {
      setState(() => _isTranscribing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Transcription error: $e'),
            backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(loc?.translate('newReport') ?? 'New Report',
            style: const TextStyle(color: Colors.white)),
        backgroundColor: Theme.of(context).colorScheme.primary,
        elevation: 0,
        actions: const [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
            child: LanguageSwitcherButton(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                loc?.translate('submitIncident') ?? 'Submit an Incident',
                style:
                    const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                loc?.translate('enterDetailsSub') ??
                    'Enter details below to report an issue to the MoI.',
                style: TextStyle(color: Colors.grey[600]),
              ),
              const SizedBox(height: 32),
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: loc?.translate('title') ?? 'Title',
                  prefixIcon: const Icon(Icons.title),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return loc?.translate('pleaseEnterTitle') ??
                        'Please enter a title';
                  }
                  if (value.length < 3) {
                    return loc?.translate('titleMinChars') ??
                        'Title must be at least 3 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _selectedCategory,
                decoration: InputDecoration(
                  labelText: loc?.translate('category') ?? 'Category',
                  prefixIcon: const Icon(Icons.category),
                ),
                items: _categoryKeys.map((catKey) {
                  final label = loc?.translate('cat_$catKey') ?? catKey;
                  return DropdownMenuItem(value: catKey, child: Text(label));
                }).toList(),
                onChanged: (String? newValue) =>
                    setState(() => _selectedCategory = newValue!),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                maxLines: 4,
                decoration: InputDecoration(
                  labelText: loc?.translate('description') ?? 'Description',
                  prefixIcon: const Icon(Icons.description),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return loc?.translate('pleaseEnterDesc') ??
                        'Please enter a description';
                  }
                  if (value.length < 10) {
                    return loc?.translate('descMinChars') ??
                        'Description must be at least 10 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 8),
              _buildVoiceRecordButton(loc),
              const SizedBox(height: 16),

              // Location Picker
              _buildLocationPicker(loc),

              const SizedBox(height: 24),

              // File Picker Section
              _buildFilePicker(loc),

              const SizedBox(height: 24),

              // Recipient Selector Section (Officer vs Lawyer)
              _buildRecipientSelector(loc),

              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _isLoading ? null : _submitReport,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 56),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                        loc?.translate('submitReport') ?? 'Submit Report',
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLocationPicker(AppLocalizations? loc) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              loc?.translate('useCurrentLocation') ?? 'Use Current Location',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            Switch(
              value: _useCurrentLocation,
              onChanged: (val) {
                setState(() {
                  _useCurrentLocation = val;
                  if (val && _currentLocationText == null) {
                    _getCurrentLocation();
                  }
                });
              },
            ),
          ],
        ),
        if (_useCurrentLocation)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue[100]!),
            ),
            child: Row(
              children: [
                const Icon(Icons.my_location, color: Colors.blue),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    _currentLocationText ??
                        (loc?.translate('pressToFetchLocation') ??
                            'Press button to fetch location'),
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh, color: Colors.blue),
                  onPressed: _getCurrentLocation,
                ),
              ],
            ),
          )
        else
          TextFormField(
            controller: _manualLocationController,
            decoration: InputDecoration(
              labelText: loc?.translate('manualLocation') ?? 'Manual Location',
              hintText: loc?.translate('enterCityOrAddress') ??
                  'Enter city or address',
              prefixIcon: const Icon(Icons.edit_location),
            ),
          ),
      ],
    );
  }

  Widget _buildFilePicker(AppLocalizations? loc) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        children: [
          if (_selectedFileNames.isNotEmpty) ...[
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _selectedFileNames.length,
              itemBuilder: (context, index) {
                return ListTile(
                  leading:
                      const Icon(Icons.insert_drive_file, color: Colors.blue),
                  title: Text(_selectedFileNames[index],
                      overflow: TextOverflow.ellipsis),
                  trailing: IconButton(
                    icon: const Icon(Icons.remove_circle, color: Colors.red),
                    onPressed: () {
                      setState(() {
                        _selectedFileBytes.removeAt(index);
                        _selectedFileNames.removeAt(index);
                      });
                    },
                  ),
                );
              },
            ),
            const Divider(),
          ],
          ElevatedButton.icon(
            onPressed: _pickFile,
            icon: const Icon(Icons.add_to_photos),
            label: Text(loc?.translate('addMoreFiles') ?? 'Add More Files'),
          ),
        ],
      ),
    );
  }

  Widget _buildVoiceRecordButton(AppLocalizations? loc) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: _isRecording ? Colors.red[50] : Colors.grey[50],
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: _isRecording ? Colors.red[300]! : Colors.grey[300]!,
            width: 1,
          ),
        ),
        child: InkWell(
          onTap: _isTranscribing
              ? null
              : (_isRecording ? _stopRecording : _startRecording),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_isTranscribing)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.blue),
                )
              else
                Icon(
                  _isRecording ? Icons.stop_circle : Icons.mic,
                  color: _isRecording ? Colors.red : Colors.blue,
                ),
              const SizedBox(width: 8),
              if (_isTranscribing)
                Text(
                  loc?.translate('transcribing') ?? 'Transcribing voice...',
                  style: const TextStyle(color: Colors.blue, fontSize: 13),
                )
              else
                Text(
                  _isRecording
                      ? (loc?.translate('stopRecording') ?? 'Stop Recording')
                      : (loc?.translate('recordDescription') ??
                          'Record Description'),
                  style: TextStyle(
                    color: _isRecording ? Colors.red : Colors.blue,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecipientSelector(AppLocalizations? loc) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          loc?.translate('sendReportTo') ?? 'Send Report To',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildRecipientCard(
                title: loc?.translate('sendToOfficer') ?? 'Officer (Directly)',
                subtitle: loc?.translate('sendToOfficerDesc') ??
                    'Send directly to police officers',
                icon: Icons.local_police,
                isSelected: !_sendToLawyer,
                onTap: () => setState(() => _sendToLawyer = false),
                activeColor: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildRecipientCard(
                title: loc?.translate('sendToLawyer') ?? 'Your Lawyer (Review)',
                subtitle: loc?.translate('sendToLawyerDesc') ??
                    'Send to lawyer for review first',
                icon: Icons.gavel,
                isSelected: _sendToLawyer,
                onTap: () => setState(() => _sendToLawyer = true),
                activeColor: Colors.amber[800]!,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRecipientCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
    required Color activeColor,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? activeColor.withValues(alpha: 0.08)
              : Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? activeColor : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(icon,
                size: 32, color: isSelected ? activeColor : Colors.grey[600]),
            const SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: isSelected ? activeColor : Colors.black87,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
