import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/security_alert.dart';
import '../models/system_stats.dart';
import '../models/user_model.dart';

class ApiService {
  // Singleton
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  // URL officielle Cloud : connectée 24h/24 sur Internet mondial
  String baseUrl = 'https://sentinel-watch-ssty.onrender.com/api/v1';

  UserModel? currentUser;
  String? authToken;

  void setBaseUrl(String newUrl) {
    baseUrl = newUrl.replaceAll(RegExp(r'/+$'), '');
    if (!baseUrl.endsWith('/api/v1')) {
      baseUrl = '$baseUrl/api/v1';
    }
  }

  /// Connexion utilisateur à la console SentinelWatch
  Future<Map<String, dynamic>> login(String usernameOrEmail, String password, {String? serverUrl}) async {
    if (serverUrl != null && serverUrl.isNotEmpty) {
      setBaseUrl(serverUrl);
    }

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username_or_email': usernameOrEmail.trim(),
          'password': password,
        }),
      ).timeout(const Duration(seconds: 25));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        authToken = data['token'];
        currentUser = UserModel.fromJson(data['user']);
        return {'success': true, 'user': currentUser};
      } else {
        final err = jsonDecode(response.body);
        return {'success': false, 'error': err['detail'] ?? 'Identifiants invalides'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Connexion au serveur Cloud ($baseUrl) impossible ou lente à répondre. Réessayez dans quelques secondes.'};
    }
  }

  /// Création d'un nouveau compte utilisateur / analyste
  Future<Map<String, dynamic>> register(String username, String email, String password, {String? fullName, String? organization, String? serverUrl}) async {
    if (serverUrl != null && serverUrl.isNotEmpty) {
      setBaseUrl(serverUrl);
    }

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username.trim(),
          'email': email.trim().toLowerCase(),
          'password': password,
          'full_name': fullName ?? username,
          'role': 'ADMIN',
          if (organization != null && organization.isNotEmpty) 'organization': organization.trim(),
        }),
      ).timeout(const Duration(seconds: 25));

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        authToken = data['token'];
        currentUser = UserModel.fromJson(data['user']);
        return {'success': true, 'user': currentUser};
      } else {
        final err = jsonDecode(response.body);
        return {'success': false, 'error': err['detail'] ?? 'Erreur lors de la création du compte'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Impossible de joindre le serveur Cloud ($baseUrl).'};
    }
  }

  void logout() {
    currentUser = null;
    authToken = null;
  }

  /// Récupère les métadonnées globales de sécurité
  Future<SystemStats> fetchStats() async {
    try {
      String url = '$baseUrl/logs/stats';
      if (currentUser?.organization != null && currentUser!.organization!.isNotEmpty) {
        url += '?organization=${Uri.encodeComponent(currentUser!.organization!)}';
      }
      final response = await http.get(Uri.parse(url)).timeout(
        const Duration(seconds: 15),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return SystemStats.fromJson(data);
      }
    } catch (_) {}
    return SystemStats.empty();
  }

  /// Récupère la liste des alertes de sécurité qualifiées
  Future<List<SecurityAlert>> fetchAlerts({String? status, int limit = 50}) async {
    try {
      String url = '$baseUrl/alerts?limit=$limit';
      if (status != null && status.isNotEmpty) {
        url += '&status=$status';
      }
      if (currentUser?.organization != null && currentUser!.organization!.isNotEmpty) {
        url += '&organization=${Uri.encodeComponent(currentUser!.organization!)}';
      }
      final response = await http.get(Uri.parse(url)).timeout(
        const Duration(seconds: 15),
      );
      if (response.statusCode == 200) {
        final List<dynamic> list = jsonDecode(response.body);
        return list.map((item) => SecurityAlert.fromJson(item)).toList();
      }
    } catch (_) {}
    return [];
  }

  /// Action de remédiation : bannit immédiatement l'adresse IP associée à une alerte
  Future<bool> banIp(int alertId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/alerts/$alertId/ban'),
      ).timeout(const Duration(seconds: 12));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  /// Acquitte ou résout une alerte
  Future<bool> resolveAlert(int alertId, {String status = 'RESOLVED'}) async {
    try {
      final response = await http.patch(
        Uri.parse('$baseUrl/alerts/$alertId'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'status': status}),
      ).timeout(const Duration(seconds: 5));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  /// Récupère la liste noire active
  Future<List<Map<String, dynamic>>> fetchBlacklist() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/blacklist')).timeout(
        const Duration(seconds: 4),
      );
      if (response.statusCode == 200) {
        final List<dynamic> list = jsonDecode(response.body);
        return list.cast<Map<String, dynamic>>();
      }
    } catch (_) {}
    return [];
  }

  /// Débloque une adresse IP
  Future<bool> unbanIp(String ipAddress) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/blacklist/$ipAddress'),
      ).timeout(const Duration(seconds: 4));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}
