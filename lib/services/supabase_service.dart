import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

// ══════════════════════════════════════════════════════════════
// SUPABASE SERVICE — Accès direct REST pour Entraide v2.0
// Tables: messages (questions/réponses), profiles
// ══════════════════════════════════════════════════════════════

const String _supabaseUrl = 'https://xqifdbgqxyrlhrkwlyir.supabase.co';
const String _supabaseAnon =
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InhxaWZkYmdxeHlybGhya3dseWlyIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzQxNzA0MDUsImV4cCI6MjA4OTc0NjQwNX0.d6FybU4zNiZMGa67jUN5LiDSFCBATikv_DmbVz2qgwM';
class SupabaseService {
  static String? _userToken;

  static void setUserAuth(String? token, String? userId) {
    _userToken = token;
    // userId stocké si nécessaire pour les futures requêtes
    // ignore: unused_local_variable
    final _ = userId;
  }

  static Map<String, String> get _headers => {
        'apikey': _supabaseAnon,
        'Authorization': 'Bearer ${_userToken ?? _supabaseAnon}',
        'Content-Type': 'application/json',
        'Prefer': 'return=representation',
      };

  static Map<String, String> get _readHeaders => {
        'apikey': _supabaseAnon,
        'Authorization': 'Bearer ${_userToken ?? _supabaseAnon}',
        'Content-Type': 'application/json',
      };

  // ═══════════════════════════════════════════════════════════
  // ENTRAIDE v2.0 — Questions-Réponses via table `messages`
  //
  // Architecture:
  //   - parent_id = NULL  → c'est une QUESTION (post principal)
  //   - parent_id = uuid  → c'est une RÉPONSE à cette question
  //   - Le champ `contenu` stocke du JSON: {type, titre, categorie, texte}
  //   - Pour les questions: {type:"q", titre:"...", categorie:"...", texte:"..."}
  //   - Pour les réponses:  {type:"r", texte:"..."}
  // ═══════════════════════════════════════════════════════════

  /// Charger les questions (parent_id IS NULL), paginées
  static Future<List<Map<String, dynamic>>> fetchQuestions({
    int page = 0,
    String? categorie,
  }) async {
    try {
      // On charge les messages sans parent (questions)
      // + le profil de l'auteur + le nombre de réponses
      final offset = page * 10;
      final limit = 10;

      String url = '$_supabaseUrl/rest/v1/messages'
          '?select=id,user_id,contenu,likes,created_at,profiles:user_id(prenom,nom,abonnement_actif)'
          '&parent_id=is.null'
          '&order=created_at.desc'
          '&offset=$offset&limit=$limit';

      final response = await http.get(Uri.parse(url), headers: _readHeaders);

      if (response.statusCode == 200) {
        final rawList = jsonDecode(response.body) as List;
        final questions = <Map<String, dynamic>>[];

        for (final item in rawList) {
          final raw = item as Map<String, dynamic>;
          // Parser le contenu JSON
          Map<String, dynamic> contenuData = {};
          try {
            contenuData = jsonDecode(raw['contenu'] as String? ?? '{}')
                as Map<String, dynamic>;
          } catch (_) {
            // Si contenu n'est pas du JSON, c'est un ancien message texte
            contenuData = {'type': 'q', 'titre': raw['contenu'] ?? '', 'texte': '', 'categorie': 'Général'};
          }

          final type = contenuData['type'] as String? ?? 'q';
          if (type != 'q') continue; // Ignorer les réponses dans cette liste

          final cat = contenuData['categorie'] as String? ?? 'Général';
          if (categorie != null && cat != categorie) continue;

          // Compter les réponses
          int nbReponses = 0;
          try {
            final countUrl = '$_supabaseUrl/rest/v1/messages'
                '?select=id&parent_id=eq.${raw['id']}'
                '&limit=1000';
            final countResp = await http.get(
              Uri.parse(countUrl),
              headers: {
                ..._readHeaders,
                'Prefer': 'count=exact',
              },
            );
            final countHeader = countResp.headers['content-range'];
            if (countHeader != null && countHeader.contains('/')) {
              nbReponses = int.tryParse(countHeader.split('/').last) ?? 0;
            }
          } catch (_) {}

          final profile = raw['profiles'] as Map<String, dynamic>? ?? {};

          questions.add({
            'id': raw['id'],
            'auteur_id': raw['user_id'],
            'auteur_prenom': profile['prenom'] ?? 'Anonyme',
            'auteur_nom': profile['nom'] ?? '',
            'titre': contenuData['titre'] ?? '',
            'texte': contenuData['texte'] ?? '',
            'categorie': cat,
            'nb_reponses': nbReponses,
            'likes': raw['likes'] ?? 0,
            'created_at': raw['created_at'],
          });
        }
        return questions;
      }
      return [];
    } catch (e) {
      if (kDebugMode) debugPrint('fetchQuestions error: $e');
      return [];
    }
  }

