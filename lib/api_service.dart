// lib/api_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'giveaway.dart';

class ApiService {
  static const String baseUrl = 'https://freegamesapi.onrender.com';

  Future<List<Giveaway>> fetchGiveaways() async {
    final response = await http.get(Uri.parse('$baseUrl/giveaways'));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final giveawaysJson = data['giveaways'] as List;
      return giveawaysJson.map((json) => Giveaway.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load giveaways');
    }
  }

  Future<List<Giveaway>> fetchOtherGiveaways() async {
    final response = await http.get(Uri.parse('$baseUrl/other-giveaways'));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final giveawaysJson = data['giveaways'] as List;
      return giveawaysJson.map((json) => Giveaway.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load other giveaways');
    }
  }

  Future<List<Giveaway>> fetchDlcGiveaways() async {
    final response = await http.get(Uri.parse('$baseUrl/dlc-giveaways'));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final giveawaysJson = data['dlc_giveaways'] as List;
      return giveawaysJson.map((json) => Giveaway.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load DLC giveaways');
    }
  }
}
