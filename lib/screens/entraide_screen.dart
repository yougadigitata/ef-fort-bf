import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../services/api_service.dart';
import '../services/supabase_service.dart';
import 'abonnement_screen.dart';

// ══════════════════════════════════════════════════════════════
// ENTRAIDE v2.0 — Système Questions-Réponses structuré
// Remplace l'ancien chat libre par un forum paginé
// Architecture: table messages — parent_id=null → question
//                              — parent_id=uuid → réponse
// ══════════════════════════════════════════════════════════════

const List<String> _categories = [
  'Tous',
  'Concours',
  'Révisions',
  'Orientation',
  'Emploi',
  'Général',
];

class EntraideScreen extends StatefulWidget {
  const EntraideScreen({super.key});

  @override
  State<EntraideScreen> createState() => _EntraideScreenState();
}

class _EntraideScreenState extends State<EntraideScreen> {
  List<Map<String, dynamic>> _questions = [];
  bool _loading = true;
  bool _loadingMore = false;
  String _selectedCat = 'Tous';
  int _page = 0;
  bool _hasMore = true;

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _syncUserAuth();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadQuestions());
  }

  void _syncUserAuth() {
    final user = ApiService.currentUser;
    if (user != null) {
      final userId = user['id']?.toString();
      SupabaseService.setUserAuth(null, userId);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      if (!_loadingMore && _hasMore) {
        _loadMore();
      }
    }
  }

  Future<void> _loadQuestions({bool reset = false}) async {
    if (reset) {
      setState(() {
        _page = 0;
        _questions = [];
        _hasMore = true;
        _loading = true;
      });
    } else {
      setState(() => _loading = true);
    }

    final cat = _selectedCat == 'Tous' ? null : _selectedCat;
    final data = await SupabaseService.fetchQuestions(page: 0, categorie: cat);

    if (mounted) {
      setState(() {
        _questions = data;
        _page = 1;
        _hasMore = data.length >= 10;
        _loading = false;
      });
    }
  }

  Future<void> _loadMore() async {
    if (_loadingMore || !_hasMore) return;
    setState(() => _loadingMore = true);

    final cat = _selectedCat == 'Tous' ? null : _selectedCat;
    final data =
        await SupabaseService.fetchQuestions(page: _page, categorie: cat);

    if (mounted) {
      setState(() {
        _questions.addAll(data);
        _page++;
        _hasMore = data.length >= 10;
        _loadingMore = false;
      });
    }
  }

  void _onCatChanged(String cat) {
    setState(() => _selectedCat = cat);
    _loadQuestions(reset: true);
  }

  Future<void> _onPublierQuestion() async {
    final user = ApiService.currentUser;
    if (user == null) {
      _showSnack('Connectez-vous pour publier une question', isError: true);
      return;
    }

    final isAbonne = ApiService.isAbonne;
    if (!isAbonne) {
      _showUpgradeDialog();
      return;
    }

    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => PublierQuestionScreen(userId: user['id'].toString()),
      ),
    );
    if (result == true) {
      _loadQuestions(reset: true);
    }
  }

  void _showUpgradeDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Fonctionnalité Premium',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
        ),
        content: const Text(
          'Seuls les membres premium peuvent publier des questions.\n\n'
          'Passez à premium pour accéder à toutes les fonctionnalités !',
          style: TextStyle(fontSize: 14, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Fermer', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AbonnementScreen()),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Passer Premium',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showSnack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? AppColors.error : AppColors.success,
    ));
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '';
    try {
      final dt = DateTime.parse(dateStr).toLocal();
      final now = DateTime.now();
      final diff = now.difference(dt);
      if (diff.inMinutes < 1) return 'À l\'instant';
      if (diff.inHours < 1) return 'Il y a ${diff.inMinutes} min';
      if (diff.inDays < 1) return 'Il y a ${diff.inHours}h';
      if (diff.inDays < 7) return 'Il y a ${diff.inDays}j';
      return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}';
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Entraide',
          style:
              TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700),
        ),
        automaticallyImplyLeading: false,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
                colors: [AppColors.primary, AppColors.primaryDark]),
          ),
        ),
        foregroundColor: AppColors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => _loadQuestions(reset: true),
          ),
        ],
      ),
      body: Column(
        children: [
          // Filtres par catégorie
          _buildCatFilter(),

          // Liste des questions
          Expanded(
            child: _loading
                ? const Center(
                    child:
                        CircularProgressIndicator(color: AppColors.primary))
                : RefreshIndicator(
                    onRefresh: () => _loadQuestions(reset: true),
                    child: _questions.isEmpty
                        ? _buildEmptyState()
                        : ListView.builder(
                            controller: _scrollController,
                            padding: const EdgeInsets.all(12),
                            itemCount:
                                _questions.length + (_loadingMore ? 1 : 0),
                            itemBuilder: (ctx, i) {
                              if (i == _questions.length) {
                                return const Center(
                                  child: Padding(
                                    padding: EdgeInsets.all(16),
                                    child: CircularProgressIndicator(
                                        color: AppColors.primary),
                                  ),
                                );
                              }
                              return _buildQuestionCard(_questions[i]);
                            },
                          ),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _onPublierQuestion,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Poser une question',
            style: TextStyle(fontWeight: FontWeight.w700)),
      ),
    );
  }

  Widget _buildCatFilter() {
    return Container(
      height: 44,
      color: Colors.white,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        itemCount: _categories.length,
        itemBuilder: (ctx, i) {
          final cat = _categories[i];
          final isSelected = _selectedCat == cat;
          return GestureDetector(
            onTap: () => _onCatChanged(cat),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 8),
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 0),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected
                      ? AppColors.primary
                      : AppColors.primary.withValues(alpha: 0.3),
                ),
              ),
              child: Center(
                child: Text(
                  cat,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? Colors.white : AppColors.primary,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('🤝', style: TextStyle(fontSize: 56)),
          const SizedBox(height: 16),
          const Text(
            'Aucune question pour l\'instant.\nSoyez le premier à partager !',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textLight, fontSize: 15),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _onPublierQuestion,
            icon: const Icon(Icons.add),
            label: const Text('Poser une question'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionCard(Map<String, dynamic> q) {
    final titre = q['titre'] as String? ?? '';
    final texte = q['texte'] as String? ?? '';
    final cat = q['categorie'] as String? ?? 'Général';
    final auteur = q['auteur_prenom'] as String? ?? 'Anonyme';
    final nbRep = q['nb_reponses'] as int? ?? 0;
    final dateStr = q['created_at'] as String?;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => QuestionDetailScreen(question: q),
          ),
        ).then((_) => _loadQuestions(reset: true));
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Catégorie + date
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    cat,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  _formatDate(dateStr),
                  style: const TextStyle(
                      fontSize: 11, color: AppColors.textLight),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Titre
            Text(
              titre,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.textDark,
                height: 1.3,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),

            if (texte.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                texte,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textLight,
                  height: 1.4,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],

            const SizedBox(height: 10),
            const Divider(height: 1),
            const SizedBox(height: 8),

            // Auteur + nb réponses
            Row(
              children: [
                CircleAvatar(
                  radius: 12,
                  backgroundColor: AppColors.primary,
                  child: Text(
                    auteur.isNotEmpty ? auteur[0].toUpperCase() : '?',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  auteur,
                  style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textDark),
                ),
                const Spacer(),
                Icon(Icons.chat_bubble_outline_rounded,
                    size: 14, color: AppColors.textLight),
                const SizedBox(width: 4),
                Text(
                  '$nbRep réponse${nbRep > 1 ? 's' : ''}',
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textLight),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// ÉCRAN DÉTAIL D'UNE QUESTION + RÉPONSES
// ══════════════════════════════════════════════════════════════
class QuestionDetailScreen extends StatefulWidget {
  final Map<String, dynamic> question;

  const QuestionDetailScreen({super.key, required this.question});

  @override
  State<QuestionDetailScreen> createState() => _QuestionDetailScreenState();
}

class _QuestionDetailScreenState extends State<QuestionDetailScreen> {
  List<Map<String, dynamic>> _reponses = [];
  bool _loading = true;
  bool _sending = false;
  int _page = 0;
  bool _hasMore = true;
  bool _loadingMore = false;

  final TextEditingController _reponseCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(_onScroll);
    _loadReponses();
  }

  @override
  void dispose() {
    _reponseCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollCtrl.position.pixels >=
        _scrollCtrl.position.maxScrollExtent - 200) {
      if (!_loadingMore && _hasMore) _loadMore();
    }
  }

  Future<void> _loadReponses() async {
    setState(() => _loading = true);
    final data = await SupabaseService.fetchReponses(
      questionId: widget.question['id'] as String,
      page: 0,
    );
    if (mounted) {
      setState(() {
        _reponses = data;
        _page = 1;
        _hasMore = data.length >= 15;
        _loading = false;
      });
    }
  }

  Future<void> _loadMore() async {
    setState(() => _loadingMore = true);
    final data = await SupabaseService.fetchReponses(
      questionId: widget.question['id'] as String,
      page: _page,
    );
    if (mounted) {
      setState(() {
        _reponses.addAll(data);
        _page++;
        _hasMore = data.length >= 15;
        _loadingMore = false;
      });
    }
  }

  Future<void> _envoyerReponse() async {
    final texte = _reponseCtrl.text.trim();
    if (texte.length < 3) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Réponse trop courte (min. 3 caractères)'),
        backgroundColor: AppColors.error,
      ));
      return;
    }

    final user = ApiService.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Connectez-vous pour répondre'),
        backgroundColor: AppColors.error,
      ));
      return;
    }

    setState(() => _sending = true);
    final result = await SupabaseService.ajouterReponse(
      userId: user['id'].toString(),
      questionId: widget.question['id'] as String,
      texte: texte,
    );

    if (mounted) {
      setState(() => _sending = false);
      if (result['success'] == true) {
        _reponseCtrl.clear();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Réponse publiée !'),
          backgroundColor: AppColors.success,
        ));
        _loadReponses();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(result['error'] ?? 'Erreur lors de l\'envoi'),
          backgroundColor: AppColors.error,
        ));
      }
    }
  }

  Future<void> _likerReponse(String reponseId, int index) async {
    final ok = await SupabaseService.likerReponse(reponseId);
    if (ok && mounted) {
      setState(() {
        _reponses[index]['likes'] = (_reponses[index]['likes'] as int? ?? 0) + 1;
      });
    }
  }

  Future<void> _marquerMeilleureReponse(String reponseId, int index) async {
    final ok = await SupabaseService.marquerMeilleureReponse(
      reponseId: reponseId,
      questionId: widget.question['id'] as String,
    );
    if (ok && mounted) {
      setState(() {
        for (int i = 0; i < _reponses.length; i++) {
          _reponses[i]['est_meilleure'] = (i == index);
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('⭐ Meilleure réponse marquée !'),
        backgroundColor: AppColors.success,
      ));
    }
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '';
    try {
      final dt = DateTime.parse(dateStr).toLocal();
      final now = DateTime.now();
      final diff = now.difference(dt);
      if (diff.inMinutes < 1) return 'À l\'instant';
      if (diff.inHours < 1) return 'Il y a ${diff.inMinutes} min';
      if (diff.inDays < 1) return 'Il y a ${diff.inHours}h';
      return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}';
    } catch (_) {
      return '';
    }
  }

  bool get _isAuteurQuestion {
    final user = ApiService.currentUser;
    if (user == null) return false;
    return user['id'].toString() == widget.question['auteur_id'].toString();
  }

  @override
  Widget build(BuildContext context) {
    final q = widget.question;
    final titre = q['titre'] as String? ?? '';
    final texte = q['texte'] as String? ?? '';
    final auteur = q['auteur_prenom'] as String? ?? 'Anonyme';
    final cat = q['categorie'] as String? ?? 'Général';
    final dateStr = q['created_at'] as String?;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Question',
            style: TextStyle(
                fontFamily: 'Poppins', fontWeight: FontWeight.w700)),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
                colors: [AppColors.primary, AppColors.primaryDark]),
          ),
        ),
        foregroundColor: AppColors.white,
      ),
      body: Column(
        children: [
          // Corps défilable
          Expanded(
            child: ListView(
              controller: _scrollCtrl,
              padding: const EdgeInsets.all(14),
              children: [
                // ── Question principale ──
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.2)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(cat,
                                style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.primary)),
                          ),
                          const Spacer(),
                          Text(_formatDate(dateStr),
                              style: const TextStyle(
                                  fontSize: 11, color: AppColors.textLight)),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        titre,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textDark,
                          height: 1.3,
                        ),
                      ),
                      if (texte.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          texte,
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.textDark,
                            height: 1.6,
                            fontFamily: 'Georgia',
                          ),
                        ),
                      ],
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 14,
                            backgroundColor: AppColors.primary,
                            child: Text(
                              auteur.isNotEmpty ? auteur[0].toUpperCase() : '?',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(auteur,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600, fontSize: 13)),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // ── Titre réponses ──
                Row(
                  children: [
                    Text(
                      '${_reponses.length} Réponse${_reponses.length > 1 ? 's' : ''}',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textDark,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // ── Liste des réponses ──
                if (_loading)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: CircularProgressIndicator(
                          color: AppColors.primary),
                    ),
                  )
                else if (_reponses.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          const Text('💬',
                              style: TextStyle(fontSize: 40)),
                          const SizedBox(height: 8),
                          Text(
                            'Soyez le premier à répondre !',
                            style: TextStyle(
                                color: AppColors.textLight, fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  ..._reponses.asMap().entries.map((e) {
                    final i = e.key;
                    final r = e.value;
                    return _buildReponseCard(r, i);
                  }),

                if (_loadingMore)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: CircularProgressIndicator(
                          color: AppColors.primary),
                    ),
                  ),

                const SizedBox(height: 80),
              ],
            ),
          ),

          // ── Zone de saisie de réponse ──
          Container(
            padding: EdgeInsets.fromLTRB(
                12, 10, 12, MediaQuery.of(context).viewInsets.bottom + 10),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _reponseCtrl,
                    maxLines: 3,
                    minLines: 1,
                    maxLength: 500,
                    decoration: InputDecoration(
                      hintText: 'Votre réponse...',
                      hintStyle:
                          const TextStyle(color: AppColors.textLight),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                            color: AppColors.primary.withValues(alpha: 0.3)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                            color: AppColors.primary, width: 1.5),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      isDense: true,
                      counterText: '',
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: _sending ? null : _envoyerReponse,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: _sending
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2),
                          )
                        : const Icon(Icons.send_rounded,
                            color: Colors.white, size: 20),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReponseCard(Map<String, dynamic> r, int index) {
    final texte = r['texte'] as String? ?? '';
    final auteur = r['auteur_prenom'] as String? ?? 'Anonyme';
    final likes = r['likes'] as int? ?? 0;
    final isMeilleure = r['est_meilleure'] == true;
    final dateStr = r['created_at'] as String?;
    final reponseId = r['id'] as String;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isMeilleure
            ? const Color(0xFFFFF8E1)
            : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isMeilleure
              ? const Color(0xFFFFD700)
              : Colors.grey.withValues(alpha: 0.15),
          width: isMeilleure ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Badge meilleure réponse
          if (isMeilleure)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFFFD700).withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                '⭐ Meilleure réponse',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFFA07A00),
                ),
              ),
            ),

          // Texte de la réponse
          Text(
            texte,
            style: const TextStyle(
              fontSize: 14,
              height: 1.55,
              color: AppColors.textDark,
              fontFamily: 'Georgia',
            ),
          ),

          const SizedBox(height: 10),
          const Divider(height: 1),
          const SizedBox(height: 8),

          // Auteur + date + actions
          Row(
            children: [
              CircleAvatar(
                radius: 12,
                backgroundColor: AppColors.secondary,
                child: Text(
                  auteur.isNotEmpty ? auteur[0].toUpperCase() : '?',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(auteur,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 12)),
                    Text(_formatDate(dateStr),
                        style: const TextStyle(
                            fontSize: 10, color: AppColors.textLight)),
                  ],
                ),
              ),

              // Bouton liker
              GestureDetector(
                onTap: () => _likerReponse(reponseId, index),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.favorite_border_rounded,
                          size: 14, color: AppColors.error),
                      const SizedBox(width: 4),
                      Text(
                        '$likes',
                        style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.error,
                            fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ),

              // Bouton marquer meilleure réponse (auteur question seulement)
              if (_isAuteurQuestion && !isMeilleure) ...[
                const SizedBox(width: 6),
                GestureDetector(
                  onTap: () =>
                      _marquerMeilleureReponse(reponseId, index),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFD700).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.star_border_rounded,
                            size: 14, color: Color(0xFFA07A00)),
                        SizedBox(width: 2),
                        Text('⭐',
                            style: TextStyle(fontSize: 10)),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// ÉCRAN PUBLICATION DE QUESTION
