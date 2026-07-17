import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'api_service.dart';

// ══════════════════════════════════════════════════════════════
// COURS SERVICE — e-learning v2.0 EF-FORT.BF
// Gestion des chapitres, leçons et progression
// ══════════════════════════════════════════════════════════════

const String _supabaseUrl = 'https://xqifdbgqxyrlhrkwlyir.supabase.co';
const String _supabaseAnon =
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InhxaWZkYmdxeHlybGhya3dseWlyIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzQxNzA0MDUsImV4cCI6MjA4OTc0NjQwNX0.d6FybU4zNiZMGa67jUN5LiDSFCBATikv_DmbVz2qgwM';
const String _supabaseService =
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InhxaWZkYmdxeHlybGhya3dseWlyIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc3NDE3MDQwNSwiZXhwIjoyMDg5NzQ2NDA1fQ.Z0BAcv2IFsBur2CwZrtSnMiA5Z5490XxArU8ULUWYLg';

/// Modèle d'un chapitre
class Chapitre {
  final String id;
  final String matiereId;
  final String titre;
  final String? description;
  final int ordre;
  final List<Lecon> lecons;

  Chapitre({
    required this.id,
    required this.matiereId,
    required this.titre,
    this.description,
    required this.ordre,
    this.lecons = const [],
  });

