import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/theme/app_colors.dart';
import '../services/api_service.dart';
import '../widgets/logo_widget.dart';
import 'login_screen.dart';
import 'admin_screen.dart';

class ProfilScreen extends StatefulWidget {
  const ProfilScreen({super.key});

  @override
  State<ProfilScreen> createState() => _ProfilScreenState();
}

class _ProfilScreenState extends State<ProfilScreen> {
  bool _loadingAbonnement = false;

  Future<void> _demanderAbonnement(String moyen) async {
    setState(() => _loadingAbonnement = true);
    final result = await ApiService.demanderAbonnement(moyen);
    if (!mounted) return;
    setState(() => _loadingAbonnement = false);

    if (result['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Demande envoyée ! Notre équipe EF-FORT activera votre accès rapidement.'),
          backgroundColor: AppColors.success,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['error']?.toString() ?? 'Erreur'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _openWhatsApp() async {
    final uri = Uri.parse('https://wa.me/22665467070?text=Bonjour%20EF-FORT%2C%20je%20souhaite%20m%27abonner%20%C3%A0%20EF-FORT.BF');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
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

  @override
  Widget build(BuildContext context) {
    final user = ApiService.currentUser;
    final nom = user?['nom'] ?? '';
    final prenom = user?['prenom'] ?? '';
    final telephone = user?['telephone'] ?? '';
    final niveau = user?['niveau'] ?? 'BAC';
    final isAdmin = user?['is_admin'] == true;
    final isAbonne = user?['abonnement_actif'] == true;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [AppColors.primary, AppColors.primaryDark],
                  ),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(28),
                    bottomRight: Radius.circular(28),
                  ),
                ),
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
                child: Column(
                  children: [
                    const LogoWidget(size: 80, borderRadius: 18),
                    const SizedBox(height: 16),
                    Text(
                      '$prenom $nom',
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.white),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      telephone,
                      style: TextStyle(fontSize: 14, color: AppColors.white.withValues(alpha: 0.7)),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'Niveau $niveau',
                            style: const TextStyle(fontSize: 12, color: AppColors.white, fontWeight: FontWeight.w600),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: isAbonne ? AppColors.success.withValues(alpha: 0.2) : AppColors.secondary.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            isAbonne ? 'ABONNE' : 'GRATUIT',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: isAbonne ? AppColors.success : AppColors.secondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              if (!isAbonne) ...[
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFD4A017), Color(0xFFB8860B)],
                    ),
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [BoxShadow(color: AppColors.secondary.withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 4))],
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.workspace_premium_rounded, color: AppColors.white, size: 40),
                      const SizedBox(height: 12),
                      const Text(
                        'Abonnement Premium',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.white),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        '12 000 FCFA',
                        style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: AppColors.white),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Valable jusqu\'au 31 decembre 2028',
                        style: TextStyle(fontSize: 13, color: AppColors.white.withValues(alpha: 0.8)),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Acces illimite a +250 QCM\nSimulations d\'examen illimitees\nCorrections detaillees',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 13, color: AppColors.white, height: 1.6),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _openWhatsApp,
                              icon: const Icon(Icons.chat_rounded, size: 18),
                              label: const Text('WhatsApp', style: TextStyle(fontWeight: FontWeight.w700)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.white,
                                foregroundColor: AppColors.primary,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _loadingAbonnement
                                  ? null
                                  : () => _showPaymentDialog(),
                              icon: _loadingAbonnement
                                  ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary))
                                  : const Icon(Icons.payment_rounded, size: 18),
                              label: const Text('J\'ai paye', style: TextStyle(fontWeight: FontWeight.w700)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.white,
                                foregroundColor: AppColors.secondary,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF3E0),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFFF7900).withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline_rounded, color: Color(0xFFFF7900), size: 18),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          'Paiement via Orange Money — 65 46 70 70\nActivation sous 24h après vérification',
                          style: TextStyle(fontSize: 12, color: AppColors.textDark, height: 1.5),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              if (isAbonne)
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.check_circle_rounded, color: AppColors.success, size: 28),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Abonnement actif', style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.success)),
                            Text('Acces illimite jusqu\'au 31/12/2028', style: TextStyle(fontSize: 12, color: AppColors.textLight)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 20),
              if (isAdmin)
                _buildMenuItem(
                  Icons.admin_panel_settings_rounded,
                  'Panel Administration',
                  'Gerer les questions, utilisateurs et abonnements',
                  AppColors.red,
                  () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminScreen())),
                ),
              _buildMenuItem(
                Icons.info_outline_rounded,
                'À propos d\'EF-FORT.BF',
                'Mission, équipe et contact',
                AppColors.primary,
                () => _showAboutDialog(),
              ),
              _buildMenuItem(
                Icons.logout_rounded,
                'Deconnexion',
                'Se deconnecter de l\'application',
                AppColors.error,
                () => _showLogoutConfirm(),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuItem(IconData icon, String title, String subtitle, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: AppColors.textDark)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: TextStyle(fontSize: 12, color: AppColors.textLight)),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: AppColors.textLight.withValues(alpha: 0.5)),
          ],
        ),
      ),
    );
  }

  void _showPaymentDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Paiement par Orange Money', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Text(
              'Mode de paiement disponible',
              style: TextStyle(fontSize: 13, color: AppColors.textLight),
            ),
            const SizedBox(height: 16),
            // Orange Money UNIQUEMENT
            GestureDetector(
              onTap: () {
                Navigator.pop(ctx);
                _demanderAbonnement('Orange Money');
              },
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.orange.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.phone_android, color: Colors.orange, size: 26),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Orange Money',
                            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            '*144*10*65 46 70 70*12000#',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.textLight,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.pop(ctx);
                        _composeOrangeMoney();
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.orange,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text(
                          'Composer',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Center(
              child: Text(
                'Tapez "Composer" pour lancer la composition automatique',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11, color: AppColors.textLight),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Future<void> _composeOrangeMoney() async {
    const String code = '*144*10*65467070*12000%23';
    final Uri telUri = Uri(scheme: 'tel', path: code);
    if (await canLaunchUrl(telUri)) {
      await launchUrl(telUri);
    } else {
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Code Orange Money', style: TextStyle(fontWeight: FontWeight.w700)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  '*144*10*65 46 70 70*12000#',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    fontFamily: 'monospace',
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 12),
              const Text('Composez ce code sur votre téléphone pour payer 12 000 FCFA', textAlign: TextAlign.center),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Fermer')),
          ],
        ),
      );
    }
  }

  void _showAboutDialog() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const _AboutScreen()),
    );
  }

  void _showLogoutConfirm() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Deconnexion'),
        content: const Text('Voulez-vous vraiment vous deconnecter ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _logout();
            },
            child: const Text('Deconnexion', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// PAGE À PROPOS - PREMIUM ANIMÉE
// ═══════════════════════════════════════════════════════════════
class _AboutScreen extends StatefulWidget {
  const _AboutScreen();

  @override
  State<_AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<_AboutScreen>
    with TickerProviderStateMixin {
  int _activeTab = 0; // 0=Mission, 1=Cyber Edu, 2=Contact

  // Animation controllers
  late AnimationController _particleCtrl;
  late AnimationController _shimmerCtrl;
  late AnimationController _pulseCtrl;
  late AnimationController _floatCtrl;
  late AnimationController _rotateCtrl;
  late AnimationController _slideCtrl;

  late Animation<double> _particleAnim;
  late Animation<double> _shimmerAnim;
  late Animation<double> _pulseAnim;
  late Animation<double> _floatAnim;
  late Animation<double> _rotateAnim;
  late Animation<double> _slideAnim;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _slideCtrl.forward();
  }

  void _initAnimations() {
    _particleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();

    _shimmerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);

    _floatCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    )..repeat(reverse: true);

    _rotateCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 15),
    )..repeat();

    _slideCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _particleAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _particleCtrl, curve: Curves.linear),
    );
    _shimmerAnim = Tween<double>(begin: -1.5, end: 2.5).animate(
      CurvedAnimation(parent: _shimmerCtrl, curve: Curves.easeInOut),
    );
    _pulseAnim = Tween<double>(begin: 0.97, end: 1.03).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
    _floatAnim = Tween<double>(begin: -5.0, end: 5.0).animate(
      CurvedAnimation(parent: _floatCtrl, curve: Curves.easeInOut),
    );
    _rotateAnim = Tween<double>(begin: 0.0, end: 2 * math.pi).animate(
      CurvedAnimation(parent: _rotateCtrl, curve: Curves.linear),
    );
    _slideAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _slideCtrl, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _particleCtrl.dispose();
    _shimmerCtrl.dispose();
    _pulseCtrl.dispose();
    _floatCtrl.dispose();
    _rotateCtrl.dispose();
    _slideCtrl.dispose();
    super.dispose();
  }

  Future<void> _openWhatsApp() async {
    final uri = Uri.parse(
        'https://wa.me/22665467070?text=Bonjour%20EF-FORT%2C%20j%27ai%20une%20question%20sur%20l%27application.');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _openEmail() async {
    final uri = Uri.parse('mailto:effortbf2026@gmail.com?subject=Question%20EF-FORT.BF');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _shareApp() async {
    final uri = Uri.parse(
        'https://wa.me/?text=Je%20vous%20recommande%20EF-FORT.BF%20-%20La%20plateforme%20N%C2%B01%20d%27apprentissage%20et%20d%27%C3%A9ducation%20au%20Burkina%20Faso%20%F0%9F%87%A7%F0%9F%87%AB%20%F0%9F%9A%80%20https%3A%2F%2Fef-fort-bf.pages.dev');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ── AppBar PREMIUM animée avec particules ──
          SliverAppBar(
            expandedHeight: 230,
            pinned: true,
            stretch: true,
            flexibleSpace: FlexibleSpaceBar(
              background: AnimatedBuilder(
                animation: Listenable.merge([_particleAnim, _shimmerAnim, _rotateAnim, _floatAnim]),
                builder: (_, __) {
                  return Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFF0A2E1A),
                          Color(0xFF1A5C38),
                          Color(0xFF0F3D24),
                        ],
                      ),
                    ),
                    child: Stack(
                      children: [
                        // Particules dorées
                        CustomPaint(
                          painter: _AboutParticlePainter(progress: _particleAnim.value),
                          size: Size.infinite,
                        ),
                        // Cercle rotatif décoratif
                        Positioned(
                          right: -40,
                          top: -40,
                          child: Transform.rotate(
                            angle: _rotateAnim.value,
                            child: Container(
                              width: 160,
                              height: 160,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: const Color(0xFFD4A017).withValues(alpha: 0.12),
                                  width: 2,
                                ),
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          left: -20,
                          bottom: -20,
                          child: Transform.rotate(
                            angle: -_rotateAnim.value * 0.7,
                            child: Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: const Color(0xFFD4A017).withValues(alpha: 0.08),
                                  width: 1.5,
                                ),
                              ),
                            ),
                          ),
                        ),
                        // Contenu de l'en-tête
                        SafeArea(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const SizedBox(height: 44),
                              // Logo avec halo doré pulsant
                              AnimatedBuilder(
                                animation: _pulseAnim,
                                builder: (_, child) => Transform.scale(
                                  scale: _pulseAnim.value,
                                  child: child,
                                ),
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    // Halo extérieur
                                    Container(
                                      width: 106,
                                      height: 106,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        gradient: RadialGradient(
                                          colors: [
                                            const Color(0xFFD4A017).withValues(alpha: 0.25),
                                            const Color(0xFFD4A017).withValues(alpha: 0.0),
                                          ],
                                        ),
                                      ),
                                    ),
                                    // Bordure dorée
                                    Container(
                                      width: 96,
                                      height: 96,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        gradient: const LinearGradient(
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                          colors: [Color(0xFFD4A017), Color(0xFFF0C040)],
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: const Color(0xFFD4A017).withValues(alpha: 0.5),
                                            blurRadius: 20,
                                            spreadRadius: 2,
                                          ),
                                        ],
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.all(3),
                                        child: Container(
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: Colors.white,
                                          ),
                                          child: ClipOval(
                                            child: Image.asset(
                                              'assets/images/logo_effort.png',
                                              fit: BoxFit.contain,
                                              errorBuilder: (ctx, err, _) => Container(
                                                decoration: const BoxDecoration(
                                                  gradient: LinearGradient(
                                                    colors: [AppColors.primary, AppColors.primaryDark],
                                                  ),
                                                ),
                                                child: const Column(
                                                  mainAxisAlignment: MainAxisAlignment.center,
                                                  children: [
                                                    Text('🎓', style: TextStyle(fontSize: 28)),
                                                    Text('EF-FORT', style: TextStyle(
                                                      color: Colors.white, fontSize: 9,
                                                      fontWeight: FontWeight.w900,
                                                    )),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 12),
                              // Titre avec shimmer
                              ShaderMask(
                                shaderCallback: (bounds) {
                                  return LinearGradient(
                                    begin: Alignment.centerLeft,
                                    end: Alignment.centerRight,
                                    colors: [
                                      Colors.white.withValues(alpha: 0.7),
                                      const Color(0xFFD4A017),
                                      Colors.white.withValues(alpha: 0.7),
                                    ],
                                    stops: [
                                      (_shimmerAnim.value - 0.4).clamp(0.0, 1.0),
                                      _shimmerAnim.value.clamp(0.0, 1.0),
                                      (_shimmerAnim.value + 0.4).clamp(0.0, 1.0),
                                    ],
                                  ).createShader(bounds);
                                },
                                child: const Text(
                                  'EF-FORT.BF',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 24,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 2,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              // Badge animé flottant
                              AnimatedBuilder(
                                animation: _floatAnim,
                                builder: (_, child) => Transform.translate(
                                  offset: Offset(0, _floatAnim.value * 0.4),
                                  child: child,
                                ),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [Color(0xFFD4A017), Color(0xFFE8B520)],
                                    ),
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFFD4A017).withValues(alpha: 0.4),
                                        blurRadius: 10,
                                      ),
                                    ],
                                  ),
                                  child: const Text(
                                    '🏆 Plateforme N°1 au Burkina Faso',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            backgroundColor: AppColors.primaryDark,
            foregroundColor: Colors.white,
            title: const Text('À propos', style: TextStyle(fontWeight: FontWeight.w700)),
          ),

          // ── Onglets de navigation Premium ──
          SliverToBoxAdapter(
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  _buildPremiumTab(0, '🎯 Mission', Icons.flag_rounded),
                  const SizedBox(width: 8),
                  _buildPremiumTab(1, '🔐 Cyber Edu', Icons.security_rounded),
                  const SizedBox(width: 8),
                  _buildPremiumTab(2, '📞 Contact', Icons.contact_support_rounded),
                ],
              ),
            ),
          ),

          // ── Contenu selon onglet ──
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: AnimatedBuilder(
                animation: _slideAnim,
                builder: (_, child) => Transform.translate(
                  offset: Offset(0, 10 * (1 - _slideAnim.value)),
                  child: Opacity(
                    opacity: _slideAnim.value,
                    child: child,
                  ),
                ),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: _activeTab == 0
                      ? _buildMissionTab()
                      : _activeTab == 1
                          ? _buildCyberEduTab()
                          : _buildContactTab(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumTab(int index, String label, IconData icon) {
    final isActive = _activeTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() => _activeTab = index);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
          decoration: BoxDecoration(
            gradient: isActive
                ? const LinearGradient(
                    colors: [AppColors.primary, Color(0xFF2D8F5E)],
                  )
                : null,
            color: isActive ? null : AppColors.background,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isActive
                  ? AppColors.primary
                  : AppColors.primary.withValues(alpha: 0.2),
              width: isActive ? 1.5 : 1,
            ),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedScale(
                scale: isActive ? 1.15 : 1.0,
                duration: const Duration(milliseconds: 200),
                child: Icon(
                  icon,
                  size: 18,
                  color: isActive ? Colors.white : AppColors.primary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: isActive ? Colors.white : AppColors.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMissionTab() {
    return Column(
      key: const ValueKey('mission'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Badge Plateforme N°1 animé
        AnimatedBuilder(
          animation: _floatAnim,
          builder: (_, child) => Transform.translate(
            offset: Offset(0, _floatAnim.value * 0.3),
            child: child,
          ),
          child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFD4A017), Color(0xFFE8B82A), Color(0xFFF0C030)],
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFD4A017).withValues(alpha: 0.4),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              AnimatedBuilder(
                animation: _pulseAnim,
                builder: (_, child) => Transform.scale(
                  scale: _pulseAnim.value,
                  child: child,
                ),
                child: const Text('🏆', style: TextStyle(fontSize: 38)),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Plateforme N°1',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'd\'apprentissage et d\'éducation au Burkina Faso',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      '🇧🇫 Conçu par des Burkinabè, pour des Burkinabè',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        ),
        const SizedBox(height: 16),
        _buildInfoCard(
          icon: '🎯',
          title: 'Notre Mission',
          color: AppColors.primary,
          content: 'Au Burkina Faso, se préparer aux concours ressemble trop souvent à un combat sans repères : peu de ressources fiables, peu d\'encadrement, beaucoup d\'incertitudes.\n\nC\'est pour répondre à ce défi qu\'EF-FORT a été conçu : une direction claire, une pratique régulière et la confiance nécessaire pour réussir.',
        ),
        const SizedBox(height: 12),
        _buildInfoCard(
          icon: '🚀',
          title: 'Ce que vous obtenez',
          color: const Color(0xFF2196F3),
          content: '',
          widget: Column(
            children: [
              _buildFeatureRow('📚', 'Séries de QCM par matière', 'Entraînement ciblé et progressif'),
              _buildFeatureRow('⏱️', 'Simulations d\'examens réels', 'Conditions authentiques de concours'),
              _buildFeatureRow('👥', 'Espace d\'entraide', 'Apprendre ensemble, réussir ensemble'),
              _buildFeatureRow('📊', 'Suivi de progression', 'Mesurez votre évolution en temps réel'),
              _buildFeatureRow('🔔', 'Actualités concours', 'Ne ratez plus aucune ouverture'),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // Stats clés
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  _buildStatBox('10,000+', 'Questions QCM', '📝'),
                  const SizedBox(width: 10),
                  _buildStatBox('50+', 'Concours couverts', '🏛️'),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  _buildStatBox('100%', 'Gratuit d\'abord', '🎁'),
                  const SizedBox(width: 10),
                  _buildStatBox('24/7', 'Disponible partout', '📱'),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Bouton partager
        GestureDetector(
          onTap: _shareApp,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primary, AppColors.primaryLight],
              ),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.share_rounded, color: Colors.white, size: 22),
                SizedBox(width: 10),
                Text(
                  'Partager EF-FORT.BF',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Citation
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.primary.withValues(alpha: 0.05),
                AppColors.secondary.withValues(alpha: 0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
          ),
          child: Column(
            children: [
              const Text('❝', style: TextStyle(fontSize: 36, color: AppColors.primary)),
              const SizedBox(height: 8),
              const Text(
                'La chance ne sourit pas au hasard, elle rencontre toujours un effort bien préparé.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  fontStyle: FontStyle.italic,
                  color: AppColors.textDark,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 10),
              Text('— EF-FORT.BF',
                style: TextStyle(fontSize: 13, color: AppColors.textLight, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
        const SizedBox(height: 30),
      ],
    );
  }

  Widget _buildCyberEduTab() {
    return Column(
      key: const ValueKey('cyber'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Bannière ebook
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF1A1A2E), Color(0xFF16213E), Color(0xFF0F3460)],
            ),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0F3460).withValues(alpha: 0.4),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            children: [
              const Text('🔐', style: TextStyle(fontSize: 44)),
              const SizedBox(height: 10),
              const Text(
                'Cybercriminalité en Afrique',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFFE94560).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFE94560).withValues(alpha: 0.5)),
                ),
                child: const Text(
                  'Le "Qui est Qui" de l\'Internet en Afrique',
                  style: TextStyle(color: Color(0xFFE94560), fontSize: 11, fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'Comprendre, se protéger et contribuer à un numérique éthique',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white.withValues(alpha: 0.75), fontSize: 13, height: 1.5),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Alerte sécurité
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF3CD),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFD4A017).withValues(alpha: 0.5)),
          ),
          child: const Row(
            children: [
              Text('⚠️', style: TextStyle(fontSize: 22)),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'L\'éducation numérique est la meilleure arme contre la cybercriminalité. Lire pour se protéger !',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF856404)),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Préface
        _buildEbookSection(
          emoji: '📖',
          title: 'Préface — Votre renaissance numérique',
          bgColor: const Color(0xFFF0F7FF),
          borderColor: const Color(0xFF2196F3),
          content: 'Les cybercriminels vous semblent être des génies intouchables. Vous pensez que la technologie appartient aux autres, que l\'Afrique est condamnée à être consommatrice plutôt que créatrice.\n\nCette lecture va littéralement reprogrammer votre ADN numérique. Vous allez comprendre les mécanismes cachés qui gouvernent notre monde connecté. Vous allez acquérir les clés pour transformer la menace cybercriminelle en opportunité technologique.\n\nTelle sera votre renaissance numérique.',
        ),
        const SizedBox(height: 12),

        // Introduction
        _buildEbookSection(
          emoji: '🌍',
          title: 'Introduction — L\'Afrique à la croisée des chemins',
          bgColor: const Color(0xFFF0FFF4),
          borderColor: AppColors.primary,
          content: 'Nous vivons un moment historique unique. L\'Afrique détient 60% des jeunes de la planète, la croissance internet la plus rapide au monde, et paradoxalement, les taux de cybercriminalité les plus alarmants.\n\nAu Nigeria, le "yahoo yahoo" génère plus de revenus que l\'industrie pétrolière pour certaines régions. En Côte d\'Ivoire, Abidjan est devenue la capitale mondiale de l\'escroquerie francophone.\n\nMais cette même énergie créatrice pourrait révolutionner la cybersécurité mondiale. Le hacker qui vole aujourd\'hui pourrait protéger demain.',
        ),
        const SizedBox(height: 12),

        // Partie 1
        _buildPartBadge('PARTIE 1', 'L\'ÉCOSYSTÈME CRIMINEL', '🕸️',
            '"Le même fleuve peut irriguer les champs ou inonder les villages."'),
        const SizedBox(height: 12),

        _buildEbookSection(
          emoji: '👾',
          title: 'Chapitre 1 — Hackers vs Brouteurs : deux espèces, une origine',
          bgColor: const Color(0xFFFFF5F5),
          borderColor: const Color(0xFFE53E3E),
          content: 'Le vrai hacker est un esthète du code. Il voit la beauté dans un algorithme élégant. En Afrique, nous produisons des hackers d\'une créativité exceptionnelle, souvent par nécessité plutôt que par formation.\n\n• L\'hacker éthique : met son génie au service du bien\n• L\'hacker non éthique : met sa compétence au service du mal\n• Le brouteur : maîtrise l\'art de la manipulation émotionnelle. Il n\'y a pas de brouteur éthique.\n\nLa différence entre un hacker éthique et un cybercriminel n\'est souvent qu\'une question d\'opportunité et de mentorat.',
        ),
        const SizedBox(height: 12),

        _buildEbookSection(
          emoji: '💰',
          title: 'Chapitre 2 — L\'économie souterraine qui défie les États',
          bgColor: const Color(0xFFFFFBF0),
          borderColor: const Color(0xFFD4A017),
          content: 'La cybercriminalité africaine brasse des sommes qui dépassent le PIB de certains pays. Au Nigeria, les estimations varient entre 500 millions et 2 milliards de dollars annuels.\n\nToute une économie parallèle s\'est développée : des marchés spécialisés où s\'échangent les données volées, des "écoles" informelles qui forment aux techniques d\'arnaque.\n\nCette économie fonctionne comme une vraie industrie avec ses spécialisations et sa hiérarchie.',
        ),
        const SizedBox(height: 12),

        _buildEbookSection(
          emoji: '🤖',
          title: 'Chapitre 3 — L\'Intelligence Artificielle au service du crime',
          bgColor: const Color(0xFFF5F0FF),
          borderColor: const Color(0xFF7C3AED),
          content: 'L\'intelligence artificielle a révolutionné la cybercriminalité en rendant accessible à tous des techniques autrefois réservées aux experts : fausses vidéos (deepfakes), imitation de voix, génération de textes convaincants.\n\n🔴 Deepfakes vocaux : des escrocs imitent la voix de proches pour demander de l\'argent d\'urgence.\n\n🔴 Chatbots séducteurs : des programmes IA maintiennent simultanément des dizaines de relations amoureuses virtuelles pour arnaquer les victimes.',
        ),
        const SizedBox(height: 16),

        // Partie 2
        _buildPartBadge('PARTIE 2', 'LA RECONVERSION, VOIE DE LA RÉDEMPTION', '🌟',
            '"Le diamant n\'est qu\'un charbon qui a résisté à la pression."'),
        const SizedBox(height: 12),

        _buildEbookSection(
          emoji: '🦸',
          title: 'Chapitre 4 — De prédateur à protecteur : l\'histoire de Samira',
          bgColor: const Color(0xFFF0FFF4),
          borderColor: AppColors.primary,
          content: 'Samira dirigeait une équipe de brouteurs à Lagos. Diplômée en informatique du MIT, elle gagnait 100 000 dollars par mois dans le crime.\n\nLe déclic est venu quand l\'une de ses victimes s\'est suicidée. "Ce jour-là, j\'ai réalisé que j\'étais devenue un monstre."\n\nAujourd\'hui, Samira dirige CyberShield Africa, une entreprise de cybersécurité qui emploie 200 personnes, dont 80% d\'anciens cybercriminels reconvertis. Elle a créé la première "Hacker Academy" d\'Afrique de l\'Ouest.',
        ),
        const SizedBox(height: 12),

        _buildEbookSection(
          emoji: '📋',
          title: 'Chapitre 5 — Le guide pratique de la reconversion',
          bgColor: const Color(0xFFF0F7FF),
          borderColor: const Color(0xFF2196F3),
          content: 'Les activités illégales développent souvent des talents très recherchés dans le secteur légal. Ces compétences peuvent être légalement monétisées :\n\n✅ Audit de sécurité informatique\n✅ Formation en sensibilisation aux risques cyber\n✅ Développement de solutions de protection\n✅ Conseil en sécurisation des systèmes\n\nCertifications clés : CEH (Certified Ethical Hacker), CISSP, OSCP, GCIH',
        ),
        const SizedBox(height: 12),

        _buildEbookSection(
          emoji: '👨‍👩‍👧‍👦',
          title: 'Chapitre 6 — Protéger sa famille en premier',
          bgColor: const Color(0xFFFFF5F5),
          borderColor: const Color(0xFFE53E3E),
          content: 'Votre reconversion commence à la maison. Vos nouvelles compétences en cybersécurité doivent d\'abord protéger vos proches.\n\n🛡️ Sécuriser tous les appareils familiaux\n🔐 Activer l\'authentification à deux facteurs\n💾 Mettre en place des sauvegardes automatiques\n👁️ Apprendre à reconnaître les tentatives de phishing\n🔑 Enseigner les bonnes pratiques de mots de passe',
        ),
        const SizedBox(height: 16),

        // Partie 3
        _buildPartBadge('PARTIE 3', 'CONSTRUIRE L\'AFRIQUE CYBERSÉCURISÉE DE DEMAIN', '🌐', ''),
        const SizedBox(height: 12),

        // Cas Burkina Faso
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF8E1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFD4A017).withValues(alpha: 0.5), width: 2),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text('🇧🇫', style: TextStyle(fontSize: 24)),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Chapitre 7 — L\'arnaque 5M au Burkina Faso (2023)',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF7A5A00),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Text(
                'L\'affaire de la plateforme 5M au Burkina Faso en 2023 montre que les cybercriminels n\'ont aucune limite. Des milliers de Burkinabè — pères de famille, jeunes diplômés, commerçants — ont été attirés par une plateforme de "trading quantitatif" promettant 20-30% de rendement par mois.\n\n"À notre grande surprise, la plateforme s\'arrêta un certain vendredi 4 août 2023. Certains y avaient adhéré le même jour et n\'ont pu rien retirer." — Sylas Bagré, porte-parole des victimes.',
                style: TextStyle(fontSize: 13, height: 1.6, color: Color(0xFF856404)),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('🚨 La règle d\'or anti-arnaque :', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Colors.red)),
                    SizedBox(height: 6),
                    Text('• Si c\'est trop beau pour être vrai, c\'est que ce n\'est pas vrai.\n• Vérifiez si l\'entreprise a un siège physique\n• Vérifiez l\'enregistrement auprès des autorités financières\n• Comprendre comment ils gagnent l\'argent promis', style: TextStyle(fontSize: 12, height: 1.5, color: Color(0xFF7A0000))),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        _buildEbookSection(
          emoji: '📱',
          title: 'Chapitre 8 — Protection intelligente de votre téléphone',
          bgColor: const Color(0xFFF0F7FF),
          borderColor: const Color(0xFF2196F3),
          content: '🔒 Activez le chiffrement complet de votre appareil\n🔑 Utilisez un gestionnaire de mots de passe\n📲 Activez l\'authentification à 2 facteurs partout\n🔄 Faites des mises à jour régulières du système\n🛡️ Installez uniquement depuis les stores officiels\n📵 Méfiez-vous des réseaux Wi-Fi publics non sécurisés',
        ),
        const SizedBox(height: 12),

        _buildEbookSection(
          emoji: '🚪',
          title: 'Chapitre 9 — Fermer la porte aux voleurs numériques',
          bgColor: const Color(0xFFF0FFF4),
          borderColor: AppColors.primary,
          content: 'Ne jamais cliquer sur des liens dans des SMS ou emails suspects. Ne jamais donner votre code OTP à qui que ce soit.\n\n🔴 Phishing : emails qui imitent votre banque ou administration\n🔴 SIM Swap : voler votre numéro de téléphone\n🔴 Faux sites web : copies parfaites de sites légitimes\n🔴 Arnaques sentimentales : relations amoureuses fictives en ligne\n\nUn organisme officiel ne demande JAMAIS votre mot de passe.',
        ),
        const SizedBox(height: 12),

        _buildEbookSection(
          emoji: '🌟',
          title: 'Chapitre 10 — L\'Afrique, future Silicon Valley de la cybersécurité',
          bgColor: const Color(0xFFFFFBF0),
          borderColor: const Color(0xFFD4A017),
          content: 'L\'Afrique peut devenir le continent qui forme les meilleurs experts en cybersécurité de la planète. Nous avons la créativité, la jeunesse et la motivation.\n\nCe choix ne se fera pas dans les palais présidentiels. Il se fera dans chaque famille, chaque école, chaque cybercafé où un jeune découvre ses talents numériques.\n\nÀ travers des plateformes comme EF-FORT.BF, nous construisons l\'Afrique numérique de demain. 🇧🇫🌍',
        ),
        const SizedBox(height: 20),

        // Bouton d'incitation à aller sur contact
        GestureDetector(
          onTap: () => setState(() => _activeTab = 2),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF1A1A2E), Color(0xFF0F3460)],
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('📞', style: TextStyle(fontSize: 22)),
                SizedBox(width: 10),
                Text(
                  'Une question sur la cybersécurité ? Contactez-nous',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 30),
      ],
    );
  }

  Widget _buildContactTab() {
    return Column(
      key: const ValueKey('contact'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Invitation à consulter le profil
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.primary, AppColors.primaryLight],
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Column(
            children: [
              Text('👋', style: TextStyle(fontSize: 36)),
              SizedBox(height: 8),
              Text(
                'Nous sommes là pour vous accompagner',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              SizedBox(height: 6),
              Text(
                'Notre équipe répond dans les 24h',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70, fontSize: 13),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _buildInfoCard(
          icon: '📬',
          title: 'Nous Contacter',
          color: AppColors.secondary,
          content: 'Notre équipe reste disponible pour vous accompagner :',
          widget: Column(
            children: [
              GestureDetector(
                onTap: _openEmail,
                child: _buildContactRow(
                  icon: Icons.email_rounded,
                  iconColor: AppColors.primary,
                  bgColor: AppColors.primary.withValues(alpha: 0.07),
                  title: 'Email',
                  subtitle: 'effortbf2026@gmail.com',
                ),
              ),
              const SizedBox(height: 10),
              GestureDetector(
                onTap: _openWhatsApp,
                child: _buildContactRow(
                  icon: Icons.chat_rounded,
                  iconColor: const Color(0xFF25D366),
                  bgColor: const Color(0xFF25D366).withValues(alpha: 0.07),
                  title: 'WhatsApp',
                  subtitle: '+226 65 46 70 70',
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // Invitation à explorer l'ebook
        GestureDetector(
          onTap: () => setState(() => _activeTab = 1),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF1A1A2E), Color(0xFF0F3460)],
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                const Text('🔐', style: TextStyle(fontSize: 28)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Guide Cybersécurité gratuit',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14),
                      ),
                      Text(
                        'Lire notre guide : Cybercriminalité en Afrique →',
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.75), fontSize: 12),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white70, size: 16),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: _shareApp,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.primary, AppColors.primaryLight],
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Column(
                    children: [
                      Icon(Icons.share_rounded, color: Colors.white, size: 26),
                      SizedBox(height: 6),
                      Text('Partager l\'app', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: GestureDetector(
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('⭐ Merci pour votre soutien ! L\'app sera bientôt sur Play Store.'),
                      backgroundColor: AppColors.secondary,
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.secondaryLight,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.secondary.withValues(alpha: 0.4)),
                  ),
                  child: const Column(
                    children: [
                      Icon(Icons.star_rounded, color: AppColors.secondary, size: 26),
                      SizedBox(height: 6),
                      Text('Noter l\'app', style: TextStyle(color: AppColors.secondary, fontWeight: FontWeight.w700, fontSize: 13)),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 30),
      ],
    );
  }

  Widget _buildInfoCard({required String icon, required String title, required Color color, required String content, Widget? widget}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 22,
                decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2)),
              ),
              const SizedBox(width: 10),
              Text(icon, style: const TextStyle(fontSize: 18)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textDark)),
              ),
            ],
          ),
          if (content.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(content, style: const TextStyle(fontSize: 13, height: 1.65, color: AppColors.textDark)),
          ],
          if (widget != null) ...[
            const SizedBox(height: 12),
            widget,
          ],
        ],
      ),
    );
  }

  Widget _buildEbookSection({required String emoji, required String title, required Color bgColor, required Color borderColor, required String content}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(emoji, style: const TextStyle(fontSize: 22)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.textDark),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(content, style: const TextStyle(fontSize: 13, height: 1.65, color: AppColors.textDark)),
        ],
      ),
    );
  }

  Widget _buildPartBadge(String partNum, String partTitle, String emoji, String quote) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primaryDark,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 28)),
          const SizedBox(height: 6),
          Text(partNum, style: const TextStyle(color: AppColors.secondary, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 2)),
          const SizedBox(height: 4),
          Text(partTitle, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w900)),
          if (quote.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text('$quote', textAlign: TextAlign.center, style: TextStyle(color: Colors.white.withValues(alpha: 0.65), fontSize: 12, fontStyle: FontStyle.italic)),
          ],
        ],
      ),
    );
  }

  Widget _buildFeatureRow(String emoji, String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textDark)),
                Text(subtitle, style: const TextStyle(fontSize: 11, color: AppColors.textLight)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatBox(String value, String label, String emoji) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 20)),
            const SizedBox(height: 4),
            Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppColors.primary)),
            Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 10, color: AppColors.textLight)),
          ],
        ),
      ),
    );
  }

  Widget _buildContactRow({required IconData icon, required Color iconColor, required Color bgColor, required String title, required String subtitle}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 12, color: AppColors.textLight)),
                Text(subtitle, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textDark)),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.textLight),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// PAINTER : Particules flottantes dorées pour la page À propos
