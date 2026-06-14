import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = 'https://lol-production-09d7.up.railway.app';

  /// Dori nomini qidirish (autocomplete)
  static Future<List<Map<String, dynamic>>> searchMedicines(String query) async {
    if (query.length < 2) return [];
    final response = await http.get(Uri.parse('$baseUrl/api/search/?q=$query'));
    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(json.decode(response.body));
    }
    return [];
  }

  /// Tanlangan dorilar bo'yicha dorixonalar
  static Future<Map<String, dynamic>> searchPharmacies(List<int> medicineIds) async {
    final params = medicineIds.map((id) => 'm=$id').join('&');
    final response = await http.get(Uri.parse('$baseUrl/api/search-pharmacies/?$params'));
    if (response.statusCode == 200) return json.decode(response.body);
    return {'pharmacies': [], 'medicines': []};
  }

  /// Barcha dorixonalar
  static Future<List<Map<String, dynamic>>> getAllPharmacies() async {
    final response = await http.get(Uri.parse('$baseUrl/api/pharmacies/'));
    if (response.statusCode == 200) return List<Map<String, dynamic>>.from(json.decode(response.body));
    return [];
  }

  /// Barcha dorilar ro'yxati (alfavit bo'yicha, rasmlar bilan)
  static Future<List<Map<String, dynamic>>> getAllMedicines() async {
    final response = await http.get(Uri.parse('$baseUrl/api/medicines/'));
    if (response.statusCode == 200) return List<Map<String, dynamic>>.from(json.decode(response.body));
    return [];
  }

  /// Bitta dori haqida to'liq ma'lumot (AI popup uchun)
  static Future<Map<String, dynamic>?> getMedicineDetail(int id) async {
    final response = await http.get(Uri.parse('$baseUrl/api/medicine/$id/'));
    if (response.statusCode == 200) return json.decode(response.body);
    return null;
  }
}
