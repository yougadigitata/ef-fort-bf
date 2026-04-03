import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../services/api_service.dart';
import 'qcm_screen.dart';
import 'serie_selection_screen.dart';

// ══════════════════════════════════════════════════════════════
// IDs Supabase des matières — v7.0 NOUVEAU DESIGN
// ══════════════════════════════════════════════════════════════

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
  'aes':          {'icone': 'asset:assets/logo/aes_logo.png', 'couleur': Color(0xFF006B3F)},
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

/// v7.0 — Matières DYNAMIQUES — Nouveau design carte avec bordure verte
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
    final code = (m['code'] as String? ?? m['id'] as String? ?? '').toLowerCase();
    final metaIcone = _matieresMeta[code]?['icone'] as String?;
    if (metaIcone != null) return metaIcone;
    for (final key in _matieresMeta.keys) {
      if (key.toLowerCase() == code) {
        final val = _matieresMeta[key]?['icone'] as String?;
        if (val != null) return val;
      }
    }
    return (m['icone'] as String?) ?? '📚';
  }

  @override
  Widget build(BuildContext context) {
    final count = _matieres.isEmpty ? '' : '${_matieres.length} ';
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
              bottom: 18,
              left: 20,
              right: 12,
            ),
            child: Row(
              children: [
                // Icône livres
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Center(
                    child: Text('📚', style: TextStyle(fontSize: 22)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '${count}Matières QCM',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh_rounded, color: Colors.white, size: 22),
                  tooltip: 'Actualiser',
                  onPressed: _loadMatieres,
                ),
              ],
            ),
          ),

          // ── Contenu ──────────────────────────────────────────
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : _error != null
                    ? _buildError()
                    : _matieres.isEmpty
                        ? _buildEmpty()
                        : _buildGrid(),
          ),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('📡', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 16),
          const Text(
            'Impossible de charger les matières',
            style: TextStyle(fontSize: 15, color: AppColors.textLight),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _loadMatieres,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Réessayer'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
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
          const Text(
            'Aucune matière disponible\npour le moment.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 15, color: AppColors.textLight),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _loadMatieres,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Actualiser'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
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
        padding: const EdgeInsets.fromLTRB(14, 16, 14, 20),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 14,
          crossAxisSpacing: 14,
          childAspectRatio: 0.92,
        ),
        itemCount: _matieres.length,
        itemBuilder: (context, index) {
          final matiere = _matieres[index];
          final matiereCode = ((matiere['code'] as String?) ?? (matiere['id'] as String? ?? '')).toLowerCase();
          final color = _getColor(matiereCode);
          return _buildMatiereCard(matiere, matiereCode, color);
        },
      ),
    );
  }

  Widget _buildMatiereCard(Map<String, dynamic> matiere, String matiereCode, Color color) {
    final nom = matiere['nom'] as String? ?? matiereCode.toUpperCase();
    final nbQuestions = (matiere['nb_questions'] as num?)?.toInt() ?? 0;
    final nbSeries = (matiere['nb_series'] as num?)?.toInt() ?? 0;
    final matiereId = matiere['matiere_id'] as String? ?? '';
    final icone = _getIcone(matiere);
    final hasMatId = matiereId.isNotEmpty;
    final isSeriesMode = _seriesMatieresIds.contains(matiereCode) && hasMatId;

    // Badges basés sur le nombre de séries
    String? badgeLabel;
    Color badgeColor = const Color(0xFF1A5C38);
    if (nbSeries >= 10) {
      badgeLabel = 'TOP';
      badgeColor = const Color(0xFF1A5C38);
    } else if (nbSeries > 0 && nbSeries <= 2) {
      badgeLabel = 'NEW';
      badgeColor = const Color(0xFFE67E22);
    } else if (nbQuestions >= 100 && nbSeries == 0) {
      badgeLabel = 'TOP';
      badgeColor = const Color(0xFF1A5C38);
    }

    // Libellé simplifié — uniquement le nombre de séries disponibles
    // (plus de confusion entre questions et séries)
    String seriesLabel = '';
    if (isSeriesMode) {
      if (nbSeries > 0) {
        seriesLabel = '$nbSeries séries disponibles';
      } else if (nbQuestions > 0) {
        // Calculer le nombre de séries estimé à partir des questions
        final nbSeriesEstime = (nbQuestions / 20).ceil();
        seriesLabel = '~$nbSeriesEstime séries';
      }
    } else if (nbQuestions > 0) {
      seriesLabel = '$nbQuestions QCM';
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
          // ── Carte principale ──────────────────────────────
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFF27AE60),
                width: 1.8,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF27AE60).withValues(alpha: 0.10),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // ── Cercle icône ──────────────────────────
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.10),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: color.withValues(alpha: 0.25),
                        width: 1.5,
                      ),
                    ),
                    child: Center(
                      child: _buildIconeWidget(icone, 36),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // ── Nom de la matière ─────────────────────
                  Text(
                    nom,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1A1A2E),
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // ── Badge nb séries / QCM ─────────────────
                  if (seriesLabel.isNotEmpty)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.content_paste_rounded,
                            size: 13, color: Colors.grey.shade500),
                        const SizedBox(width: 4),
                        Text(
                          seriesLabel,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    )
                  else
                    Container(
                      height: 3, width: 32,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // ── Badge TOP / NEW ───────────────────────────────
          if (badgeLabel != null)
            Positioned(
              top: -1, right: -1,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: badgeColor,
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(14),
                    bottomLeft: Radius.circular(10),
                  ),
                ),
                child: Text(
                  badgeLabel,
                  style: const TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildIconeWidget(String icone, double size) {
    if (icone.startsWith('asset:')) {
      final path = icone.substring(6);
      return Image.asset(
        path,
        width: size,
        height: size,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => Text('🏛️', style: TextStyle(fontSize: size * 0.75)),
      );
    }
    if (icone.startsWith('http://') || icone.startsWith('https://')) {
      return Image.network(
        icone,
        width: size,
        height: size,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => Text('🌐', style: TextStyle(fontSize: size * 0.75)),
      );
    }
    return Text(icone, style: TextStyle(fontSize: size * 0.75));
  }
}
