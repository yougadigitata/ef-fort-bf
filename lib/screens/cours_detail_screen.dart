import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../services/cours_service.dart';
import 'chapitre_detail_screen.dart';

// ══════════════════════════════════════════════════════════════
// COURS DETAIL SCREEN — Liste des chapitres d'une matière
// ══════════════════════════════════════════════════════════════

class CoursDetailScreen extends StatefulWidget {
  final String matiereId;
  final String matiereNom;
  final String matiereCode;
  final Color couleur;
  final String icone;

  const CoursDetailScreen({
    super.key,
    required this.matiereId,
    required this.matiereNom,
    required this.matiereCode,
    required this.couleur,
    required this.icone,
  });

  @override
  State<CoursDetailScreen> createState() => _CoursDetailScreenState();
}

class _CoursDetailScreenState extends State<CoursDetailScreen>
    with SingleTickerProviderStateMixin {
  List<Chapitre> _chapitres = [];
  Set<String> _leconsTerminees = {};
  bool _loading = true;
  String? _error;
  late AnimationController _animCtrl;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _loadData();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() { _loading = true; _error = null; });
    try {
      final results = await Future.wait([
        CoursService.getChapitresByMatiere(widget.matiereId),
        CoursService.getLeconsTerminees(),
      ]);

      if (mounted) {
        setState(() {
          _chapitres = results[0] as List<Chapitre>;
          _leconsTerminees = results[1] as Set<String>;
          _loading = false;
        });
        _animCtrl.forward(from: 0);
      }
    } catch (e) {
      if (mounted) {
        setState(() { _error = 'Erreur de chargement'; _loading = false; });
      }
    }
  }

  int _getNbLeconsTerminees(Chapitre ch) {
    return ch.lecons.where((l) => _leconsTerminees.contains(l.id)).length;
  }

  double _getProgression(Chapitre ch) {
    if (ch.lecons.isEmpty) return 0;
    return _getNbLeconsTerminees(ch) / ch.lecons.length;
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
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : _error != null
                    ? _buildError()
                    : _chapitres.isEmpty
                        ? _buildEmpty()
                        : _buildList(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final pct = _chapitres.isEmpty ? 0 : (() {
      int total = 0; int terminees = 0;
      for (final ch in _chapitres) {
        total += ch.lecons.length;
        terminees += _getNbLeconsTerminees(ch);
      }
      return total > 0 ? ((terminees / total) * 100).round() : 0;
    })();

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [widget.couleur, widget.couleur.withValues(alpha: 0.80)],
        ),
        boxShadow: [
          BoxShadow(color: widget.couleur.withValues(alpha: 0.30), blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 8,
        bottom: 20,
        left: 16,
        right: 16,
      ),
      child: Column(
        children: [
          // Nav bar
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
                onPressed: () => Navigator.pop(context),
              ),
              Text(widget.icone, style: const TextStyle(fontSize: 28)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.matiereNom,
                      style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white),
                    ),
                    Text(
                      '${_chapitres.length} chapitre${_chapitres.length > 1 ? 's' : ''}',
                      style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.80)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          // Progression globale
          if (pct > 0) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: pct / 100,
                      backgroundColor: Colors.white.withValues(alpha: 0.25),
                      valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                      minHeight: 8,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text('$pct%',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white)),
              ],
            ),
            const SizedBox(height: 4),
            Text('Progression du cours',
                style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.70))),
          ],
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
          const Text('Erreur de chargement', style: TextStyle(fontSize: 17, color: AppColors.textLight)),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _loadData,
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
          Text(widget.icone, style: const TextStyle(fontSize: 56)),
          const SizedBox(height: 16),
          Text('Cours de ${widget.matiereNom}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF1A1A2E))),
          const SizedBox(height: 8),
          const Text(
            'Les chapitres seront disponibles\ntrès bientôt. Restez connecté !',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: AppColors.textLight, height: 1.5),
          ),
          const SizedBox(height: 24),
          // Suggestion : aller s'entraîner en attendant
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 32),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
            ),
            child: Row(
              children: [
                const Text('💡', style: TextStyle(fontSize: 20)),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'En attendant, entraînez-vous avec les QCM disponibles dans l\'onglet "S\'entraîner"',
                    style: TextStyle(fontSize: 13, color: AppColors.primary, height: 1.4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildList() {
    return RefreshIndicator(
      onRefresh: _loadData,
      color: widget.couleur,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 30),
        itemCount: _chapitres.length,
        itemBuilder: (ctx, i) {
          final ch = _chapitres[i];
          final delay = (i * 0.08).clamp(0.0, 0.7);
          final animation = Tween<double>(begin: 0.0, end: 1.0).animate(
            CurvedAnimation(
              parent: _animCtrl,
              curve: Interval(delay, (delay + 0.45).clamp(0.0, 1.0), curve: Curves.easeOut),
            ),
          );
          return AnimatedBuilder(
            animation: animation,
            builder: (_, child) => Transform.translate(
              offset: Offset(0, 18 * (1 - animation.value)),
              child: Opacity(opacity: animation.value.clamp(0.0, 1.0), child: child),
            ),
            child: _buildChapitreCard(ch, i),
          );
        },
      ),
    );
  }

  Widget _buildChapitreCard(Chapitre ch, int index) {
    final nbLecons = ch.lecons.length;
    final nbTerminees = _getNbLeconsTerminees(ch);
    final progression = _getProgression(ch);
    final estComplet = nbLecons > 0 && nbTerminees == nbLecons;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder: (_, anim, __) => ChapitreDetailScreen(
              chapitreId: ch.id,
              chapitreNom: ch.titre,
              couleur: widget.couleur,
              matiereNom: widget.matiereNom,
              leconsTerminees: _leconsTerminees,
              onProgressionUpdate: (Set<String> updated) {
                setState(() => _leconsTerminees = updated);
              },
            ),
            transitionsBuilder: (_, anim, __, child) {
              final tween = Tween<Offset>(
                begin: const Offset(1.0, 0.0), end: Offset.zero,
              ).chain(CurveTween(curve: Curves.easeOutCubic));
              return SlideTransition(position: anim.drive(tween), child: child);
            },
            transitionDuration: const Duration(milliseconds: 300),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: estComplet
                ? const Color(0xFF22C55E).withValues(alpha: 0.40)
                : widget.couleur.withValues(alpha: 0.18),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: widget.couleur.withValues(alpha: 0.07),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Numéro de chapitre
                  Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                      color: estComplet
                          ? const Color(0xFF22C55E).withValues(alpha: 0.12)
                          : widget.couleur.withValues(alpha: 0.10),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: estComplet
                          ? const Icon(Icons.check_circle_rounded,
                              color: Color(0xFF22C55E), size: 22)
                          : Text('${index + 1}',
                              style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w800,
                                color: widget.couleur,
                              )),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(ch.titre,
                            style: const TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF1A1A2E))),
                        if (ch.description != null && ch.description!.isNotEmpty) ...[
                          const SizedBox(height: 3),
                          Text(ch.description!,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 12, color: AppColors.textLight, height: 1.3)),
                        ],
                      ],
                    ),
                  ),
                  Icon(Icons.arrow_forward_ios_rounded,
                      size: 16, color: widget.couleur.withValues(alpha: 0.60)),
                ],
              ),
              if (nbLecons > 0) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.book_rounded, size: 14, color: widget.couleur.withValues(alpha: 0.70)),
                    const SizedBox(width: 4),
                    Text('$nbLecons leçon${nbLecons > 1 ? 's' : ''}',
                        style: TextStyle(fontSize: 12, color: widget.couleur, fontWeight: FontWeight.w600)),
                    if (nbTerminees > 0) ...[
                      const SizedBox(width: 8),
                      Text('· $nbTerminees terminée${nbTerminees > 1 ? 's' : ''}',
                          style: const TextStyle(fontSize: 12, color: Color(0xFF22C55E), fontWeight: FontWeight.w500)),
                    ],
                    const Spacer(),
                    if (progression > 0)
                      Text('${(progression * 100).round()}%',
                          style: TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w700,
                            color: estComplet ? const Color(0xFF22C55E) : widget.couleur,
                          )),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progression,
                    backgroundColor: widget.couleur.withValues(alpha: 0.10),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      estComplet ? const Color(0xFF22C55E) : widget.couleur,
                    ),
                    minHeight: 5,
                  ),
                ),
              ] else ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF3CD),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text('Leçons bientôt disponibles',
                      style: TextStyle(fontSize: 11, color: Color(0xFFD4A017), fontWeight: FontWeight.w500)),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
