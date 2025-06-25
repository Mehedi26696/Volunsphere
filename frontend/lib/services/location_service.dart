import 'dart:convert';
import 'package:http/http.dart' as http;

class LocationService {
  static List<dynamic>? _cachedData; 
  static List<String>? _cachedCountries;
  static Map<String, List<String>> _cachedCities = {};

  static const _apiUrl = 'https://countriesnow.space/api/v0.1/countries/';

   
  static Future<void> _fetchData() async {
    if (_cachedData != null) return;

    final response = await http.get(Uri.parse(_apiUrl));
    if (response.statusCode == 200) {
      final jsonData = jsonDecode(response.body);
      if (jsonData['error'] == false && jsonData['data'] != null) {
        _cachedData = jsonData['data'] as List<dynamic>;
      } else {
        throw Exception('API returned error or empty data');
      }
    } else {
      throw Exception('Failed to fetch countries and cities');
    }
  }

  
  static Future<List<String>> getCountries() async {
    await _fetchData();

    if (_cachedCountries != null) return _cachedCountries!;

    _cachedCountries = _cachedData!
        .map<String>((e) => e['country'] as String)
        .toList()
      ..sort();

    return _cachedCountries!;
  }

 
  static Future<List<String>> getCitiesByCountry(String country) async {
    await _fetchData();

    if (_cachedCities.containsKey(country)) {
      return _cachedCities[country]!;
    }

    final countryData = _cachedData!.firstWhere(
      (e) => e['country'] == country,
      orElse: () => null,
    );

    if (countryData != null && countryData['cities'] != null) {
      final cities = List<String>.from(countryData['cities']);
      cities.sort();
      _cachedCities[country] = cities;
      return cities;
    }

    throw Exception('Cities not found for country: $country');
  }

   
  static void clearCache() {
    _cachedData = null;
    _cachedCountries = null;
    _cachedCities.clear();
  }
}
