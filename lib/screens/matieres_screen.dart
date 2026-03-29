import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import 'qcm_screen.dart';
import 'serie_selection_screen.dart';

// ══════════════════════════════════════════════════════════════
// IDs Supabase des matières — Phase 3 (Banque QCM complète)
// Mise à jour après import massif de 3736 questions
// ══════════════════════════════════════════════════════════════
const Map<String, String> _matiereSupabaseIds = {
  // ── Matières avec séries (WhatsApp QCM) ──
  'hg':     '0a88b3ac-33b7-4d8c-bc19-fe68bb514aef', // Histoire-Géographie
  'droit2': '9497ca2c-dc1b-43dd-8b7a-af11dde7039d', // Droit (26 séries)
  'eco2':   '756e1ca6-7f7f-4f42-940a-b6d9952ffcdf', // Économie (52 séries)
  'ang':    '37febc5e-8ab5-4875-b7ad-71b30a8253e7', // Anglais (51 séries)
  'sp':     '12e5b05a-6410-4b55-97b7-b8a838dcfb9a', // Sciences Physiques
  // ── Nouvelles matières importées (Phase 3) ──
  'psycho': 'cbd22275-d260-40d1-8ff3-d31545f3f1ab', // Psychotechnique (31 séries)
  'histo':  '104f51e4-be6e-4ce8-961e-56e604818670', // Figure Africaine (30 séries)
  'info':   'a72cc6f9-1282-4c2a-ae19-298933047694', // Informatique (20 séries)
  'comm':   'cc979206-e60d-4224-940d-943b8c68c8fa', // Communication (2 séries)
};

// Compteurs de séries par matière (info pour affichage)
const Map<String, int> _nbSeriesParMatiere = {
  'hg':     13,
  'droit2': 51,
  'eco2':   52,
  'ang':    51,
  'sp':     0,
  'psycho': 31,
  'histo':  30,
  'info':   20,
  'comm':   2,
};

// Matières utilisant le mode SerieSelection (QCM avec séries)
const Set<String> _whatsappMatieres = {
  'hg', 'droit2', 'eco2', 'ang',
  'psycho', 'histo', 'info', 'comm',
};

/// PHASE 3 — Les 16 matières officielles EF-FORT.BF
class MatieresScreen extends StatefulWidget {
  const MatieresScreen({super.key});

  @override
  State<MatieresScreen> createState() => _MatieresScreenState();
}

class _MatieresScreenState extends State<MatieresScreen> {