// ══════════════════════════════════════════════════════════════
class PublierQuestionScreen extends StatefulWidget {
  final String userId;

  const PublierQuestionScreen({super.key, required this.userId});

  @override
  State<PublierQuestionScreen> createState() => _PublierQuestionScreenState();
}

class _PublierQuestionScreenState extends State<PublierQuestionScreen> {
  final _titreCtrl = TextEditingController();
  final _texteCtrl = TextEditingController();
  String _categorie = 'Concours';
  bool _sending = false;

  @override
  void dispose() {
    _titreCtrl.dispose();
    _texteCtrl.dispose();
    super.dispose();
  }

  Future<void> _publier() async {
    final titre = _titreCtrl.text.trim();
    final texte = _texteCtrl.text.trim();

    if (titre.length < 5) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Le titre doit faire au moins 5 caractères'),
        backgroundColor: AppColors.error,
      ));
      return;
    }
    if (texte.length < 10) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Le contenu doit faire au moins 10 caractères'),
        backgroundColor: AppColors.error,
      ));
      return;
    }

    setState(() => _sending = true);
    final result = await SupabaseService.publierQuestion(
      userId: widget.userId,
      titre: titre,
      texte: texte,
      categorie: _categorie,
    );

    if (mounted) {
      setState(() => _sending = false);
      if (result['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Question publiée avec succès !'),
          backgroundColor: AppColors.success,
        ));
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(result['error'] ?? 'Erreur lors de la publication'),
          backgroundColor: AppColors.error,
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Poser une question',
            style:
                TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700)),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
                colors: [AppColors.primary, AppColors.primaryDark]),
          ),
        ),
        foregroundColor: AppColors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Info premium
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3CD),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFFFD700)),
              ),
              child: const Row(
                children: [
                  Text('👑', style: TextStyle(fontSize: 20)),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Fonctionnalité réservée aux membres Premium',
                      style: TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Catégorie
            const Text('Catégorie',
                style:
                    TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: _categories.skip(1).map((cat) {
                final isSelected = _categorie == cat;
                return ChoiceChip(
                  label: Text(cat),
                  selected: isSelected,
                  onSelected: (_) => setState(() => _categorie = cat),
                  selectedColor: AppColors.primary,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : AppColors.textDark,
                    fontWeight: FontWeight.w600,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // Titre
            const Text('Titre de votre question *',
                style:
                    TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
            const SizedBox(height: 8),
            TextField(
              controller: _titreCtrl,
              maxLength: 150,
              decoration: InputDecoration(
                hintText: 'Ex: Comment préparer le concours ENAREF ?',
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10)),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(
                        color: AppColors.primary, width: 1.5)),
              ),
            ),
            const SizedBox(height: 12),

            // Contenu
            const Text('Détails (optionnel)',
                style:
                    TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
            const SizedBox(height: 8),
            TextField(
              controller: _texteCtrl,
              maxLines: 5,
              maxLength: 1000,
              decoration: InputDecoration(
                hintText:
                    'Expliquez votre question en détail pour obtenir une meilleure réponse...',
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10)),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(
                        color: AppColors.primary, width: 1.5)),
              ),
            ),
            const SizedBox(height: 24),

            // Bouton publier
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _sending ? null : _publier,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: _sending
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Publier la question',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'Poppins'),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
