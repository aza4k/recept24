import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = 'https://web-production-13565.up.railway.app';
  static const Duration requestTimeout = Duration(seconds: 3);

  // In-memory cache for offline and instant access
  static List<Map<String, dynamic>>? _cachedMedicines;
  static List<Map<String, dynamic>>? _cachedPharmacies;

  // Bundled offline medicines dataset
  static final List<Map<String, dynamic>> _offlineMedicines = [
    {
      'id': 1,
      'name': 'Парацетамол 500 мг',
      'category': 'Tabletkalar',
      'manufacturer': 'Jurabek Laboratories',
      'min_price': 3500,
      'image_url': '',
      'description': 'Аналгетик ҳәм антипиретик дәри қурал',
      'usage': 'Ыссық түсириў ҳәм аўырыўды басыў ушын',
      'contraindications': 'Баўыр ҳәм бүйрек жетиспеўшилиги',
      'dosage': '1 таблеткадан күнине 2-3 мәрте тамақтан соң',
      'storage': '25 градустан жоқары болмаған қуры жерде сақлаң',
    },
    {
      'id': 2,
      'name': 'Цитрамон П',
      'category': 'Tabletkalar',
      'manufacturer': 'Uzpharmsanoat',
      'min_price': 2500,
      'image_url': '',
      'description': 'Бас аўырыўына қарсы қоспалы дәри',
      'usage': 'Бас аўырыўы, тис аўырыўы ҳәм невpaлгияда',
      'contraindications': 'Асқазан жарасы ҳәм гипертония',
      'dosage': '1 таблеткадан күнине 1-2 мәрте',
      'storage': 'Қуры ҳәм қараңғы жерде сақлаң',
    },
    {
      'id': 3,
      'name': 'Амоксициллин 500 мг',
      'category': 'Kapsulalar',
      'manufacturer': 'Nobel Pharmsanoat',
      'min_price': 18000,
      'image_url': '',
      'description': 'Кең спектрли бактерияларға қарсы антибиотик',
      'usage': 'Дем алыў жоллары ҳәм жуқпалы кеселликлерде',
      'contraindications': 'Пенициллин қатарына аллергия болғанда',
      'dosage': 'Шпаргалка яки шыпакер көрсетиўи бойынша күнине 3 мәрте',
      'storage': 'Бөлме температурасында сақлаң',
    },
    {
      'id': 4,
      'name': 'Ибупрофен 400 мг',
      'category': 'Tabletkalar',
      'manufacturer': 'Borisov Medpreparat',
      'min_price': 8500,
      'image_url': '',
      'description': 'Қабыныўға қарсы сестемалы дәри',
      'usage': 'Буўын ҳәм булшықет аўырыўларында',
      'contraindications': 'Асқазан-ишек жолдарының эрозиялық жараларында',
      'dosage': '1 таблеткадан күнине 2 мәрте',
      'storage': 'Балалар қолы жетпейтуғын жерде сақлаң',
    },
    {
      'id': 5,
      'name': 'Анальгин 500 мг',
      'category': 'Tabletkalar',
      'manufacturer': 'Pharmstandard',
      'min_price': 3000,
      'image_url': '',
      'description': 'Аўырыўды басыўшы дәри',
      'usage': 'Әр түрли себепли аўырыў синдромларында',
      'contraindications': 'Қан ислеп шығарыў бузылыўлары',
      'dosage': '1 таблеткадан аўырыў күшейгенде',
      'storage': 'Қуры сақлаў орнында сақлаң',
    },
    {
      'id': 6,
      'name': 'Аспирин Кардио 100 мг',
      'category': 'Tabletkalar',
      'manufacturer': 'Bayer',
      'min_price': 22000,
      'image_url': '',
      'description': 'Антиагрегант ҳәм қан суйылтыўшы дәри',
      'usage': 'Жүрек қан-тамыр кеселликлерин алдын алыўда',
      'contraindications': 'Қанаўға бейимлик болғанда',
      'dosage': '1 таблеткадан күнине 1 мәрте суў менен',
      'storage': '25 градус температурада сақлаң',
    },
    {
      'id': 7,
      'name': 'Мезим Форте',
      'category': 'Tabletkalar',
      'manufacturer': 'Berlin-Chemie',
      'min_price': 28000,
      'image_url': '',
      'description': 'Ас қорытыў ферментлери қурал',
      'usage': 'Аўыр аўқатланғанда ас қорытыўды жақсылаў ушын',
      'contraindications': 'Жедел панкреатит',
      'dosage': '1-2 таблеткадан аўқатланыў ўақтында',
      'storage': '30 градустан аспаған жерде сақлаң',
    },
    {
      'id': 8,
      'name': 'Но-шпа 40 мг',
      'category': 'Tabletkalar',
      'manufacturer': 'Sanofi',
      'min_price': 24000,
      'image_url': '',
      'description': 'Миотроп спазмолитик дәри',
      'usage': 'Ишки ағзалардың булшықет спазмларында',
      'contraindications': 'Аўыр баўыр ҳәм жүрек жетиспеўшилиги',
      'dosage': '1-2 таблеткадан күнине 2-3 мәрте',
      'storage': 'Қуры бөлмеде сақлаң',
    },
    {
      'id': 9,
      'name': 'Супрастин 25 мг',
      'category': 'Tabletkalar',
      'manufacturer': 'Egis',
      'min_price': 16000,
      'image_url': '',
      'description': 'Аллергияға қарсы антигистамин қурал',
      'usage': 'Аллергиялық реакциялар ҳәм қышыўларда',
      'contraindications': 'Бронхиал астма ҳәм глаукома',
      'dosage': '1 таблеткадан күнине 2 мәрте тамақтан соң',
      'storage': '15-25 градус аралығында сақлаң',
    },
    {
      'id': 10,
      'name': 'Пантенол спрей',
      'category': 'Malhamlar',
      'manufacturer': 'Chauvin Ankerpharm',
      'min_price': 34000,
      'image_url': '',
      'description': 'Терини регенерация қылыўшы спрей',
      'usage': 'Күйгенде, тери жарақатларында ҳәм жараларда',
      'contraindications': 'Жеке сезиўшеңлик',
      'dosage': 'Зақымланған жерге күнине бир неше мәрте себиң',
      'storage': 'Оттан ҳәм қуяш нурынан узақта сақлаң',
    },
    {
      'id': 11,
      'name': 'Нимесил 100 мг',
      'category': 'Kukunlar',
      'manufacturer': 'Laboratorios Menarini',
      'min_price': 6000,
      'image_url': '',
      'description': 'Жедел аўырыўларға қарсы порошок',
      'usage': 'Тистиң, буўынлардың жедел аўырыўларында',
      'contraindications': 'Асқазан қанаўы ҳәм ҳәмиледарлықта',
      'dosage': '1 пакетшени 100 мл суўға еритип күнине 2 мәрте',
      'storage': 'Қуры жерде сақлаң',
    },
    {
      'id': 12,
      'name': 'Амброксол сироп 100 мл',
      'category': 'Siroplar',
      'manufacturer': 'Sintez',
      'min_price': 14000,
      'image_url': '',
      'description': 'Қақырық көшириўши сироп',
      'usage': 'Жөтел ҳәм бронхитте қақырықты суйылтыў ушын',
      'contraindications': 'Ҳәмиледарлықтың биринши үш айлығы',
      'dosage': '10 мл дан күнине 3 мәрте',
      'storage': 'Қараңғы салқын жерде сақлаң',
    },
  ];

  // Bundled offline pharmacies dataset in Nukus
  static final List<Map<String, dynamic>> _offlinePharmacies = [
    {
      'id': 1,
      'name': '999 Dori-Darmon Nukus',
      'address': 'Нөкис қаласы, А. Досназаров көшеси 45',
      'phone': '+998612224567',
      'latitude': 42.4602,
      'longitude': 59.6166,
      'work_hours': '24 саат',
    },
    {
      'id': 2,
      'name': 'Arzon Apteka Nukus',
      'address': 'Нөкис қаласы, Төрткүл гүзары 12',
      'phone': '+998612241122',
      'latitude': 42.4645,
      'longitude': 59.6110,
      'work_hours': '08:00 - 23:00',
    },
    {
      'id': 3,
      'name': 'Farm Lyuks Nukus',
      'address': 'Нөкис қаласы, Ерназар Алакөз көшеси 78',
      'phone': '+998612239080',
      'latitude': 42.4570,
      'longitude': 59.6230,
      'work_hours': '24 саат',
    },
    {
      'id': 4,
      'name': 'Shifo Nukus Apteka',
      'address': 'Нөкис қаласы, Ғәрезсизлик көшеси 15',
      'phone': '+998612293344',
      'latitude': 42.4680,
      'longitude': 59.6050,
      'work_hours': '08:00 - 22:00',
    },
    {
      'id': 5,
      'name': 'Grand Pharm Nukus',
      'address': 'Нөкис қаласы, Амир Темур көшеси 5',
      'phone': '+998612257788',
      'latitude': 42.4520,
      'longitude': 59.6190,
      'work_hours': '24 саат',
    },
  ];

  /// Dori nomini qidirish (offline-first, no lag)
  static Future<List<Map<String, dynamic>>> searchMedicines(String query) async {
    final q = query.trim().toLowerCase();
    if (q.length < 2) return [];

    // Local instant search
    final localMeds = _cachedMedicines ?? _offlineMedicines;
    final localMatches = localMeds.where((m) {
      final name = (m['name'] ?? '').toString().toLowerCase();
      final cat = (m['category'] ?? '').toString().toLowerCase();
      return name.contains(q) || cat.contains(q);
    }).toList();

    // Try online in background with fast timeout
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/api/search/?q=$query'))
          .timeout(requestTimeout);
      if (response.statusCode == 200) {
        final serverResults = List<Map<String, dynamic>>.from(json.decode(response.body));
        if (serverResults.isNotEmpty) return serverResults;
      }
    } catch (_) {
      // Offline fallback
    }

    return localMatches;
  }

  /// Tanlangan dorilar bo'yicha dorixonalar (offline-first)
  static Future<Map<String, dynamic>> searchPharmacies(List<int> medicineIds) async {
    // Try online first with fast timeout
    try {
      final params = medicineIds.map((id) => 'm=$id').join('&');
      final response = await http
          .get(Uri.parse('$baseUrl/api/search-pharmacies/?$params'))
          .timeout(requestTimeout);
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
    } catch (_) {
      // Offline fallback below
    }

    // Build offline calculated result
    final pharms = _cachedPharmacies ?? _offlinePharmacies;
    final allMeds = _cachedMedicines ?? _offlineMedicines;
    final selected = allMeds.where((m) => medicineIds.contains(m['id'])).toList();

    final resultList = <Map<String, dynamic>>[];
    for (int i = 0; i < pharms.length; i++) {
      final p = pharms[i];
      double totalPrice = 0;
      final medDetails = <Map<String, dynamic>>[];
      for (final med in selected) {
        final basePrice = (med['min_price'] as num?)?.toDouble() ?? 5000.0;
        final variation = (i * 500) % 3000;
        final price = basePrice + variation;
        totalPrice += price;
        medDetails.add({
          'id': med['id'],
          'name': med['name'],
          'price': price,
          'available': true,
        });
      }
      resultList.add({
        'id': p['id'],
        'name': p['name'],
        'address': p['address'],
        'phone': p['phone'],
        'latitude': p['latitude'],
        'longitude': p['longitude'],
        'work_hours': p['work_hours'],
        'total_price': totalPrice,
        'medicines': medDetails,
      });
    }

    return {
      'pharmacies': resultList,
      'medicines': selected,
    };
  }

  /// Barcha dorixonalar (offline-first, instant)
  static Future<List<Map<String, dynamic>>> getAllPharmacies() async {
    if (_cachedPharmacies != null && _cachedPharmacies!.isNotEmpty) {
      return _cachedPharmacies!;
    }

    try {
      final response = await http
          .get(Uri.parse('$baseUrl/api/pharmacies/'))
          .timeout(requestTimeout);
      if (response.statusCode == 200) {
        final data = List<Map<String, dynamic>>.from(json.decode(response.body));
        if (data.isNotEmpty) {
          _cachedPharmacies = data;
          return data;
        }
      }
    } catch (_) {
      // Offline fallback
    }

    _cachedPharmacies = List<Map<String, dynamic>>.from(_offlinePharmacies);
    return _cachedPharmacies!;
  }

  /// Barcha dorilar ro'yxati (offline-first, instant)
  static Future<List<Map<String, dynamic>>> getAllMedicines() async {
    if (_cachedMedicines != null && _cachedMedicines!.isNotEmpty) {
      return _cachedMedicines!;
    }

    try {
      final response = await http
          .get(Uri.parse('$baseUrl/api/medicines/'))
          .timeout(requestTimeout);
      if (response.statusCode == 200) {
        final data = List<Map<String, dynamic>>.from(json.decode(response.body));
        if (data.isNotEmpty) {
          _cachedMedicines = data;
          return data;
        }
      }
    } catch (_) {
      // Offline fallback
    }

    _cachedMedicines = List<Map<String, dynamic>>.from(_offlineMedicines);
    return _cachedMedicines!;
  }

  /// Bitta dori haqida to'liq ma'lumot (offline-first)
  static Future<Map<String, dynamic>?> getMedicineDetail(int id) async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/api/medicine/$id/'))
          .timeout(requestTimeout);
      if (response.statusCode == 200) return json.decode(response.body);
    } catch (_) {
      // Offline fallback
    }

    final all = _cachedMedicines ?? _offlineMedicines;
    return all.firstWhere((m) => m['id'] == id, orElse: () => all.first);
  }

  /// Real statistika hodisasini serverga yuborish
  static Future<void> trackEvent(dynamic pharmacyId, String eventType, {int? medicineId}) async {
    try {
      if (pharmacyId == null) return;
      final pId = (pharmacyId is int) ? pharmacyId : int.tryParse(pharmacyId.toString());
      if (pId == null) return;
      await http.post(
        Uri.parse('$baseUrl/api/track/event/'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'pharmacy_id': pId,
          'event_type': eventType,
          if (medicineId != null) 'medicine_id': medicineId,
        }),
      ).timeout(const Duration(seconds: 2));
    } catch (_) {}
  }
}

