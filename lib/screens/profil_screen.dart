import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/theme/app_colors.dart';
import '../services/api_service.dart';
import '../services/progression_service.dart';
import '../utils/safe_launcher.dart';
import 'login_screen.dart';
import 'admin_screen.dart';

// ══════════════════════════════════════════════════════════════
// PROFIL SCREEN v10.0 — Inspiré Coursera
// Statistiques · Compte · Paramètres · À propos
// ══════════════════════════════════════════════════════════════

class ProfilScreen extends StatefulWidget {
  const ProfilScreen({super.key});

  @override
  State<ProfilScreen> createState() => _ProfilScreenState();
}

class _ProfilScreenState extends State<ProfilScreen>
    with TickerProviderStateMixin {
  UserStats? _stats;
  bool _loadingStats = true;

  late AnimationController _headerCtrl;
  late AnimationController _contentCtrl;
  late Animation<double> _headerAnim;
  late Animation<double> _contentAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _headerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _contentCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _headerAnim = CurvedAnimation(parent: _headerCtrl, curve: Curves.easeOutCubic);
    _contentAnim = CurvedAnimation(parent: _contentCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.12),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _contentCtrl, curve: Curves.easeOut));

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _headerCtrl.forward();
      await _contentCtrl.forward();
      _loadStats();
    });
  }

  @override
  void dispose() {
    _headerCtrl.dispose();
    _contentCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadStats() async {
    try {
      final stats = await ProgressionService.getUserStats();
      if (mounted) setState(() { _stats = stats; _loadingStats = false; });
    } catch (_) {
      if (mounted) setState(() => _loadingStats = false);
    }
  }

  Future<void> _openWhatsApp() async {
    final uri = Uri.parse(
        'https://wa.me/22665467070?text=Bonjour%20EF-FORT.BF%2C%20j%27ai%20besoin%20d%27aide');
    await SafeLauncher.launch(context, uri,
        fallbackMessage: 'Contactez-nous sur WhatsApp au 65 46 70 70');
  }

  Future<void> _logout() async {
    await ApiService.logout();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  Future<void> _openSite() async {
    final uri = Uri.parse('https://ef-fort.bf');
    await SafeLauncher.launch(context, uri,
        fallbackMessage: 'Site : https://ef-fort.bf');
  }

  @override
  Widget build(BuildContext context) {
    final user = ApiService.currentUser;
    final nom = user?['nom'] ?? '';
    final prenom = user?['prenom'] ?? '';
    final telephone = user?['telephone'] ?? '';
    final niveau = user?['niveau'] ?? 'BAC';
    final isAdmin = user?['is_admin'] == true;
    final initiales = _initiales(prenom, nom);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // ── App bar avec avatar ────────────────────────────────
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: AppColors.primary,
            surfaceTintColor: Colors.transparent,
            actions: [
              if (isAdmin)
                IconButton(
                  icon: const Icon(Icons.admin_panel_settings_outlined, color: Colors.white),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AdminScreen()),
                  ),
                  tooltip: 'Administration',
                ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: FadeTransition(
                opacity: _headerAnim,
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF0056D2), Color(0xFF003FA3)],
                    ),
                  ),
                  child: Stack(
                    children: [
                      Positioned(
                        top: -20, right: -20,
                        child: Container(
                          width: 160, height: 160,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withValues(alpha: 0.05),
                          ),
                        ),
                      ),
                      SafeArea(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Avatar
                              Row(
                                children: [
                                  Container(
                                    width: 64,
                                    height: 64,
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.2),
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.white.withValues(alpha: 0.4),
                                        width: 2.5,
                                      ),
                                    ),
                                    child: Center(
                                      child: Text(
                                        initiales,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 24,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '$prenom $nom',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 18,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          telephone.isNotEmpty ? '+226 $telephone' : 'Apprenant',
                                          style: TextStyle(
                                            color: Colors.white.withValues(alpha: 0.8),
                                            fontSize: 13,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                              decoration: BoxDecoration(
                                                color: Colors.white.withValues(alpha: 0.2),
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                              child: Text(
                                                'Niveau $niveau',
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                              decoration: BoxDecoration(
                                                color: AppColors.secondary.withValues(alpha: 0.8),
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                              child: const Text(
                                                '✓ Accès complet',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              title: const Text(
                'Mon profil',
                style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w700),
              ),
            ),
          ),
          // ── Contenu ───────────────────────────────────────────
          SliverToBoxAdapter(
            child: SlideTransition(
              position: _slideAnim,
              child: FadeTransition(
                opacity: _contentAnim,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Statistiques
                    _buildStatsSection(),
                    const SizedBox(height: 8),
                    // Compte
                    _buildSection(
                      title: 'Mon compte',
                      items: [
                        _buildMenuItem(
                          icon: Icons.person_outline_rounded,
                          label: prenom.isNotEmpty ? '$prenom $nom' : 'Profil',
                          subtitle: 'Informations personnelles',
                          onTap: () {},
                        ),
                        _buildDivider(),
                        _buildMenuItem(
                          icon: Icons.phone_outlined,
                          label: telephone.isNotEmpty ? '+226 $telephone' : 'Téléphone',
                          subtitle: 'Numéro de contact',
                          onTap: () {},
                        ),
                        _buildDivider(),
                        _buildMenuItem(
                          icon: Icons.school_outlined,
                          label: 'Niveau $niveau',
                          subtitle: 'Niveau d\'études',
                          onTap: () {},
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Support
                    _buildSection(
                      title: 'Aide & Support',
                      items: [
                        _buildMenuItem(
                          icon: Icons.support_agent_outlined,
                          label: 'Contacter le support',
                          subtitle: 'WhatsApp · 65 46 70 70',
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFF25D366).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'WhatsApp',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF25D366),
                              ),
                            ),
                          ),
                          onTap: _openWhatsApp,
                        ),
                        _buildDivider(),
                        _buildMenuItem(
                          icon: Icons.language_outlined,
                          label: 'Site web EF-FORT.BF',
                          subtitle: 'https://ef-fort.bf',
                          onTap: _openSite,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // À propos
                    _buildAboutSection(),
                    const SizedBox(height: 8),
                    // Admin
                    if (isAdmin)
                      _buildSection(
                        title: 'Administration',
                        items: [
                          _buildMenuItem(
                            icon: Icons.admin_panel_settings_outlined,
                            label: 'Panneau d\'administration',
                            subtitle: 'Gérer les questions, utilisateurs',
                            color: AppColors.primary,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const AdminScreen()),
                            ),
                          ),
                        ],
                      ),
                    if (isAdmin) const SizedBox(height: 8),
                    // Déconnexion
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: _showLogoutConfirm,
                          icon: const Icon(Icons.logout_rounded, size: 18, color: AppColors.error),
                          label: const Text(
                            'Se déconnecter',
                            style: TextStyle(color: AppColors.error, fontWeight: FontWeight.w600),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppColors.error, width: 1.5),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ),
                    ),
                    // Footer
                    const SizedBox(height: 24),
                    Center(
                      child: Column(
                        children: [
                          const Text(
                            'EF-FORT.BF',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                              color: AppColors.primary,
                              letterSpacing: 1,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'La plateforme d\'apprentissage N°1 au Burkina Faso',
                            style: TextStyle(fontSize: 11, color: AppColors.textSubtle),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            '© EF-FORT.BF 2026 — Tous droits réservés',
                            style: TextStyle(fontSize: 11, color: AppColors.textSubtle),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSection() {
    final total = _stats?.nbQuestionsRepondues ?? 0;
    final taux = _stats?.tauxReussiteGlobal ?? 0.0;
    final note = _stats?.noteSur20 ?? 0.0;
    final simus = _stats?.nbSimulations ?? 0;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Mes statistiques',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 14),
          if (_loadingStats)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2),
              ),
            )
          else ...[
            Row(
              children: [
                Expanded(child: _buildStatItem('$total', 'Questions', Icons.quiz_outlined, AppColors.primary)),
                Expanded(child: _buildStatItem('${taux.toStringAsFixed(0)}%', 'Réussite', Icons.trending_up, AppColors.secondary)),
                Expanded(child: _buildStatItem('${note.toStringAsFixed(1)}/20', 'Note', Icons.star_outline, const Color(0xFFD97706))),
                Expanded(child: _buildStatItem('$simus', 'Examens', Icons.assignment_outlined, const Color(0xFF7C3AED))),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatItem(String value, String label, IconData icon, Color color) {
    return Column(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 22),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: AppColors.textLight),
        ),
      ],
    );
  }

  Widget _buildSection({required String title, required List<Widget> items}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.textLight,
                letterSpacing: 0.5,
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.divider),
            ),
            child: Column(children: items),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String label,
    String? subtitle,
    Color? color,
    Widget? trailing,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: (color ?? AppColors.textMedium).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(icon, color: color ?? AppColors.textMedium, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: color ?? AppColors.textDark,
                      ),
                    ),
                    if (subtitle != null)
                      Text(
                        subtitle,
                        style: const TextStyle(fontSize: 12, color: AppColors.textLight),
                      ),
                  ],
                ),
              ),
              trailing ??
                  Icon(
                    Icons.chevron_right,
                    size: 18,
                    color: AppColors.textSubtle,
                  ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return const Divider(
      height: 1,
      thickness: 1,
      color: AppColors.divider,
      indent: 68,
    );
  }

  Widget _buildAboutSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(left: 4, bottom: 8),
            child: Text(
              'À PROPOS',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.textLight,
                letterSpacing: 0.5,
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF0056D2), Color(0xFF009E49)],
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'EF-FORT.BF',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                    const Spacer(),
                    const Text('🇧🇫', style: TextStyle(fontSize: 24)),
                  ],
                ),
                const SizedBox(height: 12),
                const Text(
                  'La plateforme N°1 d\'apprentissage et de préparation aux concours de la Fonction Publique du Burkina Faso.',
                  style: TextStyle(color: Colors.white, fontSize: 13, height: 1.5),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _buildFeatureChip('100% Gratuit'),
                    const SizedBox(width: 8),
                    _buildFeatureChip('Certifié'),
                    const SizedBox(width: 8),
                    _buildFeatureChip('Burkina 🇧🇫'),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: _openSite,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white, width: 1.5),
                      padding: const EdgeInsets.symmetric(vertical: 11),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text(
                      'Visiter notre site',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
      ),
    );
  }

  void _showLogoutConfirm() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Se déconnecter ?', style: TextStyle(fontWeight: FontWeight.w700)),
        content: const Text('Vous devrez vous reconnecter pour accéder à vos formations.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _logout();
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Déconnecter', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  String _initiales(String prenom, String nom) {
    final p = prenom.isNotEmpty ? prenom[0].toUpperCase() : '';
    final n = nom.isNotEmpty ? nom[0].toUpperCase() : '';
    return '$p$n'.isNotEmpty ? '$p$n' : '👤';
  }
}
