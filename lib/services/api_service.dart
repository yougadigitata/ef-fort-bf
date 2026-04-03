import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

const String apiBase = 'https://ef-fort-bf.yembuaro29.workers.dev/api';

class ApiService {
  static String? _token;
  static Map<String, dynamic>? _currentUser;

  // ── Cache en mémoire (performances) ──
  static List<dynamic>? _cachedMatieres;
  static DateTime? _matieresCacheTime;
  static List<dynamic>? _cachedExamens;
  static DateTime? _examensCacheTime;
  static const Duration _cacheDuration = Duration(minutes: 5);

  static String cleanPhone(String tel) {
    String digits = tel.replaceAll(RegExp(r'\D'), '');
    return digits.length > 8 ? digits.substring(digits.length - 8) : digits;
  }

  static Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (_token != null) 'Authorization': 'Bearer $_token',
      };

  static Map<String, dynamic>? get currentUser => _currentUser;
  static String? get token => _token;
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
      // Vérifier le cache
      if (_cachedMatieres != null && _matieresCacheTime != null) {
        if (DateTime.now().difference(_matieresCacheTime!) < _cacheDuration) {
          return _cachedMatieres!;
        }
      }
      final response = await http.get(
        Uri.parse('$apiBase/matieres'),
        headers: _headers,
      ).timeout(const Duration(seconds: 10));
      final data = jsonDecode(response.body);
      final matieres = (data['matieres'] as List?) ?? [];
      // Mettre en cache
      _cachedMatieres = matieres;
      _matieresCacheTime = DateTime.now();
      return matieres;
    } catch (e) {
      if (kDebugMode) debugPrint('Matieres error: $e');
      return _cachedMatieres ?? [];
    }
  }

  static Future<List<dynamic>> getExamens() async {
    try {
      // Vérifier le cache
      if (_cachedExamens != null && _examensCacheTime != null) {
        if (DateTime.now().difference(_examensCacheTime!) < _cacheDuration) {
          return _cachedExamens!;
        }
      }
      final response = await http.get(
        Uri.parse('$apiBase/examens'),
        headers: _headers,
      ).timeout(const Duration(seconds: 10));
      final data = jsonDecode(response.body);
      final examens = (data['examens'] as List?) ?? [];
      _cachedExamens = examens;
      _examensCacheTime = DateTime.now();
      return examens;
    } catch (e) {
      if (kDebugMode) debugPrint('Examens error: $e');
      return _cachedExamens ?? [];
    }
  }

  static Future<List<dynamic>> getExamenQuestions(String examenId) async {
    try {
      final response = await http.get(
        Uri.parse('$apiBase/examens/$examenId/questions'),
        headers: _headers,
      ).timeout(const Duration(seconds: 15));
      final data = jsonDecode(response.body);
      return (data['questions'] as List?) ?? [];
    } catch (e) {
      if (kDebugMode) debugPrint('ExamenQuestions error: $e');
      return [];
    }
  }

  static Future<List<dynamic>> getQuestions(String matiere, {int limit = 20}) async {
    try {
      final response = await http.get(
        Uri.parse('$apiBase/questions?matiere=$matiere&limit=$limit'),
        headers: _headers,
      ).timeout(const Duration(seconds: 10));
      final data = jsonDecode(response.body);
      return (data['questions'] as List?) ?? [];
    } catch (e) {
      if (kDebugMode) debugPrint('Questions error: $e');
      return [];
    }
  }

  // ── Récupérer les questions d'une série spécifique (WhatsApp QCM) ──
  // Limite haute (1000) pour récupérer TOUTES les questions de la série
  static Future<List<dynamic>> getQuestionsBySerie(String serieId, {int limit = 1000}) async {
    try {
      final response = await http.get(
        Uri.parse('$apiBase/questions?serie_id=$serieId&limit=$limit'),
        headers: _headers,
      ).timeout(const Duration(seconds: 15));
      final data = jsonDecode(response.body);
      return (data['questions'] as List?) ?? [];
    } catch (e) {
      if (kDebugMode) debugPrint('QuestionsBySerie error: $e');
      return [];
    }
  }

  // ── Récupérer les séries d'une matière ────────────────────────────
  static Future<List<dynamic>> getSeriesByMatiere(String matiereId) async {
    try {
      final response = await http.get(
        Uri.parse('$apiBase/series?matiere_id=$matiereId'),
        headers: _headers,
      ).timeout(const Duration(seconds: 10));
      final data = jsonDecode(response.body);
      return (data['series'] as List?) ?? [];
    } catch (e) {
      if (kDebugMode) debugPrint('Series error: $e');
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
      ).timeout(const Duration(seconds: 15));

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 200 || response.statusCode == 201) {
        return {'success': true, ...data};
      }
      return {'error': data['error'] ?? 'Erreur lors de la publication (code ${response.statusCode})'};
    } catch (e) {
      if (kDebugMode) debugPrint('addActualite error: $e');
      return {'error': 'Erreur de connexion. Vérifiez votre internet.'};
    }
  }

  // ══════════════════════════════════════════════════════════════
  // ENTRAIDE v3.0 — Statuts via API Cloudflare Workers
  // Utilise /api/statuts (GET/POST/DELETE)
  // ══════════════════════════════════════════════════════════════

  /// Récupérer les statuts actifs (moins de 24h) via API
  static Future<List<Map<String, dynamic>>> getStatuts() async {
    try {
      final response = await http.get(
        Uri.parse('$apiBase/statuts'),
        headers: _headers,
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final list = data['statuts'] as List? ?? [];
        return list.map((e) => e as Map<String, dynamic>).toList();
      }
      if (kDebugMode) debugPrint('getStatuts HTTP ${response.statusCode}: ${response.body}');
      return [];
    } catch (e) {
      if (kDebugMode) debugPrint('getStatuts error: $e');
      return [];
    }
  }

  /// Publier un statut via API (1 par jour par utilisateur)
  static Future<Map<String, dynamic>> publierStatutAPI({
    required String texte,
    required String type,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$apiBase/statuts'),
        headers: _headers,
        body: jsonEncode({'texte': texte, 'type': type}),
      ).timeout(const Duration(seconds: 10));

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 200 || response.statusCode == 201) {
        return {'success': true};
      }
      if (response.statusCode == 429) {
        return {'error': data['error'] ?? 'Vous avez déjà posté votre statut aujourd\'hui.', 'already_posted': true};
      }
      return {'error': data['error'] ?? 'Erreur lors de la publication'};
    } catch (e) {
      if (kDebugMode) debugPrint('publierStatutAPI error: $e');
      return {'error': 'Erreur de connexion. Vérifiez votre internet.'};
    }
  }

  /// Supprimer son propre statut via API
  static Future<bool> supprimerStatutAPI(String statutId) async {
    try {
      final response = await http.delete(
        Uri.parse('$apiBase/statuts/$statutId'),
        headers: _headers,
      ).timeout(const Duration(seconds: 10));
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      if (kDebugMode) debugPrint('supprimerStatutAPI error: $e');
      return false;
    }
  }

  /// Supprimer N'IMPORTE QUEL statut (admin seulement)
  static Future<bool> adminSupprimerStatut(String statutId) async {
    try {
      final response = await http.delete(
        Uri.parse('$apiBase/statuts/$statutId/admin'),
        headers: _headers,
      ).timeout(const Duration(seconds: 10));
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      if (kDebugMode) debugPrint('adminSupprimerStatut error: $e');
      return false;
    }
  }

  /// Récupérer TOUTES les actualités (y compris inactives) pour l'admin
  static Future<List<Map<String, dynamic>>> getActualitesAdmin() async {
    try {
      final response = await http.get(
        Uri.parse('$apiBase/actualites'),
        headers: _headers,
      ).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final list = data['actualites'] as List? ?? [];
        return list.map((e) => e as Map<String, dynamic>).toList();
      }
      return [];
    } catch (e) {
      if (kDebugMode) debugPrint('getActualitesAdmin error: $e');
      return [];
    }
  }

  /// Supprimer une actualité (admin seulement)
  static Future<bool> supprimerActualite(String id) async {
    try {
      final response = await http.delete(
        Uri.parse('$apiBase/actualites/$id'),
        headers: _headers,
      ).timeout(const Duration(seconds: 10));
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      if (kDebugMode) debugPrint('supprimerActualite error: $e');
      return false;
    }
  }

  /// Modifier une actualité (admin seulement)
  static Future<Map<String, dynamic>> modifierActualite(String id, Map<String, dynamic> data) async {
    try {
      final response = await http.put(
        Uri.parse('$apiBase/actualites/$id'),
        headers: _headers,
        body: jsonEncode(data),
      ).timeout(const Duration(seconds: 10));
      final resp = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 200) return {'success': true, ...resp};
      return {'error': resp['error'] ?? 'Erreur'};
    } catch (e) {
      if (kDebugMode) debugPrint('modifierActualite error: $e');
      return {'error': 'Erreur de connexion.'};
    }
  }

  // ══════════════════════════════════════════════════════════════
  // SIMULATIONS D'EXAMEN — Créées par l'admin, disponibles pour tous
  // ══════════════════════════════════════════════════════════════

  /// Récupérer les simulations publiées par l'admin
  static Future<List<dynamic>> getSimulationsAdmin() async {
    try {
      final response = await http.get(
        Uri.parse('$apiBase/simulations-admin'),
        headers: _headers,
      ).timeout(const Duration(seconds: 10));
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return (data['simulations'] as List?) ?? [];
    } catch (e) {
      if (kDebugMode) debugPrint('getSimulationsAdmin error: $e');
      return [];
    }
  }

  /// Lancer une simulation admin avec ses questions
  static Future<Map<String, dynamic>> demarrerSimulationAdmin(String simulationId) async {
    try {
      final response = await http.post(
        Uri.parse('$apiBase/simulations-admin/$simulationId/demarrer'),
        headers: _headers,
      ).timeout(const Duration(seconds: 15));
      return jsonDecode(response.body) as Map<String, dynamic>;
    } catch (e) {
      if (kDebugMode) debugPrint('demarrerSimulationAdmin error: $e');
      return {'error': 'Erreur de connexion.'};
    }
  }

  // Compatibilité
  static Future<List<dynamic>> getEntraideMsgs() async => [];

  static Future<Map<String, dynamic>> sendEntraideMsgAPI({
    required String contenu,
    bool partagerWhatsApp = false,
    String? telephone,
  }) async {
    return {'error': 'Utilisez ApiService.publierStatutAPI'};
  }

  // ══════════════════════════════════════════════════════════════
  // TÂCHE 4 — Stats utilisateur pour le dashboard
  // ══════════════════════════════════════════════════════════════
  static Future<Map<String, dynamic>> getUserStats() async {
    try {
      final response = await http.get(
        Uri.parse('$apiBase/user/stats'),
        headers: _headers,
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data as Map<String, dynamic>;
      }
      return {'nb_simulations': 0, 'score_moyen': 0.0, 'questions_repondues': 0};
    } catch (e) {
      if (kDebugMode) debugPrint('getUserStats error: $e');
      return {'nb_simulations': 0, 'score_moyen': 0.0, 'questions_repondues': 0};
    }
  }

  // ══════════════════════════════════════════════════════════════
  // TÂCHE 5 — Vérifier si une demande abonnement est en cours
  // ══════════════════════════════════════════════════════════════
  static Future<Map<String, dynamic>> checkPendingSubscription() async {
    try {
      final response = await http.get(
        Uri.parse('$apiBase/abonnements/statut'),
        headers: _headers,
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
      return {'abonnement_actif': false};
    } catch (e) {
      if (kDebugMode) debugPrint('checkPending error: $e');
      return {'abonnement_actif': false};
    }
  }

  static Future<void> logout() async {
    _token = null;
    _currentUser = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('jwt_token');
    await prefs.remove('user_data');
  }

  // ── Changer le mot de passe ──────────────────────────────────
  static Future<Map<String, dynamic>> changePassword(String currentPassword, String newPassword) async {
    try {
      final response = await http.post(
        Uri.parse('${apiBase.replaceAll('/api', '')}/api/admin/change-password'),
        headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $_token'},
        body: jsonEncode({'current_password': currentPassword, 'new_password': newPassword}),
      );
      if (response.statusCode == 200) return jsonDecode(response.body) as Map<String, dynamic>;
      final err = jsonDecode(response.body) as Map<String, dynamic>;
      return {'success': false, 'error': err['error'] ?? 'Erreur ${response.statusCode}'};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  // ── Stats utilisateur en temps réel ────────────────────────
  static Future<Map<String, dynamic>> getUserDashboardStats() async {
    try {
      final response = await http.get(
        Uri.parse('$apiBase/user/dashboard-stats'),
        headers: {
          'Content-Type': 'application/json',
          if (_token != null) 'Authorization': 'Bearer $_token',
        },
      );
      if (response.statusCode == 200) return jsonDecode(response.body) as Map<String, dynamic>;
      return {};
    } catch (e) {
      return {};
    }
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
