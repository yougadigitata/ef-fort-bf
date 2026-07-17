import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../services/cours_service.dart';
import '../services/bell_service.dart';

// ══════════════════════════════════════════════════════════════
// LEÇON SCREEN — Affichage du contenu d'une leçon
// Avec bouton "Marquer comme terminée" et "Quiz"
// ══════════════════════════════════════════════════════════════

class LeconScreen extends StatefulWidget {
  final String leconId;
  final String leconTitre;
  final String chapitreNom;
  final Color couleur;
  final String matiereNom;
  final bool estTerminee;

  const LeconScreen({
    super.key,
    required this.leconId,
    required this.leconTitre,
    required this.chapitreNom,
    required this.couleur,
    required this.matiereNom,
    this.estTerminee = false,
  });

  @override
  State<LeconScreen> createState() => _LeconScreenState();
}

class _LeconScreenState extends State<LeconScreen> {
  Lecon? _lecon;
  bool _loading = true;
  String? _error;
  bool _estTerminee = false;
  bool _marquageEnCours = false;

  @override
  void initState() {
    super.initState();
    _estTerminee = widget.estTerminee;
    _loadLecon();
  }

  Future<void> _loadLecon() async {
    setState(() { _loading = true; _error = null; });
    try {
      final l = await CoursService.getLecon(widget.leconId);
      if (mounted) {
        setState(() { _lecon = l; _loading = false; });
      }
    } catch (e) {
      if (mounted) {
        setState(() { _error = 'Erreur de chargement'; _loading = false; });
      }
    }
  }

  Future<void> _marquerTerminee() async {
    if (_estTerminee || _marquageEnCours) return;
    setState(() => _marquageEnCours = true);

    final ok = await CoursService.marquerLeconTerminee(widget.leconId);
    if (mounted) {
      setState(() {
        _marquageEnCours = false;
        if (ok) _estTerminee = true;
      });
      if (ok) {
        BellService.playClick();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Text('Leçon marquée comme terminée !',
                    style: TextStyle(fontWeight: FontWeight.w600)),
              ],
            ),
            backgroundColor: const Color(0xFF22C55E),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        // Retourner true pour signaler la progression mise à jour
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted) Navigator.pop(context, true);
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Impossible d\'enregistrer. Vérifiez votre connexion.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: _loading
          ? _buildLoading()
          : _error != null
              ? _buildError()
              : _buildContent(),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildLoading() {
    return Column(
      children: [
        _buildMiniHeader(),
        const Expanded(
          child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
        ),
      ],
    );
  }

