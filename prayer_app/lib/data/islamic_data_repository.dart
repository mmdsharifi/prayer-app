import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;
import '../main.dart';

/// Abstract Port / Seam for Islamic Content & Environmental Weather Data
abstract class IslamicDataRepository {
  Future<PrayerData> loadData();
  Future<Map<String, dynamic>?> fetchWeather({
    double lat = 36.5211,
    double lon = 46.2089,
  });
}

/// Offline / Asset-based Adapter
class AssetIslamicDataRepository implements IslamicDataRepository {
  const AssetIslamicDataRepository();

  @override
  Future<PrayerData> loadData() async {
    final s = await rootBundle.loadString('assets/times.json');
    final j = jsonDecode(s);
    final d = PrayerData(
      j['times'],
      Map<String, dynamic>.from(j['months']).cast<String, int>(),
    );
    d.azkar = jsonDecode(await rootBundle.loadString('assets/azkar.json'));
    try {
      final fullAzkarJson =
          jsonDecode(await rootBundle.loadString('assets/azkar_full.json'));
      d.fullMorningAzkar = ((fullAzkarJson['morning'] as List?) ?? [])
          .map((e) => DhikrItem.fromJson(Map<String, dynamic>.from(e)))
          .toList();
      d.fullEveningAzkar = ((fullAzkarJson['evening'] as List?) ?? [])
          .map((e) => DhikrItem.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } catch (_) {
      d.fullMorningAzkar = [];
      d.fullEveningAzkar = [];
    }
    d.schedule =
        (jsonDecode(await rootBundle.loadString('assets/schedule.json')))['schedule_rules'];
    d.hadiths = (jsonDecode(await rootBundle.loadString('assets/hadith.json')))['hadiths'];
    try {
      d.quranJuz =
          (jsonDecode(await rootBundle.loadString('assets/quran_juz.json')))['juz_list'];
    } catch (_) {
      d.quranJuz = [];
    }
    return d;
  }

  @override
  Future<Map<String, dynamic>?> fetchWeather({
    double lat = 36.5211,
    double lon = 46.2089,
  }) async {
    return {
      'temp': 20.0,
      'code': 0,
    };
  }
}

/// Production Network + Asset Fallback Adapter
class HttpIslamicDataRepository implements IslamicDataRepository {
  final AssetIslamicDataRepository _fallback = const AssetIslamicDataRepository();
  final http.Client _client;

  HttpIslamicDataRepository({http.Client? client})
      : _client = client ?? http.Client();

  @override
  Future<PrayerData> loadData() async {
    return _fallback.loadData();
  }

  @override
  Future<Map<String, dynamic>?> fetchWeather({
    double lat = 36.5211,
    double lon = 46.2089,
  }) async {
    try {
      final url = Uri.parse(
        'https://api.open-meteo.com/v1/forecast?latitude=$lat&longitude=$lon&current=temperature_2m,weather_code',
      );
      final res = await _client.get(url).timeout(const Duration(seconds: 4));
      if (res.statusCode == 200) {
        final j = jsonDecode(res.body);
        final cur = j['current'];
        return {
          'temp': (cur['temperature_2m'] as num).toDouble(),
          'code': cur['weather_code'] as int,
        };
      }
    } catch (_) {
      // Graceful fallback on network failure
    }
    return null;
  }
}
