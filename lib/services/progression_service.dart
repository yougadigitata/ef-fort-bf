import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'api_service.dart';

// ══════════════════════════════════════════════════════════════
// PROGRESSION SERVICE — Suivi de l'apprentissage e-learning
// Utilise les tables: progression, sessions_examen
// ══════════════════════════════════════════════════════════════

const String _supabaseUrl = 'https://xqifdbgqxyrlhrkwlyir.supabase.co';
const String _supabaseService =
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InhxaWZkYmdxeHlybGhya3dseWlyIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc3NDE3MDQwNSwiZXhwIjoyMDg5NzQ2NDA1fQ.Z0BAcv2IFsBur2CwZrtSnMiA5Z5490XxArU8ULUWYLg';
const String _supabaseAnon =
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InhxaWZkYmdxeHlybGhya3dseWlyIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzQxNzA0MDUsImV4cCI6MjA4OTc0NjQwNX0.d6FybU4zNiZMGa67jUN5LiDSFCBATikv_DmbVz2qgwM';

/// Statistiques globales de l'utilisateur
class UserStats {
  final int nbQuestionsRepondues;
  final int nbBonnesReponses;
  final int nbSimulations;
  final double scoreMoyenSimulation;
  final Map<String, MatiereStats> statsByMatiere;

  UserStats({
    required this.nbQuestionsRepondues,
    required this.nbBonnesReponses,
    required this.nbSimulations,
    required this.scoreMoyenSimulation,
    required this.statsByMatiere,
  });

  /// Taux de réussite global en %
  double get tauxReussiteGlobal {
    if (nbQuestionsRepondues == 0) return 0.0;
    return (nbBonnesReponses / nbQuestionsRepondues) * 100;
  }

  /// Note sur 20 globale
  double get noteSur20 {
    return (tauxReussiteGlobal / 100) * 20;
  }

  static UserStats empty() => UserStats(
        nbQuestionsRepondues: 0,
        nbBonnesReponses: 0,
        nbSimulations: 0,
        scoreMoyenSimulation: 0.0,
        statsByMatiere: {},
      );
}

/// Statistiques par matière
class MatiereStats {
  final String matiereId;
  final String matiereNom;
  final int questionsVues;
  final int questionsCorrectes;
  final String icone;
  final String couleurHex;

  MatiereStats({
    required this.matiereId,
    required this.matiereNom,
    required this.questionsVues,
    required this.questionsCorrectes,
    this.icone = '📚',
    this.couleurHex = '#1A5C38',
  });

  double get tauxReussite {
    if (questionsVues == 0) return 0.0;
    return (questionsCorrectes / questionsVues) * 100;
  }

  double get noteSur20 {
    return (tauxReussite / 100) * 20;
  }
}

class ProgressionService {
  // ── Enregistrer une réponse (dans la table progression) ─────────
  static Future<bool> enregistrerReponse({
    required String questionId,
    required bool estCorrect,
    required String? matiereId,
    String? serieId,
    String? reponseDonnee,
  }) async {
    try {
      final userId = ApiService.currentUser?['id'] as String?;
      if (userId == null) return false;

      // Mise à jour de la table 'progression' (par matière)
      if (matiereId != null) {
        await _updateProgressionMatiere(
          userId: userId,
          matiereId: matiereId,
          estCorrect: estCorrect,
        );
      }

      // Enregistrer aussi dans une table locale (SharedPreferences)
      // pour les stats immédiates sans rechargement
      return true;
    } catch (e) {
      if (kDebugMode) debugPrint('enregistrerReponse error: $e');
      return false;
    }
  }

  static Future<void> _updateProgressionMatiere({
    required String userId,
    required String matiereId,
    required bool estCorrect,
  }) async {
    try {
      // Chercher si une progression existe déjà pour ce user/matière
      final checkUrl =
          '$_supabaseUrl/rest/v1/progression?user_id=eq.$userId&matiere_id=eq.$matiereId';

      final checkResp = await http.get(
        Uri.parse(checkUrl),
        headers: _serviceHeaders,
      );

      if (checkResp.statusCode == 200) {
        final existing = jsonDecode(checkResp.body) as List;

        if (existing.isEmpty) {
          // Créer une nouvelle entrée
          await http.post(
            Uri.parse('$_supabaseUrl/rest/v1/progression'),
            headers: {..._serviceHeaders, 'Prefer': 'return=minimal'},
            body: jsonEncode({
              'user_id': userId,
              'matiere_id': matiereId,
              'questions_vues': 1,
              'questions_correctes': estCorrect ? 1 : 0,
            }),
          );
        } else {
          // Mettre à jour l'entrée existante
          final current = existing[0] as Map<String, dynamic>;
          final vues = ((current['questions_vues'] as int?) ?? 0) + 1;
          final correctes =
              ((current['questions_correctes'] as int?) ?? 0) +
                  (estCorrect ? 1 : 0);
          final entryId = current['id'] as String;

          await http.patch(
            Uri.parse('$_supabaseUrl/rest/v1/progression?id=eq.$entryId'),
            headers: {..._serviceHeaders, 'Prefer': 'return=minimal'},
            body: jsonEncode({
              'questions_vues': vues,
              'questions_correctes': correctes,
              'derniere_activite': DateTime.now().toUtc().toIso8601String(),
            }),
          );
        }
      }
    } catch (e) {
      if (kDebugMode) debugPrint('_updateProgressionMatiere error: $e');
    }
  }