  /// Charger les réponses d'une question, paginées
  static Future<List<Map<String, dynamic>>> fetchReponses({
    required String questionId,
    int page = 0,
  }) async {
    try {
      final offset = page * 15;
      final url = '$_supabaseUrl/rest/v1/messages'
          '?select=id,user_id,contenu,likes,is_admin_message,created_at,profiles:user_id(prenom,nom)'
          '&parent_id=eq.$questionId'
          '&order=likes.desc,created_at.asc'
          '&offset=$offset&limit=15';

      final response = await http.get(Uri.parse(url), headers: _readHeaders);

      if (response.statusCode == 200) {
        final rawList = jsonDecode(response.body) as List;
        return rawList.map((item) {
          final raw = item as Map<String, dynamic>;
          Map<String, dynamic> contenuData = {};
          try {
            contenuData = jsonDecode(raw['contenu'] as String? ?? '{}')
                as Map<String, dynamic>;
          } catch (_) {
            contenuData = {'texte': raw['contenu'] ?? ''};
          }

          final profile = raw['profiles'] as Map<String, dynamic>? ?? {};
          return {
            'id': raw['id'],
            'auteur_id': raw['user_id'],
            'auteur_prenom': profile['prenom'] ?? 'Anonyme',
            'auteur_nom': profile['nom'] ?? '',
            'texte': contenuData['texte'] ?? raw['contenu'] ?? '',
            'est_meilleure': raw['is_admin_message'] == true, // Réutilise le champ
            'likes': raw['likes'] ?? 0,
            'created_at': raw['created_at'],
          };
        }).toList();
      }
      return [];
    } catch (e) {
      if (kDebugMode) debugPrint('fetchReponses error: $e');
      return [];
    }
  }

  /// Publier une question (réservé aux premium)
  static Future<Map<String, dynamic>> publierQuestion({
    required String userId,
    required String titre,
    required String texte,
    required String categorie,
  }) async {
    try {
      final contenu = jsonEncode({
        'type': 'q',
        'titre': titre,
        'texte': texte,
        'categorie': categorie,
      });

      final response = await http.post(
        Uri.parse('$_supabaseUrl/rest/v1/messages'),
        headers: _headers,
        body: jsonEncode({
          'user_id': userId,
          'contenu': contenu,
          'likes': 0,
          'is_admin_message': false,
        }),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        return {'success': true};
      }
      final err = jsonDecode(response.body);
      return {'error': err['message'] ?? 'Erreur lors de la publication'};
    } catch (e) {
      if (kDebugMode) debugPrint('publierQuestion error: $e');
      return {'error': 'Erreur de connexion'};
    }
  }

