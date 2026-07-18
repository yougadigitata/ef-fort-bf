import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../services/cours_service.dart';
import 'chapitre_detail_screen.dart';

// ══════════════════════════════════════════════════════════════
// DOMAINE DETAIL SCREEN v10.0 — Présente un domaine avec modules & leçons
// Vocabulaire e-learning : domaine / module / leçon (style Coursera)
// ══════════════════════════════════════════════════════════════

class DomaineDetailScreen extends StatefulWidget {
  final String matiereId;
  final String matiereNom;
  final String matiereCode;
  final Color couleur;
  final String icone;

  const DomaineDetailScreen({
    super.key,
    required this.matiereId,
    required this.matiereNom,
    required this.matiereCode,
    required this.couleur,
    required this.icone,
  });

  @override
  State<DomaineDetailScreen> createState() => _DomaineDetailScreenState();
}

class _DomaineDetailScreenState extends State<DomaineDetailScreen>
    with SingleTickerProviderStateMixin {
  List<Chapitre> _modules = [];
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
          _modules = results[0] as List<Chapitre>;
          _leconsTerminees = results[1] as Set<String>;
          _loading = false;
        });
        _animCtrl.forward(from: 0);
      }
    } catch (_) {
      if (mounted) {
        setState(() { _error = 'Erreur de chargement'; _loading = false; });
      }
    }
  }

  int _getNbLeconsTerminees(Chapitre module) {
    return module.lecons.where((l) => _leconsTerminees.contains(l.id)).length;
  }

  double _getProgression(Chapitre module) {
    if (module.lecons.isEmpty) return 0;
    return _getNbLeconsTerminees(module) / module.lecons.length;
  }

  int get _progressionGlobale {
    int total = 0; int terminees = 0;
    for (final m in _modules) {
      total += m.lecons.length;
      terminees += _getNbLeconsTerminees(m);
    }
    return total > 0 ? ((terminees / total) * 100).round() : 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2.5))
                : _error != null
                    ? _buildError()
                    : _modules.isEmpty
                        ? _buildEmpty()
                        : _buildContent(),
          ),
        ],
      ),
      // Bouton flottant Commencer/Continuer
      bottomNavigationBar: _loading || _error != null
          ? null
          : _buildBottomAction(),
    );
  }

  Widget _buildHeader() {
    final pct = _progressionGlobale;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [widget.couleur, widget.couleur.withValues(alpha: 0.75)],
        ),
      ),
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 4,
        bottom: 24,
        left: 16,
        right: 16,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Navigation
          Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
                ),
              ),
              const Spacer(),
              // Badge gratuit
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  '100% Gratuit',
                  style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Icône + nom domaine
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(widget.icone, style: const TextStyle(fontSize: 30)),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'DOMAINE',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      widget.matiereNom,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        height: 1.2,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_modules.length} module${_modules.length > 1 ? 's' : ''} · Apprentissage libre',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          // Progression globale
          if (pct > 0) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: pct / 100,
                      backgroundColor: Colors.white.withValues(alpha: 0.2),
                      valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFFCD116)),
                      minHeight: 6,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  '$pct%',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Progression de votre formation',
              style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.7)),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildContent() {
    return RefreshIndicator(
      onRefresh: _loadData,
      color: widget.couleur,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
        itemCount: _modules.length + 1, // +1 pour le header "Modules"
        itemBuilder: (ctx, i) {
          if (i == 0) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Modules du domaine',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Chaque module contient des leçons et des exercices pratiques',
                    style: const TextStyle(fontSize: 13, color: AppColors.textLight),
                  ),
                ],
              ),
            );
          }
          final module = _modules[i - 1];
          final delay = ((i - 1) * 0.08).clamp(0.0, 0.7);
          final anim = Tween<double>(begin: 0.0, end: 1.0).animate(
            CurvedAnimation(
              parent: _animCtrl,
              curve: Interval(delay, (delay + 0.45).clamp(0.0, 1.0), curve: Curves.easeOut),
            ),
          );
          return AnimatedBuilder(
            animation: anim,
            builder: (_, child) => Transform.translate(
              offset: Offset(0, 18 * (1 - anim.value)),
              child: Opacity(opacity: anim.value.clamp(0.0, 1.0), child: child),
            ),
            child: _buildModuleCard(module, i - 1),
          );
        },
      ),
    );
  }

  Widget _buildModuleCard(Chapitre module, int index) {
    final nbLecons = module.lecons.length;
    final nbTerminees = _getNbLeconsTerminees(module);
    final progression = _getProgression(module);
    final estComplet = nbLecons > 0 && nbTerminees == nbLecons;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder: (_, anim, __) => ChapitreDetailScreen(
              chapitreId: module.id,
              chapitreNom: module.titre,
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
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: estComplet
                ? AppColors.success.withValues(alpha: 0.35)
                : AppColors.divider,
            width: estComplet ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
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
                  // Badge module
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: estComplet
                          ? AppColors.success.withValues(alpha: 0.1)
                          : widget.couleur.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: estComplet
                          ? const Icon(Icons.check_circle_rounded,
                              color: AppColors.success, size: 22)
                          : Text(
                              'M${index + 1}',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: widget.couleur,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Module ${index + 1}',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: widget.couleur,
                            letterSpacing: 0.2,
                          ),
                        ),
                        Text(
                          module.titre,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textDark,
                            height: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 16,
                    color: AppColors.textSubtle,
                  ),
                ],
              ),
              if (module.description != null && module.description!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  module.description!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textLight,
                    height: 1.4,
                  ),
                ),
              ],
              const SizedBox(height: 12),
              // Info leçons
              Row(
                children: [
                  Icon(Icons.menu_book_outlined, size: 14, color: widget.couleur),
                  const SizedBox(width: 4),
                  Text(
                    '$nbLecons leçon${nbLecons > 1 ? 's' : ''}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: widget.couleur,
                    ),
                  ),
                  if (nbTerminees > 0) ...[
                    const Text(' · ', style: TextStyle(color: AppColors.textSubtle)),
                    Text(
                      '$nbTerminees terminée${nbTerminees > 1 ? 's' : ''}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.success,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                  const Spacer(),
                  // Statut
                  if (estComplet)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.successSurface,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'Terminé ✓',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.success,
                        ),
                      ),
                    )
                  else if (nbTerminees > 0)
                    Text(
                      '${(progression * 100).round()}%',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: widget.couleur,
                      ),
                    ),
                ],
              ),
              // Barre de progression
              if (nbLecons > 0) ...[
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progression,
                    backgroundColor: widget.couleur.withValues(alpha: 0.08),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      estComplet ? AppColors.success : widget.couleur,
                    ),
                    minHeight: 4,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomAction() {
    final pct = _progressionGlobale;
    final hasMods = _modules.isNotEmpty;
    final label = pct > 0 ? 'Continuer la formation' : 'Commencer la formation';

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      decoration: BoxDecoration(
        color: AppColors.white,
        border: const Border(top: BorderSide(color: AppColors.divider)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: hasMods ? () {
              // Ouvrir le premier module non terminé
              final premier = _modules.firstWhere(
                (m) => _getProgression(m) < 1.0,
                orElse: () => _modules.first,
              );
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ChapitreDetailScreen(
                    chapitreId: premier.id,
                    chapitreNom: premier.titre,
                    couleur: widget.couleur,
                    matiereNom: widget.matiereNom,
                    leconsTerminees: _leconsTerminees,
                    onProgressionUpdate: (Set<String> updated) {
                      setState(() => _leconsTerminees = updated);
                    },
                  ),
                ),
              );
            } : null,
            icon: Icon(
              pct > 0 ? Icons.play_arrow_rounded : Icons.rocket_launch_outlined,
              size: 20,
            ),
            label: Text(label),
            style: ElevatedButton.styleFrom(
              backgroundColor: widget.couleur,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 15),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.wifi_off_rounded, size: 52, color: AppColors.textSubtle),
          const SizedBox(height: 16),
          const Text('Impossible de charger le domaine',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          TextButton(
            onPressed: _loadData,
            child: const Text('Réessayer'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(widget.icone, style: const TextStyle(fontSize: 64)),
            const SizedBox(height: 20),
            Text(
              widget.matiereNom,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Les modules de ce domaine seront disponibles très bientôt.\nRestez connecté !',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: AppColors.textLight, height: 1.5),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primarySurface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
              ),
              child: const Row(
                children: [
                  Text('💡', style: TextStyle(fontSize: 20)),
                  SizedBox(width: 10),
                  Expanded(
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
      ),
    );
  }
}
