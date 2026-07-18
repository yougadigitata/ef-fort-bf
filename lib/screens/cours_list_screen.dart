import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../services/api_service.dart';
import '../services/cours_service.dart';
import '../services/bell_service.dart';
import '../widgets/logo_widget.dart';
import 'domaine_detail_screen.dart';

// ══════════════════════════════════════════════════════════════
// COURS LIST SCREEN — e-learning v2.0
// Affiche les matières avec descriptions et avancement
// ══════════════════════════════════════════════════════════════

const Map<String, Map<String, dynamic>> _matieresMeta = {
  'hg':           {'icone': '🗺️', 'couleur': Color(0xFFBD3B3B)},
  'droit2':       {'icone': '⚖️', 'couleur': Color(0xFF1A5C38)},
  'eco2':         {'icone': '💰', 'couleur': Color(0xFF27AE60)},
  'ang':          {'icone': '🗣️', 'couleur': Color(0xFF2980B9)},
  'sp':           {'icone': '⚛️', 'couleur': Color(0xFFE74C3C)},
  'psycho':       {'icone': '🧩', 'couleur': Color(0xFF8E44AD)},
  'psy':          {'icone': '🧠', 'couleur': Color(0xFF8E44AD)},
  'histo':        {'icone': '👤', 'couleur': Color(0xFFC0392B)},
  'info':         {'icone': '💻', 'couleur': Color(0xFF16A085)},
  'comm':         {'icone': '📢', 'couleur': Color(0xFFE67E22)},
  'aes':          {'icone': '🌍', 'couleur': Color(0xFF006B3F)},
  'bf':           {'icone': '🇧🇫', 'couleur': Color(0xFFEF2B2D)},
  'burkina_faso': {'icone': '🇧🇫', 'couleur': Color(0xFFEF2B2D)},
  'armee':        {'icone': '🪖', 'couleur': Color(0xFF34495E)},
  'actu':         {'icone': '📰', 'couleur': Color(0xFFF39C12)},
  'maths':        {'icone': '🔢', 'couleur': Color(0xFF3498DB)},
  'svt':          {'icone': '🧬', 'couleur': Color(0xFF1ABC9C)},
  'cg':           {'icone': '🌍', 'couleur': Color(0xFF9B59B6)},
  'pana':         {'icone': '🌍', 'couleur': Color(0xFFD35400)},
  'fr':           {'icone': '📖', 'couleur': Color(0xFF1A5C38)},
  'pc':           {'icone': '🔬', 'couleur': Color(0xFFE74C3C)},
  'enaref':       {'icone': '🏛️', 'couleur': Color(0xFF1A5C38)},
  'haut':         {'icone': '🎓', 'couleur': Color(0xFF8B0000)},
  'default':      {'icone': '📚', 'couleur': Color(0xFF1A5C38)},
};

class CoursListScreen extends StatefulWidget {
  const CoursListScreen({super.key});

  @override
  State<CoursListScreen> createState() => _CoursListScreenState();
}