  /// Ajouter une réponse à une question
  static Future<Map<String, dynamic>> ajouterReponse({
    required String userId,
    required String questionId,
    required String texte,
  }) async {
    try {
      final contenu = jsonEncode({'type': 'r', 'texte': texte});

      final response = await http.post(
        Uri.parse('$_supabaseUrl/rest/v1/messages'),
        headers: _headers,
        body: jsonEncode({
          'user_id': userId,
          'parent_id': questionId,
          'contenu': contenu,
          'likes': 0,
          'is_admin_message': false,
        }),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        return {'success': true};
      }
      final err = jsonDecode(response.body);
      return {'error': err['message'] ?? 'Erreur lors de l\'envoi'};
    } catch (e) {
      if (kDebugMode) debugPrint('ajouterReponse error: $e');
      return {'error': 'Erreur de connexion'};
    }
  }

  /// Liker une réponse (incrémenter le compteur)
  static Future<bool> likerReponse(String reponseId) async {
    try {
      // D'abord récupérer le nombre de likes actuel
      final getUrl = '$_supabaseUrl/rest/v1/messages?select=likes&id=eq.$reponseId';
      final getResp = await http.get(Uri.parse(getUrl), headers: _readHeaders);
      if (getResp.statusCode != 200) return false;

      final data = jsonDecode(getResp.body) as List;
      if (data.isEmpty) return false;

      final currentLikes = (data[0]['likes'] as int?) ?? 0;

      // Incrémenter
      final patchUrl = '$_supabaseUrl/rest/v1/messages?id=eq.$reponseId';
      final patchResp = await http.patch(
        Uri.parse(patchUrl),
        headers: _headers,
        body: jsonEncode({'likes': currentLikes + 1}),
      );
      return patchResp.statusCode == 200 || patchResp.statusCode == 204;
    } catch (e) {
      if (kDebugMode) debugPrint('likerReponse error: $e');
      return false;
    }
  }

  /// Marquer comme meilleure réponse (réutilise is_admin_message)
  static Future<bool> marquerMeilleureReponse({
    required String reponseId,
    required String questionId,
  }) async {
    try {
      // Retirer l'ancienne meilleure réponse pour cette question
      await http.patch(
        Uri.parse('$_supabaseUrl/rest/v1/messages?parent_id=eq.$questionId'),
        headers: _headers,
        body: jsonEncode({'is_admin_message': false}),
      );

      // Marquer la nouvelle
      final resp = await http.patch(
        Uri.parse('$_supabaseUrl/rest/v1/messages?id=eq.$reponseId'),
        headers: _headers,
        body: jsonEncode({'is_admin_message': true}),
      );
      return resp.statusCode == 200 || resp.statusCode == 204;
    } catch (e) {
      if (kDebugMode) debugPrint('marquerMeilleureReponse error: $e');
      return false;
    }
  }

  // ═══════════════════════════════════════════════════════════
  // EXAMEN BLANC — Utilisation des tables existantes
  // ═══════════════════════════════════════════════════════════

