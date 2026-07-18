import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../services/api_service.dart';
import '../services/cours_service.dart';
import '../services/bell_service.dart';
import 'domaine_detail_screen.dart';

// ══════════════════════════════════════════════════════════════
// EXPLORER SCREEN v10.0 — Parcourir tous les domaines
// Inspiré de l'onglet "Explore" de Coursera
// ══════════════════════════════════════════════════════════════

const Map<String, Map<String, dynamic>> _domaineMeta = {
  'hg':           {'icone': '🗺️', 'couleur': Color(0xFFBD3B3B), 'categorie': 'Sciences humaines'},
  'droit2':       {'icone': '⚖️', 'couleur': Color(0xFF1A5C38), 'categorie': 'Droit & Juridique'},
  'eco2':         {'icone': '💰', 'couleur': Color(0xFF27AE60), 'categorie': 'Économie'},
  'ang':          {'icone': '🗣️', 'couleur': Color(0xFF2980B9), 'categorie': 'Langues'},
  'sp':           {'icone': '⚛️', 'couleur': Color(0xFFE74C3C), 'categorie': 'Sciences'},
  'psycho':       {'icone': '🧩', 'couleur': Color(0xFF8E44AD), 'categorie': 'Psychotechnique'},
  'psy':          {'icone': '🧠', 'couleur': Color(0xFF8E44AD), 'categorie': 'Psychotechnique'},
  'histo':        {'icone': '👤', 'couleur': Color(0xFFC0392B), 'categorie': 'Histoire'},
  'info':         {'icone': '💻', 'couleur': Color(0xFF16A085), 'categorie': 'Informatique'},
  'comm':         {'icone': '📢', 'couleur': Color(0xFFE67E22), 'categorie': 'Communication'},
  'aes':          {'icone': '🌍', 'couleur': Color(0xFF006B3F), 'categorie': 'Géopolitique'},
  'bf':           {'icone': '🇧🇫', 'couleur': Color(0xFFEF2B2D), 'categorie': 'Burkina Faso'},
  'burkina_faso': {'icone': '🇧🇫', 'couleur': Color(0xFFEF2B2D), 'categorie': 'Burkina Faso'},
  'armee':        {'icone': '🪖', 'couleur': Color(0xFF34495E), 'categorie': 'Défense & Sécurité'},
  'actu':         {'icone': '📰', 'couleur': Color(0xFFF39C12), 'categorie': 'Actualité'},
  'maths':        {'icone': '🔢', 'couleur': Color(0xFF3498DB), 'categorie': 'Mathématiques'},
  'svt':          {'icone': '🧬', 'couleur': Color(0xFF1ABC9C), 'categorie': 'Sciences naturelles'},
  'cg':           {'icone': '🌍', 'couleur': Color(0xFF9B59B6), 'categorie': 'Culture générale'},
  'pana':         {'icone': '🌍', 'couleur': Color(0xFFD35400), 'categorie': 'Panafricanisme'},
  'fr':           {'icone': '📖', 'couleur': Color(0xFF1A5C38), 'categorie': 'Langues'},
  'pc':           {'icone': '🔬', 'couleur': Color(0xFFE74C3C), 'categorie': 'Sciences'},
  'enaref':       {'icone': '🏛️', 'couleur': Color(0xFF1A5C38), 'categorie': 'Administration'},
  'haut':         {'icone': '🎓', 'couleur': Color(0xFF8B0000), 'categorie': 'Hautes études'},
  'default':      {'icone': '📚', 'couleur': Color(0xFF0056D2), 'categorie': 'Général'},
};

const Map<String, String> _domaineDescriptions = {
  'psy':    'Tests de logique, séries numériques et raisonnement abstrait.',
  'psycho': 'Tests de logique, séries numériques et raisonnement abstrait.',
  'droit2': 'Droit constitutionnel, administratif et civil burkinabè.',
  'eco2':   'Micro-économie, macro-économie et économie du développement.',
  'maths':  'Algèbre, analyse, probabilités et statistiques appliquées.',
  'pc':     'Physique, Chimie et Sciences de la Vie pour les concours.',
  'sp':     'Sciences Physiques : mécanique, optique, électricité.',
  'svt':    'Sciences de la Vie et de la Terre : biologie et géologie.',
  'hg':     'Histoire de l\'Afrique et géographie du Burkina Faso.',
  'fr':     'Grammaire, expression écrite, littérature francophone.',
  'ang':    'Anglais des affaires et communication internationale.',
  'info':   'Informatique, algorithmique et systèmes d\'information.',
  'comm':   'Techniques de communication orale et écrite professionnelle.',
  'cg':     'Culture générale, actualité africaine et institutions.',
  'bf':     'Histoire, géographie et institutions du Burkina Faso.',
  'burkina_faso': 'Histoire, géographie et institutions du Burkina Faso.',
  'aes':    'Alliance des États du Sahel : histoire et enjeux.',
  'armee':  'Connaissances militaires et civiques pour les forces armées.',
  'actu':   'Actualité internationale et géopolitique africaine.',
  'pana':   'Panafricanisme, histoire et leaders africains.',
  'histo':  'Figures historiques et leadership africain contemporain.',
  'enaref': 'Finances publiques, comptabilité et gestion de l\'État.',
  'haut':   'Préparation aux concours de haut niveau : culture et analyse.',
};

