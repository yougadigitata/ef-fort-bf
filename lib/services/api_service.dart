import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

const String apiBase = 'https://ef-fort-bf.pages.dev/api';

class ApiService {
  static String? _token;
  static Map<String, dynamic>? _currentUser;

  static String cleanPhone(String tel) {
    String digits = tel.replaceAll(RegExp(r'\D'), '');
    return digits.length > 8 ? digits.substring(digits.length - 8) : digits;
  }

  static Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (_token != null) 'Authorization': 'Bearer $_token',
      };

  static Map<String, dynamic>? get currentUser => _currentUser;
  static bool get isLoggedIn => _token != null;
  static bool get isAdmin => _currentUser?['is_admin'] == true;
  static bool get isAbonne => _currentUser?['abonnement_actif'] == true;

  static Future<Map<String, dynamic>> login(String telephone, String password) async {
    try {
      final tel = cleanPhone(telephone);
      final response = await http.post(
        Uri.parse('$apiBase/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'telephone': tel, 'password': password}),
      );
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (data['success'] == true) {
        _token = data['token'] as String;
        _currentUser = data['user'] as Map<String, dynamic>;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('jwt_token', _token!);
        await prefs.setString('user_data', jsonEncode(_currentUser));
      }
      return data;
    } catch (e) {
      if (kDebugMode) debugPrint('Login error: $e');
      return {'error': 'Erreur de connexion. Verifiez votre internet.'};
    }
  }

  static Future<Map<String, dynamic>> inscription({
    required String nom,
    required String prenom,
    required String telephone,
    required String niveau,
    required String password,
  }) async {
    try {
      final tel = cleanPhone(telephone);
      if (tel.length != 8) {
        return {'error': 'Numero de telephone invalide (8 chiffres requis)'};
      }
      final response = await http.post(
        Uri.parse('$apiBase/auth/inscription'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'nom': nom,
          'prenom': prenom,
          'telephone': tel,
          'niveau': niveau,
          'password': password,
        }),
      );
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (data['success'] == true) {
        _token = data['token'] as String;
        _currentUser = data['user'] as Map<String, dynamic>;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('jwt_token', _token!);
        await prefs.setString('user_data', jsonEncode(_currentUser));
      }
      return data;
    } catch (e) {
      if (kDebugMode) debugPrint('Inscription error: $e');
      return {'error': 'Erreur de connexion. Verifiez votre internet.'};
    }
  }

  static Future<Map<String, dynamic>> demarrerSimulation() async {
    try {
      final response = await http.post(
        Uri.parse('$apiBase/simulation/demarrer'),
        headers: _headers,
      );
      return jsonDecode(response.body) as Map<String, dynamic>;
    } catch (e) {
      if (kDebugMode) debugPrint('Simulation error: $e');
      return {'error': 'Erreur de connexion.'};
    }
  }

  static Future<Map<String, dynamic>> terminerSimulation({
    required String sessionId,
    required List<Map<String, String>> reponses,
    required int tempsUtilise,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$apiBase/simulation/terminer'),
        headers: _headers,
        body: jsonEncode({
          'session_id': sessionId,
          'reponses': reponses,
          'temps_utilise': tempsUtilise,
        }),
      );
      return jsonDecode(response.body) as Map<String, dynamic>;
    } catch (e) {
      if (kDebugMode) debugPrint('Terminer sim error: $e');
      return {'error': 'Erreur de connexion.'};
    }
  }

  static Future<List<dynamic>> getMatieres() async {
    try {
      final response = await http.get(
        Uri.parse('$apiBase/matieres'),
        headers: _headers,
      );
      final data = jsonDecode(response.body);
      return (data['matieres'] as List?) ?? [];
    } catch (e) {
      if (kDebugMode) debugPrint('Matieres error: $e');
      return [];
    }
  }

  static Future<List<dynamic>> getQuestions(String matiere, {int limit = 30}) async {
    try {
      final response = await http.get(
        Uri.parse('$apiBase/questions?matiere=$matiere&limit=$limit'),
        headers: _headers,
      );
      final data = jsonDecode(response.body);
      return (data['questions'] as List?) ?? [];
    } catch (e) {
      if (kDebugMode) debugPrint('Questions error: $e');
      return [];
    }
  }

  static Future<List<dynamic>> getActualites() async {
    try {
      final response = await http.get(
        Uri.parse('$apiBase/actualites'),
        headers: _headers,
      );
      final data = jsonDecode(response.body);
      return (data['actualites'] as List?) ?? [];
    } catch (e) {
      if (kDebugMode) debugPrint('Actualites error: $e');
      return [];
    }
  }

  static Future<Map<String, dynamic>> demanderAbonnement(String moyenPaiement) async {
    try {
      final response = await http.post(
        Uri.parse('$apiBase/abonnements/demande'),
        headers: _headers,
        body: jsonEncode({'moyen_paiement': moyenPaiement}),
      );
      return jsonDecode(response.body) as Map<String, dynamic>;
    } catch (e) {
      if (kDebugMode) debugPrint('Abonnement error: $e');
      return {'error': 'Erreur de connexion.'};
    }
  }

  static Future<Map<String, dynamic>> getAdminStats() async {
    try {
      final response = await http.get(
        Uri.parse('$apiBase/admin/stats'),
        headers: _headers,
      );
      return jsonDecode(response.body) as Map<String, dynamic>;
    } catch (e) {
      if (kDebugMode) debugPrint('Admin stats error: $e');
      return {'error': 'Erreur de connexion.'};
    }
  }

  static Future<List<dynamic>> getDemandesAbonnement() async {
    try {
      final response = await http.get(
        Uri.parse('$apiBase/admin/demandes'),
        headers: _headers,
      );
      final data = jsonDecode(response.body);
      return (data['demandes'] as List?) ?? [];
    } catch (e) {
      if (kDebugMode) debugPrint('Demandes error: $e');
      return [];
    }
  }

  static Future<Map<String, dynamic>> validerAbonnement(String id) async {
    try {
      final response = await http.post(
        Uri.parse('$apiBase/admin/valider/$id'),
        headers: _headers,
      );
      return jsonDecode(response.body) as Map<String, dynamic>;
    } catch (e) {
      if (kDebugMode) debugPrint('Valider error: $e');
      return {'error': 'Erreur de connexion.'};
    }
  }

  static Future<Map<String, dynamic>> addQuestion(Map<String, dynamic> question) async {
    try {
      final response = await http.post(
        Uri.parse('$apiBase/admin/questions'),
        headers: _headers,
        body: jsonEncode(question),
      );
      return jsonDecode(response.body) as Map<String, dynamic>;
    } catch (e) {
      return {'error': 'Erreur de connexion.'};
    }
  }

  static Future<Map<String, dynamic>> addActualite(Map<String, dynamic> actu) async {
    try {
      final response = await http.post(
        Uri.parse('$apiBase/admin/actualites'),
        headers: _headers,
        body: jsonEncode(actu),
      );
      return jsonDecode(response.body) as Map<String, dynamic>;
    } catch (e) {
      return {'error': 'Erreur de connexion.'};
    }
  }

  static Future<void> logout() async {
    _token = null;
    _currentUser = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('jwt_token');
    await prefs.remove('user_data');
  }

  static Future<bool> loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');
    final userData = prefs.getString('user_data');
    if (token != null && userData != null) {
      _token = token;
      _currentUser = jsonDecode(userData) as Map<String, dynamic>;
      return true;
    }
    return false;
  }
}
