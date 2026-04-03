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
      // Matières avec suffisamment de questions en base (vérifiées)
      final matiereOrder = [
        'Psychotechnique',       // 201 questions
        'Figure Africaine',      // 520 questions
        'Économie',              // 220 questions
        'Droit',                 // 220 questions
        'Français',              // 520 questions
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

      // Si on n'a pas 50, compléter avec Droit (220 questions disponibles)
      if (selected.length < totalNeeded) {
        final droitId = matMap.entries
            .where((e) => e.value == 'Droit')
            .map((e) => e.key)
            .firstOrNull;
        if (droitId != null) {
          final droitQ = (byMat[droitId] ?? [])
              .where((q) => !selected.any((s) => s['id'] == q['id']))
              .toList();
          droitQ.shuffle();
          int more = totalNeeded - selected.length;
          for (final q in droitQ.take(more)) {
            selected.add({...q, 'matiere': 'Droit'});
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

  // ═══════════════════════════════════════════════════════════
  // ENTRAIDE v3.0 — Statuts (1 par jour, 24h)
  // Table: statuts_entraide
  //   - user_id, prenom, nom, texte, type, created_at
  //   - Expires automatiquement après 24h (filtré côté client)
  // ═══════════════════════════════════════════════════════════

  /// Charger les statuts actifs (moins de 24h), triés du plus récent au plus ancien
  static Future<List<Map<String, dynamic>>> fetchStatuts() async {
    try {
      // Filtrer côté serveur: created_at >= maintenant - 24h
      final cutoff = DateTime.now().toUtc().subtract(const Duration(hours: 24));
      final cutoffStr = cutoff.toIso8601String();

      // Essayer d'abord avec la table statuts_entraide
      final url = '$_supabaseUrl/rest/v1/statuts_entraide'
          '?select=id,user_id,prenom,nom,texte,type,is_admin,created_at'
          '&created_at=gte.$cutoffStr'
          '&order=created_at.desc'
          '&limit=50';

      final resp = await http.get(Uri.parse(url), headers: _readHeaders)
          .timeout(const Duration(seconds: 10));

      if (resp.statusCode == 200) {
        final raw = jsonDecode(resp.body) as List;
        return raw.cast<Map<String, dynamic>>();
      }

      // Fallback: table messages_entraide si statuts_entraide n'existe pas
      if (resp.statusCode == 404 || resp.body.contains('does not exist')) {
        final fallbackUrl = '$_supabaseUrl/rest/v1/messages_entraide'
            '?select=id,user_id,contenu,created_at,profiles:user_id(prenom,nom)'
            '&created_at=gte.$cutoffStr'
            '&actif=eq.true'
            '&order=created_at.desc'
            '&limit=50';
        final fallback = await http.get(Uri.parse(fallbackUrl), headers: _readHeaders);
        if (fallback.statusCode == 200) {
          final raw = jsonDecode(fallback.body) as List;
          return raw.map((item) {
            final m = item as Map<String, dynamic>;
            final profile = m['profiles'] as Map<String, dynamic>? ?? {};
            return {
              'id': m['id'],
              'user_id': m['user_id'],
              'prenom': profile['prenom'] ?? 'Utilisateur',
              'nom': profile['nom'] ?? '',
              'texte': m['contenu'] ?? '',
              'type': 'info',
              'is_admin': false,
              'created_at': m['created_at'],
            };
          }).toList();
        }
      }
      return [];
    } catch (e) {
      if (kDebugMode) debugPrint('fetchStatuts error: $e');
      return [];
    }
  }

  /// Publier un statut (1 seul par jour par utilisateur)
  static Future<Map<String, dynamic>> publierStatut({
    required String userId,
    required String prenom,
    required String nom,
    required String texte,
    required String type,
  }) async {
    try {
      // Vérifier si l'utilisateur a déjà posté dans les 24 dernières heures
      final cutoff = DateTime.now().toUtc().subtract(const Duration(hours: 24));
      final checkUrl = '$_supabaseUrl/rest/v1/statuts_entraide'
          '?select=id,created_at'
          '&user_id=eq.$userId'
          '&created_at=gte.${cutoff.toIso8601String()}'
          '&limit=1';

      final checkResp = await http.get(Uri.parse(checkUrl), headers: _readHeaders);
      if (checkResp.statusCode == 200) {
        final existing = jsonDecode(checkResp.body) as List;
        if (existing.isNotEmpty) {
          return {'error': 'Vous avez déjà posté votre statut aujourd\'hui. Revenez demain !', 'already_posted': true};
        }
      }

      // Créer le statut
      final body = jsonEncode({
        'user_id': userId,
        'prenom': prenom,
        'nom': nom,
        'texte': texte.trim().substring(0, texte.trim().length > 280 ? 280 : texte.trim().length),
        'type': type,
        'is_admin': false,
        'created_at': DateTime.now().toUtc().toIso8601String(),
      });

      final resp = await http.post(
        Uri.parse('$_supabaseUrl/rest/v1/statuts_entraide'),
        headers: _headers,
        body: body,
      );

      if (resp.statusCode == 201 || resp.statusCode == 200) {
        return {'success': true};
      }

      // Si la table n'existe pas, tenter de créer via messages_entraide
      if (resp.statusCode == 404 || (resp.body.contains('does not exist'))) {
        // Fallback vers messages_entraide
        final fallbackBody = jsonEncode({
          'user_id': userId,
          'contenu': texte.trim(),
          'partage_whatsapp': false,
          'actif': true,
        });
        final fallback = await http.post(
          Uri.parse('$_supabaseUrl/rest/v1/messages_entraide'),
          headers: _headers,
          body: fallbackBody,
        );
        if (fallback.statusCode == 201 || fallback.statusCode == 200) {
          return {'success': true};
        }
        return {'error': 'Table statuts_entraide introuvable. Contactez l\'administrateur.'};
      }

      final errData = jsonDecode(resp.body);
      return {'error': errData['message'] ?? 'Erreur lors de la publication'};
    } catch (e) {
      if (kDebugMode) debugPrint('publierStatut error: $e');
      return {'error': 'Erreur de connexion. Vérifiez votre internet.'};
    }
  }

  /// Supprimer son propre statut
  static Future<bool> supprimerStatut({
    required String statutId,
    required String userId,
  }) async {
    try {
      // Essayer d'abord statuts_entraide
      final resp = await http.delete(
        Uri.parse('$_supabaseUrl/rest/v1/statuts_entraide?id=eq.$statutId&user_id=eq.$userId'),
        headers: _readHeaders,
      );
      if (resp.statusCode == 200 || resp.statusCode == 204) return true;

      // Fallback messages_entraide
      final fallback = await http.patch(
        Uri.parse('$_supabaseUrl/rest/v1/messages_entraide?id=eq.$statutId&user_id=eq.$userId'),
        headers: _headers,
        body: jsonEncode({'actif': false}),
      );
      return fallback.statusCode == 200 || fallback.statusCode == 204;
    } catch (e) {
      if (kDebugMode) debugPrint('supprimerStatut error: $e');
      return false;
    }
  }
}
