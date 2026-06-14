import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'results_screen.dart';
import 'medicines_screen.dart';
import 'map_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentNavIndex = 0;

  final List<Widget> _screens = [
    const _SearchTab(),
    const MedicinesScreen(),
    const _PharmaciesTab(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentNavIndex, children: _screens),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 20, offset: const Offset(0, -4))],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _navItem(Icons.search_rounded, 'Излеў', 0),
              _navItem(Icons.medication_rounded, 'Дәрилер', 1),
              _navItem(Icons.local_pharmacy_rounded, 'Дәриханалар', 2),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navItem(IconData icon, String label, int index) {
    final active = _currentNavIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _currentNavIndex = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: active ? const Color(0xFFEFF6FF) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: active ? const Color(0xFF2563EB) : Colors.grey.shade400, size: 24),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: active ? FontWeight.w600 : FontWeight.w500,
                color: active ? const Color(0xFF2563EB) : Colors.grey.shade500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ========== ИЗЛЕЎ ТАБЫ ==========
class _SearchTab extends StatefulWidget {
  const _SearchTab();
  @override
  State<_SearchTab> createState() => _SearchTabState();
}

class _SearchTabState extends State<_SearchTab> with TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  List<Map<String, dynamic>> _suggestions = [];
  final List<Map<String, dynamic>> _selectedMedicines = [];
  List<Map<String, dynamic>> _popularMedicines = [];
  bool _showDropdown = false;
  Timer? _debounce;
  late AnimationController _heroAnim;

  @override
  void initState() {
    super.initState();
    _heroAnim = AnimationController(vsync: this, duration: const Duration(milliseconds: 700))..forward();
    _loadPopular();
  }

  Future<void> _loadPopular() async {
    final all = await ApiService.getAllMedicines();
    if (mounted) setState(() => _popularMedicines = all.take(6).toList());
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    _debounce?.cancel();
    _heroAnim.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () async {
      if (query.length > 1) {
        final results = await ApiService.searchMedicines(query);
        if (mounted) setState(() { _suggestions = results; _showDropdown = results.isNotEmpty; });
      } else {
        setState(() { _suggestions = []; _showDropdown = false; });
      }
    });
  }

  void _selectMedicine(Map<String, dynamic> medicine) {
    if (!_selectedMedicines.any((m) => m['id'] == medicine['id'])) {
      setState(() => _selectedMedicines.add(medicine));
    }
    _searchController.clear();
    setState(() { _showDropdown = false; _suggestions = []; });
    _focusNode.requestFocus();
  }

  void _removeMedicine(int id) => setState(() => _selectedMedicines.removeWhere((m) => m['id'] == id));

  void _search() {
    if (_selectedMedicines.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Row(children: [Icon(Icons.info_outline, color: Colors.white, size: 20), SizedBox(width: 10), Text('Кеминде бир дәри таңлаң')]),
        backgroundColor: const Color(0xFF2563EB),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ));
      return;
    }
    Navigator.push(context, PageRouteBuilder(
      pageBuilder: (_, __, ___) => ResultsScreen(selectedMedicines: _selectedMedicines),
      transitionsBuilder: (_, a, __, child) => SlideTransition(
        position: Tween<Offset>(begin: const Offset(0, 0.12), end: Offset.zero).animate(CurvedAnimation(parent: a, curve: Curves.easeOutCubic)),
        child: FadeTransition(opacity: a, child: child),
      ),
      transitionDuration: const Duration(milliseconds: 350),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () { _focusNode.unfocus(); setState(() => _showDropdown = false); },
      child: Stack(
        children: [
          Positioned(top: -60, right: -50, child: _bgCircle(180, 0.07)),
          Positioned(bottom: 120, left: -70, child: _bgCircle(200, 0.04)),
          CustomScrollView(
            slivers: [
              SliverToBoxAdapter(child: _buildHero()),
              if (_showDropdown) SliverToBoxAdapter(child: _buildDropdown()),
              if (_selectedMedicines.isNotEmpty) SliverToBoxAdapter(child: _buildTags()),
              SliverToBoxAdapter(child: _buildPopularSection()),
            ],
          ),
        ],
      ),
    );
  }

  Widget _bgCircle(double size, double opacity) => Container(
    width: size, height: size,
    decoration: BoxDecoration(shape: BoxShape.circle, color: const Color(0xFF2563EB).withValues(alpha: opacity)),
  );

  Widget _buildHero() {
    return FadeTransition(
      opacity: CurvedAnimation(parent: _heroAnim, curve: Curves.easeOut),
      child: Container(
        padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + 14, 20, 28),
        decoration: const BoxDecoration(
          gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF1E40AF), Color(0xFF3B82F6)]),
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.grid_view_rounded, color: Colors.white, size: 22),
                ),
                Column(
                  children: [
                    Image.asset('assets/logo.png', height: 40, fit: BoxFit.contain), // Custom logo
                    const Text('Нөкис қаласы', style: TextStyle(fontSize: 11, color: Colors.white70)),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.notifications_outlined, color: Colors.white, size: 22),
                ),
              ],
            ),
            const SizedBox(height: 22),
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 46, height: 46,
                        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(13)),
                        child: const Icon(Icons.receipt_long_rounded, color: Colors.white, size: 24),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Рецепт бойынша излеў', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 15)),
                          SizedBox(height: 2),
                          Text('Бирнеше дәри қосып, ең арзан дәрихананы табың', style: TextStyle(color: Colors.white70, fontSize: 12)),
                        ],
                      )),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 20, offset: const Offset(0, 8))],
              ),
              child: Row(
                children: [
                  const SizedBox(width: 14),
                  Icon(Icons.search_rounded, color: Colors.grey.shade400, size: 22),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      focusNode: _focusNode,
                      onChanged: _onSearchChanged,
                      style: const TextStyle(fontSize: 15),
                      decoration: InputDecoration(
                        hintText: 'Дәри атамасын киритиң...',
                        hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 15),
                        border: InputBorder.none, enabledBorder: InputBorder.none, focusedBorder: InputBorder.none,
                        fillColor: Colors.transparent,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: _search,
                    child: Container(
                      margin: const EdgeInsets.all(5),
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [Color(0xFF2563EB), Color(0xFF3B82F6)]),
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [BoxShadow(color: const Color(0xFF2563EB).withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 3))],
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.search, color: Colors.white, size: 18),
                          SizedBox(width: 4),
                          Text('Излеў', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdown() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 6, 20, 0),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 20, offset: const Offset(0, 6))],
      ),
      constraints: const BoxConstraints(maxHeight: 240),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: ListView.separated(
          padding: EdgeInsets.zero, shrinkWrap: true,
          itemCount: _suggestions.length,
          separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey.shade100),
          itemBuilder: (_, i) {
            final med = _suggestions[i];
            final imageUrl = med['image_url'] ?? '';
            return ListTile(
              leading: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  width: 38, height: 38, color: const Color(0xFFF1F5F9),
                  child: imageUrl.isNotEmpty
                      ? Image.network(imageUrl, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.medication_outlined, color: Color(0xFF2563EB), size: 20))
                      : const Icon(Icons.medication_outlined, color: Color(0xFF2563EB), size: 20),
                ),
              ),
              title: Text(med['name'], style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
              subtitle: Text(med['manufacturer'] ?? '', style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
              trailing: const Icon(Icons.add_circle_outline, color: Color(0xFF2563EB), size: 22),
              dense: true,
              onTap: () => _selectMedicine(med),
            );
          },
        ),
      ),
    );
  }

  Widget _buildTags() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Таңланған дәрилер (${_selectedMedicines.length})', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey.shade600)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8, runSpacing: 8,
            children: _selectedMedicines.map((med) => Container(
              padding: const EdgeInsets.fromLTRB(12, 7, 6, 7),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFBFDBFE)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.medication, size: 16, color: Color(0xFF2563EB)),
                  const SizedBox(width: 6),
                  Text(med['name'], style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF1E40AF))),
                  const SizedBox(width: 4),
                  GestureDetector(
                    onTap: () => _removeMedicine(med['id']),
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(color: const Color(0xFFFEE2E2), borderRadius: BorderRadius.circular(6)),
                      child: const Icon(Icons.close, size: 14, color: Color(0xFFEF4444)),
                    ),
                  ),
                ],
              ),
            )).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildPopularSection() {
    if (_popularMedicines.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.local_fire_department_rounded, color: Color(0xFFEF4444), size: 20),
              SizedBox(width: 6),
              Text('Көп сатылатуғын дәрилер', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Color(0xFF0F172A))),
            ],
          ),
          const SizedBox(height: 14),
          ..._popularMedicines.map((med) {
            final imageUrl = med['image_url'] ?? '';
            final minPrice = (med['min_price'] as num?)?.toDouble() ?? 0;
            return GestureDetector(
              onTap: () => _selectMedicine(med),
              child: Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white, borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 6)],
                ),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        width: 48, height: 48, color: const Color(0xFFF1F5F9),
                        child: imageUrl.isNotEmpty
                            ? Image.network(imageUrl, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.medication, size: 22, color: Color(0xFF2563EB)))
                            : const Icon(Icons.medication, size: 22, color: Color(0xFF2563EB)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(med['name'], style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                        Text(med['manufacturer'] ?? '', style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                      ],
                    )),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(minPrice.toStringAsFixed(0), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF2563EB))),
                        const Text("сўм", style: TextStyle(fontSize: 10, color: Color(0xFF2563EB))),
                      ],
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.add_circle_outline, color: Color(0xFF2563EB), size: 22),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

