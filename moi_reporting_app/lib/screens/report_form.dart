import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
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
  
  List<Uint8List> _selectedFileBytes = [];
  List<String> _selectedFileNames = [];
  bool _isLoading = false;
  bool _useCurrentLocation = true;
  String? _currentLocationText;

  // Voice recording
  final AudioRecorder _audioRecorder = AudioRecorder();
  bool _isRecording = false;
  bool _isTranscribing = false;

  final Map<String, String> _categories = {
    'environmental': 'Environmental',
    'infrastructure': 'Infrastructure',
    'utilities': 'Utilities',
    'crime': 'Crime',
    'traffic': 'Traffic',
    'public_nuisance': 'Public Nuisance',
    'other': 'Other',
  };

  Future<void> _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      withData: true,
      allowMultiple: true,
    );
    if (result != null) {
      setState(() {
        for (var file in result.files) {
          if (file.bytes != null && !_selectedFileNames.contains(file.name)) {
            _selectedFileBytes.add(file.bytes!);
            _selectedFileNames.add(file.name);
          }
        }
      });
    }
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isLoading = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw 'Location services are disabled.';
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw 'Location permissions are denied';
        }
      }
      
      if (permission == LocationPermission.deniedForever) {
        throw 'Location permissions are permanently denied';
      }

      Position position = await Geolocator.getCurrentPosition();
      setState(() {
        _currentLocationText = "${position.latitude}, ${position.longitude}";
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error getting location: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _submitReport() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = context.read<AuthProvider>();
    if (!auth.isAuthenticated) return;

    setState(() => _isLoading = true);

    String finalLocation = _useCurrentLocation 
        ? (_currentLocationText ?? 'Unknown Location') 
        : _manualLocationController.text;

    if (_useCurrentLocation && _currentLocationText == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fetch current location first'), backgroundColor: Colors.orange),
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
        fileBytesList: _selectedFileBytes.isNotEmpty ? _selectedFileBytes : null,
        fileNamesList: _selectedFileNames.isNotEmpty ? _selectedFileNames : null,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Report submitted successfully!'), backgroundColor: Colors.green),
        );
        _formKey.currentState!.reset();
        _manualLocationController.clear();
        setState(() {
          _selectedFileBytes = [];
          _selectedFileNames = [];
          _currentLocationText = null;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}'), backgroundColor: Colors.red),
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
        await _audioRecorder.start(config, path: ''); 
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error starting recording: $e')),
      );
    }
  }

  Future<void> _stopRecording() async {
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
        String transcribedText = await ReportService().transcribeVoice(
          audioBytes, 
          'voice_recording.m4a', 
          auth.token!
        );

        setState(() {
          _descriptionController.text = "${_descriptionController.text} $transcribedText".trim();
          _isTranscribing = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Voice transcribed successfully')),
        );
      }
    } catch (e) {
      setState(() => _isTranscribing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Transcription error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('New Report', style: TextStyle(color: Colors.white)),
        backgroundColor: Theme.of(context).colorScheme.primary,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Submit an Incident',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Enter details below to report an issue to the MoI.',
                style: TextStyle(color: Colors.grey[600]),
              ),
              const SizedBox(height: 32),
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Title', prefixIcon: Icon(Icons.title)),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Please enter a title';
                  if (value.length < 3) return 'Title must be at least 3 characters';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: const InputDecoration(labelText: 'Category', prefixIcon: Icon(Icons.category)),
                items: _categories.entries.map((e) {
                  return DropdownMenuItem(value: e.key, child: Text(e.value));
                }).toList(),
                onChanged: (String? newValue) => setState(() => _selectedCategory = newValue!),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                maxLines: 4,
                decoration: const InputDecoration(labelText: 'Description', prefixIcon: Icon(Icons.description)),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Please enter a description';
                  if (value.length < 10) return 'Description must be at least 10 characters';
                  return null;
                },
              ),
              const SizedBox(height: 8),
              _buildVoiceRecordButton(),
              const SizedBox(height: 16),
              
              // NEW: Mock Location Picker
              _buildLocationPicker(),
              
              const SizedBox(height: 24),
              
              // File Picker Section
              _buildFilePicker(),

              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: _isLoading ? null : _submitReport,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 56),
                ),
                child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('Submit Report', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLocationPicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Use Current Location', style: TextStyle(fontWeight: FontWeight.bold)),
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
                    _currentLocationText ?? 'Press button to fetch location',
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
            decoration: const InputDecoration(
              labelText: 'Manual Location',
              hintText: 'Enter city or address',
              prefixIcon: Icon(Icons.edit_location),
            ),
          ),
      ],
    );
  }

  Widget _buildFilePicker() {
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
                  leading: const Icon(Icons.insert_drive_file, color: Colors.blue),
                  title: Text(_selectedFileNames[index], overflow: TextOverflow.ellipsis),
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
            label: const Text('Add More Files'),
          ),
        ],
      ),
    );
  }

  Widget _buildVoiceRecordButton() {
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
          onTap: _isTranscribing ? null : (_isRecording ? _stopRecording : _startRecording),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_isTranscribing)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.blue),
                )
              else
                Icon(
                  _isRecording ? Icons.stop_circle : Icons.mic,
                  color: _isRecording ? Colors.red : Colors.blue,
                ),
              const SizedBox(width: 8),
              if (_isTranscribing)
                const Text('Transcribing voice...', style: TextStyle(color: Colors.blue, fontSize: 13))
              else
                Text(
                  _isRecording ? 'Stop Recording' : 'Record Description',
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
}
