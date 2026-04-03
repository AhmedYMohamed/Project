import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import '../providers/auth_provider.dart';
import '../services/officer_service.dart';
import 'officer_report_details_screen.dart';
import 'officer_map_screen.dart';
import '../services/location_service.dart';

class OfficerDashboardScreen extends StatefulWidget {
  const OfficerDashboardScreen({super.key});

  @override
  State<OfficerDashboardScreen> createState() => _OfficerDashboardScreenState();
}

class _OfficerDashboardScreenState extends State<OfficerDashboardScreen> {
  final OfficerService _officerService = OfficerService();
  bool _isLoading = false;
  Map<String, int> _stats = {
    'Submitted': 0,
    'InProgress': 0,
    'Resolved': 0,
  };
  
  List<Map<String, dynamic>> _nearbyReports = [];
  double? _currentLat;
  double? _currentLon;
  String _locationStatus = 'Fetching location...';

  @override
  void initState() {
    super.initState();
    _fetchLocationAndData();
  }

  Future<void> _getCurrentLocation() async {
    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          setState(() => _locationStatus = 'Location services disabled');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location services are disabled. Please enable them.'), backgroundColor: Colors.orange),
          );
        }
        return;
      }

      // Check location permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            setState(() => _locationStatus = 'Location permission denied');
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Location permission is required'), backgroundColor: Colors.orange),
            );
          }
          return;
        }
      }
      
      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          setState(() => _locationStatus = 'Location permission permanently denied');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location permission is permanently denied. Please enable it in app settings.'), backgroundColor: Colors.orange),
          );
        }
        return;
      }

      // Get current position
      final Position position = await LocationService.getCurrentLocation();

      String addressName = '${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}';
      
      final fetchedName = await _officerService.getLocationName(position.latitude, position.longitude);
      if (fetchedName != null && fetchedName.isNotEmpty) {
        addressName = fetchedName;
      }

      if (mounted) {
        setState(() {
          _currentLat = position.latitude;
          _currentLon = position.longitude;
          _locationStatus = 'Zone: $addressName';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _locationStatus = 'Error fetching location');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error fetching location: \$e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _fetchLocationAndData() async {
    setState(() => _isLoading = true);
    
    // First, fetch the officer's current location
    await _getCurrentLocation();
    
    // Then fetch data using the location
    await _fetchData();
  }

  Future<void> _fetchData() async {
    try {
      final statsData = await _officerService.getDashboardStats();
      final reportsData = await _officerService.getNearbyReports(
        latitude: _currentLat,
        longitude: _currentLon,
      );
      
      if (mounted) {
        setState(() {
          _stats = Map<String, int>.from(statsData);
          _nearbyReports = reportsData.map((e) => {
            'id': e['reportId'].toString(),
            'title': e['title'] ?? 'No Title',
            'location': e['location'] ?? 'Unknown Location',
            'status': e['status'] ?? 'Submitted',
            'latitude': e['latitude'],
            'longitude': e['longitude'],
            'date': e['createdAt'] != null ? DateTime.parse(e['createdAt']).toLocal().toString().split(' ')[0] : 'N/A',
          }).toList();
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error loading dashboard: \$e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 180.0,
            floating: false,
            pinned: true,
            flexibleSpace: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF0F2027), Color(0xFF203A43), Color(0xFF2C5364)],
                ),
              ),
              child: FlexibleSpaceBar(
                title: const Text('Officer Dashboard', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                background: Stack(
                  children: [
                    Positioned(
                      right: -30,
                      top: -20,
                      child: Icon(Icons.shield, size: 150, color: Colors.white.withOpacity(0.1)),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 20.0, bottom: 60.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Greetings, Officer', style: TextStyle(color: Colors.white70, fontSize: 16)),
                          Text(_locationStatus, style: const TextStyle(color: Colors.white, fontSize: 14)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh, color: Colors.white),
                onPressed: _fetchLocationAndData,
                tooltip: 'Refresh location and reports',
              ),
              IconButton(
                icon: const Icon(Icons.map_outlined, color: Colors.white),
                onPressed: () {
                  if (_currentLat != null && _currentLon != null) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => OfficerMapScreen(
                          reports: _nearbyReports,
                          initialLat: _currentLat!,
                          initialLon: _currentLon!,
                        ),
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Wait for location to be fetched...'))
                    );
                  }
                },
                tooltip: 'View Reports on Map',
              ),
              IconButton(
                icon: const Icon(Icons.logout, color: Colors.white),
                onPressed: () {
                  context.read<AuthProvider>().logout();
                },
              )
            ],
          ),
          SliverToBoxAdapter(
            child: _isLoading 
                ? const Padding(
                    padding: EdgeInsets.all(40.0),
                    child: Center(child: CircularProgressIndicator()),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 16),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 20.0),
                        child: Text('Live Statistics', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(height: 12),
                      _buildStatsRow(),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 20.0),
                            child: Text('Nearby Reports', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                          ),
                          IconButton(
                            icon: const Icon(Icons.refresh),
                            onPressed: _fetchLocationAndData,
                            tooltip: 'Refresh location and reports',
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),
          ),
          if (!_isLoading)
            _nearbyReports.isEmpty 
              ? const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(40.0),
                    child: Center(child: Text('No nearby reports found in your active service area.', style: TextStyle(color: Colors.grey))),
                  ),
                )
              : SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final report = _nearbyReports[index];
                      return _buildReportCard(context, report);
                    },
                    childCount: _nearbyReports.length,
                  ),
                ),
        ],
      ),
    );
  }

  Widget _buildStatsRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Expanded(child: _buildStatCard('Submitted', _stats['Submitted'] ?? 0, [const Color(0xFF4b6cb7), const Color(0xFF182848)], Icons.assignment)),
          const SizedBox(width: 8),
          Expanded(child: _buildStatCard('Execution', _stats['InProgress'] ?? 0, [const Color(0xFFF2994A), const Color(0xFFF2C94C)], Icons.pending_actions)),
          const SizedBox(width: 8),
          Expanded(child: _buildStatCard('Resolved', _stats['Resolved'] ?? 0, [const Color(0xFF11998e), const Color(0xFF38ef7d)], Icons.check_circle_outline)),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, int value, List<Color> gradientColors, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 8.0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradientColors,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: gradientColors[0].withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.white, size: 24),
          const SizedBox(height: 8),
          Text(value.toString(), style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(title, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildReportCard(BuildContext context, Map<String, dynamic> report) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 3,
      shadowColor: Colors.black12,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => OfficerReportDetailsScreen(reportId: report['id']),
            ),
          ).then((_) => _fetchData()); // Refresh on return
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.report_problem, color: Colors.blueGrey),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(report['title'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.location_on, size: 14, color: Colors.grey),
                        const SizedBox(width: 4),
                        Expanded(child: Text(report['location'], style: const TextStyle(color: Colors.grey, fontSize: 12), overflow: TextOverflow.ellipsis)),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getStatusColor(report['status']).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      report['status'],
                      style: TextStyle(color: _getStatusColor(report['status']), fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(report['date'], style: const TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'submitted':
        return Colors.blue;
      case 'inprogress':
        return Colors.orange;
      case 'resolved':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
}
