import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../services/api_service.dart';
import '../services/supabase_service.dart';

// ══════════════════════════════════════════════════════════════
// ENTRAIDE v3.0 — Système de Statuts (1 statut/jour, 24h)
// Chaque utilisateur peut poster UN seul statut par jour
// Le statut expire après 24h (automatiquement supprimé de l'UI)
// Style: stories/statuts avec bulle + avatar + texte
// L'admin (logo EF-FORT) apparaît toujours en premier
// ══════════════════════════════════════════════════════════════

class EntraideScreen extends StatefulWidget {
  const EntraideScreen({super.key});

  @override
  State<EntraideScreen> createState() => _EntraideScreenState();
}

class _EntraideScreenState extends State<EntraideScreen> {
  List<Map<String, dynamic>> _statuts = [];
  bool _loading = true;
  bool _sending = false;
  bool _aDejaPoste = false; // L'utilisateur a-t-il déjà posté aujourd'hui ?
  String? _monStatutId;
  DateTime? _prochain; // Quand peut-il reposer ?

  final TextEditingController _textCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();

  // Types de statuts disponibles
  static const List<Map<String, dynamic>> _types = [
    {'label': '📢 Signaler', 'value': 'signaler', 'color': Color(0xFFE74C3C)},
    {'label': '🤝 Aide', 'value': 'aide', 'color': Color(0xFF2980B9)},
    {'label': '💡 Info', 'value': 'info', 'color': Color(0xFF27AE60)},
    {'label': '📚 Révision', 'value': 'revision', 'color': Color(0xFF8E44AD)},
    {'label': '🎉 Succès', 'value': 'succes', 'color': Color(0xFFD4A017)},
  ];
  String _typeSelectionne = 'info';

