import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../services/api_service.dart';
import '../services/bell_service.dart';
import '../widgets/logo_widget.dart';
import 'qcm_screen.dart';
import 'serie_selection_screen.dart';

// ══════════════════════════════════════════════════════════════
// IDs Supabase des matières — v8.0 DESIGN LISTE HARMONISÉ
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
  'haut':         {'icone': '🎓', 'couleur': Color(0xFF8B0000)},
  'default':      {'icone': '📚', 'couleur': Color(0xFF1A5C38)},
};

const Set<String> _seriesMatieresIds = {
  'hg', 'droit2', 'eco2', 'ang', 'psycho', 'histo', 'info', 'comm',
  'aes', 'bf', 'burkina_faso', 'armee', 'actu', 'cg', 'fr', 'maths',
  'svt', 'pana', 'sp', 'psy', 'pc', 'enaref', 'haut',
};

/// v8.0 — Matières DYNAMIQUES — Design liste harmonisé
class MatieresScreen extends StatefulWidget {
  const MatieresScreen({super.key});

  @override
  State<MatieresScreen> createState() => _MatieresScreenState();
}

class _MatieresScreenState extends State<MatieresScreen>
    with SingleTickerProviderStateMixin {
  List<Map<String, dynamic>> _matieres = [];
  bool _loading = true;
  String? _error;

  late AnimationController _listAnimController;

  @override
  void initState() {
    super.initState();
    _listAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _loadMatieres();
  }

  @override
  void dispose() {
    _listAnimController.dispose();
    super.dispose();
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
        _listAnimController.forward(from: 0);
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
              boxShadow: [
                BoxShadow(
                  color: Color(0x331A5C38),
                  blurRadius: 12,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 14,
              bottom: 18,
              left: 20,
              right: 12,
            ),
            child: Row(
              children: [
                // Logo EF-FORT
                const LogoWidget(size: 38, borderRadius: 10),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${count}Matières QCM',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: 0.3,
                        ),
                      ),
                      const Text(
                        'Choisissez votre matière',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFFD4A017),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
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
                        : _buildList(),
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
            style: TextStyle(fontSize: 17, color: AppColors.textLight),
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
            style: TextStyle(fontSize: 17, color: AppColors.textLight),
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

  Widget _buildList() {
    return RefreshIndicator(
      onRefresh: _loadMatieres,
      color: AppColors.primary,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(14, 16, 14, 24),
        itemCount: _matieres.length,
        separatorBuilder: (_, __) => const Divider(
          height: 1,
          thickness: 1,
          color: Color(0xFFE8F0EC),
          indent: 68,
          endIndent: 0,
        ),
        itemBuilder: (context, index) {
          final matiere = _matieres[index];
          final matiereCode = ((matiere['code'] as String?) ?? (matiere['id'] as String? ?? '')).toLowerCase();
          final color = _getColor(matiereCode);

          // Animation en cascade par index
          final delay = (index * 0.05).clamp(0.0, 0.8);
          final animation = Tween<double>(begin: 0.0, end: 1.0).animate(
            CurvedAnimation(
              parent: _listAnimController,
              curve: Interval(delay, (delay + 0.4).clamp(0.0, 1.0), curve: Curves.easeOut),
            ),
          );

          return AnimatedBuilder(
            animation: animation,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(0, 20 * (1 - animation.value)),
                child: Opacity(
                  opacity: animation.value.clamp(0.0, 1.0),
                  child: child,
                ),
              );
            },
            child: _buildMatiereRow(matiere, matiereCode, color),
          );
        },
      ),
    );
  }

  Widget _buildMatiereRow(Map<String, dynamic> matiere, String matiereCode, Color color) {
    final nom = matiere['nom'] as String? ?? matiereCode.toUpperCase();
    final nbSeries = (matiere['nb_series'] as num?)?.toInt() ?? 0;
    final matiereId = matiere['matiere_id'] as String? ?? '';
    final icone = _getIcone(matiere);
    final hasMatId = matiereId.isNotEmpty;
    final isSeriesMode = _seriesMatieresIds.contains(matiereCode) && hasMatId;

    // Badge TOP / NEW
    String? badgeLabel;
    Color badgeColor = const Color(0xFF1A5C38);
    if (nbSeries >= 10) {
      badgeLabel = 'TOP';
      badgeColor = const Color(0xFF1A5C38);
    } else if (nbSeries > 0 && nbSeries <= 2) {
      badgeLabel = 'NEW';
      badgeColor = const Color(0xFFE67E22);
    }

    return _AnimatedTapCard(
      onTap: () {
        BellService.playClick();
        if (isSeriesMode) {
          Navigator.push(
            context,
            _buildSlideRoute(
              SerieSelectionScreen(
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
            _buildSlideRoute(
              QcmScreen(
                matiere: matiereCode,
                label: nom,
                couleur: color,
                icone: icone,
              ),
            ),
          );
        }
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFF27AE60).withValues(alpha: 0.25),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.08),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
            const BoxShadow(
              color: Color(0x0A000000),
              blurRadius: 4,
              offset: Offset(0, 1),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          child: Row(
            children: [
              // ── Cercle icône ─────────────────────────────
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.10),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: color.withValues(alpha: 0.25),
                    width: 1.5,
                  ),
                ),
                child: Center(
                  child: _buildIconeWidget(icone, 26),
                ),
              ),
              const SizedBox(width: 14),

              // ── Nom de la matière ─────────────────────────
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            nom,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF1A1A2E),
                              letterSpacing: 0.1,
                            ),
                          ),
                        ),
                        if (badgeLabel != null) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: badgeColor,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              badgeLabel,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (nbSeries > 0) ...[
                      const SizedBox(height: 3),
                      Text(
                        '$nbSeries série${nbSeries > 1 ? 's' : ''}',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textLight,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(width: 10),

              // ── Bouton Séries QCM / QCM ───────────────────
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: color.withValues(alpha: 0.30),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      isSeriesMode ? 'Séries QCM' : 'QCM',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: color,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(Icons.arrow_forward_ios_rounded, size: 10, color: color),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Transition slide douce vers la droite
  Route _buildSlideRoute(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (_, animation, __) => page,
      transitionsBuilder: (_, animation, __, child) {
        final tween = Tween<Offset>(
          begin: const Offset(1.0, 0.0),
          end: Offset.zero,
        ).chain(CurveTween(curve: Curves.easeOutCubic));
        return SlideTransition(position: animation.drive(tween), child: child);
      },
      transitionDuration: const Duration(milliseconds: 320),
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

// ── Widget tap animé (micro-interaction rebond) ────────────────
class _AnimatedTapCard extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;

  const _AnimatedTapCard({required this.child, required this.onTap});

  @override
  State<_AnimatedTapCard> createState() => _AnimatedTapCardState();
}

class _AnimatedTapCardState extends State<_AnimatedTapCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      reverseDuration: const Duration(milliseconds: 200),
    );
    _scale = Tween<double>(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) {
        _ctrl.reverse();
        widget.onTap();
      },
      onTapCancel: () => _ctrl.reverse(),
      child: ScaleTransition(scale: _scale, child: widget.child),
    );
  }
}
