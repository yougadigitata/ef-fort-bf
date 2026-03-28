import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'examen_screen.dart';

/// PHASE 3 — Écran de sélection des 10 examens professionnels
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
      'couleur': '#2C3E50',
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
      'couleur': '#E74C3C',
      'icone': '⚕️',
      'nombre_questions': 50,
      'duree_minutes': 90,
      'ordre': 4,
    },
    {
      'id': 'exam_005',
      'nom': 'Éducation & formation',
      'description': 'Enseignants du primaire, enseignants du secondaire',
      'couleur': '#3498DB',
      'icone': '🎓',
      'nombre_questions': 50,
      'duree_minutes': 90,
      'ordre': 5,
    },
    {
      'id': 'exam_006',
      'nom': 'Concours techniques',
      'description': 'Techniciens génie civil, électricité, mécanique, supérieurs',
      'couleur': '#F39C12',
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
      return const Color(0xFF1A5C38);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A2E),
        foregroundColor: Colors.white,
        title: const Text(
          'Choisir votre Concours',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF1A5C38)))
          : Column(
              children: [
                // Header informatif
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  color: const Color(0xFF1A1A2E),
                  child: const Text(
                    '10 examens professionnels · 50 questions · 1h30',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                    ),
                  ),
                ),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _loadExamens,
                    child: GridView.builder(
                      padding: const EdgeInsets.all(16),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 16, // ✅ Espacement vertical 16px
                        crossAxisSpacing: 16, // ✅ Espacement horizontal 16px
                        childAspectRatio: 0.85,
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
    final id = examen['id'] as String? ?? '';

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ExamenScreen(
            examenId: id,
            nomExamen: nom,
            couleur: color,
          ),
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.18),
              blurRadius: 14,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Bandeau couleur en haut
              Container(
                height: 6,
                color: color,
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Icône
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(icone, style: const TextStyle(fontSize: 28)),
                        ),
                      ),
                      const SizedBox(height: 10),
                      // Nom
                      Text(
                        nom,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: color,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 6),
                      // Description courte
                      Text(
                        description,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.black54,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 10),
                      // Badge 50 questions / 1h30
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: color.withValues(alpha: 0.3)),
                            ),
                            child: Text(
                              '50 q.',
                              style: TextStyle(
                                fontSize: 10,
                                color: color,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: color.withValues(alpha: 0.3)),
                            ),
                            child: Text(
                              '1h30',
                              style: TextStyle(
                                fontSize: 10,
                                color: color,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
