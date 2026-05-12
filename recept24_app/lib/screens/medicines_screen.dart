import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import '../services/api_service.dart';

class MedicinesScreen extends StatefulWidget {
  const MedicinesScreen({super.key});

  @override
  State<MedicinesScreen> createState() => _MedicinesScreenState();
}

class _MedicinesScreenState extends State<MedicinesScreen> {
  List<Map<String, dynamic>> _allMedicines = [];
  List<Map<String, dynamic>> _filtered = [];
  bool _loading = true;
  final TextEditingController _searchCtrl = TextEditingController();
  String _selectedCategory = 'Барлығы';

  final List<Map<String, dynamic>> _categories = [
    {'label': 'Барлығы', 'icon': Icons.apps_rounded, 'value': 'Barchasi'},
    {'label': 'Таблеткалар', 'icon': Icons.medication_rounded, 'value': 'Tabletkalar'},
    {'label': 'Капсулалар', 'icon': Icons.vaccines_outlined, 'value': 'Kapsulalar'},
    {'label': 'Сироплар', 'icon': Icons.water_drop_outlined, 'value': 'Siroplar'},
    {'label': 'Порошоклар', 'icon': Icons.grain_rounded, 'value': 'Kukunlar'},
    {'label': 'Малхамлар', 'icon': Icons.healing_outlined, 'value': 'Malhamlar'},
  ];

  @override
  void initState() {
    super.initState();
    _loadMedicines();
  }

  Future<void> _loadMedicines() async {
    final data = await ApiService.getAllMedicines();
    if (mounted) {
      setState(() {
        _allMedicines = data;
        _filtered = data;
        _loading = false;
      });
    }
  }

  void _filter() {
    setState(() {
      _filtered = _allMedicines.where((m) {
        final matchSearch = _searchCtrl.text.isEmpty ||
            m['name'].toString().toLowerCase().contains(_searchCtrl.text.toLowerCase());
        final matchCategory = _selectedCategory == 'Барлығы' ||
            m['category'] == _categories.firstWhere((c) => c['label'] == _selectedCategory)['value'];
        return matchSearch && matchCategory;
      }).toList();
    });
  }

  void _showAiInfo(Map<String, dynamic> medicine) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AiInfoSheet(medicine: medicine),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Container(
            padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + 12, 20, 20),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft, end: Alignment.bottomRight,
                colors: [Color(0xFF1E40AF), Color(0xFF3B82F6)],
              ),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Дәрилер', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: Colors.white)),
                const SizedBox(height: 4),
                Text('${_allMedicines.length} дәри базада бар', style: const TextStyle(fontSize: 13, color: Colors.white70)),
                const SizedBox(height: 16),
                Container(
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                  child: TextField(
                    controller: _searchCtrl,
                    onChanged: (_) => _filter(),
                    style: const TextStyle(fontSize: 15),
                    decoration: InputDecoration(
                      hintText: 'Дәри излеў...',
                      hintStyle: TextStyle(color: Colors.grey.shade400),
                      prefixIcon: Icon(Icons.search, color: Colors.grey.shade400),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 52,
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              scrollDirection: Axis.horizontal,
              itemCount: _categories.length,
              itemBuilder: (_, i) {
                final cat = _categories[i];
                final active = _selectedCategory == cat['label'];
                return GestureDetector(
                  onTap: () { _selectedCategory = cat['label'] as String; _filter(); },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: active ? const Color(0xFF2563EB) : Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: active ? Colors.transparent : const Color(0xFFE2E8F0)),
                      boxShadow: active ? [BoxShadow(color: const Color(0xFF2563EB).withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 2))] : [],
                    ),
                    child: Row(
                      children: [
                        Icon(cat['icon'] as IconData, size: 16, color: active ? Colors.white : Colors.grey.shade500),
                        const SizedBox(width: 6),
                        Text(cat['label'] as String, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: active ? Colors.white : Colors.grey.shade600)),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF2563EB)))
                : _filtered.isEmpty
                    ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Icon(Icons.search_off, size: 48, color: Colors.grey.shade300),
                        const SizedBox(height: 12),
                        Text('Дәри табылмады', style: TextStyle(fontSize: 16, color: Colors.grey.shade500)),
                      ]))
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 80),
                        itemCount: _filtered.length,
                        itemBuilder: (_, i) => _buildMedicineCard(_filtered[i]),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildMedicineCard(Map<String, dynamic> med) {
    final imageUrl = med['image_url'] ?? '';
    final minPrice = (med['min_price'] as num?)?.toDouble() ?? 0;
    return GestureDetector(
      onTap: () => _showAiInfo(med),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  width: 64, height: 64, color: const Color(0xFFF1F5F9),
                  child: imageUrl.isNotEmpty
                      ? Image.network(imageUrl, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.medication_rounded, color: Color(0xFF2563EB), size: 28))
                      : const Icon(Icons.medication_rounded, color: Color(0xFF2563EB), size: 28),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(med['name'], style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF0F172A))),
                  const SizedBox(height: 2),
                  Text(med['category'] ?? '', style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                  const SizedBox(height: 2),
                  Text(med['manufacturer'] ?? '', style: TextStyle(fontSize: 12, color: Colors.grey.shade400)),
                ],
              )),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(minPrice.toStringAsFixed(0), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF2563EB))),
                  const Text("сўм", style: TextStyle(fontSize: 11, color: Color(0xFF2563EB))),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF8B5CF6), Color(0xFFA78BFA)]), borderRadius: BorderRadius.circular(6)),
                    child: const Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.auto_awesome, size: 12, color: Colors.white),
                      SizedBox(width: 3),
                      Text('AI', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white)),
                    ]),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ========== AI МАҒЛЫЎМАТ ПАНЕЛИ ==========