// ========== ДӘРИХАНАЛАР ТАБЫ ==========
class _PharmaciesTab extends StatefulWidget {
  const _PharmaciesTab();
  @override
  State<_PharmaciesTab> createState() => _PharmaciesTabState();
}

class _PharmaciesTabState extends State<_PharmaciesTab> {
  List<Map<String, dynamic>> _pharmacies = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final data = await ApiService.getAllPharmacies();
    if (mounted) setState(() { _pharmacies = data; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + 12, 20, 20),
          decoration: const BoxDecoration(
            gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF1E40AF), Color(0xFF3B82F6)]),
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Дәриханалар', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: Colors.white)),
              const SizedBox(height: 4),
              Text('Нөкис қаласындағы ${_pharmacies.length} дәрихана', style: const TextStyle(fontSize: 13, color: Colors.white70)),
            ],
          ),
        ),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator(color: Color(0xFF2563EB)))
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
                  itemCount: _pharmacies.length,
                  itemBuilder: (_, i) {
                    final p = _pharmacies[i];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white, borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 46, height: 46,
                            decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(12)),
                            child: const Icon(Icons.local_pharmacy_rounded, color: Color(0xFF2563EB), size: 24),
                          ),
                          const SizedBox(width: 12),
                          Expanded(child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(children: [
                                Flexible(child: Text(p['name'], style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600))),
                                const SizedBox(width: 4),
                                const Icon(Icons.verified_rounded, size: 16, color: Color(0xFF2563EB)),
                              ]),
                              const SizedBox(height: 3),
                              Row(children: [
                                Icon(Icons.location_on_outlined, size: 13, color: Colors.grey.shade500),
                                const SizedBox(width: 3),
                                Expanded(child: Text(p['address'], style: TextStyle(fontSize: 12, color: Colors.grey.shade500), overflow: TextOverflow.ellipsis)),
                              ]),
                              const SizedBox(height: 2),
                              Row(children: [
                                Icon(Icons.access_time_rounded, size: 13, color: Colors.grey.shade500),
                                const SizedBox(width: 3),
                                Text(p['work_hours'] ?? '24 саат', style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                              ]),
                            ],
                          )),
                          GestureDetector(
                            onTap: () {
                              Navigator.push(context, MaterialPageRoute(
                                builder: (_) => MapScreen(
                                  pharmacyLat: (p['latitude'] as num).toDouble(),
                                  pharmacyLng: (p['longitude'] as num).toDouble(),
                                  pharmacyName: p['name'],
                                  pharmacyAddress: p['address'],
                                  pharmacyPhone: p['phone'] ?? '',
                                ),
                              ));
                            },
                            child: Container(
                              width: 40, height: 40,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(colors: [Color(0xFF2563EB), Color(0xFF3B82F6)]),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.map_rounded, color: Colors.white, size: 20),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
