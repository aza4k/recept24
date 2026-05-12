import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:geolocator/geolocator.dart';
import '../services/api_service.dart';
import 'map_screen.dart';

class ResultsScreen extends StatefulWidget {
  final List<Map<String, dynamic>> selectedMedicines;
  const ResultsScreen({super.key, required this.selectedMedicines});

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen> with TickerProviderStateMixin {
  List<Map<String, dynamic>> _pharmacies = [];
  bool _loading = true;
  bool _sortByCheap = true;
  Position? _userPosition;
  late AnimationController _listAnimController;

  @override
  void initState() {
    super.initState();
    _listAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _loadData();
  }

  @override
  void dispose() {
    _listAnimController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final ids = widget.selectedMedicines.map((m) => m['id'] as int).toList();
    final result = await ApiService.searchPharmacies(ids);
    if (mounted) {
      setState(() {
        _pharmacies = List<Map<String, dynamic>>.from(result['pharmacies'] ?? []);
        _loading = false;
      });
      _listAnimController.forward();
    }
    _getUserLocation();
  }

  Future<void> _getUserLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.whileInUse || permission == LocationPermission.always) {
        final pos = await Geolocator.getCurrentPosition();
        if (mounted) {
          setState(() {
            _userPosition = pos;
            _calculateDistances();
          });
        }
      }
    } catch (_) {}
  }

  double _haversine(double lat1, double lon1, double lat2, double lon2) {
    const R = 6371.0;
    final dLat = (lat2 - lat1) * pi / 180;
    final dLon = (lon2 - lon1) * pi / 180;
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1 * pi / 180) * cos(lat2 * pi / 180) * sin(dLon / 2) * sin(dLon / 2);
    return R * 2 * atan2(sqrt(a), sqrt(1 - a));
  }

  void _calculateDistances() {
    if (_userPosition == null) return;
    for (var p in _pharmacies) {
      p['distance'] = _haversine(
        _userPosition!.latitude, _userPosition!.longitude,
        (p['latitude'] as num).toDouble(), (p['longitude'] as num).toDouble(),
      );
    }
    _sortPharmacies();
  }

  void _sortPharmacies() {
    setState(() {
      if (_sortByCheap) {
        _pharmacies.sort((a, b) => (a['total_price'] as num).compareTo(b['total_price'] as num));
      } else {
        _pharmacies.sort((a, b) {
          final dA = (a['distance'] as num?)?.toDouble() ?? 99999;
          final dB = (b['distance'] as num?)?.toDouble() ?? 99999;
          return dA.compareTo(dB);
        });
      }
    });
  }

  void _openMap(Map<String, dynamic> pharmacy) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => MapScreen(
          pharmacyLat: (pharmacy['latitude'] as num).toDouble(),
          pharmacyLng: (pharmacy['longitude'] as num).toDouble(),
          pharmacyName: pharmacy['name'],
          pharmacyAddress: pharmacy['address'],
          pharmacyPhone: pharmacy['phone'] ?? '',
        ),
        transitionsBuilder: (_, a, __, child) => FadeTransition(opacity: a, child: child),
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }

  void _callPhone(String phone) async {
    final url = Uri.parse('tel:$phone');
    if (await canLaunchUrl(url)) await launchUrl(url);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background
          Positioned(top: -40, right: -40, child: _bgCircle(180, 0.07)),
          Positioned(bottom: 80, left: -60, child: _bgCircle(220, 0.05)),

          Column(
            children: [
              _buildAppBar(),
              _buildSortTabs(),
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator(color: Color(0xFF2563EB)))
                    : _pharmacies.isEmpty
                        ? _buildEmptyState()
                        : _buildList(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _bgCircle(double size, double opacity) {
    return Container(
      width: size, height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFF2563EB).withValues(alpha: opacity),
      ),
    );
  }

  Widget _buildAppBar() {
    return Container(
      padding: EdgeInsets.fromLTRB(6, MediaQuery.of(context).padding.top + 4, 20, 14),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1E40AF), Color(0xFF3B82F6)],
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white, size: 20),
                onPressed: () => Navigator.pop(context),
              ),
              const Expanded(
                child: Text(
                  'Нәтийжелер',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(width: 48),
            ],
          ),
          const SizedBox(height: 8),
          // Selected medicines summary
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.receipt_long_rounded, color: Colors.white, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Рецептиңиз', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 15)),
                          const SizedBox(height: 2),
                          Text(
                            '${widget.selectedMedicines.length} дәри • ${_pharmacies.length} дәрихана табылды',
                            style: const TextStyle(color: Colors.white70, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSortTabs() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 2))],
      ),
      child: Row(
        children: [
          _sortTab('Арзанрақ', Icons.sell_outlined, true),
          _sortTab('Жақынрақ', Icons.near_me_outlined, false),
        ],
      ),
    );
  }

  Widget _sortTab(String label, IconData icon, bool isCheap) {
    final active = _sortByCheap == isCheap;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() => _sortByCheap = isCheap);
          _sortPharmacies();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding: const EdgeInsets.symmetric(vertical: 11),
          decoration: BoxDecoration(
            gradient: active
                ? const LinearGradient(colors: [Color(0xFF2563EB), Color(0xFF3B82F6)])
                : null,
            borderRadius: BorderRadius.circular(10),
            boxShadow: active
                ? [BoxShadow(color: const Color(0xFF2563EB).withValues(alpha: 0.25), blurRadius: 8, offset: const Offset(0, 3))]
                : [],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 17, color: active ? Colors.white : Colors.grey.shade500),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: active ? Colors.white : Colors.grey.shade500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildList() {
    return AnimatedBuilder(
      animation: _listAnimController,
      builder: (_, __) {
        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
          itemCount: _pharmacies.length,
          itemBuilder: (_, i) {
            final delay = (i * 0.15).clamp(0.0, 1.0);
            final itemAnim = Tween<double>(begin: 0, end: 1).animate(
              CurvedAnimation(
                parent: _listAnimController,
                curve: Interval(delay, (delay + 0.5).clamp(0.0, 1.0), curve: Curves.easeOutCubic),
              ),
            );
            return FadeTransition(
              opacity: itemAnim,
              child: SlideTransition(
                position: Tween<Offset>(begin: const Offset(0, 0.15), end: Offset.zero).animate(itemAnim),
                child: _buildPharmacyCard(_pharmacies[i], i),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildPharmacyCard(Map<String, dynamic> pharmacy, int index) {
    final stocks = List<Map<String, dynamic>>.from(pharmacy['stocks'] ?? []);
    final totalPrice = (pharmacy['total_price'] as num).toDouble();
    final lat = (pharmacy['latitude'] as num).toDouble();
    final lng = (pharmacy['longitude'] as num).toDouble();
    final distance = pharmacy['distance'] as double?;
    final phone = pharmacy['phone'] ?? '';
    final isCheapest = index == 0 && _sortByCheap;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isCheapest ? const Color(0xFF2563EB).withValues(alpha: 0.3) : const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          // Cheapest badge
          if (isCheapest)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 6),
              decoration: const BoxDecoration(
                gradient: LinearGradient(colors: [Color(0xFF2563EB), Color(0xFF3B82F6)]),
                borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.star_rounded, color: Colors.white, size: 16),
                  SizedBox(width: 4),
                  Text('Ең арзан усыныс', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 12)),
                ],
              ),
            ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Header
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 46, height: 46,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.local_pharmacy_rounded, color: Color(0xFF2563EB), size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  pharmacy['name'],
                                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF0F172A)),
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(Icons.verified_rounded, size: 16, color: Color(0xFF2563EB)),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Row(
                            children: [
                              Icon(Icons.location_on_outlined, size: 13, color: Colors.grey.shade500),
                              const SizedBox(width: 3),
                              Expanded(
                                child: Text(
                                  pharmacy['address'],
                                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Row(
                            children: [
                              Icon(Icons.access_time_rounded, size: 13, color: Colors.grey.shade500),
                              const SizedBox(width: 3),
                              Text(pharmacy['work_hours'] ?? '24 саат', style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                              if (distance != null) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEFF6FF),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.directions_walk_rounded, size: 12, color: Color(0xFF2563EB)),
                                      const SizedBox(width: 2),
                                      Text(
                                        distance < 1 ? '${(distance * 1000).round()} m' : '${distance.toStringAsFixed(1)} km',
                                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF2563EB)),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '${totalPrice.toStringAsFixed(0)}',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Color(0xFF2563EB)),
                    ),
                    const Text(' сўм', style: TextStyle(fontSize: 11, color: Color(0xFF2563EB), fontWeight: FontWeight.w500)),
                  ],
                ),

                const SizedBox(height: 12),

                // Medicines
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    children: stocks.asMap().entries.map((e) {
                      final s = e.value;
                      final last = e.key == stocks.length - 1;
                      return Container(
                        padding: EdgeInsets.only(bottom: last ? 0 : 8, top: e.key == 0 ? 0 : 8),
                        decoration: BoxDecoration(
                          border: last ? null : Border(bottom: BorderSide(color: Colors.grey.shade200)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.check_circle_rounded, size: 16, color: Color(0xFF10B981)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(s['medicine_name'], style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                                  Text(s['manufacturer'], style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                                ],
                              ),
                            ),
                            Text(
                              '${(s['price'] as num).toStringAsFixed(0)} сўм',
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF0F172A)),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),

                const SizedBox(height: 12),

                // Action buttons
                Row(
                  children: [
                    if (phone.isNotEmpty)
                      Expanded(
                        child: _actionBtn(
                          icon: Icons.phone_rounded,
                          label: 'Қоңыраў',
                          colors: [const Color(0xFF059669), const Color(0xFF10B981)],
                          onTap: () => _callPhone(phone),
                        ),
                      ),
                    if (phone.isNotEmpty) const SizedBox(width: 8),
                    Expanded(
                      child: _actionBtn(
                        icon: Icons.map_rounded,
                        label: 'Картада',
                        colors: [const Color(0xFF2563EB), const Color(0xFF3B82F6)],
                        onTap: () => _openMap(pharmacy),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionBtn({
    required IconData icon,
    required String label,
    required List<Color> colors,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: colors),
          borderRadius: BorderRadius.circular(10),
          boxShadow: [BoxShadow(color: colors[0].withValues(alpha: 0.25), blurRadius: 8, offset: const Offset(0, 3))],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: Colors.white),
            const SizedBox(width: 6),
            Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white)),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inventory_2_outlined, size: 56, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          const Text('Дәрихана табылмады', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text(
            'Бул дәрилер бирден бар болған\nдәрихана табылмады.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }
}
