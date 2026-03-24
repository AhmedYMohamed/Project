import 'package:flutter/material.dart';

class OfficerReportDetailsScreen extends StatefulWidget {
  final String reportId;
  const OfficerReportDetailsScreen({super.key, required this.reportId});

  @override
  State<OfficerReportDetailsScreen> createState() => _OfficerReportDetailsScreenState();
}

class _OfficerReportDetailsScreenState extends State<OfficerReportDetailsScreen> {
  String _selectedStatus = 'InProgress';
  final _noteController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Report ${widget.reportId}', style: const TextStyle(color: Colors.white)),
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
      body: SingleChildScrollView(
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
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Location', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey)),
                        Text('Cairo, Nasr City (Tap to Navigate)'),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.map, color: Colors.blue),
                    onPressed: () {
                      // Navigate via maps
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Opening maps...')));
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
              child: const Text('A traffic light is broken at the main intersection, causing severe traffic jams. Needs immediate attention.', style: TextStyle(fontSize: 16)),
            ),
            const SizedBox(height: 24),

            // Evidence Player
            const Text('Evidence', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Container(
              height: 200,
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.play_circle_fill, color: Colors.white, size: 64),
                    SizedBox(height: 8),
                    Text('Play Video.mp4', style: TextStyle(color: Colors.white)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Status Update Section
            const Text('Update Status', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _selectedStatus,
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
              textDirection: TextDirection.rtl, // Support Arabic
              decoration: InputDecoration(
                hintText: 'اكتب ملاحظاتك هنا...', // Arabic support representation
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Status updated successfully!')));
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2C5364),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Submit Update', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            )
          ],
        ),
      ),
    );
  }
}
