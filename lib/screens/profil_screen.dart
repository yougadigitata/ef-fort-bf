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
// PAGE À PROPOS - REFONTE COMPLÈTE (Phase 5)
// ═══════════════════════════════════════════════════════════════
class _AboutScreen extends StatelessWidget {
  const _AboutScreen();

  Future<void> _openWhatsApp(BuildContext context) async {
    final uri = Uri.parse(
        'https://wa.me/22665467070?text=Bonjour%20EF-FORT%2C%20j%27ai%20une%20question%20sur%20l%27application.');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _openEmail(BuildContext context) async {
    final uri = Uri.parse('mailto:effortbf2026@gmail.com?subject=Question%20EF-FORT.BF');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _shareApp(BuildContext context) async {
    final uri = Uri.parse(
        'https://wa.me/?text=Je%20vous%20recommande%20EF-FORT.BF%20-%20La%20plateforme%20N%C2%B01%20de%20pr%C3%A9paration%20aux%20concours%20du%20Burkina%20Faso%20%F0%9F%87%A7%F0%9F%87%AB%20https%3A%2F%2Fef-fort-bf.pages.dev');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('À propos'),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.primary, AppColors.primaryDark],
            ),
          ),
        ),
        foregroundColor: AppColors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // ── En-tête gradient ──
            Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [AppColors.primaryDark, AppColors.primary],
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(32),
                  bottomRight: Radius.circular(32),
                ),
              ),
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 36),
              child: Column(
                children: [
                  // LOGO EF-FORT RESTAURÉ ✅ (vrai logo PNG)
                  Container(
                    width: 110,
                    height: 110,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 20,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: Image.asset(
                        'assets/images/logo_effort.png',
                        width: 110,
                        height: 110,
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
                              Text('🎓', style: TextStyle(fontSize: 36)),
                              Text('EF-FORT', style: TextStyle(
                                color: Colors.white, fontSize: 11,
                                fontWeight: FontWeight.w900,
                              )),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'EF-FORT.BF',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Transformer l\'effort en réussite',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontSize: 15,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),

            // ── Corps principal ──
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Bloc mission
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 10,
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
                              width: 4,
                              height: 22,
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            const SizedBox(width: 10),
                            const Text(
                              'Notre Mission',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textDark,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Au Burkina Faso, se préparer aux concours ressemble trop souvent à un combat sans repères : peu de ressources fiables, peu d\'encadrement, beaucoup d\'incertitudes. Ainsi, malgré leur volonté, de nombreux candidats avancent sans méthode et peinent à transformer leurs efforts en résultats concrets.',
                          style: TextStyle(
                            fontSize: 14,
                            height: 1.7,
                            color: AppColors.textDark,
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'C\'est pour répondre à ce défi qu\'EF-Fort a été conçu.',
                          style: TextStyle(
                            fontSize: 14,
                            height: 1.7,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'En réunissant entraînement structuré, séries par matière, simulations réelles et espace d\'échange, l\'application redonne au candidat l\'essentiel : une direction claire, une pratique régulière et la confiance nécessaire pour réussir.',
                          style: TextStyle(
                            fontSize: 14,
                            height: 1.7,
                            color: AppColors.textDark,
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'EF-Fort n\'est donc pas simplement une application, mais un véritable levier pour organiser l\'effort, renforcer la discipline et maximiser les chances de réussite.',
                          style: TextStyle(
                            fontSize: 14,
                            height: 1.7,
                            color: AppColors.textDark,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Bloc contact
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 4,
                              height: 22,
                              decoration: BoxDecoration(
                                color: AppColors.secondary,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            const SizedBox(width: 10),
                            const Text(
                              'Nous Contacter',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textDark,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Notre équipe reste disponible pour vous accompagner :',
                          style: TextStyle(fontSize: 13, color: AppColors.textLight),
                        ),
                        const SizedBox(height: 16),
                        // Email
                        GestureDetector(
                          onTap: () => _openEmail(context),
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.07),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(Icons.email_rounded, color: AppColors.primary, size: 20),
                                ),
                                const SizedBox(width: 12),
                                const Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Email', style: TextStyle(fontSize: 12, color: AppColors.textLight)),
                                      Text('effortbf2026@gmail.com', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textDark)),
                                    ],
                                  ),
                                ),
                                const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.textLight),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        // WhatsApp
                        GestureDetector(
                          onTap: () => _openWhatsApp(context),
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: const Color(0xFF25D366).withValues(alpha: 0.07),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF25D366).withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(Icons.chat_rounded, color: Color(0xFF25D366), size: 20),
                                ),
                                const SizedBox(width: 12),
                                const Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('WhatsApp', style: TextStyle(fontSize: 12, color: AppColors.textLight)),
                                      Text('+226 65 46 70 70', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textDark)),
                                    ],
                                  ),
                                ),
                                const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.textLight),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Boutons Partager et Noter
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => _shareApp(context),
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
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.secondary.withValues(alpha: 0.2),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
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

                  const SizedBox(height: 24),

                  // Citation finale
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primary.withValues(alpha: 0.05),
                          AppColors.secondary.withValues(alpha: 0.05),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.15),
                      ),
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
                        const SizedBox(height: 12),
                        Text(
                          '— EF-FORT.BF',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.textLight,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
