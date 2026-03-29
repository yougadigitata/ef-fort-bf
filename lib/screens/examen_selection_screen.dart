import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../services/api_service.dart';
import 'simulation_screen.dart';

/// PHASE 3 — Écran de sélection des 10 examens professionnels
/// Design harmonisé : header vert, cartes uniformes, sans bandes noires
class ExamenSelectionScreen extends StatefulWidget {
  const ExamenSelectionScreen({super.key});

  @override
  State<ExamenSelectionScreen> createState() => _ExamenSelectionScreenState();
}

class _ExamenSelectionScreenState extends State<ExamenSelectionScreen> {
  List<dynamic> _examens = [];
  bool _loading = true;

  // Données statiques en fallback (si API pas dispo)
  static const List<Map<String, dynamic>> _fallbackExamens = [
    {
      'id': 'exam_001',
      'nom': 'Administration générale',
      'description': 'Adjoints administratifs, agents administratifs, assistants de direction',
      'couleur': '#1A5C38',
      'icone': '📋',
      'nombre_questions': 50,
      'duree_minutes': 90,
      'ordre': 1,
    },
    {
      'id': 'exam_002',
      'nom': 'Justice & sécurité',
      'description': 'Greffiers, police nationale, gendarmerie, douane, eaux et forêts',
      'couleur': '#C0392B',
      'icone': '⚖️',
      'nombre_questions': 50,
      'duree_minutes': 90,
      'ordre': 2,
    },
    {
      'id': 'exam_003',
      'nom': 'Économie & finances',
      'description': 'Impôts, trésor public, contrôleurs des finances, comptabilité publique',
      'couleur': '#27AE60',
      'icone': '💰',
      'nombre_questions': 50,
      'duree_minutes': 90,
      'ordre': 3,
    },
    {
      'id': 'exam_004',
      'nom': 'Concours de la santé',
      'description': 'Infirmiers, sages-femmes, agents de santé',
      'couleur': '#8E44AD',
      'icone': '⚕️',
      'nombre_questions': 50,
      'duree_minutes': 90,
      'ordre': 4,
    },
    {
      'id': 'exam_005',
      'nom': 'Éducation & formation',
      'description': 'Enseignants du primaire, enseignants du secondaire',
      'couleur': '#2980B9',
      'icone': '🎓',
      'nombre_questions': 50,
      'duree_minutes': 90,
      'ordre': 5,
    },
    {
      'id': 'exam_006',
      'nom': 'Concours techniques',
      'description': 'Techniciens génie civil, électricité, mécanique, supérieurs',
      'couleur': '#D4A017',
      'icone': '🔧',
      'nombre_questions': 50,
      'duree_minutes': 90,
      'ordre': 6,
    },
    {
      'id': 'exam_007',
      'nom': 'Agriculture & environnement',
      'description': 'Agents agricoles, élevage, environnement, développement rural',
      'couleur': '#16A085',
      'icone': '🌾',
      'nombre_questions': 50,
      'duree_minutes': 90,
      'ordre': 7,
    },
    {
      'id': 'exam_008',
      'nom': 'Informatique & numérique',
      'description': 'Techniciens informatiques, développeurs, ingénieurs IT',
      'couleur': '#2ECC71',
      'icone': '💻',
      'nombre_questions': 50,
      'duree_minutes': 90,
      'ordre': 8,
    },
    {
      'id': 'exam_009',
      'nom': 'Travaux publics & urbanisme',
      'description': 'BTP, urbanisme, topographie',
      'couleur': '#9B59B6',
      'icone': '🏗️',
      'nombre_questions': 50,
      'duree_minutes': 90,
      'ordre': 9,
    },
    {
      'id': 'exam_010',
      'nom': 'Statistiques & planification',
      'description': 'Statisticiens, économistes, planificateurs',
      'couleur': '#34495E',
      'icone': '📊',
      'nombre_questions': 50,
      'duree_minutes': 90,
      'ordre': 10,
    },
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadExamens());
  }

  Future<void> _loadExamens() async {
    setState(() { _loading = true; });
    try {
      final data = await ApiService.getExamens();
      if (mounted) {
        setState(() {
          _examens = data.isNotEmpty ? data : _fallbackExamens;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _examens = _fallbackExamens;
          _loading = false;
        });
      }
    }
  }

  Color _parseColor(String hex) {
    try {
      return Color(int.parse('0xFF${hex.replaceAll('#', '')}'));
    } catch (_) {
      return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.primary, AppColors.primaryDark],
            ),
          ),
        ),
        foregroundColor: AppColors.white,
        elevation: 0,
        title: const Text(
          'Choisir votre Concours',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : Column(
              children: [
                // Header informatif — même couleur que l'AppBar (vert)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.primaryDark, AppColors.primary],
                    ),
                  ),
                  child: const Text(
                    '10 examens professionnels · 50 questions · 1h30',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _loadExamens,
                    color: AppColors.primary,
                    child: GridView.builder(
                      padding: const EdgeInsets.all(14),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 14,
                        crossAxisSpacing: 14,
                        // Ratio harmonisé pour que toutes les cartes soient identiques
                        childAspectRatio: 0.88,
                      ),
                      itemCount: _examens.length,
                      itemBuilder: (ctx, i) => _buildExamenCard(_examens[i]),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildExamenCard(dynamic examen) {
    final color = _parseColor(examen['couleur'] ?? '#1A5C38');
    final nom = examen['nom'] as String? ?? '';
    final description = examen['description'] as String? ?? '';
    final icone = examen['icone'] as String? ?? '📋';

    return GestureDetector(
      onTap: () {
        // Flow : directement vers l'écran de lancement simulation
        final user = ApiService.currentUser;
        final nomCandidat = user != null
            ? '${user['prenom'] ?? ''} ${user['nom'] ?? ''}'.trim()
            : 'Candidat';
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ExamWelcomeSlide(
              candidatName: nomCandidat.isNotEmpty ? nomCandidat : 'Candidat',
              examenNom: nom,
            ),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.15),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Icône dans un cercle coloré
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: color.withValues(alpha: 0.3),
                    width: 1.5,
                  ),
                ),
                child: Center(
                  child: Text(icone, style: const TextStyle(fontSize: 26)),
                ),
              ),
              const SizedBox(height: 8),
              // Nom de l'examen
              Text(
                nom,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: color,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 4),
              // Description courte
              Text(
                description,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 10,
                  color: Colors.black45,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 8),
              // Badges 50 questions / 1h30
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _badge('50 q.', color),
                  const SizedBox(width: 6),
                  _badge('1h30', color),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _badge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
