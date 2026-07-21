import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import '../providers/auth_provider.dart';
import '../services/officer_service.dart';
import '../theme/app_colors.dart';
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
          const SnackBar(content: Text('Error fetching location: \$e'), backgroundColor: Colors.red),
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
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error loading dashboard: \$e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 190.0,
            floating: false,
            pinned: true,
            backgroundColor: AppColors.deepTwilight,
            flexibleSpace: Container(
              decoration: const BoxDecoration(
                gradient: AppColors.headerGradient,
              ),
              child: FlexibleSpaceBar(
                title: const Text('Officer Dashboard', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                background: Stack(
                  children: [
                    Positioned(
                      right: -30,
                      top: -20,
                      child: Icon(Icons.shield, size: 150, color: Colors.white.withValues(alpha: 0.08)),
                    ),
                    Positioned(
                      left: -20,
                      bottom: -30,
                      child: Icon(Icons.water_drop, size: 110, color: AppColors.skyAqua.withValues(alpha: 0.18)),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 20.0, bottom: 60.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Greetings, Officer', style: TextStyle(color: Colors.white.withValues(alpha: 0.75), fontSize: 16)),
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
                    child: Center(child: CircularProgressIndicator(color: AppColors.brightTealBlue)),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 20),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 20.0),
                        child: Text('Live Statistics', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                      ),
                      const SizedBox(height: 12),
                      _buildStatsRow(),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 20.0),
                            child: Text('Nearby Reports', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                          ),
                          IconButton(
                            icon: const Icon(Icons.refresh, color: AppColors.brightTealBlue),
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
                    child: Center(child: Text('No nearby reports found in your active service area.', style: TextStyle(color: AppColors.textSecondary))),
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
          const SliverToBoxAdapter(child: SizedBox(height: 20)),
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
          Expanded(child: _buildStatCard('Submitted', _stats['Submitted'] ?? 0, [AppColors.frenchBlue, AppColors.deepTwilight], Icons.assignment)),
          const SizedBox(width: 8),
          Expanded(child: _buildStatCard('Execution', _stats['InProgress'] ?? 0, [AppColors.turquoiseSurf, AppColors.blueGreen], Icons.pending_actions)),
          const SizedBox(width: 8),
          Expanded(child: _buildStatCard('Resolved', _stats['Resolved'] ?? 0, [AppColors.statusResolved, AppColors.blueGreen], Icons.check_circle_outline)),
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
            color: gradientColors[0].withValues(alpha: 0.35),
            blurRadius: 10,
            offset: const Offset(0, 5),
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
          Text(title, textAlign: TextAlign.center, style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildReportCard(BuildContext context, Map<String, dynamic> report) {
    final Color statusColor = AppColors.statusColor(report['status']);
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: AppColors.frostedBlue.withValues(alpha: 0.6)),
      ),
      elevation: 2,
      shadowColor: AppColors.brightTealBlue.withValues(alpha: 0.15),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => OfficerReportDetailsScreen(reportId: report['id']),
            ),
          ).then((_) => _fetchData()); // Refresh on return
        },
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: const BoxDecoration(
                  color: AppColors.lightCyan,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.report_problem, color: AppColors.brightTealBlue),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(report['title'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textPrimary)),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.location_on, size: 14, color: AppColors.textSecondary),
                        const SizedBox(width: 4),
                        Expanded(child: Text(report['location'], style: const TextStyle(color: AppColors.textSecondary, fontSize: 12), overflow: TextOverflow.ellipsis)),
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
                      color: statusColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      report['status'],
                      style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(report['date'], style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}