  factory Chapitre.fromJson(Map<String, dynamic> json) {
    final leconsData = json['lecons'] as List<dynamic>? ?? [];
    return Chapitre(
      id: json['id'] as String? ?? '',
      matiereId: json['matiere_id'] as String? ?? '',
      titre: json['titre'] as String? ?? '',
      description: json['description'] as String?,
      ordre: (json['ordre'] as num?)?.toInt() ?? 0,
      lecons: leconsData
          .map((l) => Lecon.fromJson(l as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'matiere_id': matiereId,
        'titre': titre,
        'description': description,
        'ordre': ordre,
      };
}

/// Modèle d'une leçon
class Lecon {
  final String id;
  final String chapitreId;
  final String titre;
  final String? contenu;
  final String? videoUrl;
  final int ordre;
  final int dureeMinutes;
  bool estTerminee;

  Lecon({
    required this.id,
    required this.chapitreId,
    required this.titre,
    this.contenu,
    this.videoUrl,
    required this.ordre,
    this.dureeMinutes = 10,
    this.estTerminee = false,
  });

  factory Lecon.fromJson(Map<String, dynamic> json) {
    return Lecon(
      id: json['id'] as String? ?? '',
      chapitreId: json['chapitre_id'] as String? ?? '',
      titre: json['titre'] as String? ?? '',
      contenu: json['contenu'] as String?,
      videoUrl: json['video_url'] as String?,
      ordre: (json['ordre'] as num?)?.toInt() ?? 0,
      dureeMinutes: (json['duree_minutes'] as num?)?.toInt() ?? 10,
      estTerminee: json['est_terminee'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'chapitre_id': chapitreId,
        'titre': titre,
        'contenu': contenu,
        'video_url': videoUrl,
        'ordre': ordre,
        'duree_minutes': dureeMinutes,
      };
}

/// Service principal e-learning
class CoursService {
  static Map<String, String> get _headers => {
        'apikey': _supabaseAnon,
        'Authorization': 'Bearer ${ApiService.token ?? _supabaseAnon}',
        'Content-Type': 'application/json',
      };

  static Map<String, String> get _svcHeaders => {
        'apikey': _supabaseService,
        'Authorization': 'Bearer $_supabaseService',
        'Content-Type': 'application/json',
      };

  // ── Worker API ──────────────────────────────────────────────
  static Map<String, String> get _workerHeaders => {
        'Content-Type': 'application/json',
        if (ApiService.token != null)
          'Authorization': 'Bearer ${ApiService.token}',
      };

  // ──────────────────────────────────────────────────────────
  // CHAPITRES
  // ──────────────────────────────────────────────────────────

  /// Récupérer les chapitres d'une matière
  static Future<List<Chapitre>> getChapitresByMatiere(String matiereId) async {
    try {
      // D'abord essayer via le Worker
      final workerResp = await http
          .get(
            Uri.parse('${apiBase}/cours/chapitres?matiere_id=$matiereId'),
            headers: _workerHeaders,
          )
          .timeout(const Duration(seconds: 10));

      if (workerResp.statusCode == 200) {
        final data = jsonDecode(workerResp.body) as Map<String, dynamic>;
        if (data['success'] == true) {
          final chapitres = (data['chapitres'] as List<dynamic>? ?? [])
              .map((c) => Chapitre.fromJson(c as Map<String, dynamic>))
              .toList();
          return chapitres;
        }
      }

      // Fallback: Supabase direct
      final url =
          '$_supabaseUrl/rest/v1/chapitres?matiere_id=eq.$matiereId&select=id,matiere_id,titre,description,ordre&order=ordre.asc';
      final resp = await http.get(Uri.parse(url), headers: _headers);
      if (resp.statusCode == 200) {
        final list = jsonDecode(resp.body) as List;
        return list
            .map((c) => Chapitre.fromJson(c as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      if (kDebugMode) debugPrint('getChapitresByMatiere error: $e');
      return [];
    }
  }

  /// Récupérer un chapitre avec ses leçons
  static Future<Chapitre?> getChapitreWithLecons(String chapitreId) async {
    try {
      // Via Worker
      final workerResp = await http
          .get(
            Uri.parse('${apiBase}/cours/chapitres/$chapitreId'),
            headers: _workerHeaders,
          )
          .timeout(const Duration(seconds: 10));

      if (workerResp.statusCode == 200) {
        final data = jsonDecode(workerResp.body) as Map<String, dynamic>;
        if (data['success'] == true && data['chapitre'] != null) {
          return Chapitre.fromJson(data['chapitre'] as Map<String, dynamic>);
        }
      }

      // Fallback: Supabase direct
      final chapUrl =
          '$_supabaseUrl/rest/v1/chapitres?id=eq.$chapitreId&select=id,matiere_id,titre,description,ordre&limit=1';
      final chapResp = await http.get(Uri.parse(chapUrl), headers: _headers);
      if (chapResp.statusCode != 200) return null;

      final chapList = jsonDecode(chapResp.body) as List;
      if (chapList.isEmpty) return null;

      final chapData = chapList[0] as Map<String, dynamic>;

      // Récupérer les leçons
      final lecUrl =
          '$_supabaseUrl/rest/v1/lecons?chapitre_id=eq.$chapitreId&select=id,chapitre_id,titre,contenu,video_url,ordre,duree_minutes&order=ordre.asc';
      final lecResp = await http.get(Uri.parse(lecUrl), headers: _headers);
      List<Lecon> lecons = [];
      if (lecResp.statusCode == 200) {
        final lecList = jsonDecode(lecResp.body) as List;
        lecons = lecList
            .map((l) => Lecon.fromJson(l as Map<String, dynamic>))
            .toList();
      }

      return Chapitre(
        id: chapData['id'] as String,
        matiereId: chapData['matiere_id'] as String,
        titre: chapData['titre'] as String,
        description: chapData['description'] as String?,
        ordre: (chapData['ordre'] as num?)?.toInt() ?? 0,
        lecons: lecons,
      );
    } catch (e) {
      if (kDebugMode) debugPrint('getChapitreWithLecons error: $e');
      return null;
    }
  }

  // ──────────────────────────────────────────────────────────
  // LEÇONS
  // ──────────────────────────────────────────────────────────

  /// Récupérer le contenu d'une leçon
  static Future<Lecon?> getLecon(String leconId) async {
    try {
      // Via Worker
      final workerResp = await http
          .get(
            Uri.parse('${apiBase}/cours/lecons/$leconId'),
            headers: _workerHeaders,
          )
          .timeout(const Duration(seconds: 10));

      if (workerResp.statusCode == 200) {
        final data = jsonDecode(workerResp.body) as Map<String, dynamic>;
        if (data['success'] == true && data['lecon'] != null) {
          return Lecon.fromJson(data['lecon'] as Map<String, dynamic>);
        }
      }

      // Fallback: Supabase direct
      final url =
          '$_supabaseUrl/rest/v1/lecons?id=eq.$leconId&select=id,chapitre_id,titre,contenu,video_url,ordre,duree_minutes&limit=1';
      final resp = await http.get(Uri.parse(url), headers: _headers);
      if (resp.statusCode == 200) {
        final list = jsonDecode(resp.body) as List;
        if (list.isNotEmpty) {
          return Lecon.fromJson(list[0] as Map<String, dynamic>);
        }
      }
      return null;
    } catch (e) {
      if (kDebugMode) debugPrint('getLecon error: $e');
      return null;
    }
  }

  // ──────────────────────────────────────────────────────────
  // PROGRESSION PAR LEÇON
  // ──────────────────────────────────────────────────────────

  /// Marquer une leçon comme terminée
  static Future<bool> marquerLeconTerminee(String leconId) async {
    try {
      final userId = ApiService.currentUser?['id'] as String?;
      if (userId == null) return false;

      // Via Worker (authentifié)
      if (ApiService.token != null) {
        final resp = await http
            .post(
              Uri.parse('${apiBase}/cours/lecons/$leconId/terminer'),
              headers: _workerHeaders,
              body: jsonEncode({}),
            )
            .timeout(const Duration(seconds: 10));

        if (resp.statusCode == 200) {
          final data = jsonDecode(resp.body) as Map<String, dynamic>;
          return data['success'] == true;
        }
      }

      // Fallback: Supabase direct avec service key (upsert)
      final checkUrl =
          '$_supabaseUrl/rest/v1/user_progress_lecon?user_id=eq.$userId&lecon_id=eq.$leconId&limit=1';
      final checkResp = await http.get(Uri.parse(checkUrl), headers: _svcHeaders);
      
      if (checkResp.statusCode == 200) {
        final existing = jsonDecode(checkResp.body) as List;
        final now = DateTime.now().toUtc().toIso8601String();

        if (existing.isEmpty) {
          // Insérer
          await http.post(
            Uri.parse('$_supabaseUrl/rest/v1/user_progress_lecon'),
            headers: {..._svcHeaders, 'Prefer': 'return=minimal'},
            body: jsonEncode({
              'user_id': userId,
              'lecon_id': leconId,
              'termine': true,
              'date_termine': now,
            }),
          );
        } else {
          // Mettre à jour
          final id = existing[0]['id'] as String;
          await http.patch(
            Uri.parse('$_supabaseUrl/rest/v1/user_progress_lecon?id=eq.$id'),
            headers: {..._svcHeaders, 'Prefer': 'return=minimal'},
            body: jsonEncode({'termine': true, 'date_termine': now}),
          );
        }
        return true;
      }
      return false;
    } catch (e) {
      if (kDebugMode) debugPrint('marquerLeconTerminee error: $e');
      return false;
    }
  }

  /// Récupérer la progression d'un utilisateur (IDs des leçons terminées)
  static Future<Set<String>> getLeconsTerminees() async {
    try {
      final userId = ApiService.currentUser?['id'] as String?;
      if (userId == null) return {};

      // Via Worker
      if (ApiService.token != null) {
        final resp = await http
            .get(
              Uri.parse('${apiBase}/cours/progression'),
              headers: _workerHeaders,
            )
            .timeout(const Duration(seconds: 8));

        if (resp.statusCode == 200) {
          final data = jsonDecode(resp.body) as Map<String, dynamic>;
          final ids = (data['lecons_terminees'] as List<dynamic>? ?? [])
              .cast<String>()
              .toSet();
          return ids;
        }
      }

      // Fallback: Supabase direct
      final url =
          '$_supabaseUrl/rest/v1/user_progress_lecon?user_id=eq.$userId&termine=eq.true&select=lecon_id';
      final resp = await http.get(Uri.parse(url), headers: _headers);
      if (resp.statusCode == 200) {
        final list = jsonDecode(resp.body) as List;
        return list
            .map((l) => (l as Map<String, dynamic>)['lecon_id'] as String)
            .toSet();
      }
      return {};
    } catch (e) {
      if (kDebugMode) debugPrint('getLeconsTerminees error: $e');
      return {};
    }
  }

  /// Calculer le pourcentage d'avancement pour une matière
  static Future<int> getPourcentageMatiere(String matiereId) async {
    try {
      final userId = ApiService.currentUser?['id'] as String?;
      if (userId == null) return 0;

      // Via Worker
      if (ApiService.token != null) {
        final resp = await http
            .get(
              Uri.parse('${apiBase}/cours/progression?matiere_id=$matiereId'),
              headers: _workerHeaders,
            )
            .timeout(const Duration(seconds: 8));

        if (resp.statusCode == 200) {
          final data = jsonDecode(resp.body) as Map<String, dynamic>;
          return (data['pourcentage'] as num?)?.toInt() ?? 0;
        }
      }

      // Fallback local
      final chapitres = await getChapitresByMatiere(matiereId);
      if (chapitres.isEmpty) return 0;

      int totalLecons = 0;
      int termineesCount = 0;
      final terminees = await getLeconsTerminees();

      for (final ch in chapitres) {
        final chapFull = await getChapitreWithLecons(ch.id);
        if (chapFull != null) {
          totalLecons += chapFull.lecons.length;
          termineesCount +=
              chapFull.lecons.where((l) => terminees.contains(l.id)).length;
        }
      }

      if (totalLecons == 0) return 0;
      return ((termineesCount / totalLecons) * 100).round();
    } catch (e) {
      if (kDebugMode) debugPrint('getPourcentageMatiere error: $e');
      return 0;
    }
  }
}
