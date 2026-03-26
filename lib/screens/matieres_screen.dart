import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import 'qcm_screen.dart';

class MatieresScreen extends StatefulWidget {
  const MatieresScreen({super.key});

  @override
  State<MatieresScreen> createState() => _MatieresScreenState();
}

class _MatieresScreenState extends State<MatieresScreen> {

  // ══════════════════════════════════════════════════════════
  // LISTE OFFICIELLE DES MATIÈRES v4
  // ⚠️ ENAREF n'est PAS une matière — c'est un concours
  // ⚠️ Droit et Économie sont SÉPARÉS
  // ⚠️ Sciences Physiques et SVT sont SÉPARÉS
  // ══════════════════════════════════════════════════════════
  static const List<Map<String, dynamic>> _matieresList = [
    {
      'id': 'culture_generale',
      'nom': 'Culture Générale',
      'icone': '🌍',
      'couleur': Color(0xFF1A5C38),
      'description': 'Histoire, géographie, institutions...',
    },
    {
      'id': 'francais',
      'nom': 'Français',
      'icone': '📝',
      'couleur': Color(0xFF2980B9),
      'description': 'Grammaire, vocabulaire, orthographe...',
    },
    {
      'id': 'mathematiques',
      'nom': 'Mathématiques',
      'icone': '📐',
      'couleur': Color(0xFFE67E22),
      'description': 'Calculs, géométrie, statistiques...',
    },
    {
      'id': 'psychotechnique',
      'nom': 'Psychotechnique',
      'icone': '🧠',
      'couleur': Color(0xFF8E44AD),
      'description': 'Suites numériques, alphabétiques, mixtes...',
    },
    {
      'id': 'logique_dominos',
      'nom': 'Dominos & Logique',
      'icone': '🎲',
      'couleur': Color(0xFF16A085),
      'description': 'Dominos visuels, progressions...',
    },
    {
      'id': 'logique_cartes',
      'nom': 'Cartes à Jouer',
      'icone': '🃏',
      'couleur': Color(0xFFC0392B),
      'description': 'Logique des cartes à jouer...',
    },
    {
      'id': 'logique_intrus',
      'nom': "Trouver l'Intrus",
      'icone': '🔍',
      'couleur': Color(0xFF27AE60),
      'description': 'Trouver l\'élément qui ne correspond pas...',
    },
    {
      'id': 'logique_codages',
      'nom': 'Codages & Substitutions',
      'icone': '🔐',
      'couleur': Color(0xFF2C3E50),
      'description': 'Déchiffrer des codes et substitutions...',
    },
    {
      'id': 'logique_syllogisme',
      'nom': 'Syllogismes',
      'icone': '💡',
      'couleur': Color(0xFFF39C12),
      'description': 'Raisonnement logique et syllogismes...',
    },
    {
      'id': 'droit',
      'nom': 'Droit',
      'icone': '⚖️',
      'couleur': Color(0xFF1A5C38),
      'description': 'Droit public, fonctions publiques...',
    },
    {
      'id': 'economie',
      'nom': 'Économie',
      'icone': '📊',
      'couleur': Color(0xFFD4A017),
      'description': 'Économie générale, microéconomie...',
    },
    {
      'id': 'histoire_geographie',
      'nom': 'Histoire & Géographie',
      'icone': '🗺️',
      'couleur': Color(0xFF8B4513),
      'description': 'Histoire du Burkina Faso et de l\'Afrique...',
    },
    {
      'id': 'sciences_physiques',
      'nom': 'Sciences Physiques',
      'icone': '⚗️',
      'couleur': Color(0xFF3498DB),
      'description': 'Physique, chimie, sciences appliquées...',
    },
    {
      'id': 'svt',
      'nom': 'SVT',
      'icone': '🌿',
      'couleur': Color(0xFF2ECC71),
      'description': 'Sciences de la vie et de la Terre...',
    },
    {
      'id': 'actualite',
      'nom': 'Actualité & Institutions',
      'icone': '🏛️',
      'couleur': Color(0xFFE74C3C),
      'description': 'Institutions burkinabè et africaines...',
    },
    {
      'id': 'figures_africaines',
      'nom': 'Figures Africaines',
      'icone': '👑',
      'couleur': Color(0xFFD35400),
      'description': 'Grandes figures africaines et burkinabè...',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('📚 Matières QCM'),
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
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 14,
                crossAxisSpacing: 14,
                childAspectRatio: 1.05,
              ),
              itemCount: _matieresList.length,
              itemBuilder: (context, index) {
                final matiere = _matieresList[index];
                final color = matiere['couleur'] as Color;
                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => QcmScreen(
                          matiere: matiere['id'] as String,
                          label: matiere['nom'] as String,
                          couleur: color,
                          icone: matiere['icone'] as String,
                        ),
                      ),
                    );
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: color.withValues(alpha: 0.15),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Icône 3D dans container stylisé
                          Container(
                            width: 58,
                            height: 58,
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.12),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: color.withValues(alpha: 0.2),
                                width: 1.5,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                matiere['icone'] as String,
                                style: const TextStyle(fontSize: 28),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            matiere['nom'] as String,
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textDark,
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(height: 4),
                          // Barre de couleur indicateur
                          Container(
                            height: 3,
                            width: 40,
                            decoration: BoxDecoration(
                              color: color,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
