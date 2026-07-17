import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../services/cours_service.dart';
import 'lecon_screen.dart';

// ══════════════════════════════════════════════════════════════
// CHAPITRE DETAIL SCREEN — Liste des leçons d'un chapitre
// ══════════════════════════════════════════════════════════════

class ChapitreDetailScreen extends StatefulWidget {
  final String chapitreId;
  final String chapitreNom;
  final Color couleur;
  final String matiereNom;
  final Set<String> leconsTerminees;
  final Function(Set<String>) onProgressionUpdate;

  const ChapitreDetailScreen({
    super.key,
    required this.chapitreId,
    required this.chapitreNom,
    required this.couleur,
    required this.matiereNom,
    required this.leconsTerminees,
    required this.onProgressionUpdate,
  });

  @override
  State<ChapitreDetailScreen> createState() => _ChapitreDetailScreenState();
}

class _ChapitreDetailScreenState extends State<ChapitreDetailScreen>
    with SingleTickerProviderStateMixin {
  Chapitre? _chapitre;
  late Set<String> _terminees;
  bool _loading = true;
  String? _error;
  late AnimationController _animCtrl;

  @override
  void initState() {
    super.initState();
    _terminees = Set<String>.from(widget.leconsTerminees);
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _loadChapitre();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadChapitre() async {
    setState(() { _loading = true; _error = null; });
    try {
      final ch = await CoursService.getChapitreWithLecons(widget.chapitreId);
      if (mounted) {
        setState(() {
          _chapitre = ch;
          _loading = false;
        });
        if (ch != null) _animCtrl.forward(from: 0);
      }
    } catch (e) {
      if (mounted) {
        setState(() { _error = 'Erreur de chargement'; _loading = false; });
      }
    }
  }

  double get _progression {
    final ch = _chapitre;
    if (ch == null || ch.lecons.isEmpty) return 0;
    final t = ch.lecons.where((l) => _terminees.contains(l.id)).length;
    return t / ch.lecons.length;
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
                    : _chapitre == null
                        ? _buildNotFound()
                        : _chapitre!.lecons.isEmpty
                            ? _buildEmpty()
                            : _buildList(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final pct = (_progression * 100).round();
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [widget.couleur, widget.couleur.withValues(alpha: 0.75)],
        ),
      ),
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 8,
        bottom: 20,
        left: 16,
        right: 16,
      ),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
                onPressed: () {
                  widget.onProgressionUpdate(_terminees);
                  Navigator.pop(context);
                },
              ),
              const Icon(Icons.menu_book_rounded, color: Colors.white, size: 26),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.chapitreNom,
                        style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white)),
                    Text(widget.matiereNom,
                        style: TextStyle(
                          fontSize: 12, color: Colors.white.withValues(alpha: 0.75))),
                  ],
                ),
              ),
            ],
          ),
          if (_chapitre != null && _chapitre!.lecons.isNotEmpty) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: _progression,
                      backgroundColor: Colors.white.withValues(alpha: 0.25),
                      valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                      minHeight: 7,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text('$pct%',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white)),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '${_chapitre!.lecons.where((l) => _terminees.contains(l.id)).length}/${_chapitre!.lecons.length} leçons terminées',
              style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.70)),
            ),
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
          Text(_error!, style: const TextStyle(color: AppColors.textLight)),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadChapitre,
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
            child: const Text('Réessayer'),
          ),
        ],
      ),
    );
  }

  Widget _buildNotFound() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('🔍', style: TextStyle(fontSize: 48)),
          SizedBox(height: 16),
          Text('Chapitre introuvable', style: TextStyle(fontSize: 17, color: AppColors.textLight)),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('📖', style: TextStyle(fontSize: 56)),
          const SizedBox(height: 16),
          Text(widget.chapitreNom,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF1A1A2E))),
          const SizedBox(height: 8),
          const Text(
            'Les leçons de ce chapitre\narriveront très bientôt !',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: AppColors.textLight, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildList() {
    final lecons = _chapitre!.lecons;
    return RefreshIndicator(
      onRefresh: _loadChapitre,
      color: widget.couleur,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 30),
        itemCount: lecons.length,
        itemBuilder: (ctx, i) {
          final l = lecons[i];
          final estTerminee = _terminees.contains(l.id);
          final delay = (i * 0.07).clamp(0.0, 0.6);
          final animation = Tween<double>(begin: 0.0, end: 1.0).animate(
            CurvedAnimation(
              parent: _animCtrl,
              curve: Interval(delay, (delay + 0.4).clamp(0.0, 1.0), curve: Curves.easeOut),
            ),
          );
          return AnimatedBuilder(
            animation: animation,
            builder: (_, child) => Transform.translate(
              offset: Offset(0, 15 * (1 - animation.value)),
              child: Opacity(opacity: animation.value.clamp(0.0, 1.0), child: child),
            ),
            child: _buildLeconCard(l, i, estTerminee),
          );
        },
      ),
    );
  }

  Widget _buildLeconCard(Lecon lecon, int index, bool estTerminee) {
    return GestureDetector(
      onTap: () async {
        final result = await Navigator.push<bool>(
          context,
          PageRouteBuilder(
            pageBuilder: (_, anim, __) => LeconScreen(
              leconId: lecon.id,
              leconTitre: lecon.titre,
              chapitreNom: widget.chapitreNom,
              couleur: widget.couleur,
              matiereNom: widget.matiereNom,
              estTerminee: estTerminee,
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
        // Si la leçon a été marquée comme terminée
        if (result == true && !estTerminee) {
          setState(() => _terminees.add(lecon.id));
          widget.onProgressionUpdate(_terminees);
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: estTerminee
                ? const Color(0xFF22C55E).withValues(alpha: 0.35)
                : widget.couleur.withValues(alpha: 0.15),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: widget.couleur.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              // Numéro / Icône état
              Container(
                width: 38, height: 38,
                decoration: BoxDecoration(
                  color: estTerminee
                      ? const Color(0xFF22C55E).withValues(alpha: 0.12)
                      : widget.couleur.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: estTerminee
                      ? const Icon(Icons.check_rounded, color: Color(0xFF22C55E), size: 20)
                      : Text('${index + 1}',
                          style: TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w700,
                            color: widget.couleur,
                          )),
                ),
              ),
              const SizedBox(width: 12),
              // Titre et durée
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(lecon.titre,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: estTerminee ? const Color(0xFF22C55E) : const Color(0xFF1A1A2E),
                        )),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Icon(Icons.schedule_rounded,
                            size: 12, color: AppColors.textLight.withValues(alpha: 0.70)),
                        const SizedBox(width: 3),
                        Text('${lecon.dureeMinutes} min',
                            style: const TextStyle(fontSize: 11, color: AppColors.textLight)),
                        if (lecon.videoUrl != null && lecon.videoUrl!.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          const Icon(Icons.play_circle_outline_rounded,
                              size: 12, color: Color(0xFFE74C3C)),
                          const SizedBox(width: 2),
                          const Text('Vidéo',
                              style: TextStyle(fontSize: 11, color: Color(0xFFE74C3C))),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              // Badge état + flèche
              if (estTerminee)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDCFCE7),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text('✓ Fait',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF22C55E))),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: widget.couleur.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Lire', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: widget.couleur)),
                      const SizedBox(width: 2),
                      Icon(Icons.arrow_forward_ios_rounded, size: 10, color: widget.couleur),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