class _AiInfoSheet extends StatefulWidget {
  final Map<String, dynamic> medicine;
  const _AiInfoSheet({required this.medicine});
  @override
  State<_AiInfoSheet> createState() => _AiInfoSheetState();
}

class _AiInfoSheetState extends State<_AiInfoSheet> {
  String _displayedText = '';
  bool _isTyping = true;
  bool _loadingDetail = true;
  Map<String, dynamic>? _detail;

  @override
  void initState() {
    super.initState();
    _loadDetail();
  }

  Future<void> _loadDetail() async {
    final detail = await ApiService.getMedicineDetail(widget.medicine['id']);
    if (mounted) {
      setState(() { _detail = detail; _loadingDetail = false; });
      if (detail != null) _startTypingAnimation(detail['description'] ?? '');
    }
  }

  void _startTypingAnimation(String fullText) async {
    for (int i = 0; i <= fullText.length; i++) {
      if (!mounted) return;
      await Future.delayed(const Duration(milliseconds: 12));
      if (mounted) setState(() => _displayedText = fullText.substring(0, i));
    }
    if (mounted) setState(() => _isTyping = false);
  }

  @override
  Widget build(BuildContext context) {
    final imageUrl = widget.medicine['image_url'] ?? '';
    return DraggableScrollableSheet(
      initialChildSize: 0.85, minChildSize: 0.5, maxChildSize: 0.95,
      builder: (_, controller) {
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: Container(
              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.95), borderRadius: const BorderRadius.vertical(top: Radius.circular(24))),
              child: ListView(
                controller: controller,
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 30),
                children: [
                  Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)))),
                  const SizedBox(height: 16),
                  Row(children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF8B5CF6), Color(0xFFA78BFA)]), borderRadius: BorderRadius.circular(8)),
                      child: const Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(Icons.auto_awesome, size: 14, color: Colors.white),
                        SizedBox(width: 4),
                        Text('AI Жәрдемши', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white)),
                      ]),
                    ),
                    const Spacer(),
                    if (_isTyping) Row(children: [
                      SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.purple.shade300)),
                      const SizedBox(width: 6),
                      Text('Жазылмақта...', style: TextStyle(fontSize: 12, color: Colors.purple.shade300)),
                    ]),
                  ]),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFFEFF6FF), Color(0xFFF0F4FF)]),
                      borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFBFDBFE)),
                    ),
                    child: Row(children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          width: 70, height: 70, color: Colors.white,
                          child: imageUrl.isNotEmpty
                              ? Image.network(imageUrl, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.medication, size: 32, color: Color(0xFF2563EB)))
                              : const Icon(Icons.medication, size: 32, color: Color(0xFF2563EB)),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(widget.medicine['name'], style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF0F172A))),
                        const SizedBox(height: 2),
                        Text(widget.medicine['manufacturer'] ?? '', style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(6)),
                          child: Text(widget.medicine['category'] ?? '', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF2563EB))),
                        ),
                      ])),
                    ]),
                  ),
                  const SizedBox(height: 20),
                  if (_loadingDetail)
                    const Center(child: Padding(padding: EdgeInsets.all(30), child: CircularProgressIndicator(color: Color(0xFF8B5CF6))))
                  else ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: const Color(0xFFFAF5FF), borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFFE9D5FF))),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Row(children: [
                          Icon(Icons.auto_awesome, size: 16, color: Colors.purple.shade400),
                          const SizedBox(width: 6),
                          Text('Дәри ҳаққында толық мағлыўмат', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.purple.shade700)),
                        ]),
                        const SizedBox(height: 10),
                        Text(_displayedText, style: const TextStyle(fontSize: 14, color: Color(0xFF334155), height: 1.6)),
                        if (_isTyping) Container(margin: const EdgeInsets.only(top: 4), width: 8, height: 16, color: Colors.purple.shade400),
                      ]),
                    ),
                    const SizedBox(height: 16),
                    if (_detail != null && (_detail!['pharmacies'] as List).isNotEmpty) ...[
                      Text('Дәриханалардағы бахалар', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.grey.shade800)),
                      const SizedBox(height: 10),
                      ...(_detail!['pharmacies'] as List).map((p) => Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFFE2E8F0))),
                        child: Row(children: [
                          Container(
                            width: 36, height: 36,
                            decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(8)),
                            child: const Icon(Icons.local_pharmacy, size: 18, color: Color(0xFF2563EB)),
                          ),
                          const SizedBox(width: 10),
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(p['pharmacy_name'], style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                            Text(p['address'], style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                          ])),
                          Text('${(p['price'] as num).toStringAsFixed(0)} сўм', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF2563EB))),
                        ]),
                      )),
                    ],
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
