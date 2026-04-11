import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../services/api_service.dart';

// ══════════════════════════════════════════════════════════════
// ENTRAIDE v7.0 — Interface communautaire enrichie
// ══════════════════════════════════════════════════════════════
// • Likes/Réactions (❤️) sur chaque message
// • Épinglage admin (message mis en avant avec badge 📌)
// • Filtres par type (Tout, Aide, Révision, Signalement, Info, Succès)
// • Meilleure UI avec cartes modernes
// • Notifications visuelles pour les réponses admin
// • Suppression optionnelle (admin ou auteur)
// • 1 question/statut par jour pour les non-admins
// ══════════════════════════════════════════════════════════════

class EntraideScreen extends StatefulWidget {
  const EntraideScreen({super.key});

  @override
  State<EntraideScreen> createState() => _EntraideScreenState();
}

class _EntraideScreenState extends State<EntraideScreen>
    with SingleTickerProviderStateMixin {
  List<Map<String, dynamic>> _messages = [];
  List<Map<String, dynamic>> _filteredMessages = [];
  bool _loading = true;
  bool _sending = false;
  bool _aDejaPoste = false;
  String? _monMessageId;
  DateTime? _prochainPostage;
  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;
  String _activeFilter = 'all';

  final TextEditingController _textCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();

  // Filtres disponibles
  static const List<Map<String, dynamic>> _filters = [
    {'label': 'Tout', 'value': 'all', 'icon': Icons.all_inclusive_rounded, 'color': Color(0xFF475569)},
    {'label': 'Aide', 'value': 'aide', 'icon': Icons.handshake_rounded, 'color': Color(0xFF2980B9)},
    {'label': 'Révision', 'value': 'revision', 'icon': Icons.menu_book_rounded, 'color': Color(0xFF8E44AD)},
    {'label': 'Info', 'value': 'info', 'icon': Icons.info_outline_rounded, 'color': Color(0xFF27AE60)},
    {'label': 'Succès', 'value': 'succes', 'icon': Icons.emoji_events_rounded, 'color': Color(0xFFD4A017)},
    {'label': 'Signaler', 'value': 'signaler', 'icon': Icons.flag_rounded, 'color': Color(0xFFE74C3C)},
  ];

  // Types pour la saisie
  static const List<Map<String, dynamic>> _types = [
    {'label': '🤝 Aide', 'value': 'aide', 'color': Color(0xFF2980B9)},
    {'label': '📚 Révision', 'value': 'revision', 'color': Color(0xFF8E44AD)},
    {'label': '📢 Signaler', 'value': 'signaler', 'color': Color(0xFFE74C3C)},
    {'label': '💡 Info', 'value': 'info', 'color': Color(0xFF27AE60)},
    {'label': '🎉 Succès', 'value': 'succes', 'color': Color(0xFFD4A017)},
  ];
  String _typeSelectionne = 'aide';

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadMessages());
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _textCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadMessages() async {
    setState(() => _loading = true);
    _animCtrl.reset();

    try {
      final data = await ApiService.getEntraideMsgsV2();
      final user = ApiService.currentUser;
      bool dejaPoste = false;
      String? monId;
      DateTime? prochain;

      if (user != null) {
        final userId = user['id'].toString();
        for (final m in data) {
          if (m['user_id']?.toString() == userId && m['parent_id'] == null) {
            dejaPoste = true;
            monId = m['id']?.toString();
            try {
              final createdAt = DateTime.parse(m['created_at'].toString()).toLocal();
              prochain = createdAt.add(const Duration(hours: 24));
            } catch (_) {}
            break;
          }
        }
      }

      if (mounted) {
        setState(() {
          _messages = data;
          _aDejaPoste = dejaPoste;
          _monMessageId = monId;
          _prochainPostage = prochain;
          _loading = false;
        });
        _applyFilter(_activeFilter);
        _animCtrl.forward();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        _showSnack('Impossible de charger les messages. Vérifiez votre connexion.', isError: true);
      }
    }
  }

  void _applyFilter(String filterValue) {
    setState(() {
      _activeFilter = filterValue;
      if (filterValue == 'all') {
        _filteredMessages = List.from(_messages);
      } else {
        // Pour l'instant, filtrer côté client (les messages ont un type dans le contenu)
        // TODO: ajouter colonne 'type' dans Supabase pour un vrai filtrage
        _filteredMessages = _messages.where((m) {
          final contenu = m['contenu']?.toString().toLowerCase() ?? '';
          switch (filterValue) {
            case 'aide': return contenu.contains('aide') || contenu.contains('aider') || contenu.contains('comment');
            case 'revision': return contenu.contains('révision') || contenu.contains('réviser') || contenu.contains('révision');
            case 'info': return contenu.contains('info') || contenu.contains('information');
            case 'succes': return contenu.contains('succès') || contenu.contains('réussi') || contenu.contains('admis');
            case 'signaler': return contenu.contains('erreur') || contenu.contains('problème') || contenu.contains('signaler');
            default: return true;
          }
        }).toList();
      }
    });
  }

  Future<void> _publierMessage() async {
    final texte = _textCtrl.text.trim();
    if (texte.length < 5) {
      _showSnack('Message trop court (minimum 5 caractères)', isError: true);
      return;
    }
    if (texte.length > 500) {
      _showSnack('Message trop long (maximum 500 caractères)', isError: true);
      return;
    }
    if (ApiService.currentUser == null) {
      _showSnack('Connectez-vous pour publier un message', isError: true);
      return;
    }
    if (_aDejaPoste && !ApiService.isAdmin) {
      _showSnack('Vous avez déjà posté votre message aujourd\'hui', isError: true);
      return;
    }

    setState(() => _sending = true);

    final result = await ApiService.publierEntraideMsg(contenu: texte);

    if (mounted) {
      setState(() => _sending = false);
      if (result['success'] == true) {
        _textCtrl.clear();
        _showSnack('Message publié avec succès ! ✅');
        await _loadMessages();
      } else {
        final errMsg = result['error']?.toString() ?? 'Erreur lors de la publication';
        if (errMsg.contains('already_posted') || result['already_posted'] == true) {
          _showSnack('Vous avez déjà posté votre message aujourd\'hui', isError: true);
          setState(() => _aDejaPoste = true);
        } else {
          _showSnack(errMsg, isError: true);
        }
      }
    }
  }

  Future<void> _likerMessage(Map<String, dynamic> msg) async {
    if (ApiService.currentUser == null) {
      _showSnack('Connectez-vous pour réagir', isError: true);
      return;
    }
    final messageId = msg['id']?.toString() ?? '';
    if (messageId.isEmpty) return;

    // Mise à jour optimiste locale
    final currentLiked = msg['liked_by_me'] == true;
    final currentCount = (msg['likes_count'] as int?) ?? 0;
    setState(() {
      final idx = _messages.indexWhere((m) => m['id'] == msg['id']);
      if (idx >= 0) {
        _messages[idx] = {
          ..._messages[idx],
          'liked_by_me': !currentLiked,
          'likes_count': currentLiked ? currentCount - 1 : currentCount + 1,
        };
      }
      _applyFilter(_activeFilter);
    });

    final result = await ApiService.likerEntraideMsg(messageId);
    if (mounted && result['success'] != true) {
      // Reverter si erreur
      setState(() {
        final idx = _messages.indexWhere((m) => m['id'] == msg['id']);
        if (idx >= 0) {
          _messages[idx] = {
            ..._messages[idx],
            'liked_by_me': currentLiked,
            'likes_count': currentCount,
          };
        }
        _applyFilter(_activeFilter);
      });
    }
  }

  Future<void> _epinglerMessage(Map<String, dynamic> msg) async {
    if (!ApiService.isAdmin) return;
    final messageId = msg['id']?.toString() ?? '';
    if (messageId.isEmpty) return;

    final result = await ApiService.epinglerEntraideMsg(messageId);
    if (mounted) {
      if (result['success'] == true) {
        final isPinned = result['pinned'] == true;
        _showSnack(isPinned ? '📌 Message épinglé !' : 'Message désépinglé.');
        await _loadMessages();
      } else {
        _showSnack(result['error']?.toString() ?? 'Erreur', isError: true);
      }
    }
  }

  Future<void> _repondre(Map<String, dynamic> message) async {
    if (!ApiService.isAdmin) return;

    final repCtrl = TextEditingController();
    final confirm = await showDialog<String>(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.reply_rounded, color: AppColors.primary, size: 20),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'Répondre au message',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF1A1A2E)),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F4F1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  message['contenu']?.toString() ?? '',
                  style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), fontStyle: FontStyle.italic),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: repCtrl,
                maxLines: 4,
                minLines: 2,
                maxLength: 1000,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Rédigez votre réponse officielle...',
                  hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.primary, width: 2),
                  ),
                  contentPadding: const EdgeInsets.all(12),
                  fillColor: Colors.white,
                  filled: true,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx, null),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFFCBD5E1)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text('Annuler', style: TextStyle(color: Color(0xFF64748B))),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        final text = repCtrl.text.trim();
                        if (text.isEmpty) return;
                        Navigator.pop(ctx, text);
                      },
                      icon: const Icon(Icons.send_rounded, size: 16),
                      label: const Text('Envoyer'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (confirm != null && confirm.isNotEmpty) {
      final result = await ApiService.repondreEntraideMsg(
        messageId: message['id'].toString(),
        reponse: confirm,
      );
      if (mounted) {
        if (result['success'] == true) {
          _showSnack('Réponse publiée ! ✅');
          await _loadMessages();
        } else {
          final err = result['error']?.toString() ?? 'Erreur lors de la publication';
          _showSnack(err, isError: true);
        }
      }
    }
  }

  Future<void> _supprimerMessage(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Supprimer ce message ?'),
        content: const Text('Ce message sera supprimé définitivement.'),
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
    if (confirm == true) {
      final ok = await ApiService.supprimerEntraide(id);
      if (mounted) {
        if (ok) {
          _showSnack('Message supprimé.');
          await _loadMessages();
        } else {
          _showSnack('Impossible de supprimer le message.', isError: true);
        }
      }
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(
        children: [
          Icon(
            isError ? Icons.error_outline_rounded : Icons.check_circle_outline_rounded,
            color: Colors.white,
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(msg, style: const TextStyle(fontSize: 13))),
        ],
      ),
      backgroundColor: isError ? AppColors.error : AppColors.success,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      duration: const Duration(seconds: 3),
    ));
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
      if (diff.inDays < 7) return 'Il y a ${diff.inDays}j';
      return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}';
    } catch (_) {
      return '';
    }
  }

  String _formatRestant(DateTime? expiration) {
    if (expiration == null) return '';
    final now = DateTime.now();
    final remaining = expiration.difference(now);
    if (remaining.isNegative) return '';
    if (remaining.inHours > 0) {
      return '${remaining.inHours}h${remaining.inMinutes.remainder(60).toString().padLeft(2, '0')} restant';
    }
    return '${remaining.inMinutes} min restant';
  }

  Color _getTypeColor(String? type) {
    for (final t in _types) {
      if (t['value'] == type) return t['color'] as Color;
    }
    return AppColors.primary;
  }

  @override
  Widget build(BuildContext context) {
    final user = ApiService.currentUser;
    final isAdmin = ApiService.isAdmin;
    final pinnedCount = _messages.where((m) => m['is_pinned'] == true).length;

    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F1),
      appBar: AppBar(
        title: const Text(
          'Entraide',
          style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700),
        ),
        automaticallyImplyLeading: false,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.primary, AppColors.primaryDark],
            ),
          ),
        ),
        foregroundColor: AppColors.white,
        elevation: 0,
        actions: [
          if (pinnedCount > 0)
            Container(
              margin: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.amber.withValues(alpha: 0.5)),
              ),
              child: Row(
                children: [
                  const Text('📌', style: TextStyle(fontSize: 12)),
                  const SizedBox(width: 3),
                  Text('$pinnedCount', style: const TextStyle(fontSize: 11, color: Colors.amber, fontWeight: FontWeight.w700)),
                ],
              ),
            ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadMessages,
            tooltip: 'Actualiser',
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Bandeau info + statistiques ──
          _buildInfoBanner(isAdmin),

          // ── Filtres horizontaux ──
          _buildFiltersBar(),

          // ── Zone de saisie ──
          if (user != null)
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: (_aDejaPoste && !isAdmin)
                  ? _buildDejaPosteBar()
                  : _buildSaisieBar(),
            ),

          // ── Liste des messages ──
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : FadeTransition(
                    opacity: _fadeAnim,
                    child: RefreshIndicator(
                      onRefresh: _loadMessages,
                      color: AppColors.primary,
                      child: _filteredMessages.isEmpty
                          ? _buildVide()
                          : ListView.builder(
                              controller: _scrollCtrl,
                              padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
                              itemCount: _filteredMessages.length,
                              itemBuilder: (ctx, i) => _buildMessageCard(_filteredMessages[i]),
                            ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoBanner(bool isAdmin) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.people_outline_rounded, size: 16, color: AppColors.primary),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              isAdmin
                  ? 'Mode Admin · Répondez, épinglez et modérez la communauté'
                  : '1 question par jour · ❤️ Likez · L\'admin répond rapidement',
              style: TextStyle(
                fontSize: 11.5,
                color: isAdmin ? AppColors.primary : const Color(0xFF475569),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          if (isAdmin)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'ADMIN',
                style: TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.w900),
              ),
            ),
          // Compteur de messages
          if (!isAdmin) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${_messages.length}',
                style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFiltersBar() {
    return Container(
      height: 44,
      color: Colors.white,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        itemCount: _filters.length,
        itemBuilder: (ctx, i) {
          final f = _filters[i];
          final isActive = _activeFilter == f['value'];
          final color = f['color'] as Color;
          return GestureDetector(
            onTap: () => _applyFilter(f['value'] as String),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: isActive ? color : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isActive ? color : Colors.grey.shade300,
                  width: isActive ? 1.5 : 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    f['icon'] as IconData,
                    size: 13,
                    color: isActive ? Colors.white : color,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    f['label'] as String,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                      color: isActive ? Colors.white : const Color(0xFF475569),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSaisieBar() {
    return Container(
      key: const ValueKey('saisie'),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Sélecteur de type (scroll horizontal)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _types.map((t) {
                final isSelected = t['value'] == _typeSelectionne;
                final color = t['color'] as Color;
                return GestureDetector(
                  onTap: () => setState(() => _typeSelectionne = t['value'] as String),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.only(right: 6, bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: isSelected ? color.withValues(alpha: 0.12) : Colors.grey.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected ? color : Colors.grey.withValues(alpha: 0.2),
                        width: isSelected ? 1.5 : 1,
                      ),
                    ),
                    child: Text(
                      t['label'] as String,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected ? color : const Color(0xFF64748B),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          // Zone texte + bouton envoyer
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: TextField(
                  controller: _textCtrl,
                  maxLines: 3,
                  minLines: 1,
                  maxLength: 500,
                  decoration: InputDecoration(
                    hintText: ApiService.isAdmin
                        ? 'Publiez un message pour la communauté...'
                        : 'Posez votre question ou partagez quelque chose...',
                    hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade200),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    isDense: true,
                    counterText: '',
                    fillColor: const Color(0xFFF8FAFC),
                    filled: true,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: _sending ? null : _publierMessage,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _sending ? Colors.grey : AppColors.primary,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: _sending ? [] : [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
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
      key: const ValueKey('dejaPoste'),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_circle_outline_rounded, color: AppColors.success, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Message posté aujourd\'hui ✅',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF1A1A2E)),
                ),
                if (_prochainPostage != null)
                  Text(
                    _formatRestant(_prochainPostage),
                    style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                  ),
              ],
            ),
          ),
          if (_monMessageId != null)
            GestureDetector(
              onTap: () => _supprimerMessage(_monMessageId!),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.error.withValues(alpha: 0.2)),
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
            const Text('🤝', style: TextStyle(fontSize: 42)),
            const SizedBox(height: 16),
            const Text(
              'Aucun message pour l\'instant',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF1A1A2E)),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                ApiService.isAdmin
                    ? 'Soyez le premier à publier un message pour la communauté.'
                    : 'Posez votre question ou partagez quelque chose.\nL\'administrateur vous répondra rapidement !',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xFF64748B), fontSize: 13, height: 1.5),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageCard(Map<String, dynamic> msg) {
    final userId = msg['user_id']?.toString() ?? '';
    final prenom = msg['prenom']?.toString() ?? 'Utilisateur';
    final nom = msg['nom']?.toString() ?? '';
    final contenu = msg['contenu']?.toString() ?? '';
    final dateStr = msg['created_at']?.toString();
    final isAdminPost = msg['is_admin'] == true || msg['is_admin'] == 1;
    final isPinned = msg['is_pinned'] == true;
    final likesCount = (msg['likes_count'] as int?) ?? 0;
    final likedByMe = msg['liked_by_me'] == true;
    final currentUserId = ApiService.currentUser?['id']?.toString() ?? '';
    final isMyPost = userId == currentUserId;
    final iAmAdmin = ApiService.isAdmin;
    final reponses = (msg['reponses'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final initiale = prenom.isNotEmpty ? prenom[0].toUpperCase() : 'U';
    final msgColor = isAdminPost ? AppColors.primary : _getTypeColor(_typeSelectionne);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isPinned
              ? Colors.amber.shade300
              : isMyPost
                  ? AppColors.primary.withValues(alpha: 0.3)
                  : Colors.grey.shade200,
          width: isPinned ? 2 : (isMyPost ? 1.5 : 1),
        ),
        boxShadow: [
          BoxShadow(
            color: isPinned
                ? Colors.amber.withValues(alpha: 0.15)
                : Colors.black.withValues(alpha: 0.04),
            blurRadius: isPinned ? 12 : 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Bandeau épinglé ──
            if (isPinned) ...[
              Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.amber.shade200),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('📌', style: TextStyle(fontSize: 13)),
                    const SizedBox(width: 5),
                    Text(
                      'Message épinglé par l\'administrateur',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.amber.shade800,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // ── En-tête ──
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Avatar
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isAdminPost
                        ? AppColors.primary
                        : msgColor.withValues(alpha: 0.12),
                    border: Border.all(
                      color: isAdminPost
                          ? AppColors.primary
                          : msgColor.withValues(alpha: 0.35),
                      width: 1.5,
                    ),
                  ),
                  child: isAdminPost
                      ? ClipOval(
                          child: Image.asset(
                            'assets/images/logo_effort.png',
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Center(
                              child: Text('EF', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13)),
                            ),
                          ),
                        )
                      : Center(
                          child: Text(
                            initiale,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: msgColor,
                            ),
                          ),
                        ),
                ),
                const SizedBox(width: 10),

                // Nom + tags
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              isAdminPost ? 'EF-FORT.BF' : '$prenom $nom'.trim(),
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: isAdminPost ? AppColors.primary : const Color(0xFF1A1A2E),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isAdminPost) ...[
                            const SizedBox(width: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text('OFFICIEL', style: TextStyle(fontSize: 8, fontWeight: FontWeight.w900, color: Colors.white)),
                            ),
                          ],
                          if (isMyPost && !isAdminPost) ...[
                            const SizedBox(width: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text('MOI', style: TextStyle(fontSize: 8, fontWeight: FontWeight.w900, color: AppColors.primary)),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _formatAge(dateStr),
                        style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                      ),
                    ],
                  ),
                ),

                // Menu actions (supprimer + épingler)
                if (iAmAdmin || isMyPost)
                  PopupMenuButton<String>(
                    icon: Icon(Icons.more_vert_rounded, size: 18, color: Colors.grey.shade400),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    onSelected: (val) {
                      if (val == 'supprimer') _supprimerMessage(msg['id']?.toString() ?? '');
                      if (val == 'epingler') _epinglerMessage(msg);
                    },
                    itemBuilder: (_) => [
                      if (iAmAdmin) PopupMenuItem(
                        value: 'epingler',
                        child: Row(
                          children: [
                            Icon(isPinned ? Icons.push_pin_outlined : Icons.push_pin_rounded, size: 16, color: Colors.amber.shade700),
                            const SizedBox(width: 8),
                            Text(isPinned ? 'Désépingler' : 'Épingler', style: TextStyle(fontSize: 13, color: Colors.amber.shade700)),
                          ],
                        ),
                      ),
                      if (iAmAdmin || isMyPost) PopupMenuItem(
                        value: 'supprimer',
                        child: const Row(
                          children: [
                            Icon(Icons.delete_outline_rounded, size: 16, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Supprimer', style: TextStyle(fontSize: 13, color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                  ),
              ],
            ),

            const SizedBox(height: 10),

            // ── Contenu ──
            Text(
              contenu,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF1E293B),
                height: 1.55,
              ),
            ),

            // ── Notification réponse admin non lue ──
            if (reponses.isNotEmpty && !isAdminPost) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.mark_chat_read_rounded, size: 14, color: AppColors.primary),
                    const SizedBox(width: 5),
                    Text(
                      '${reponses.length} réponse${reponses.length > 1 ? 's' : ''} de l\'admin',
                      style: const TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
            ],

            // ── Réponses admin ──
            if (reponses.isNotEmpty) ...[
              const SizedBox(height: 10),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(10, 8, 10, 4),
                      child: Row(
                        children: [
                          const Icon(Icons.verified_rounded, size: 14, color: AppColors.primary),
                          const SizedBox(width: 4),
                          Text(
                            '${reponses.length} réponse${reponses.length > 1 ? 's' : ''} officielle${reponses.length > 1 ? 's' : ''}',
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    ...reponses.map((rep) => _buildReponseItem(rep)),
                  ],
                ),
              ),
            ],

            // ── Actions bas (likes + répondre) ──
            const SizedBox(height: 10),
            Row(
              children: [
                // Bouton Like ❤️
                GestureDetector(
                  onTap: () => _likerMessage(msg),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: likedByMe
                          ? Colors.red.withValues(alpha: 0.1)
                          : Colors.grey.withValues(alpha: 0.07),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: likedByMe ? Colors.red.withValues(alpha: 0.4) : Colors.grey.shade200,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          likedByMe ? '❤️' : '🤍',
                          style: const TextStyle(fontSize: 14),
                        ),
                        if (likesCount > 0) ...[
                          const SizedBox(width: 4),
                          Text(
                            '$likesCount',
                            style: TextStyle(
                              fontSize: 12,
                              color: likedByMe ? Colors.red : const Color(0xFF64748B),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

                const SizedBox(width: 8),

                // En attente si pas de réponse
                if (reponses.isEmpty && !iAmAdmin && !isAdminPost)
                  Row(
                    children: [
                      Icon(Icons.chat_bubble_outline_rounded, size: 13, color: Colors.grey.shade400),
                      const SizedBox(width: 4),
                      Text(
                        'En attente de réponse',
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
                      ),
                    ],
                  ),

                const Spacer(),

                // Bouton répondre (ADMIN UNIQUEMENT)
                if (iAmAdmin && !isAdminPost)
                  GestureDetector(
                    onTap: () => _repondre(msg),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.primary, AppColors.primaryDark],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.3),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.reply_rounded, size: 14, color: Colors.white),
                          SizedBox(width: 5),
                          Text(
                            'Répondre',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReponseItem(Map<String, dynamic> rep) {
    final repContenu = rep['contenu']?.toString() ?? '';
    final repDate = rep['created_at']?.toString();
    final repPrenom = rep['prenom']?.toString() ?? 'Admin';

    return Container(
      margin: const EdgeInsets.fromLTRB(10, 0, 10, 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: ClipOval(
                  child: Image.asset(
                    'assets/images/logo_effort.png',
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Center(
                      child: Text('EF', style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.w800)),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                repPrenom,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text('ADMIN', style: TextStyle(fontSize: 7, color: AppColors.primary, fontWeight: FontWeight.w900)),
              ),
              const Spacer(),
              Text(
                _formatAge(repDate),
                style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            repContenu,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF334155),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