  @override
  void initState() {
    super.initState();
    _syncUserAuth();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadStatuts());
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
    _textCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadStatuts() async {
    setState(() => _loading = true);

    try {
      // Charger tous les statuts actifs (moins de 24h)
      final data = await SupabaseService.fetchStatuts();

      // Vérifier si l'utilisateur actuel a déjà posté aujourd'hui
      final user = ApiService.currentUser;
      bool dejaPoste = false;
      String? monId;
      DateTime? prochain;

      if (user != null) {
        final userId = user['id'].toString();
        for (final s in data) {
          if (s['user_id']?.toString() == userId) {
            dejaPoste = true;
            monId = s['id']?.toString();
            // Calculer quand il peut reposer (24h après le post)
            try {
              final createdAt = DateTime.parse(s['created_at'].toString()).toLocal();
              prochain = createdAt.add(const Duration(hours: 24));
            } catch (_) {}
            break;
          }
        }
      }

      if (mounted) {
        setState(() {
          _statuts = data;
          _aDejaPoste = dejaPoste;
          _monStatutId = monId;
          _prochain = prochain;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _publierStatut() async {
    final texte = _textCtrl.text.trim();
    if (texte.length < 5) {
      _showSnack('Message trop court (minimum 5 caractères)', isError: true);
      return;
    }
    if (texte.length > 280) {
      _showSnack('Message trop long (maximum 280 caractères)', isError: true);
      return;
    }

    final user = ApiService.currentUser;
    if (user == null) {
      _showSnack('Connectez-vous pour publier un statut', isError: true);
      return;
    }

    if (_aDejaPoste) {
      _showSnack('Vous avez déjà posté votre statut aujourd\'hui', isError: true);
      return;
    }

    setState(() => _sending = true);

    final result = await SupabaseService.publierStatut(
      userId: user['id'].toString(),
      prenom: user['prenom']?.toString() ?? 'Anonyme',
      nom: user['nom']?.toString() ?? '',
      texte: texte,
      type: _typeSelectionne,
    );

    if (mounted) {
      setState(() => _sending = false);
      if (result['success'] == true) {
        _textCtrl.clear();
        _showSnack('Statut publié ! Il sera visible 24h.');
        await _loadStatuts();
      } else {
        final errMsg = result['error']?.toString() ?? 'Erreur lors de la publication';
        if (errMsg.contains('already_posted') || errMsg.contains('une seule fois')) {
          _showSnack('Vous avez déjà posté votre statut aujourd\'hui', isError: true);
          setState(() => _aDejaPoste = true);
        } else {
          _showSnack(errMsg, isError: true);
        }
      }
    }
  }

  Future<void> _supprimerMonStatut() async {
    if (_monStatutId == null) return;
    final user = ApiService.currentUser;
    if (user == null) return;

    final ok = await SupabaseService.supprimerStatut(
      statutId: _monStatutId!,
      userId: user['id'].toString(),
    );

    if (ok && mounted) {
      _showSnack('Statut supprimé.');
      await _loadStatuts();
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? AppColors.error : AppColors.success,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  String _formatDateRestant(DateTime? expiration) {
    if (expiration == null) return '';
    final now = DateTime.now();
    final remaining = expiration.difference(now);
    if (remaining.isNegative) return 'Expiré';
    if (remaining.inHours > 0) {
      return 'Expire dans ${remaining.inHours}h${remaining.inMinutes.remainder(60).toString().padLeft(2, '0')}';
    }
    return 'Expire dans ${remaining.inMinutes} min';
  }

  String _formatAge(String? dateStr) {
    if (dateStr == null) return '';
    try {
      final dt = DateTime.parse(dateStr).toLocal();
      final now = DateTime.now();
      final diff = now.difference(dt);
      if (diff.inMinutes < 1) return 'À l\'instant';
      if (diff.inMinutes < 60) return 'Il y a ${diff.inMinutes} min';
      if (diff.inHours < 24) return 'Il y a ${diff.inHours}h';
      return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}';
    } catch (_) {
      return '';
    }
  }

  Color _getTypeColor(String type) {
    for (final t in _types) {
      if (t['value'] == type) return t['color'] as Color;
    }
    return AppColors.primary;
  }

  String _getTypeEmoji(String type) {
    const map = {
      'signaler': '📢',
      'aide': '🤝',
      'info': '💡',
      'revision': '📚',
      'succes': '🎉',
    };
    return map[type] ?? '💬';
  }

  @override
  Widget build(BuildContext context) {
    final user = ApiService.currentUser;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Entraide',
          style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700),
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
            onPressed: _loadStatuts,
            tooltip: 'Actualiser',
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Bandeau explicatif ──
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: AppColors.primary.withValues(alpha: 0.06),
            child: Row(
              children: [
                const Icon(Icons.info_outline_rounded, size: 16, color: AppColors.primary),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    '1 statut par jour • Visible 24h • Signalez, demandez de l\'aide ou partagez !',
                    style: TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),

          // ── Zone de saisie (si pas encore posté) ──
          if (user != null)
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              child: _aDejaPoste
                  ? _buildDejaPosteBar()
                  : _buildPublierBar(),
            ),

          // ── Liste des statuts ──
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : RefreshIndicator(
                    onRefresh: _loadStatuts,
                    color: AppColors.primary,
                    child: _statuts.isEmpty
                        ? _buildVide()
                        : ListView.builder(
                            controller: _scrollCtrl,
                            padding: const EdgeInsets.fromLTRB(12, 8, 12, 100),
                            itemCount: _statuts.length,
                            itemBuilder: (ctx, i) => _buildStatutCard(_statuts[i]),
                          ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildPublierBar() {
    final typeInfo = _types.firstWhere(
      (t) => t['value'] == _typeSelectionne,
      orElse: () => _types[2],
    );
    final typeColor = typeInfo['color'] as Color;

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Sélecteur de type
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _types.map((t) {
                final isSelected = t['value'] == _typeSelectionne;
                return GestureDetector(
                  onTap: () => setState(() => _typeSelectionne = t['value'] as String),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.only(right: 8, bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? (t['color'] as Color).withValues(alpha: 0.15)
                          : Colors.grey.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected ? t['color'] as Color : Colors.grey.withValues(alpha: 0.2),
                        width: isSelected ? 1.5 : 1,
                      ),
                    ),
                    child: Text(
                      t['label'] as String,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected ? t['color'] as Color : AppColors.textLight,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          // Zone de texte + bouton envoyer
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: TextField(
                  controller: _textCtrl,
                  maxLines: 3,
                  minLines: 1,
                  maxLength: 280,
                  decoration: InputDecoration(
                    hintText: 'Signalez quelque chose, demandez de l\'aide...',
                    hintStyle: TextStyle(color: AppColors.textLight, fontSize: 13),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: typeColor.withValues(alpha: 0.3)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: typeColor, width: 1.5),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    isDense: true,
                    counterText: '',
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: _sending ? null : _publierStatut,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: typeColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: _sending
                      ? const SizedBox(
                          width: 20, height: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDejaPosteBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.withValues(alpha: 0.15))),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Statut posté aujourd\'hui ✅',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textDark),
                ),
                if (_prochain != null)
                  Text(
                    _formatDateRestant(_prochain),
                    style: const TextStyle(fontSize: 11, color: AppColors.textLight),
                  ),
              ],
            ),
          ),
          if (_monStatutId != null)
            GestureDetector(
              onTap: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    title: const Text('Supprimer le statut ?'),
                    content: const Text('Vous pourrez en poster un nouveau demain.'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
                        child: const Text('Supprimer', style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                );
                if (confirm == true) _supprimerMonStatut();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Supprimer',
                  style: TextStyle(fontSize: 11, color: AppColors.error, fontWeight: FontWeight.w700),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildVide() {
    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('🤝', style: TextStyle(fontSize: 56)),
            const SizedBox(height: 16),
            const Text(
              'Aucun statut pour l\'instant.',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textDark),
            ),
            const SizedBox(height: 8),
            Text(
              'Soyez le premier à signaler quelque chose\nou à demander de l\'aide !',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textLight, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatutCard(Map<String, dynamic> s) {
    final userId = s['user_id']?.toString() ?? '';
    final prenom = s['prenom']?.toString() ?? 'Utilisateur';
    final nom = s['nom']?.toString() ?? '';
    final texte = s['texte']?.toString() ?? s['contenu']?.toString() ?? '';
    final type = s['type']?.toString() ?? 'info';
    final dateStr = s['created_at']?.toString();
    final isAdminPost = s['is_admin'] == true || s['is_admin'] == 1;
    final currentUserId = ApiService.currentUser?['id']?.toString() ?? '';
    final isMyPost = userId == currentUserId;

    // Calculer l'expiration
    DateTime? expiration;
    try {
      expiration = DateTime.parse(dateStr!).toLocal().add(const Duration(hours: 24));
    } catch (_) {}

    final typeColor = _getTypeColor(type);
    final typeEmoji = _getTypeEmoji(type);
    final initiale = prenom.isNotEmpty ? prenom[0].toUpperCase() : 'U';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: isMyPost
            ? Border.all(color: typeColor.withValues(alpha: 0.4), width: 1.5)
            : Border.all(color: Colors.grey.withValues(alpha: 0.12)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Avatar
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isAdminPost ? AppColors.primary : typeColor.withValues(alpha: 0.15),
                    border: Border.all(
                      color: isAdminPost ? AppColors.primary : typeColor.withValues(alpha: 0.4),
                      width: 1.5,
                    ),
                  ),
                  child: isAdminPost
                      ? ClipOval(
                          child: Image.asset(
                            'assets/images/logo_effort.png',
                            fit: BoxFit.cover,
                          ),
                        )
                      : Center(
                          child: Text(
                            initiale,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: typeColor,
                            ),
                          ),
                        ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            isAdminPost ? 'EF-FORT.BF' : '$prenom $nom'.trim(),
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: isAdminPost ? AppColors.primary : AppColors.textDark,
                            ),
                          ),
                          if (isAdminPost) ...[
                            const SizedBox(width: 5),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'OFFICIEL',
                                style: TextStyle(fontSize: 8, fontWeight: FontWeight.w900, color: Colors.white),
                              ),
                            ),
                          ],
                          if (isMyPost && !isAdminPost) ...[
                            const SizedBox(width: 5),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                              decoration: BoxDecoration(
                                color: typeColor.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'MOI',
                                style: TextStyle(fontSize: 8, fontWeight: FontWeight.w900, color: AppColors.primary),
                              ),
                            ),
                          ],
                          const Spacer(),
                          Text(
                            _formatAge(dateStr),
                            style: const TextStyle(fontSize: 11, color: AppColors.textLight),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      // Badge type
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: typeColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '$typeEmoji ${type.capitalize()}',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: typeColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            // Contenu du statut
            Text(
              texte,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF1A1A1A),
                height: 1.5,
              ),
            ),

            if (expiration != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.access_time_rounded, size: 12, color: Colors.grey[400]),
                  const SizedBox(width: 4),
                  Text(
                    _formatDateRestant(expiration),
                    style: TextStyle(fontSize: 10, color: Colors.grey[400]),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// Extension pour capitaliser
extension StringExt on String {
  String capitalize() {
    if (isEmpty) return this;
    return this[0].toUpperCase() + substring(1);
  }
}
