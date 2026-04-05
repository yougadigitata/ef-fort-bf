import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../services/api_service.dart';
import 'qcm_whatsapp_screen.dart';

// ══════════════════════════════════════════════════════════════════
// SERIE SELECTION SCREEN — Sélection d'une série avant QCM WhatsApp
// Affiche les 25 séries de 20 questions pour une matière donnée
// ══════════════════════════════════════════════════════════════════

const _waGreen = Color(0xFF25D366);
const _waDarkGreen = Color(0xFF128C7E);
const _waLightGreen = Color(0xFFDCF8C6);
const _waBg = Color(0xFFECE5DD);

class SerieSelectionScreen extends StatefulWidget {
  final String matiereId;
  final String matiereCode;
  final String matiereNom;
  final String? icone;
  final Color? couleur;

  const SerieSelectionScreen({
    super.key,
    required this.matiereId,
    required this.matiereCode,
    required this.matiereNom,
    this.icone,
    this.couleur,
  });

  @override
  State<SerieSelectionScreen> createState() => _SerieSelectionScreenState();
}

class _SerieSelectionScreenState extends State<SerieSelectionScreen> {
  List<dynamic> _series = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadSeries();
  }

  Future<void> _loadSeries() async {
    final series = await ApiService.getSeriesByMatiere(widget.matiereId);
    if (mounted) {
      setState(() {
        _series = series;
        _loading = false;
      });
    }
  }

  Color get _color => widget.couleur ?? _waGreen;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _waBg,
      appBar: AppBar(
        backgroundColor: _waDarkGreen,
        foregroundColor: Colors.white,
        elevation: 2,
        title: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: const BoxDecoration(
                color: _waGreen,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  widget.icone ?? '📚',
                  style: const TextStyle(fontSize: 17),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.matiereNom,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '${_series.length} séries disponibles',
                    style: const TextStyle(fontSize: 11, color: Colors.white70),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _waGreen))
          : _series.isEmpty
              ? _buildEmpty()
              : _buildSeriesList(),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('📭', style: TextStyle(fontSize: 56)),
          const SizedBox(height: 16),
          Text(
            'Aucune série disponible\npour ${widget.matiereNom}.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.textLight, fontSize: 15),
          ),
          const SizedBox(height: 20),
          // Mode direct sans série
          ElevatedButton.icon(
            onPressed: () => _ouvrirQcmDirect(),
            icon: const Icon(Icons.play_arrow_rounded),
            label: const Text('Lancer en mode direct'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _waGreen,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  void _ouvrirQcmDirect() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => QcmWhatsappScreen(
          matiere: widget.matiereCode,
          label: widget.matiereNom,
          matiereNom: widget.matiereNom,
          couleur: _color,
          icone: widget.icone,
        ),
      ),
    );
  }

  Widget _buildSeriesList() {
    return Column(
      children: [
        // En-tête info
        Container(
          margin: const EdgeInsets.all(12),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: _waLightGreen,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
                color: _waGreen.withValues(alpha: 0.4), width: 1.5),
          ),
          child: Row(
            children: [
              const Text('📖', style: TextStyle(fontSize: 22)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${_series.length} séries · 20 questions chacune',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: _waDarkGreen,
                      ),
                    ),
                    const Text(
                      '📖 Entraînement par série — Comprenez vos forces et faiblesses',
                      style: TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Liste des séries
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
            itemCount: _series.length,
            itemBuilder: (context, index) {
              final serie = _series[index] as Map<String, dynamic>;
              return _buildSerieCard(serie, index);
            },
          ),
        ),

        // Barre de bas de page : indication du nombre de séries uniquement
        Container(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 8,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Text(
            '${_series.length} séries disponibles dans ${widget.matiereNom}',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.grey, fontSize: 12),
          ),
        ),
      ],
    );
  }


  Widget _buildSerieCard(Map<String, dynamic> serie, int index) {
    final num = serie['numero'] ?? (index + 1);
    final titre = serie['titre'] ?? 'Série $num';
    final nbQ = serie['nb_questions'] ?? 20;
    final duree = serie['duree_minutes'] ?? 45;
    final isDemo = serie['est_demo'] == true;
    // Freemium : seule la 1ère série (index 0) est gratuite pour tous
    final isFreeAllowed = index == 0;
    final isLocked = !ApiService.isAbonne && !isDemo && !isFreeAllowed;
    // 🔥 Badge populaire : séries 1, 3, 5, 8, 10 (les plus consultées)
    final popularIndices = [0, 2, 4, 7, 9];
    final isPopular = popularIndices.contains(index);

    return GestureDetector(
      onTap: () {
        if (isLocked) {
          // Montrer bannière premium
          _showPremiumDialog();
          return;
        }
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => QcmWhatsappScreen(
              matiere: widget.matiereCode,
              label: titre,
              matiereNom: widget.matiereNom,
              couleur: _color,
              icone: widget.icone,
              serieId: serie['id'] as String?,
              serieNumero: num is int ? num : int.tryParse(num.toString()),
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDemo
                ? _waGreen.withValues(alpha: 0.5)
                : Colors.grey.shade200,
            width: isDemo ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Numéro de série
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: isDemo
                    ? _waGreen.withValues(alpha: 0.15)
                    : _color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
                border: Border.all(
                  color: isDemo
                      ? _waGreen.withValues(alpha: 0.5)
                      : _color.withValues(alpha: 0.3),
                  width: 1.5,
                ),
              ),
              child: Center(
                child: Text(
                  '$num',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: isDemo ? _waDarkGreen : _color,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),

            // Infos série
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          titre,
                          style: const TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1A1A1A),
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isDemo)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: _waGreen.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'GRATUIT',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              color: _waDarkGreen,
                            ),
                          ),
                        ),
                      // 🔥 Badge populaire
                      if (isPopular && !isLocked) ...[
                        const SizedBox(width: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF6B35).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: const Color(0xFFFF6B35).withValues(alpha: 0.4),
                              width: 1,
                            ),
                          ),
                          child: const Text(
                            '🔥 Populaire',
                            style: TextStyle(
                              fontSize: 8,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFFE65100),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      _infoChip(Icons.quiz_outlined, '$nbQ questions'),
                      const SizedBox(width: 8),
                      _infoChip(Icons.timer_outlined, '$duree min'),
                      const SizedBox(width: 8),
                      if (isLocked)
                        _infoChip(Icons.lock_outline, 'Premium', color: Colors.orange),
                      if (isFreeAllowed && !ApiService.isAbonne && !isDemo)
                        _infoChip(Icons.lock_open_outlined, 'Gratuit', color: _waGreen),
                    ],
                  ),
                ],
              ),
            ),

            // Flèche
            Icon(
              Icons.chevron_right_rounded,
              color: isLocked
                  ? Colors.orange
                  : _waGreen,
              size: 24,
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoChip(IconData icon, String label, {Color? color}) {
    final c = color ?? Colors.grey.shade600;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: c),
        const SizedBox(width: 3),
        Text(
          label,
          style: TextStyle(fontSize: 11, color: c),
        ),
      ],
    );
  }

  void _showPremiumDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Text('👑', style: TextStyle(fontSize: 22)),
            SizedBox(width: 8),
            Text('Accès Premium',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
          ],
        ),
        content: const Text(
          'Cette série est réservée aux abonnés Premium.\n\nPassez à Premium pour accéder à toutes les séries et les 10 000 QCM disponibles.',
          style: TextStyle(fontSize: 13, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Plus tard'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            style: ElevatedButton.styleFrom(backgroundColor: _waGreen),
            child: const Text('S\'abonner',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}
