import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import 'qcm_screen.dart';
import 'serie_selection_screen.dart';

// ══════════════════════════════════════════════════════════════
// IDs Supabase des matières — v5.1 (2228 questions + AES + BF)
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
  // Nouvelles matières v5.1
  'aes':          'c7681b66-91af-423b-9ef6-becbe8f5bd85',
  'burkina_faso': '7c2b0599-4971-4d31-87ce-aeeb5c5cb394',
  'armee':        'b8df7f6e-587d-4871-856c-30dbaa6a52c3',
  'actu':         '5f7ef458-9fd3-4f70-b498-d3391b5d5677',
};

const Map<String, int> _nbSeriesParMatiere = {
  'hg':           13,
  'droit2':       51,
  'eco2':         52,
  'ang':          51,
  'sp':           0,
  'psycho':       31,
  'histo':        30,
  'info':         20,
  'comm':         2,
  // Nouvelles matières v5.1
  'aes':          8,
  'burkina_faso': 1,
  'armee':        10,
  'actu':         3,
};

const Set<String> _whatsappMatieres = {
  'hg', 'droit2', 'eco2', 'ang',
  'psycho', 'histo', 'info', 'comm',
  // Nouvelles matières v5.1
  'aes', 'burkina_faso', 'armee', 'actu',
};

/// v5.1 — Les 18 matières officielles EF-FORT.BF (+ AES + Burkina Faso)
/// Design harmonisé : cartes toutes identiques, espacements uniformes
class MatieresScreen extends StatefulWidget {
  const MatieresScreen({super.key});

  @override
  State<MatieresScreen> createState() => _MatieresScreenState();
}

class _MatieresScreenState extends State<MatieresScreen> {

  static const List<Map<String, dynamic>> _matieresList = [
    // ── NOUVELLES MATIÈRES v5.1 en tête (mises en avant) ──────
    {
      'id': 'aes',
      'nom': 'Alliance des États du Sahel',
      'sous_titre': 'AES — Burkina, Mali, Niger',
      'icone_type': 'IMAGE',
      'icone': '🤝',
      'icone_asset': 'assets/logo/aes_logo.png',
      'couleur': Color(0xFF006B3F),
      'badge': 'NEW',
    },
    {
      'id': 'burkina_faso',
      'nom': 'Burkina Faso',
      'sous_titre': 'Pays des Hommes Intègres',
      'icone_type': 'EMOJI',
      'icone': '🇧🇫',
      'couleur': Color(0xFFEF2B2D),
      'badge': 'NEW',
    },
    // ── MATIÈRES ENRICHIES v5.1 ────────────────────────────────
    {
      'id': 'droit2',
      'nom': 'Droit',
      'icone_type': 'EMOJI',
      'icone': '⚖️',
      'couleur': Color(0xFF1A5C38),
    },
    {
      'id': 'armee',
      'nom': 'Force Armée Nationale',
      'icone_type': 'EMOJI',
      'icone': '🪖',
      'couleur': Color(0xFF34495E),
    },
    {
      'id': 'info',
      'nom': 'Informatique',
      'icone_type': 'EMOJI',
      'icone': '💻',
      'couleur': Color(0xFF16A085),
    },
    {
      'id': 'hg',
      'nom': 'Histoire-Géographie',
      'icone_type': 'EMOJI',
      'icone': '🗺️',
      'couleur': Color(0xFFBD3B3B),
    },
    {
      'id': 'actu',
      'nom': 'Actualité Internationale',
      'icone_type': 'EMOJI',
      'icone': '📰',
      'couleur': Color(0xFFF39C12),
    },
    // ── MATIÈRES CLASSIQUES ────────────────────────────────────
    {
      'id': 'psycho',
      'nom': 'Psychotechnique',
      'icone_type': 'EMOJI',
      'icone': '🧩',
      'couleur': Color(0xFF8E44AD),
    },
    {
      'id': 'histo',
      'nom': 'Figure Africaine',
      'icone_type': 'EMOJI',
      'icone': '👤',
      'couleur': Color(0xFFC0392B),
    },
    {
      'id': 'eco2',
      'nom': 'Économie',
      'icone_type': 'EMOJI',
      'icone': '💰',
      'couleur': Color(0xFF27AE60),
    },
    {
      'id': 'ang',
      'nom': 'Anglais',
      'icone_type': 'EMOJI',
      'icone': '🗣️',
      'couleur': Color(0xFF2980B9),
    },
    {
      'id': 'comm',
      'nom': 'Communication',
      'icone_type': 'EMOJI',
      'icone': '📢',
      'couleur': Color(0xFFE67E22),
    },
    {
      'id': 'maths',
      'nom': 'Mathématiques',
      'icone_type': 'EMOJI',
      'icone': '🔢',
      'couleur': Color(0xFF3498DB),
    },
    {
      'id': 'sp',
      'nom': 'Sciences Physiques',
      'icone_type': 'EMOJI',
      'icone': '⚛️',
      'couleur': Color(0xFFE74C3C),
    },
    {
      'id': 'svt',
      'nom': 'SVT',
      'icone_type': 'EMOJI',
      'icone': '🧬',
      'couleur': Color(0xFF1ABC9C),
    },
    {
      'id': 'cg',
      'nom': 'Culture Générale',
      'icone_type': 'EMOJI',
      'icone': '🌍',
      'couleur': Color(0xFF9B59B6),
    },
    {
      'id': 'pana',
      'nom': 'Guide Panafricain',
      'icone_type': 'EMOJI',
      'icone': '🌍',
      'couleur': Color(0xFFD35400),
    },
    {
      'id': 'fr',
      'nom': 'Français',
      'icone_type': 'EMOJI',
      'icone': '📖',
      'couleur': Color(0xFF1A5C38),
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          '📚 18 Matières QCM',
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

    // Badge label — NEW pour nouvelles matières, TOP pour les grandes
    String? badgeLabel = matiere['badge'] as String?;
    if (badgeLabel == null) {
      if (isWhatsapp && nbSeries >= 20) badgeLabel = 'TOP';
      if (isWhatsapp && nbSeries > 0 && nbSeries < 20) badgeLabel = 'NEW';
    }

    // Type d'icône
    final iconeType = (matiere['icone_type'] as String?) ?? 'EMOJI';
    final iconeAsset = matiere['icone_asset'] as String?;

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
        clipBehavior: Clip.none,
        children: [
          // ── Rectangle vert en arrière-plan (ombre verte style consignes) ──
          Positioned(
            bottom: -4,
            left: 4,
            right: -4,
            child: Container(
              height: double.infinity,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.22),
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),

          // ── Rectangle blanc principal ──
          Container(
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: color.withValues(alpha: 0.15),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.14),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Icône dans un cercle coloré — IMAGE ou EMOJI
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: iconeType == 'IMAGE'
                          ? Colors.white
                          : color.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: color.withValues(alpha: 0.3),
                        width: 1.5,
                      ),
                    ),
                    child: Center(
                      child: iconeType == 'IMAGE' && iconeAsset != null
                          ? ClipOval(
                              child: Image.asset(
                                iconeAsset,
                                width: 44,
                                height: 44,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Text(
                                  matiere['icone'] as String,
                                  style: const TextStyle(fontSize: 22),
                                ),
                              ),
                            )
                          : Text(
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
