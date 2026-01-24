import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/constants/api_constants.dart';
import '../data/models/country_model.dart';

class CountriesService {
  Future<List<Country>> getActiveCountries() async {
    // Static return for South Africa
    return [
      Country(
        id: 1,
        name: 'South Africa',
        code: 'ZA',
        flag: 'https://media.api-sports.io/flags/za.svg',
      ),
    ];
  }
}