  // ── Récupérer les statistiques complètes d'un utilisateur ───────
  static Future<UserStats> getUserStats() async {
    try {
      final userId = ApiService.currentUser?['id'] as String?;
      if (userId == null) return UserStats.empty();

      // 1. Récupérer les progressions par matière
      final progressionUrl =
          '$_supabaseUrl/rest/v1/progression?user_id=eq.$userId&select=*';
      final progResp = await http.get(
        Uri.parse(progressionUrl),
        headers: _anonHeaders,
      );

      Map<String, MatiereStats> statsByMatiere = {};
      int totalVues = 0;
      int totalCorrectes = 0;

      if (progResp.statusCode == 200) {
        final progressions = jsonDecode(progResp.body) as List;

        // Récupérer les noms des matières
        final matResp = await http.get(
          Uri.parse('$_supabaseUrl/rest/v1/matieres?select=id,nom,icone,couleur'),
          headers: _anonHeaders,
        );

        final Map<String, Map<String, dynamic>> matiereMap = {};
        if (matResp.statusCode == 200) {
          final matieres = jsonDecode(matResp.body) as List;
          for (final m in matieres) {
            final mat = m as Map<String, dynamic>;
            matiereMap[mat['id'] as String] = mat;
          }
        }

        for (final prog in progressions) {
          final p = prog as Map<String, dynamic>;
          final matiereId = p['matiere_id'] as String?;
          if (matiereId == null) continue;

          final matInfo = matiereMap[matiereId];
          final vues = (p['questions_vues'] as int?) ?? 0;
          final correctes = (p['questions_correctes'] as int?) ?? 0;

          totalVues += vues;
          totalCorrectes += correctes;

          statsByMatiere[matiereId] = MatiereStats(
            matiereId: matiereId,
            matiereNom: matInfo?['nom'] as String? ?? 'Matière',
            questionsVues: vues,
            questionsCorrectes: correctes,
            icone: matInfo?['icone'] as String? ?? '📚',
            couleurHex: matInfo?['couleur'] as String? ?? '#1A5C38',
          );
        }
      }

      // 2. Récupérer les sessions d'examen / simulation
      final sessionUrl =
          '$_supabaseUrl/rest/v1/sessions_examen?user_id=eq.$userId&termine=eq.true&select=score,total_questions,type_session';
      final sessResp = await http.get(
        Uri.parse(sessionUrl),
        headers: _anonHeaders,
      );

      int nbSimulations = 0;
      double scoreMoyen = 0.0;

      if (sessResp.statusCode == 200) {
        final sessions = jsonDecode(sessResp.body) as List;
        final List<double> scores = [];
        int simCount = 0;

        for (final s in sessions) {
          final sess = s as Map<String, dynamic>;
          final score = (sess['score'] as num?)?.toDouble() ?? 0;
          final total = (sess['total_questions'] as num?)?.toDouble() ?? 1;
          if (total > 0) {
            scores.add((score / total) * 100);
          }
          simCount++;
        }

        nbSimulations = simCount;
        if (scores.isNotEmpty) {
          scoreMoyen = scores.reduce((a, b) => a + b) / scores.length;
        }
      }

      return UserStats(
        nbQuestionsRepondues: totalVues,
        nbBonnesReponses: totalCorrectes,
        nbSimulations: nbSimulations,
        scoreMoyenSimulation: scoreMoyen,
        statsByMatiere: statsByMatiere,
      );
    } catch (e) {
      if (kDebugMode) debugPrint('getUserStats error: $e');
      return UserStats.empty();
    }
  }

  // ── Enregistrer une session QCM complète ───────────────────────
  static Future<void> enregistrerSessionQCM({
    required String matiereId,
    required int questionsVues,
    required int questionsCorrectes,
  }) async {
    try {
      final userId = ApiService.currentUser?['id'] as String?;
      if (userId == null) return;

      final checkUrl =
          '$_supabaseUrl/rest/v1/progression?user_id=eq.$userId&matiere_id=eq.$matiereId';
      final checkResp =
          await http.get(Uri.parse(checkUrl), headers: _serviceHeaders);

      if (checkResp.statusCode == 200) {
        final existing = jsonDecode(checkResp.body) as List;

        if (existing.isEmpty) {
          await http.post(
            Uri.parse('$_supabaseUrl/rest/v1/progression'),
            headers: {..._serviceHeaders, 'Prefer': 'return=minimal'},
            body: jsonEncode({
              'user_id': userId,
              'matiere_id': matiereId,
              'questions_vues': questionsVues,
              'questions_correctes': questionsCorrectes,
            }),
          );
        } else {
          final current = existing[0] as Map<String, dynamic>;
          final newVues =
              ((current['questions_vues'] as int?) ?? 0) + questionsVues;
          final newCorrectes =
              ((current['questions_correctes'] as int?) ?? 0) +
                  questionsCorrectes;
          final entryId = current['id'] as String;

          await http.patch(
            Uri.parse('$_supabaseUrl/rest/v1/progression?id=eq.$entryId'),
            headers: {..._serviceHeaders, 'Prefer': 'return=minimal'},
            body: jsonEncode({
              'questions_vues': newVues,
              'questions_correctes': newCorrectes,
              'derniere_activite': DateTime.now().toUtc().toIso8601String(),
            }),
          );
        }
      }
    } catch (e) {
      if (kDebugMode) debugPrint('enregistrerSessionQCM error: $e');
    }
  }

  static Map<String, String> get _serviceHeaders => {
        'apikey': _supabaseService,
        'Authorization': 'Bearer ${ApiService.token ?? _supabaseAnon}',
        'Content-Type': 'application/json',
      };

  static Map<String, String> get _anonHeaders => {
        'apikey': _supabaseAnon,
        'Authorization': 'Bearer ${ApiService.token ?? _supabaseAnon}',
        'Content-Type': 'application/json',
      };
}
