import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../services/api_service.dart';
import 'qcm_screen.dart';

class MatieresScreen extends StatefulWidget {
  const MatieresScreen({super.key});

  @override
  State<MatieresScreen> createState() => _MatieresScreenState();
}

class _MatieresScreenState extends State<MatieresScreen> {
  List<dynamic> _matieres = [];
  bool _loading = true;

  static const Map<String, Map<String, dynamic>> _matiereInfo = {
    'culture_generale': {'icon': Icons.public_rounded, 'color': Color(0xFF1A5C38), 'label': 'Culture Generale'},
    'francais': {'icon': Icons.translate_rounded, 'color': Color(0xFF2196F3), 'label': 'Francais'},
    'mathematiques': {'icon': Icons.calculate_rounded, 'color': Color(0xFFFF5722), 'label': 'Mathematiques'},
    'psychotechnique': {'icon': Icons.psychology_rounded, 'color': Color(0xFF9C27B0), 'label': 'Psychotechnique'},
    'droit': {'icon': Icons.gavel_rounded, 'color': Color(0xFF795548), 'label': 'Droit'},
    'economie': {'icon': Icons.trending_up_rounded, 'color': Color(0xFF4CAF50), 'label': 'Economie'},
    'histoire_geo': {'icon': Icons.map_rounded, 'color': Color(0xFFFF9800), 'label': 'Histoire-Geo'},
    'sciences': {'icon': Icons.science_rounded, 'color': Color(0xFF00BCD4), 'label': 'Sciences'},
    'actualite': {'icon': Icons.newspaper_rounded, 'color': Color(0xFFD4A017), 'label': 'Actualite'},
    'informatique': {'icon': Icons.computer_rounded, 'color': Color(0xFF607D8B), 'label': 'Informatique'},
  };

  @override
  void initState() {
    super.initState();
    _loadMatieres();
  }

  Future<void> _loadMatieres() async {
    final matieres = await ApiService.getMatieres();
    if (mounted) {
      setState(() {
        _matieres = matieres;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Matieres QCM'),
        automaticallyImplyLeading: false,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.primary, AppColors.primaryDark],
            ),
          ),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : RefreshIndicator(
              onRefresh: _loadMatieres,
              child: _matieres.isEmpty
                  ? ListView(
                      children: [
                        SizedBox(
                          height: MediaQuery.of(context).size.height * 0.6,
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.menu_book_rounded, size: 64, color: AppColors.textLight.withValues(alpha: 0.3)),
                                const SizedBox(height: 16),
                                const Text('Aucune matiere disponible', style: TextStyle(color: AppColors.textLight, fontSize: 16)),
                                const SizedBox(height: 8),
                                const Text('Tirez vers le bas pour recharger', style: TextStyle(color: AppColors.textLight, fontSize: 13)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    )
                  : GridView.builder(
                      padding: const EdgeInsets.all(16),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 14,
                        crossAxisSpacing: 14,
                        childAspectRatio: 1.1,
                      ),
                      itemCount: _matieres.length,
                      itemBuilder: (context, index) {
                        final matiere = _matieres[index];
                        String matiereKey;
                        int count = 0;
                        if (matiere is Map) {
                          matiereKey = (matiere['matiere'] ?? matiere['nom'] ?? '').toString();
                          count = (matiere['count'] ?? matiere['nb'] ?? 0) as int;
                        } else {
                          matiereKey = matiere.toString();
                        }
                        final info = _matiereInfo[matiereKey] ?? {
                          'icon': Icons.quiz_rounded,
                          'color': AppColors.primary,
                          'label': matiereKey.replaceAll('_', ' ').toUpperCase(),
                        };
                        final color = info['color'] as Color;
                        return GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => QcmScreen(matiere: matiereKey, label: info['label'] as String),
                              ),
                            );
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: AppColors.white,
                              borderRadius: BorderRadius.circular(18),
                              boxShadow: [
                                BoxShadow(
                                  color: color.withValues(alpha: 0.12),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: color.withValues(alpha: 0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(info['icon'] as IconData, color: color, size: 32),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  info['label'] as String,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textDark,
                                  ),
                                ),
                                if (count > 0) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    '$count questions',
                                    style: TextStyle(fontSize: 11, color: AppColors.textLight),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}
