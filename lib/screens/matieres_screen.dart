import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../services/api_service.dart';
import 'qcm_screen.dart';
import 'serie_selection_screen.dart';

// ══════════════════════════════════════════════════════════════
// IDs Supabase des matières — v6.0 DYNAMIQUE (chargé depuis API)
// ══════════════════════════════════════════════════════════════

/// Matières officielles avec leurs métadonnées visuelles
const Map<String, Map<String, dynamic>> _matieresMeta = {
  'hg':           {'icone': '🗺️', 'couleur': Color(0xFFBD3B3B)},
  'droit2':       {'icone': '⚖️', 'couleur': Color(0xFF1A5C38)},
  'eco2':         {'icone': '💰', 'couleur': Color(0xFF27AE60)},
  'ang':          {'icone': '🗣️', 'couleur': Color(0xFF2980B9)},
  'sp':           {'icone': '⚛️', 'couleur': Color(0xFFE74C3C)},
  'psycho':       {'icone': '🧩', 'couleur': Color(0xFF8E44AD)},
  'histo':        {'icone': '👤', 'couleur': Color(0xFFC0392B)},
  'info':         {'icone': '💻', 'couleur': Color(0xFF16A085)},
  'comm':         {'icone': '📢', 'couleur': Color(0xFFE67E22)},
  'aes':          {'icone': '🤝', 'couleur': Color(0xFF006B3F)},
  'bf':           {'icone': '🇧🇫', 'couleur': Color(0xFFEF2B2D)},
  'burkina_faso': {'icone': '🇧🇫', 'couleur': Color(0xFFEF2B2D)},
  'armee':        {'icone': '🪖', 'couleur': Color(0xFF34495E)},
  'actu':         {'icone': '📰', 'couleur': Color(0xFFF39C12)},
  'maths':        {'icone': '🔢', 'couleur': Color(0xFF3498DB)},
  'svt':          {'icone': '🧬', 'couleur': Color(0xFF1ABC9C)},
  'cg':           {'icone': '🌍', 'couleur': Color(0xFF9B59B6)},
  'pana':         {'icone': '🌍', 'couleur': Color(0xFFD35400)},
  'fr':           {'icone': '📖', 'couleur': Color(0xFF1A5C38)},
  'psy':          {'icone': '🧠', 'couleur': Color(0xFF8E44AD)},
  'pc':           {'icone': '🔬', 'couleur': Color(0xFFE74C3C)},
  'enaref':       {'icone': '🏛️', 'couleur': Color(0xFF1A5C38)},
  'default':      {'icone': '📚', 'couleur': Color(0xFF1A5C38)},
};

const Set<String> _seriesMatieresIds = {
  'hg', 'droit2', 'eco2', 'ang', 'psycho', 'histo', 'info', 'comm',
  'aes', 'bf', 'burkina_faso', 'armee', 'actu', 'cg', 'fr', 'maths',
  'svt', 'pana', 'sp', 'psy', 'pc', 'enaref',
};

/// v6.0 — Matières DYNAMIQUES (chargées depuis l'API Supabase en temps réel)
class MatieresScreen extends StatefulWidget {
  const MatieresScreen({super.key});

  @override
  State<MatieresScreen> createState() => _MatieresScreenState();
}