  Widget _buildError() {
    return Column(
      children: [
        _buildMiniHeader(),
        Expanded(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('📡', style: TextStyle(fontSize: 48)),
                const SizedBox(height: 16),
                Text(_error!, style: const TextStyle(color: AppColors.textLight)),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _loadLecon,
                  style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary, foregroundColor: Colors.white),
                  child: const Text('Réessayer'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMiniHeader() {
    return Container(
      decoration: BoxDecoration(
        color: widget.couleur,
        boxShadow: [
          BoxShadow(color: widget.couleur.withValues(alpha: 0.30), blurRadius: 8, offset: const Offset(0, 3)),
        ],
      ),
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 6,
        bottom: 14,
        left: 8,
        right: 16,
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
            onPressed: () => Navigator.pop(context, _estTerminee),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.chapitreNom,
                    style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.75))),
                Text(widget.leconTitre,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
              ],
            ),
          ),
          if (_estTerminee)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.20),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle_rounded, color: Colors.white, size: 16),
                  SizedBox(width: 4),
                  Text('Terminée', style: TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    final lecon = _lecon;
    if (lecon == null) {
      return Column(
        children: [
          _buildMiniHeader(),
          const Expanded(
            child: Center(
              child: Text('Contenu indisponible',
                  style: TextStyle(color: AppColors.textLight, fontSize: 16)),
            ),
          ),
        ],
      );
    }

    return CustomScrollView(
      slivers: [
        // Header
        SliverToBoxAdapter(child: _buildMiniHeader()),

        // Métadonnées
        SliverToBoxAdapter(
          child: Container(
            margin: const EdgeInsets.fromLTRB(16, 20, 16, 0),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: widget.couleur.withValues(alpha: 0.15)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(lecon.titre,
                    style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFF1A1A2E))),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _metaBadge(Icons.schedule_rounded, '${lecon.dureeMinutes} min', widget.couleur),
                    const SizedBox(width: 8),
                    _metaBadge(Icons.menu_book_rounded, 'Leçon', widget.couleur),
                    if (lecon.videoUrl != null && lecon.videoUrl!.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      _metaBadge(Icons.play_circle_outline_rounded, 'Vidéo', const Color(0xFFE74C3C)),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),

        // Contenu de la leçon
        SliverToBoxAdapter(
          child: _buildContenu(lecon),
        ),

        // Vidéo si disponible
        if (lecon.videoUrl != null && lecon.videoUrl!.isNotEmpty)
          SliverToBoxAdapter(
            child: _buildVideoSection(lecon.videoUrl!),
          ),

        // Espace pour le bouton bas
        const SliverToBoxAdapter(child: SizedBox(height: 100)),
      ],
    );
  }

  Widget _metaBadge(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color)),
        ],
      ),
    );
  }

  Widget _buildContenu(Lecon lecon) {
    final contenu = lecon.contenu;

    if (contenu == null || contenu.isEmpty) {
      return Container(
        margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            const Text('📝', style: TextStyle(fontSize: 40)),
            const SizedBox(height: 12),
            Text(
              'Le contenu de la leçon "${lecon.titre}" sera ajouté prochainement.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: AppColors.textLight, height: 1.6),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF0F4F1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('💡 Conseil',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.primary)),
                  SizedBox(height: 6),
                  Text(
                    'En attendant le contenu de cette leçon, vous pouvez vous entraîner avec les QCM de cette matière en utilisant l\'onglet "S\'entraîner".',
                    style: TextStyle(fontSize: 13, color: AppColors.textLight, height: 1.5),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // Affichage du contenu (texte brut ou HTML simplifié)
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: _parseContenu(contenu),
    );
  }

  Widget _parseContenu(String contenu) {
    // Parser simple pour afficher le contenu HTML/texte
    // En attendant le package html ou flutter_html
    final paragraphes = contenu
        .replaceAll('<br>', '\n')
        .replaceAll('<br/>', '\n')
        .replaceAll('<p>', '\n')
        .replaceAll('</p>', '\n')
        .replaceAll(RegExp(r'<[^>]+>'), '') // Supprimer les balises HTML
        .split('\n')
        .where((p) => p.trim().isNotEmpty)
        .toList();

    if (paragraphes.isEmpty) {
      return Text(contenu, style: const TextStyle(fontSize: 15, height: 1.7, color: Color(0xFF2D3748)));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: paragraphes.map((p) {
        final trimmed = p.trim();
        // Détecter les titres (lignes commençant par # ou ** ou MAJUSCULES)
        if (trimmed.startsWith('##') || trimmed.startsWith('**') || 
            (trimmed.length < 60 && trimmed == trimmed.toUpperCase() && trimmed.length > 3)) {
          final titre = trimmed.replaceAll('##', '').replaceAll('**', '').trim();
          return Padding(
            padding: const EdgeInsets.only(top: 16, bottom: 8),
            child: Text(titre,
                style: TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w700,
                  color: widget.couleur,
                )),
          );
        }
        // Listes
        if (trimmed.startsWith('- ') || trimmed.startsWith('• ')) {
          final item = trimmed.substring(2);
          return Padding(
            padding: const EdgeInsets.only(bottom: 6, left: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 7),
                  width: 6, height: 6,
                  decoration: BoxDecoration(color: widget.couleur, shape: BoxShape.circle),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(item,
                      style: const TextStyle(fontSize: 14, height: 1.6, color: Color(0xFF2D3748))),
                ),
              ],
            ),
          );
        }
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Text(trimmed,
              style: const TextStyle(fontSize: 15, height: 1.7, color: Color(0xFF2D3748))),
        );
      }).toList(),
    );
  }

  Widget _buildVideoSection(String videoUrl) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              children: [
                Icon(Icons.play_circle_filled_rounded, color: Color(0xFFE74C3C), size: 22),
                SizedBox(width: 8),
                Text('Vidéo de la leçon',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF1A1A2E))),
              ],
            ),
          ),
          // Vignette vidéo cliquable
          GestureDetector(
            onTap: () async {
              // Ouvrir l'URL vidéo
              // En production: utiliser url_launcher
            },
            child: Container(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              height: 180,
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A2E),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE74C3C).withValues(alpha: 0.30)),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 60, height: 60,
                      decoration: const BoxDecoration(
                        color: Color(0xFFE74C3C),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 34),
                    ),
                    const SizedBox(height: 12),
                    const Text('Appuyer pour regarder la vidéo',
                        style: TextStyle(fontSize: 13, color: Colors.white70)),
                    const SizedBox(height: 4),
                    Text(
                      videoUrl.length > 40 ? '${videoUrl.substring(0, 40)}...' : videoUrl,
                      style: const TextStyle(fontSize: 11, color: Colors.white38),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget? _buildBottomBar() {
    if (_loading || _error != null) return null;

    return Container(
      padding: EdgeInsets.only(
        left: 16, right: 16, top: 12,
        bottom: MediaQuery.of(context).padding.bottom + 12,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Color(0x12000000), blurRadius: 10, offset: Offset(0, -3)),
        ],
      ),
      child: Row(
        children: [
          // Bouton marquer terminée
          Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              child: ElevatedButton.icon(
                onPressed: _estTerminee ? null : (_marquageEnCours ? null : _marquerTerminee),
                icon: _marquageEnCours
                    ? const SizedBox(
                        width: 16, height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Icon(
                        _estTerminee ? Icons.check_circle_rounded : Icons.check_circle_outline_rounded,
                        size: 20),
                label: Text(_estTerminee ? 'Terminée ✓' : 'Marquer terminée'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _estTerminee ? const Color(0xFF22C55E) : widget.couleur,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: const Color(0xFF22C55E),
                  disabledForegroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