// ═══════════════════════════════════════════════════════════════════════
class _AboutParticlePainter extends CustomPainter {
  final double progress;
  static final _random = math.Random(77);
  static late List<_AboutParticle> _particles;
  static bool _initialized = false;

  _AboutParticlePainter({required this.progress}) {
    if (!_initialized) {
      _particles = List.generate(25, (i) => _AboutParticle(
        x: _random.nextDouble(),
        y: _random.nextDouble(),
        size: 1.2 + _random.nextDouble() * 2.8,
        speed: 0.12 + _random.nextDouble() * 0.2,
        opacity: 0.2 + _random.nextDouble() * 0.55,
        phase: _random.nextDouble(),
      ));
      _initialized = true;
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in _particles) {
      final phase = (progress * p.speed + p.phase) % 1.0;
      final y = size.height * (1 - phase);
      final x = p.x * size.width + math.sin(phase * 2 * math.pi + p.phase) * 15;
      final alpha = math.sin(phase * math.pi) * p.opacity;

      final paint = Paint()
        ..color = const Color(0xFFD4A017).withValues(alpha: alpha)
        ..style = PaintingStyle.fill;

      if (p.size > 2.5) {
        // Dessiner une petite étoile
        final path = Path();
        const pts = 4;
        for (int i = 0; i < pts * 2; i++) {
          final angle = (i * math.pi / pts) - math.pi / 2;
          final r = i.isEven ? p.size * 1.2 : p.size * 0.4;
          final px = x + r * math.cos(angle);
          final py = y + r * math.sin(angle);
          if (i == 0) path.moveTo(px, py);
          else path.lineTo(px, py);
        }
        path.close();
        canvas.drawPath(path, paint);
      } else {
        canvas.drawCircle(Offset(x, y), p.size, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_AboutParticlePainter old) => old.progress != progress;
}

class _AboutParticle {
  final double x, y, size, speed, opacity, phase;
  _AboutParticle({
    required this.x, required this.y, required this.size,
    required this.speed, required this.opacity, required this.phase,
  });
}