  /// Charger les questions pour un examen (depuis la table questions existante)
  /// Retourne 50 questions réparties sur 5 matières
  static Future<List<Map<String, dynamic>>> getExamenBlanc50Questions() async {
    try {
      // Récupérer toutes les matières avec suffisamment de questions
      final allQ = await _getAllQuestions();

      // Organiser par matière
      final Map<String, List<Map<String, dynamic>>> byMat = {};
      for (final q in allQ) {
        final mid = q['matiere_id'] as String? ?? 'unknown';
        byMat.putIfAbsent(mid, () => []).add(q);
      }

      // Sélectionner 50 questions : 10 par matière (5 matières)
      // ou distribuer équitablement
      final selected = <Map<String, dynamic>>[];
      // Récupérer les matières
      final matResp = await http.get(
        Uri.parse('$_supabaseUrl/rest/v1/matieres?select=id,nom,code'),
        headers: _readHeaders,
      );

      final matList = jsonDecode(matResp.body) as List;
      final matMap = <String, String>{};
      for (final m in matList) {
        matMap[m['id'] as String] = m['nom'] as String? ?? '';
      }

      // Pour chaque matière disponible, prendre jusqu'à 10 questions
      const int quota = 10;
      const int totalNeeded = 50;
      final matiereOrder = [
        'Culture Générale',
        'Français',
        'Mathématiques',
        'Histoire-Géographie',
        'Sciences PC/SVT',
      ];

      for (final matName in matiereOrder) {
        if (selected.length >= totalNeeded) break;
        // Trouver les questions de cette matière
        final matId = matMap.entries
            .where((e) => e.value == matName)
            .map((e) => e.key)
            .firstOrNull;
        if (matId == null) continue;

        final matQuestions = byMat[matId] ?? [];
        if (matQuestions.isEmpty) continue;

        // Mélanger et prendre jusqu'à quota
        matQuestions.shuffle();
        final take = matQuestions.take(quota).toList();
        for (final q in take) {
          selected.add({
            ...q,
            'matiere': matName,
          });
        }
      }

      // Si on n'a pas 50, compléter avec Culture Générale
      if (selected.length < totalNeeded) {
        final cgId = matMap.entries
            .where((e) => e.value == 'Culture Générale')
            .map((e) => e.key)
            .firstOrNull;
        if (cgId != null) {
          final cgQ = (byMat[cgId] ?? [])
              .where((q) => !selected.any((s) => s['id'] == q['id']))
              .toList();
          cgQ.shuffle();
          int more = totalNeeded - selected.length;
          for (final q in cgQ.take(more)) {
            selected.add({...q, 'matiere': 'Culture Générale'});
          }
        }
      }

      // Numéroter
      for (int i = 0; i < selected.length; i++) {
        selected[i]['numero_examen'] = i + 1;
      }

      return selected.take(50).toList();
    } catch (e) {
      if (kDebugMode) debugPrint('getExamenBlanc50Questions error: $e');
      return [];
    }
  }

  static Future<List<Map<String, dynamic>>> _getAllQuestions() async {
    try {
      final resp = await http.get(
        Uri.parse(
            '$_supabaseUrl/rest/v1/questions?select=id,matiere_id,numero,enonce,option_a,option_b,option_c,option_d,option_e,bonne_reponse,explication&limit=500'),
        headers: _readHeaders,
      );
      if (resp.statusCode == 200) {
        return (jsonDecode(resp.body) as List)
            .cast<Map<String, dynamic>>();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  /// Sauvegarder le résultat d'un examen blanc
  static Future<bool> saveExamenBlanc({
    required String userId,
    required int score,
    required int total,
    required int tempsUtilise,
    required Map<int, Set<String>> reponses,
  }) async {
    try {
      final pourcentage = total > 0 ? (score / total * 100).round() : 0;
      final resp = await http.post(
        Uri.parse('$_supabaseUrl/rest/v1/sessions_examen'),
        headers: _headers,
        body: jsonEncode({
          'user_id': userId,
          'type_session': 'EXAMEN_BLANC',
          'score': score,
          'total_questions': total,
          'temps_utilise': tempsUtilise,
          'termine': true,
          'details': jsonEncode({
            'pourcentage': pourcentage,
            'reponses': reponses.map((k, v) => MapEntry(k.toString(), v.toList())),
          }),
        }),
      );
      return resp.statusCode == 201 || resp.statusCode == 200;
    } catch (e) {
      if (kDebugMode) debugPrint('saveExamenBlanc error: $e');
      return false;
    }
  }

  // ═══════════════════════════════════════════════════════════
  // PROFIL — Vérifier le statut premium
  // ═══════════════════════════════════════════════════════════
  static Future<bool> isUserPremium(String userId) async {
    try {
      final resp = await http.get(
        Uri.parse(
            '$_supabaseUrl/rest/v1/profiles?select=abonnement_actif&id=eq.$userId'),
        headers: _readHeaders,
      );
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body) as List;
        if (data.isNotEmpty) {
          return data[0]['abonnement_actif'] == true;
        }
      }
      return false;
    } catch (e) {
      return false;
    }
  }
}