class ExplorerScreen extends StatefulWidget {
  const ExplorerScreen({super.key});

  @override
  State<ExplorerScreen> createState() => _ExplorerScreenState();
}

class _ExplorerScreenState extends State<ExplorerScreen>
    with SingleTickerProviderStateMixin {
  List<Map<String, dynamic>> _domaines = [];
  List<Map<String, dynamic>> _domainesFiltres = [];
  final Map<String, int> _pourcentages = {};
  bool _loading = true;
  String? _error;
  String _filtre = 'Tous';
  final _searchCtrl = TextEditingController();
  late AnimationController _animCtrl;

  static const _filtres = ['Tous', 'Droit', 'Langues', 'Sciences', 'Culture générale'];

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _loadDomaines();
    _searchCtrl.addListener(_filterDomaines);
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadDomaines() async {
    setState(() { _loading = true; _error = null; });
    try {
      final data = await ApiService.getMatieres();
      if (mounted) {
        setState(() {
          _domaines = data.cast<Map<String, dynamic>>();
          _domainesFiltres = List.from(_domaines);
          _loading = false;
        });
        _animCtrl.forward(from: 0);
        _loadPourcentages();
      }
    } catch (e) {
      if (mounted) {
        setState(() { _error = 'Erreur de chargement'; _loading = false; });
      }
    }
  }

  Future<void> _loadPourcentages() async {
    for (final m in _domaines) {
      final id = m['matiere_id'] as String? ?? '';
      if (id.isEmpty) continue;
      try {
        final pct = await CoursService.getPourcentageMatiere(id);
        if (mounted) setState(() => _pourcentages[id] = pct);
      } catch (_) {}
    }
  }

  void _filterDomaines() {
    final query = _searchCtrl.text.toLowerCase();
    setState(() {
      _domainesFiltres = _domaines.where((d) {
        final nom = (d['matiere_nom'] ?? d['nom'] ?? '').toString().toLowerCase();
        final code = (d['matiere_code'] ?? d['code'] ?? '').toString().toLowerCase();
        return nom.contains(query) || code.contains(query);
      }).toList();
    });
  }

  Color _getColor(String code) {
    final key = code.toLowerCase();
    return (_domaineMeta[key]?['couleur'] as Color?) ??
        (_domaineMeta['default']!['couleur'] as Color);
  }

  String _getIcone(String code) {
    final key = code.toLowerCase();
    return (_domaineMeta[key]?['icone'] as String?) ?? '📚';
  }

  String _getDescription(String code) {
    return _domaineDescriptions[code.toLowerCase()] ?? 'Préparez-vous avec des exercices variés.';
  }

  String _getCategorie(String code) {
    final key = code.toLowerCase();
    return (_domaineMeta[key]?['categorie'] as String?) ?? 'Formation';
  }

  void _openDomaine(Map<String, dynamic> d) {
    BellService.playWelcome();
    final code = (d['matiere_code'] ?? d['code'] ?? '').toString();
    final nom = d['matiere_nom'] ?? d['nom'] ?? 'Domaine';
    final id = d['matiere_id'] ?? d['id'] ?? '';

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DomaineDetailScreen(
          matiereId: id.toString(),
          matiereNom: nom.toString(),
          matiereCode: code,
          couleur: _getColor(code),
          icone: _getIcone(code),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAppBar(
            pinned: true,
            floating: true,
            backgroundColor: AppColors.white,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            title: const Text(
              'Explorer',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppColors.textDark,
                letterSpacing: -0.3,
              ),
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(100),
              child: Column(
                children: [
                  // Barre de recherche
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                    child: TextField(
                      controller: _searchCtrl,
                      decoration: InputDecoration(
                        hintText: 'Rechercher un domaine...',
                        prefixIcon: const Icon(Icons.search, color: AppColors.textLight, size: 20),
                        filled: true,
                        fillColor: AppColors.surfaceVariant,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(vertical: 12),
                        suffixIcon: _searchCtrl.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.close, size: 18, color: AppColors.textLight),
                                onPressed: () {
                                  _searchCtrl.clear();
                                  _filterDomaines();
                                },
                              )
                            : null,
                      ),
                    ),
                  ),
                  // Filtres chips
                  SizedBox(
                    height: 36,
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      scrollDirection: Axis.horizontal,
                      itemCount: _filtres.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (context, i) {
                        final f = _filtres[i];
                        final selected = _filtre == f;
                        return GestureDetector(
                          onTap: () => setState(() => _filtre = f),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: selected ? AppColors.primary : AppColors.surfaceVariant,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              f,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: selected ? Colors.white : AppColors.textMedium,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            ),
          ),
        ],
        body: _loading
            ? const Center(child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2.5))
            : _error != null
                ? _buildError()
                : RefreshIndicator(
                    onRefresh: _loadDomaines,
                    child: _domainesFiltres.isEmpty
                        ? _buildEmpty()
                        : _buildGrid(),
                  ),
      ),
    );
  }

  Widget _buildGrid() {
    return CustomScrollView(
      slivers: [
        // Bannière certifications
        SliverToBoxAdapter(child: _buildCertifBanner()),
        // Compteur résultats
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              '${_domainesFiltres.length} domaine${_domainesFiltres.length > 1 ? 's' : ''} disponible${_domainesFiltres.length > 1 ? 's' : ''}',
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textLight,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
        // Grille de domaines
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverGrid(
            delegate: SliverChildBuilderDelegate(
              (context, i) {
                final d = _domainesFiltres[i];
                final code = (d['matiere_code'] ?? d['code'] ?? '').toString();
                final nom = d['matiere_nom'] ?? d['nom'] ?? 'Domaine';
                final id = (d['matiere_id'] ?? '').toString();
                final pct = _pourcentages[id] ?? 0;
                return AnimatedBuilder(
                  animation: _animCtrl,
                  builder: (context, child) => FadeTransition(
                    opacity: _animCtrl,
                    child: child,
                  ),
                  child: _buildDomaineCard(d, nom.toString(), code, pct),
                );
              },
              childCount: _domainesFiltres.length,
            ),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.85,
            ),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 80)),
      ],
    );
  }

  Widget _buildDomaineCard(Map<String, dynamic> d, String nom, String code, int pct) {
    final color = _getColor(code);
    final icone = _getIcone(code);
    final desc = _getDescription(code);
    final categorie = _getCategorie(code);

    return GestureDetector(
      onTap: () => _openDomaine(d),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.divider),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header coloré
            Container(
              height: 80,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
              ),
              child: Stack(
                children: [
                  Center(
                    child: Text(icone, style: const TextStyle(fontSize: 38)),
                  ),
                  // Badge gratuit
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.secondary,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'GRATUIT',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Corps
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Catégorie
                    Text(
                      categorie,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: color,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Nom domaine
                    Text(
                      nom,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textDark,
                        letterSpacing: -0.1,
                        height: 1.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      desc,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textLight,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    // Progression
                    if (pct > 0) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '$pct%',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: color,
                            ),
                          ),
                          Text(
                            'complété',
                            style: const TextStyle(fontSize: 11, color: AppColors.textLight),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: pct / 100,
                          backgroundColor: color.withValues(alpha: 0.1),
                          valueColor: AlwaysStoppedAnimation<Color>(color),
                          minHeight: 4,
                        ),
                      ),
                    ] else
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'Commencer →',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: color,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCertifBanner() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF7C3AED), Color(0xFF4F46E5)],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Text('🏆', style: TextStyle(fontSize: 32)),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Certifications disponibles',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  'Obtenez des certificats après validation de vos modules',
                  style: TextStyle(color: Colors.white70, fontSize: 12, height: 1.3),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Text(
              'Bientôt',
              style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700),
            ),
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
          const Icon(Icons.wifi_off_rounded, size: 52, color: AppColors.textSubtle),
          const SizedBox(height: 16),
          const Text('Impossible de charger les domaines', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          TextButton(onPressed: _loadDomaines, child: const Text('Réessayer')),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('🔍', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 16),
          const Text('Aucun domaine trouvé', style: TextStyle(fontWeight: FontWeight.w600)),
          TextButton(
            onPressed: () {
              _searchCtrl.clear();
              _filterDomaines();
            },
            child: const Text('Effacer la recherche'),
          ),
        ],
      ),
    );
  }
}