  // ══════════════════════════════════════════════════════════
  // LES 16 MATIÈRES OFFICIELLES — Phase 3
  // ══════════════════════════════════════════════════════════
  static const List<Map<String, dynamic>> _matieresList = [
    {
      'id': 'psycho',
      'nom': 'Psychotechnique',
      'icone': '🧩',
      'couleur': Color(0xFF8E44AD),
      'description': 'Séries, matrices, raisonnement logique, dominos...',
    },
    {
      'id': 'histo',
      'nom': 'Figure Africaine',
      'icone': '👤',
      'couleur': Color(0xFFC0392B),
      'description': 'Grandes figures africaines et burkinabè...',
    },
    {
      'id': 'droit2',
      'nom': 'Droit',
      'icone': '⚖️',
      'couleur': Color(0xFF2C3E50),
      'description': 'Droit public, administratif, constitutionnel...',
    },
    {
      'id': 'eco2',
      'nom': 'Économie',
      'icone': '💰',
      'couleur': Color(0xFF27AE60),
      'description': 'Microéconomie, macroéconomie, finances...',
    },
    {
      'id': 'ang',
      'nom': 'Anglais',
      'icone': '🗣️',
      'couleur': Color(0xFF2980B9),
      'description': 'Grammaire anglaise, vocabulaire, compréhension...',
    },
    {
      'id': 'info',
      'nom': 'Informatique',
      'icone': '💻',
      'couleur': Color(0xFF2ECC71),
      'description': 'Bureautique, systèmes, réseaux, programmation...',
    },
    {
      'id': 'comm',
      'nom': 'Communication',
      'icone': '📢',
      'couleur': Color(0xFFE67E22),
      'description': 'Communication institutionnelle, médias, presse...',
    },
    {
      'id': 'maths',
      'nom': 'Mathématiques',
      'icone': '🔢',
      'couleur': Color(0xFF3498DB),
      'description': 'Calculs, algèbre, statistiques, probabilités...',
    },
    {
      'id': 'sp',
      'nom': 'Sciences Physiques',
      'icone': '⚛️',
      'couleur': Color(0xFFE74C3C),
      'description': 'Physique, chimie, électricité, optique...',
    },
    {
      'id': 'svt',
      'nom': 'SVT',
      'icone': '🧬',
      'couleur': Color(0xFF16A085),
      'description': 'Sciences de la Vie et de la Terre, biologie...',
    },
    {
      'id': 'cg',
      'nom': 'Culture Générale',
      'icone': '🌍',
      'couleur': Color(0xFF9B59B6),
      'description': 'Histoire, géographie, institutions, culture...',
    },
    {
      'id': 'actu',
      'nom': 'Actualité Internationale',
      'icone': '📰',
      'couleur': Color(0xFFF39C12),
      'description': 'Actualités mondiales, géopolitique, ONU...',
    },
    {
      'id': 'pana',
      'nom': 'Guide Panafricain',
      'icone': '🌍',
      'couleur': Color(0xFFD35400),
      'description': 'Union Africaine, CEDEAO, intégration africaine...',
    },
    {
      'id': 'armee',
      'nom': 'Force Armée Nationale',
      'icone': '🪖',
      'couleur': Color(0xFF34495E),
      'description': 'Organisation militaire, défense nationale...',
    },
    {
      'id': 'fr',
      'nom': 'Français',
      'icone': '📖',
      'couleur': Color(0xFF1ABC9C),
      'description': 'Grammaire, vocabulaire, orthographe, rédaction...',
    },
    {
      'id': 'hg',
      'nom': 'Histoire-Géographie',
      'icone': '🗺️',
      'couleur': Color(0xFFBD3B3B),
      'description': 'Histoire du Burkina, Afrique, monde, géographie...',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('📚 16 Matières QCM'),
        automaticallyImplyLeading: false,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.primary, AppColors.primaryDark],
            ),
          ),
        ),
        foregroundColor: AppColors.white,
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(14),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.05,
        ),
        itemCount: _matieresList.length,
        itemBuilder: (context, index) {
          final matiere = _matieresList[index];
          final color = matiere['couleur'] as Color;
          return _buildMatiereCard(context, matiere, color);
        },
      ),
    );
  }

  Widget _buildMatiereCard(BuildContext context, Map<String, dynamic> matiere, Color color) {
    final matiereId = matiere['id'] as String;
    final isWhatsapp = _whatsappMatieres.contains(matiereId);
    final supabaseId = _matiereSupabaseIds[matiereId];
    final nbSeries = _nbSeriesParMatiere[matiereId] ?? 0;

    return GestureDetector(
      onTap: () {
        if (isWhatsapp && supabaseId != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => SerieSelectionScreen(
                matiereId: supabaseId,
                matiereCode: matiereId,
                matiereNom: matiere['nom'] as String,
                icone: matiere['icone'] as String,
                couleur: color,
              ),
            ),
          );
        } else {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => QcmScreen(
                matiere: matiereId,
                label: matiere['nom'] as String,
                couleur: color,
                icone: matiere['icone'] as String,
              ),
            ),
          );
        }
      },
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.15),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Icône
                  Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: color.withValues(alpha: 0.25),
                        width: 1.5,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        matiere['icone'] as String,
                        style: const TextStyle(fontSize: 26),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Nom
                  Text(
                    matiere['nom'] as String,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textDark,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Badge séries ou barre couleur
                  if (isWhatsapp && nbSeries > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF25D366).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Text(
                        '📋 $nbSeries séries',
                        style: const TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF128C7E),
                        ),
                      ),
                    )
                  else if (isWhatsapp)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF25D366).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: const Text(
                        '📋 Séries QCM',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF128C7E),
                        ),
                      ),
                    )
                  else
                    Container(
                      height: 3,
                      width: 36,
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                ],
              ),
            ),
          ),
          // Badge pour les matières avec de nombreuses séries
          if (isWhatsapp)
            Positioned(
              top: 6,
              right: 6,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: nbSeries >= 20
                      ? const Color(0xFF25D366)
                      : const Color(0xFFF39C12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  nbSeries >= 20 ? 'TOP' : 'NEW',
                  style: const TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
