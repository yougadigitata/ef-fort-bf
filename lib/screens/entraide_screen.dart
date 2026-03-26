import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/theme/app_colors.dart';
import '../services/api_service.dart';
import 'abonnement_screen.dart';

class EntraideScreen extends StatefulWidget {
  const EntraideScreen({super.key});

  @override
  State<EntraideScreen> createState() => _EntraideScreenState();
}

class _EntraideScreenState extends State<EntraideScreen> {
  List<dynamic> _messages = [];
  bool _loading = true;
  bool _sending = false;
  bool _showRules = true;

  final TextEditingController _messageCtrl = TextEditingController();
  bool _partagerWhatsApp = false;
  final TextEditingController _telCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (ApiService.isAbonne) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadMessages();
      });
    } else {
      setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _messageCtrl.dispose();
    _telCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadMessages() async {
    setState(() => _loading = true);
    final messages = await ApiService.getEntraideMsgs();
    if (mounted) {
      setState(() {
        _messages = messages;
        _loading = false;
      });
    }
  }

  Future<void> _sendMessage() async {
    final contenu = _messageCtrl.text.trim();
    if (contenu.length < 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Message trop court (min. 3 caractères)'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _sending = true);
    final result = await ApiService.sendEntraideMsgAPI(
      contenu: contenu,
      partagerWhatsApp: _partagerWhatsApp,
      telephone: _partagerWhatsApp ? _telCtrl.text.trim() : null,
    );

    if (mounted) {
      setState(() => _sending = false);
      if (result['success'] == true) {
        _messageCtrl.clear();
        _telCtrl.clear();
        setState(() => _partagerWhatsApp = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Message publié avec succès !'),
            backgroundColor: AppColors.success,
          ),
        );
        _loadMessages();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['error'] ?? 'Erreur lors de l\'envoi'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _launchWhatsApp(String? tel) async {
    if (tel == null || tel.isEmpty) return;
    final cleanTel = tel.replaceAll(RegExp(r'\D'), '');
    final number = cleanTel.length == 8 ? '226$cleanTel' : cleanTel;
    final uri = Uri.parse(
        'https://wa.me/$number?text=Bonjour%2C%20je%20vous%20contacte%20via%20EF-FORT.BF');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  String _getInitiales(Map<String, dynamic> profile) {
    final prenom = (profile['prenom'] ?? '').toString();
    final nom = (profile['nom'] ?? '').toString();
    if (prenom.isEmpty && nom.isEmpty) return '?';
    return '${prenom.isNotEmpty ? prenom[0] : ''}${nom.isNotEmpty ? nom[0] : ''}'
        .toUpperCase();
  }

  Color _getAvatarColor(String initiales) {
    final colors = [
      AppColors.primary,
      const Color(0xFF8E44AD),
      const Color(0xFF2980B9),
      const Color(0xFFE67E22),
      const Color(0xFF16A085),
      const Color(0xFFC0392B),
    ];
    if (initiales.isEmpty) return colors[0];
    return colors[initiales.codeUnitAt(0) % colors.length];
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
    // ── TÂCHE 2 : Afficher écran cadenas si non-abonné ──
    if (!ApiService.isAbonne) {
      return _buildPremiumLock(context);
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Espace Entraide'),
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
            onPressed: _loadMessages,
            tooltip: 'Actualiser',
          ),
        ],
      ),
      body: Column(
        children: [
          // Bandeau règles
          if (_showRules)
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              color: const Color(0xFF1A5C38).withValues(alpha: 0.08),
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  const Text('🎓', style: TextStyle(fontSize: 20)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Bienvenue dans l\'espace entraide !',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                        Text(
                          'Partagez vos conseils, posez vos questions, échangez vos contacts.',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.textLight,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Soyez respectueux · Pas de publicité · Entraide uniquement',
                          style: TextStyle(
                            fontSize: 10,
                            color: AppColors.error,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => setState(() => _showRules = false),
                    child: Icon(Icons.close_rounded,
                        color: AppColors.textLight, size: 18),
                  ),
                ],
              ),
            ),

          // Liste des messages
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.primary))
                : _messages.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text('🤝',
                                style: TextStyle(fontSize: 56)),
                            const SizedBox(height: 16),
                            const Text(
                              'Aucun message pour l\'instant.\nSoyez le premier à partager !',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: AppColors.textLight,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadMessages,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(12),
                          itemCount: _messages.length,
                          itemBuilder: (context, index) {
                            final msg =
                                _messages[index] as Map<String, dynamic>;
                            final profile =
                                msg['profiles'] as Map<String, dynamic>? ?? {};
                            final initiales = _getInitiales(profile);
                            final avatarColor = _getAvatarColor(initiales);
                            final partageWA =
                                msg['partage_whatsapp'] == true;
                            final tel =
                                msg['telephone_partage']?.toString();
                            final contenu = msg['contenu']?.toString() ?? '';
                            final dateStr =
                                msg['created_at']?.toString();
                            final niveau =
                                profile['niveau']?.toString() ?? '';

                            return Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: AppColors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color:
                                        Colors.black.withValues(alpha: 0.04),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      color: avatarColor,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Center(
                                      child: Text(
                                        initiales,
                                        style: const TextStyle(
                                          color: AppColors.white,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Text(
                                              profile['prenom']?.toString() ??
                                                  'Anonyme',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w700,
                                                fontSize: 14,
                                                color: AppColors.textDark,
                                              ),
                                            ),
                                            if (niveau.isNotEmpty) ...[
                                              const SizedBox(width: 6),
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 6,
                                                        vertical: 2),
                                                decoration: BoxDecoration(
                                                  color:
                                                      avatarColor.withValues(alpha: 0.1),
                                                  borderRadius:
                                                      BorderRadius.circular(6),
                                                ),
                                                child: Text(
                                                  niveau,
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                    color: avatarColor,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ),
                                            ],
                                            const Spacer(),
                                            Text(
                                              _formatDate(dateStr),
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: AppColors.textLight,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          contenu,
                                          style: const TextStyle(
                                            fontSize: 14,
                                            height: 1.5,
                                            color: AppColors.textDark,
                                          ),
                                        ),
                                        if (partageWA && tel != null) ...[
                                          const SizedBox(height: 8),
                                          GestureDetector(
                                            onTap: () =>
                                                _launchWhatsApp(tel),
                                            child: Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 10,
                                                      vertical: 6),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFF25D366)
                                                    .withValues(alpha: 0.1),
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                                border: Border.all(
                                                  color: const Color(0xFF25D366)
                                                      .withValues(alpha: 0.4),
                                                ),
                                              ),
                                              child: const Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Text('📲',
                                                      style: TextStyle(
                                                          fontSize: 14)),
                                                  SizedBox(width: 6),
                                                  Text(
                                                    'Contacter sur WhatsApp',
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color: Color(0xFF25D366),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
          ),

          // Zone de saisie du message
          Container(
            decoration: BoxDecoration(
              color: AppColors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            padding: EdgeInsets.fromLTRB(
                16, 12, 16, MediaQuery.of(context).viewInsets.bottom + 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Partager mon WhatsApp',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textDark,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Switch(
                      value: _partagerWhatsApp,
                      onChanged: (val) =>
                          setState(() => _partagerWhatsApp = val),
                      activeThumbColor: AppColors.primary,
                    ),
                  ],
                ),
                if (_partagerWhatsApp) ...[
                  const SizedBox(height: 6),
                  TextField(
                    controller: _telCtrl,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      hintText: 'Votre numéro WhatsApp (ex: 65 46 70 70)',
                      hintStyle: TextStyle(color: AppColors.textLight),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide:
                            BorderSide(color: AppColors.primary.withValues(alpha: 0.3)),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 8),
                ],

                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _messageCtrl,
                        maxLines: 2,
                        maxLength: 500,
                        decoration: InputDecoration(
                          hintText:
                              'Écrire un conseil, une question...',
                          hintStyle:
                              TextStyle(color: AppColors.textLight),
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
                              horizontal: 14, vertical: 10),
                          isDense: true,
                          counterText: '',
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    GestureDetector(
                      onTap: _sending ? null : _sendMessage,
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xFFD4A017),
                              Color(0xFFE67E22)
                            ],
                          ),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color:
                                  const Color(0xFFD4A017).withValues(alpha: 0.4),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: _sending
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  color: AppColors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.send_rounded,
                                color: AppColors.white, size: 22),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Écran de verrouillage Premium (TÂCHE 2) ──
  Widget _buildPremiumLock(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Espace Entraide'),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
                colors: [AppColors.primary, AppColors.primaryDark]),
          ),
        ),
        foregroundColor: AppColors.white,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icône cadenas
              Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFFD4A017), Color(0xFFE67E22)],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFD4A017).withValues(alpha: 0.4),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.lock_rounded,
                  color: Colors.white,
                  size: 52,
                ),
              ),
              const SizedBox(height: 28),
              const Text(
                'Fonctionnalité Premium',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'L\'espace Entraide est réservé aux membres abonnés.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: AppColors.textLight,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Rejoignez la communauté et échangez avec d\'autres candidats !',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textLight,
                  fontStyle: FontStyle.italic,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 36),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AbonnementScreen(),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 4,
                  ),
                  child: const Text(
                    'M\'abonner maintenant',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Accès illimité · Entraide · Simulations · PDF',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textLight,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
