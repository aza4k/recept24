import 'dart:async';
import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

class MapScreen extends StatefulWidget {
  final double pharmacyLat;
  final double pharmacyLng;
  final String pharmacyName;
  final String pharmacyAddress;
  final String pharmacyPhone;

  const MapScreen({
    super.key,
    required this.pharmacyLat,
    required this.pharmacyLng,
    required this.pharmacyName,
    required this.pharmacyAddress,
    this.pharmacyPhone = '',
  });

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> with TickerProviderStateMixin {
  late final MapController _mapController;
  Position? _userPosition;
  bool _loadingLocation = true;
  bool _loadingRoute = false;
  List<LatLng> _routePoints = [];
  double? _routeDistanceKm;
  int? _routeDurationMin;
  late AnimationController _pulseAnim;
  late AnimationController _slideAnim;
  StreamSubscription<Position>? _positionStream;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _pulseAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _slideAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..forward();
    _getUserLocation();
  }

  @override
  void dispose() {
    _pulseAnim.dispose();
    _slideAnim.dispose();
    _mapController.dispose();
    _positionStream?.cancel();
    super.dispose();
  }

  Future<void> _getUserLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.whileInUse || permission == LocationPermission.always) {
        final pos = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
        );
        if (mounted) {
          setState(() {
            _userPosition = pos;
            _loadingLocation = false;
          });
          _fetchRoute(pos.latitude, pos.longitude);
          _startLiveTracking();
        }
      } else {
        if (mounted) setState(() => _loadingLocation = false);
      }
    } catch (_) {
      if (mounted) setState(() => _loadingLocation = false);
    }
  }

  void _startLiveTracking() {
    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10, // har 10 metrda yangilanadi
      ),
    ).listen((pos) {
      if (mounted) {
        setState(() => _userPosition = pos);
        // Har 500m da marshrutni yangilaymiz
        _fetchRoute(pos.latitude, pos.longitude);
      }
    });
  }

  /// OSRM API orqali haqiqiy yo'llar bo'ylab marshrut olish
  Future<void> _fetchRoute(double userLat, double userLng) async {
    if (_loadingRoute) return;
    setState(() => _loadingRoute = true);

    try {
      final url = 'https://router.project-osrm.org/route/v1/driving/'
          '$userLng,$userLat;${widget.pharmacyLng},${widget.pharmacyLat}'
          '?overview=full&geometries=geojson&steps=true';

      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['routes'] != null && (data['routes'] as List).isNotEmpty) {
          final route = data['routes'][0];
          final geometry = route['geometry'];
          final coords = geometry['coordinates'] as List;

          final points = coords.map<LatLng>((c) => LatLng(
            (c[1] as num).toDouble(),
            (c[0] as num).toDouble(),
          )).toList();

          final distance = (route['distance'] as num).toDouble() / 1000; // km
          final duration = (route['duration'] as num).toDouble() / 60; // min

          if (mounted) {
            setState(() {
              _routePoints = points;
              _routeDistanceKm = distance;
              _routeDurationMin = duration.round();
              _loadingRoute = false;
            });
          }
          return;
        }
      }
    } catch (_) {}
    if (mounted) setState(() => _loadingRoute = false);
  }

  void _openYandexNavigator() async {
    final url = Uri.parse(
      'https://yandex.uz/maps/?rtext=${_userPosition?.latitude ?? ''},${_userPosition?.longitude ?? ''}~${widget.pharmacyLat},${widget.pharmacyLng}&rtt=auto',
    );
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  void _openGoogleNavigator() async {
    final url = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=${widget.pharmacyLat},${widget.pharmacyLng}&travelmode=driving',
    );
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  void _callPhone() async {
    if (widget.pharmacyPhone.isNotEmpty) {
      final url = Uri.parse('tel:${widget.pharmacyPhone}');
      if (await canLaunchUrl(url)) await launchUrl(url);
    }
  }

  void _fitRoute() {
    if (_routePoints.isNotEmpty) {
      final bounds = LatLngBounds.fromPoints(_routePoints);
      _mapController.fitCamera(CameraFit.bounds(
        bounds: bounds,
        padding: const EdgeInsets.fromLTRB(50, 120, 50, 280),
      ));
    }
  }

  void _centerOnPharmacy() {
    _mapController.move(LatLng(widget.pharmacyLat, widget.pharmacyLng), 16.5);
  }

  void _centerOnUser() {
    if (_userPosition != null) {
      _mapController.move(LatLng(_userPosition!.latitude, _userPosition!.longitude), 16.5);
    }
  }

  @override
  Widget build(BuildContext context) {
    final pharmacyLatLng = LatLng(widget.pharmacyLat, widget.pharmacyLng);

    return Scaffold(
      body: Stack(
        children: [
          // ===== MAP =====
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: pharmacyLatLng,
              initialZoom: 15.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'uz.recept24.app',
              ),

              // Real road route
              if (_routePoints.isNotEmpty)
                PolylineLayer(
                  polylines: [
                    // Shadow
                    Polyline(
                      points: _routePoints,
                      color: const Color(0xFF1E40AF).withValues(alpha: 0.2),
                      strokeWidth: 10,
                    ),
                    // Main route
                    Polyline(
                      points: _routePoints,
                      color: const Color(0xFF2563EB),
                      strokeWidth: 5,
                    ),
                  ],
                ),

              // Markers
              MarkerLayer(
                markers: [
                  // Pharmacy marker
                  Marker(
                    point: pharmacyLatLng,
                    width: 56,
                    height: 56,
                    child: AnimatedBuilder(
                      animation: _pulseAnim,
                      builder: (_, __) {
                        return Stack(
                          alignment: Alignment.center,
                          children: [
                            Container(
                              width: 42 + (_pulseAnim.value * 14),
                              height: 42 + (_pulseAnim.value * 14),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: const Color(0xFF2563EB).withValues(alpha: 0.15 - (_pulseAnim.value * 0.1)),
                              ),
                            ),
                            Container(
                              width: 40, height: 40,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  begin: Alignment.topLeft, end: Alignment.bottomRight,
                                  colors: [Color(0xFF1E40AF), Color(0xFF3B82F6)],
                                ),
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 3),
                                boxShadow: [BoxShadow(color: const Color(0xFF2563EB).withValues(alpha: 0.4), blurRadius: 10, offset: const Offset(0, 4))],
                              ),
                              child: const Icon(Icons.local_pharmacy_rounded, color: Colors.white, size: 20),
                            ),
                          ],
                        );
                      },
                    ),
                  ),

                  // User marker with direction
                  if (_userPosition != null)
                    Marker(
                      point: LatLng(_userPosition!.latitude, _userPosition!.longitude),
                      width: 44, height: 44,
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                          boxShadow: [BoxShadow(color: const Color(0xFF10B981).withValues(alpha: 0.4), blurRadius: 8, offset: const Offset(0, 3))],
                        ),
                        child: const Icon(Icons.navigation_rounded, color: Colors.white, size: 20),
                      ),
                    ),
                ],
              ),
            ],
          ),

          // ===== TOP BAR =====
          Positioned(
            top: 0, left: 0, right: 0,
            child: Container(
              padding: EdgeInsets.fromLTRB(8, MediaQuery.of(context).padding.top + 4, 16, 10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter, end: Alignment.bottomCenter,
                  colors: [Colors.white, Colors.white.withValues(alpha: 0.0)],
                ),
              ),
              child: Row(
                children: [
                  _topBtn(Icons.arrow_back_ios_rounded, () => Navigator.pop(context)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white, borderRadius: BorderRadius.circular(12),
                        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 10)],
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.local_pharmacy, size: 18, color: Color(0xFF2563EB)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(widget.pharmacyName,
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF0F172A)),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (_routeDistanceKm != null) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                _routeDistanceKm! < 1
                                    ? '${(_routeDistanceKm! * 1000).round()} m'
                                    : '${_routeDistanceKm!.toStringAsFixed(1)} km',
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF2563EB)),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ===== ROUTE INFO BADGE =====
          if (_routeDurationMin != null)
            Positioned(
              top: MediaQuery.of(context).padding.top + 60,
              left: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white, borderRadius: BorderRadius.circular(10),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 10)],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.directions_car_rounded, size: 16, color: Color(0xFF2563EB)),
                    const SizedBox(width: 6),
                    Text('~$_routeDurationMin min', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF0F172A))),
                    const SizedBox(width: 4),
                    Text(
                      _routeDistanceKm! < 1
                          ? '(${(_routeDistanceKm! * 1000).round()} m)'
                          : '(${_routeDistanceKm!.toStringAsFixed(1)} km)',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                    ),
                    if (_loadingRoute) ...[
                      const SizedBox(width: 8),
                      SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.blue.shade300)),
                    ],
                  ],
                ),
              ),
            ),

          // ===== MAP CONTROLS =====
          Positioned(
            right: 16,
            top: MediaQuery.of(context).padding.top + 60,
            child: Column(
              children: [
                _mapButton(Icons.route_rounded, const Color(0xFFEAB308), _fitRoute),
                const SizedBox(height: 8),
                _mapButton(Icons.local_pharmacy_rounded, const Color(0xFF2563EB), _centerOnPharmacy),
                const SizedBox(height: 8),
                _mapButton(Icons.my_location_rounded, const Color(0xFF10B981), _centerOnUser),
              ],
            ),
          ),

          // ===== LOADING ROUTE =====
          if (_loadingRoute && _routePoints.isEmpty)
            Positioned(
              top: MediaQuery.of(context).padding.top + 60,
              left: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white, borderRadius: BorderRadius.circular(10),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 10)],
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF2563EB))),
                    SizedBox(width: 8),
                    Text('Маршрут жүкленбекте...', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
            ),

          // ===== BOTTOM CARD =====
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: SlideTransition(
              position: Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero).animate(
                CurvedAnimation(parent: _slideAnim, curve: Curves.easeOutCubic),
              ),
              child: _buildBottomCard(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _topBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 10)],
        ),
        child: Icon(icon, size: 18, color: const Color(0xFF0F172A)),
      ),
    );
  }

  Widget _mapButton(IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44, height: 44,
        decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 10)],
        ),
        child: Icon(icon, color: color, size: 22),
      ),
    );
  }

  Widget _buildBottomCard() {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          padding: EdgeInsets.fromLTRB(20, 14, 20, MediaQuery.of(context).padding.bottom + 16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.94),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 20, offset: const Offset(0, -5))],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 14),

              // Pharmacy info row
              Row(
                children: [
                  Container(
                    width: 48, height: 48,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [Color(0xFF1E40AF), Color(0xFF3B82F6)]),
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: const Icon(Icons.local_pharmacy_rounded, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.pharmacyName, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF0F172A))),
                        const SizedBox(height: 2),
                        Row(children: [
                          Icon(Icons.location_on_outlined, size: 13, color: Colors.grey.shade500),
                          const SizedBox(width: 3),
                          Expanded(child: Text(widget.pharmacyAddress, style: TextStyle(fontSize: 12, color: Colors.grey.shade500), overflow: TextOverflow.ellipsis)),
                        ]),
                        if (widget.pharmacyPhone.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Row(children: [
                              Icon(Icons.phone_outlined, size: 13, color: Colors.grey.shade500),
                              const SizedBox(width: 3),
                              Text(widget.pharmacyPhone, style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                            ]),
                          ),
                      ],
                    ),
                  ),
                ],
              ),

              // Route summary
              if (_routeDistanceKm != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F4FF), borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _infoChip(Icons.straighten_rounded, _routeDistanceKm! < 1 ? '${(_routeDistanceKm! * 1000).round()} м' : '${_routeDistanceKm!.toStringAsFixed(1)} км', 'Аралық'),
                      Container(width: 1, height: 30, color: const Color(0xFFBFDBFE)),
                      _infoChip(Icons.access_time_rounded, '~$_routeDurationMin мин', 'Ўақыт'),
                      Container(width: 1, height: 30, color: const Color(0xFFBFDBFE)),
                      _infoChip(Icons.directions_car_rounded, 'Автомобиль', 'Режим'),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 14),

              // Navigation buttons
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: GestureDetector(
                      onTap: _openYandexNavigator,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [Color(0xFF1E40AF), Color(0xFF3B82F6)]),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [BoxShadow(color: const Color(0xFF2563EB).withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 4))],
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.navigation_rounded, color: Colors.white, size: 18),
                            SizedBox(width: 8),
                            Text('Яндекс Навигатор', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: GestureDetector(
                      onTap: _openGoogleNavigator,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        decoration: BoxDecoration(
                          color: Colors.white, borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.map_rounded, color: Color(0xFF0F172A), size: 18),
                            SizedBox(width: 6),
                            Text('Google', style: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.w600, fontSize: 14)),
                          ],
                        ),
                      ),
                    ),
                  ),
                  if (widget.pharmacyPhone.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: _callPhone,
                      child: Container(
                        width: 48, height: 48,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [Color(0xFF059669), Color(0xFF10B981)]),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.phone_rounded, color: Colors.white, size: 20),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoChip(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, size: 18, color: const Color(0xFF2563EB)),
        const SizedBox(height: 3),
        Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF0F172A))),
        Text(label, style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
      ],
    );
  }
}