class _CoursListScreenState extends State<CoursListScreen>
    with SingleTickerProviderStateMixin {
  List<Map<String, dynamic>> _matieres = [];
  final Map<String, int> _pourcentages = {};
  bool _loading = true;
  String? _error;
  late AnimationController _animCtrl;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _loadMatieres();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
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
        _animCtrl.forward(from: 0);
        // Charger les pourcentages en arrière-plan
        _loadPourcentages();
      }
    } catch (e) {
      if (mounted) {
        setState(() { _error = 'Erreur de chargement'; _loading = false; });
      }
    }
  }

  Future<void> _loadPourcentages() async {
    // Charger les pourcentages matière par matière
    for (final m in _matieres) {
      final matiereId = m['matiere_id'] as String? ?? '';
      if (matiereId.isEmpty) continue;
      try {
        final pct = await CoursService.getPourcentageMatiere(matiereId);
        if (mounted) {
          setState(() => _pourcentages[matiereId] = pct);
        }
      } catch (_) {}
    }
  }

  Color _getColor(String code) {
    final key = code.toLowerCase();
    return (_matieresMeta[key]?['couleur'] as Color?) ??
        (_matieresMeta['default']!['couleur'] as Color);
  }

  String _getIcone(String code) {
    final key = code.toLowerCase();
    return (_matieresMeta[key]?['icone'] as String?) ?? '📚';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F1),
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.primary))
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

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.primaryDark],
        ),
        boxShadow: [
          BoxShadow(color: Color(0x331A5C38), blurRadius: 12, offset: Offset(0, 4)),
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
          const LogoWidget(size: 38, borderRadius: 10),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${_matieres.isEmpty ? '' : '${_matieres.length} '}Cours disponibles',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const Text(
                  'Choisissez un cours et commencez à apprendre',
                  style: TextStyle(fontSize: 12, color: Color(0xFFD4A017), fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white, size: 22),
            onPressed: _loadMatieres,
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
          const Text('Impossible de charger les cours',
              style: TextStyle(fontSize: 17, color: AppColors.textLight)),
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
          const Text('📚', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 16),
          const Text('Aucun cours disponible',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 17, color: AppColors.textLight)),
          const SizedBox(height: 8),
          const Text('Les chapitres seront disponibles bientôt',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: AppColors.textLight)),
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
          height: 1, thickness: 1, color: Color(0xFFE8F0EC), indent: 68,
        ),
        itemBuilder: (context, index) {
          final m = _matieres[index];
          final code = ((m['code'] as String?) ?? '').toLowerCase();
          final color = _getColor(code);
          final delay = (index * 0.05).clamp(0.0, 0.8);
          final animation = Tween<double>(begin: 0.0, end: 1.0).animate(
            CurvedAnimation(
              parent: _animCtrl,
              curve: Interval(delay, (delay + 0.4).clamp(0.0, 1.0), curve: Curves.easeOut),
            ),
          );
          return AnimatedBuilder(
            animation: animation,
            builder: (ctx, child) => Transform.translate(
              offset: Offset(0, 20 * (1 - animation.value)),
              child: Opacity(opacity: animation.value.clamp(0.0, 1.0), child: child),
            ),
            child: _buildCoursCard(m, code, color),
          );
        },
      ),
    );
  }

  Widget _buildCoursCard(Map<String, dynamic> m, String code, Color color) {
    final nom = m['nom'] as String? ?? code.toUpperCase();
    final matiereId = m['matiere_id'] as String? ?? '';
    final icone = _getIcone(code);
    final pct = _pourcentages[matiereId] ?? 0;
    final description = m['description'] as String?
        ?? 'Explorez les chapitres et leçons de $nom.';

    return _TapCard(
      onTap: () {
        BellService.playClick();
        Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder: (_, animation, __) => DomaineDetailScreen(
              matiereId: matiereId,
              matiereNom: nom,
              matiereCode: code,
              couleur: color,
              icone: icone,
            ),
            transitionsBuilder: (_, animation, __, child) {
              final tween = Tween<Offset>(
                begin: const Offset(1.0, 0.0),
                end: Offset.zero,
              ).chain(CurveTween(curve: Curves.easeOutCubic));
              return SlideTransition(
                position: animation.drive(tween),
                child: child,
              );
            },
            transitionDuration: const Duration(milliseconds: 320),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.20), width: 1.5),
          boxShadow: [
            BoxShadow(color: color.withValues(alpha: 0.07), blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Icône
                  Container(
                    width: 50, height: 50,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.10),
                      shape: BoxShape.circle,
                      border: Border.all(color: color.withValues(alpha: 0.25), width: 1.5),
                    ),
                    child: Center(
                      child: Text(icone, style: const TextStyle(fontSize: 22)),
                    ),
                  ),
                  const SizedBox(width: 14),
                  // Infos
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(nom,
                            style: const TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF1A1A2E)),
                        ),
                        const SizedBox(height: 3),
                        Text(description,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 11, color: AppColors.textLight, height: 1.3)),
                      ],
                    ),
                  ),
                  // Flèche
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: color.withValues(alpha: 0.30), width: 1),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Cours', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: color)),
                        const SizedBox(width: 3),
                        Icon(Icons.arrow_forward_ios_rounded, size: 10, color: color),
                      ],
                    ),
                  ),
                ],
              ),
              // Barre de progression
              if (pct > 0) ...[
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: pct / 100,
                          backgroundColor: color.withValues(alpha: 0.12),
                          valueColor: AlwaysStoppedAnimation<Color>(color),
                          minHeight: 6,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text('$pct%',
                        style: TextStyle(
                          fontSize: 11, fontWeight: FontWeight.w700, color: color)),
                  ],
                ),
              ] else ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0F4F1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.play_circle_outline, size: 12, color: AppColors.primary),
                          SizedBox(width: 3),
                          Text('Commencer', style: TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ── Micro-interaction tap ──────────────────────────────────────
class _TapCard extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  const _TapCard({required this.child, required this.onTap});

  @override
  State<_TapCard> createState() => _TapCardState();
}

class _TapCardState extends State<_TapCard> with SingleTickerProviderStateMixin {
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
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) { _ctrl.reverse(); widget.onTap(); },
      onTapCancel: () => _ctrl.reverse(),
      child: ScaleTransition(scale: _scale, child: widget.child),
    );
  }
}