class _MatieresScreenState extends State<MatieresScreen> {
  List<Map<String, dynamic>> _matieres = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadMatieres();
  }

  Future<void> _loadMatieres() async {
    setState(() { _loading = true; _error = null; });
    try {
      final data = await ApiService.getMatieres();
      if (mounted) {
        setState(() {
          _matieres = data.cast<Map<String, dynamic>>();
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Erreur de chargement';
          _loading = false;
        });
      }
    }
  }

  Color _getColor(String code) {
    final key = code.toLowerCase();
    return (_matieresMeta[key]?['couleur'] as Color?) ??
           (_matieresMeta['default']!['couleur'] as Color);
  }

  String _getIcone(Map<String, dynamic> m) {
    final code = (m['id'] as String? ?? '').toLowerCase();
    return (_matieresMeta[code]?['icone'] as String?) ??
           (m['icone'] as String?) ?? '📚';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          '📚 ${_matieres.isEmpty ? "Matières QCM" : "${_matieres.length} Matières"}',
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
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
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Actualiser',
            onPressed: _loadMatieres,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _error != null
              ? _buildError()
              : _matieres.isEmpty
                  ? _buildEmpty()
                  : _buildGrid(),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('📡', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 16),
          const Text('Impossible de charger les matières', style: TextStyle(fontSize: 15, color: AppColors.textLight)),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _loadMatieres,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Réessayer'),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('📭', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 16),
          const Text('Aucune matière disponible\npour le moment.', textAlign: TextAlign.center, style: TextStyle(fontSize: 15, color: AppColors.textLight)),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _loadMatieres,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Actualiser'),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildGrid() {
    return RefreshIndicator(
      onRefresh: _loadMatieres,
      color: AppColors.primary,
      child: GridView.builder(
        padding: const EdgeInsets.all(14),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.0,
        ),
        itemCount: _matieres.length,
        itemBuilder: (context, index) {
          final matiere = _matieres[index];
          final matiereCode = (matiere['id'] as String? ?? '').toLowerCase();
          final color = _getColor(matiereCode);
          return _buildMatiereCard(matiere, matiereCode, color);
        },
      ),
    );
  }

  Widget _buildMatiereCard(Map<String, dynamic> matiere, String matiereCode, Color color) {
    final nom = matiere['nom'] as String? ?? matiereCode.toUpperCase();
    final nbQuestions = matiere['nb_questions'] as int? ?? 0;
    final matiereId = matiere['matiere_id'] as String? ?? '';
    final icone = _getIcone(matiere);

    // Déterminer si on affiche en mode séries ou mode direct
    final hasMatId = matiereId.isNotEmpty;
    final isSeriesMode = _seriesMatieresIds.contains(matiereCode) && hasMatId;

    // Badge
    String? badgeLabel;
    if (nbQuestions >= 100) {
      badgeLabel = 'TOP';
    } else if (nbQuestions > 0 && nbQuestions < 30) {
      badgeLabel = 'NEW';
    }

    return GestureDetector(
      onTap: () {
        if (isSeriesMode) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => SerieSelectionScreen(
                matiereId: matiereId,
                matiereCode: matiereCode,
                matiereNom: nom,
                icone: icone,
                couleur: color,
              ),
            ),
          );
        } else {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => QcmScreen(
                matiere: matiereCode,
                label: nom,
                couleur: color,
                icone: icone,
              ),
            ),
          );
        }
      },
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Rectangle ombre
          Positioned(
            bottom: -4, left: 4, right: -4,
            child: Container(
              height: double.infinity,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.22),
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),

          // Card principale
          Container(
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: color.withValues(alpha: 0.15), width: 1),
              boxShadow: [
                BoxShadow(color: color.withValues(alpha: 0.14), blurRadius: 6, offset: const Offset(0, 2)),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Icône
                  Container(
                    width: 50, height: 50,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                      border: Border.all(color: color.withValues(alpha: 0.3), width: 1.5),
                    ),
                    child: Center(
                      child: Text(icone, style: const TextStyle(fontSize: 22)),
                    ),
                  ),
                  const SizedBox(height: 7),

                  // Nom
                  SizedBox(
                    height: 34,
                    child: Text(
                      nom,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11, fontWeight: FontWeight.w800,
                        color: AppColors.textDark, height: 1.2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 5),

                  // Badge bas — questions/séries
                  if (nbQuestions > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A5C38).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        isSeriesMode ? '📋 $nbQuestions QCM' : '✏️ $nbQuestions QCM',
                        style: const TextStyle(
                          fontSize: 9, fontWeight: FontWeight.w700,
                          color: Color(0xFF1A5C38),
                        ),
                      ),
                    )
                  else
                    Container(
                      height: 3, width: 32,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // Badge TOP/NEW
          if (badgeLabel != null)
            Positioned(
              top: 6, right: 6,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: badgeLabel == 'TOP' ? const Color(0xFF1A5C38) : const Color(0xFFF39C12),
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Text(
                  badgeLabel,
                  style: const TextStyle(fontSize: 8, fontWeight: FontWeight.w900, color: Colors.white),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
