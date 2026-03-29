import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import 'qcm_screen.dart';
import 'serie_selection_screen.dart';

// ══════════════════════════════════════════════════════════════
// IDs Supabase des matières — Phase 3 (Banque QCM complète)
// ══════════════════════════════════════════════════════════════
const Map<String, String> _matiereSupabaseIds = {
  'hg':     '0a88b3ac-33b7-4d8c-bc19-fe68bb514aef',
  'droit2': '9497ca2c-dc1b-43dd-8b7a-af11dde7039d',
  'eco2':   '756e1ca6-7f7f-4f42-940a-b6d9952ffcdf',
  'ang':    '37febc5e-8ab5-4875-b7ad-71b30a8253e7',
  'sp':     '12e5b05a-6410-4b55-97b7-b8a838dcfb9a',
  'psycho': 'cbd22275-d260-40d1-8ff3-d31545f3f1ab',
  'histo':  '104f51e4-be6e-4ce8-961e-56e604818670',
  'info':   'a72cc6f9-1282-4c2a-ae19-298933047694',
  'comm':   'cc979206-e60d-4224-940d-943b8c68c8fa',
};

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

const Set<String> _whatsappMatieres = {
  'hg', 'droit2', 'eco2', 'ang',
  'psycho', 'histo', 'info', 'comm',
};

/// PHASE 3 — Les 16 matières officielles EF-FORT.BF
/// Design harmonisé : cartes toutes identiques, espacements uniformes
class MatieresScreen extends StatefulWidget {
  const MatieresScreen({super.key});

  @override
  State<MatieresScreen> createState() => _MatieresScreenState();
}

class _MatieresScreenState extends State<MatieresScreen> {

  static const List<Map<String, dynamic>> _matieresList = [
    {
      'id': 'psycho',
      'nom': 'Psychotechnique',
      'icone': '🧩',
      'couleur': Color(0xFF8E44AD),
    },
    {
      'id': 'histo',
      'nom': 'Figure Africaine',
      'icone': '👤',
      'couleur': Color(0xFFC0392B),
    },
    {
      'id': 'droit2',
      'nom': 'Droit',
      'icone': '⚖️',
      'couleur': Color(0xFF1A5C38),
    },
    {
      'id': 'eco2',
      'nom': 'Économie',
      'icone': '💰',
      'couleur': Color(0xFF27AE60),
    },
    {
      'id': 'ang',
      'nom': 'Anglais',
      'icone': '🗣️',
      'couleur': Color(0xFF2980B9),
    },
    {
      'id': 'info',
      'nom': 'Informatique',
      'icone': '💻',
      'couleur': Color(0xFF16A085),
    },
    {
      'id': 'comm',
      'nom': 'Communication',
      'icone': '📢',
      'couleur': Color(0xFFE67E22),
    },
    {
      'id': 'maths',
      'nom': 'Mathématiques',
      'icone': '🔢',
      'couleur': Color(0xFF3498DB),
    },
    {
      'id': 'sp',
      'nom': 'Sciences Physiques',
      'icone': '⚛️',
      'couleur': Color(0xFFE74C3C),
    },
    {
      'id': 'svt',
      'nom': 'SVT',
      'icone': '🧬',
      'couleur': Color(0xFF1ABC9C),
    },
    {
      'id': 'cg',
      'nom': 'Culture Générale',
      'icone': '🌍',
      'couleur': Color(0xFF9B59B6),
    },
    {
      'id': 'actu',
      'nom': 'Actualité Internationale',
      'icone': '📰',
      'couleur': Color(0xFFF39C12),
    },
    {
      'id': 'pana',
      'nom': 'Guide Panafricain',
      'icone': '🌍',
      'couleur': Color(0xFFD35400),
    },
    {
      'id': 'armee',
      'nom': 'Force Armée Nationale',
      'icone': '🪖',
      'couleur': Color(0xFF34495E),
    },
    {
      'id': 'fr',
      'nom': 'Français',
      'icone': '📖',
      'couleur': Color(0xFF1A5C38),
    },
    {
      'id': 'hg',
      'nom': 'Histoire-Géographie',
      'icone': '🗺️',
      'couleur': Color(0xFFBD3B3B),
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          '📚 16 Matières QCM',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
        ),
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
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(14),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          // Ratio fixe pour toutes les cartes — cartes uniformes garanties
          childAspectRatio: 1.0,
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

    // Badge label
    String? badgeLabel;
    if (isWhatsapp && nbSeries >= 20) badgeLabel = 'TOP';
    if (isWhatsapp && nbSeries > 0 && nbSeries < 20) badgeLabel = 'NEW';

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
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.12),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Icône dans un cercle coloré — taille fixe
                  Container(
                    width: 50,
                    height: 50,
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
                        style: const TextStyle(fontSize: 22),
                      ),
                    ),
                  ),
                  const SizedBox(height: 7),
                  // Nom — hauteur fixe grâce à maxLines
                  SizedBox(
                    height: 34,
                    child: Text(
                      matiere['nom'] as String,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textDark,
                        height: 1.2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 5),
                  // Badge info en bas
                  if (isWhatsapp && nbSeries > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A5C38).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '📋 $nbSeries séries',
                        style: const TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1A5C38),
                        ),
                      ),
                    )
                  else
                    Container(
                      height: 3,
                      width: 32,
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                ],
              ),
            ),
          ),
          // Badge TOP / NEW en haut à droite
          if (badgeLabel != null)
            Positioned(
              top: 6,
              right: 6,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: badgeLabel == 'TOP'
                      ? const Color(0xFF1A5C38)
                      : const Color(0xFFF39C12),
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Text(
                  badgeLabel,
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
