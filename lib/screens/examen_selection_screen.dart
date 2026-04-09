import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import 'examen_screen.dart';
import 'examen_immersif_screen.dart';

/// v7.0 — Écran de sélection des examens — Nouveau design coloré
class ExamenSelectionScreen extends StatefulWidget {
  const ExamenSelectionScreen({super.key});

  @override
  State<ExamenSelectionScreen> createState() => _ExamenSelectionScreenState();
}

class _ExamenSelectionScreenState extends State<ExamenSelectionScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Couleurs par catégorie pour le design coloré
  static const Map<String, Color> _examColors = {
    'exam_001': Color(0xFF2980B9),  // Bleu - Administration
    'exam_002': Color(0xFFC0392B),  // Rouge - Justice
    'exam_003': Color(0xFF27AE60),  // Vert - Finances
    'exam_004': Color(0xFF8E44AD),  // Violet - Santé
    'exam_005': Color(0xFF2980B9),  // Bleu - Éducation
    'exam_006': Color(0xFFD4A017),  // Or - Technique
    'exam_007': Color(0xFF27AE60),  // Vert - Agriculture
    'exam_008': Color(0xFF16A085),  // Turquoise - Informatique
    'exam_009': Color(0xFF8E44AD),  // Violet - TP
    'exam_010': Color(0xFF5D6D7E),  // Gris - Stats
  };


  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 1, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }



  Color _parseColor(String? hex) {
    try {
      return Color(int.parse('0xFF${(hex ?? '#1A5C38').replaceAll('#', '')}'));
    } catch (_) {
      return AppColors.primary;
    }
  }

  // Obtenir la couleur par index ou par ID
  Color _getExamColor(dynamic examen, int index) {
    final id = examen['id']?.toString() ?? '';
    if (_examColors.containsKey(id)) return _examColors[id]!;
    final hex = examen['couleur']?.toString();
    if (hex != null && hex.isNotEmpty) return _parseColor(hex);
    // Fallback couleurs par index
    const fallbackColors = [
      Color(0xFF2980B9), Color(0xFFD4A017), Color(0xFF27AE60),
      Color(0xFF16A085), Color(0xFF8E44AD), Color(0xFF5D6D7E),
      Color(0xFFC0392B), Color(0xFFE67E22), Color(0xFF1A5C38),
      Color(0xFF2ECC71),
    ];
    return fallbackColors[index % fallbackColors.length];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F1),
      body: Column(
        children: [
          // ── Header dégradé vert ──────────────────────────────
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.primary, AppColors.primaryDark],
              ),
            ),
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 14,
              bottom: 0,
              left: 20,
              right: 20,
            ),
            child: Column(
              children: [
                // Titre et sous-titre
                const Text(
                  'Examens Types — Choisir votre Concours',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Choisir votre domaine de concours',
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.white.withValues(alpha: 0.75),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 12),
                // Sous-titre (plus de TabBar — un seul écran)
                Text(
                  '11 matières · 30 séries · 50 questions · 1h30',
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.white.withValues(alpha: 0.75),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          // ── Contenu — Examens Types directement ─────────────
          Expanded(
            child: _buildExamensTypesTab(),
          ),
        ],
      ),
    );
  }


  // ─── ONGLET EXAMENS TYPES — Nouvelle interface immersive ─────
  Widget _buildExamensTypesTab() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Illustration
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primary, AppColors.primaryDark],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    blurRadius: 14,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: const Center(
                child: Text('📋', style: TextStyle(fontSize: 42)),
              ),
            ),
            const SizedBox(height: 20),

            // Titre
            const Text(
              'Examens Types Immersifs',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: AppColors.textDark,
                fontFamily: 'Poppins',
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '20 séries officielles · Interface vraie feuille\n50 questions · 1h30 · Correction détaillée',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: AppColors.textLight,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),

            // Badges caractéristiques
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                _buildFeatureBadge('🔔 Cloches officielles', AppColors.primary),
                _buildFeatureBadge('📄 Feuille 2 colonnes', const Color(0xFF2980B9)),
                _buildFeatureBadge('⏱️ Timer 1h30', const Color(0xFFE67E22)),
                _buildFeatureBadge('📊 Correction + PDF', const Color(0xFF27AE60)),
                _buildFeatureBadge('🔒 Soumission après 30min', const Color(0xFF8E44AD)),
              ],
            ),
            const SizedBox(height: 28),

            // Bouton
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ExamenImmersifAccueilScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.play_circle_filled_rounded, size: 26),
                label: const Text(
                  'ACCÉDER AUX EXAMENS TYPES',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.3,
                    fontFamily: 'Poppins',
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 4,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '10 concours × 2 séries = 20 examens types disponibles',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textLight.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1.2),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 14,
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  // ignore: unused_element
  Widget _buildExamenCard(dynamic examen, int index) {
    final color = _getExamColor(examen, index);
    final nom = examen['nom'] as String? ?? '';
    final description = examen['description'] as String? ?? '';
    final icone = examen['icone'] as String? ?? '📋';
    final nbQ = examen['nombre_questions'] as int? ?? 50;
    final duree = examen['duree_minutes'] as int? ?? 90;
    final dureeStr = duree >= 60
        ? '${duree ~/ 60}h${duree % 60 > 0 ? (duree % 60).toString().padLeft(2, '0') : ''}'
        : '${duree}min';
    final examenId = examen['id'] as String? ?? '';

    void lancerSerie(int serie) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ExamenScreen(
            examenId: examenId,
            nomExamen: serie == 2 ? '$nom — Série 2' : nom,
            couleur: color,
            serie: serie,
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: color.withValues(alpha: 0.22),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.13),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 14, 10, 10),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // ── Icône sur pastille colorée ─────────────────
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.13),
                shape: BoxShape.circle,
                border: Border.all(
                  color: color.withValues(alpha: 0.3),
                  width: 1.5,
                ),
              ),
              child: Center(
                child: Text(icone, style: const TextStyle(fontSize: 24)),
              ),
            ),
            const SizedBox(height: 7),

            // ── Nom du concours ────────────────────────────
            Text(
              nom,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w800,
                color: color,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 3),

            // ── Description ────────────────────────────────
            Text(
              description,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 9.5,
                color: Colors.black45,
                height: 1.3,
              ),
            ),

            const Spacer(),

            // ── Badges pilules ─────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildPillBadge('$nbQ q.', color),
                const SizedBox(width: 5),
                _buildPillBadge(
                  dureeStr,
                  color,
                  icon: Icons.access_time_rounded,
                ),
              ],
            ),
            const SizedBox(height: 8),

            // ── 2 boutons Série 1 & Série 2 ───────────────
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => lancerSerie(1),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 7),
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text(
                        'Série 1',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: GestureDetector(
                    onTap: () => lancerSerie(2),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 7),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: color, width: 1.5),
                      ),
                      child: Text(
                        'Série 2',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: color,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── Badge pilule ─────────────────────────────────────────────
  Widget _buildPillBadge(String label, Color color, {IconData? icon}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.30)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 11, color: color),
            const SizedBox(width: 3),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  // ignore: unused_element
  void _showAbonnementDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Text('👑', style: TextStyle(fontSize: 22)),
            SizedBox(width: 8),
            Text('Accès Premium',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
          ],
        ),
        content: const Text(
          'Les examens blancs sont réservés aux abonnés Premium.\n\nAbonnez-vous pour y accéder et pratiquer dans des conditions réelles.',
          style: TextStyle(fontSize: 16, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Plus tard'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text("S'abonner",
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}
