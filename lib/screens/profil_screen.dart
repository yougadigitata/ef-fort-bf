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
          content: Text('Demande envoyee ! Marc vous contactera sous 24h.'),
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
    final uri = Uri.parse('https://wa.me/22665467070?text=Bonjour%20Marc%2C%20je%20souhaite%20m%27abonner%20%C3%A0%20EF-FORT.BF');
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
                const SizedBox(height: 16),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.secondaryLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.phone_android_rounded, color: AppColors.secondary, size: 20),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Orange Money : *144*10*65 46 70 70*12000#\nMoov Money : *555*10*65 46 70 70*12000#',
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
                'A propos d\'EF-FORT.BF',
                'Version 2.0 | Marc LOMPO',
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
            const Text('Moyen de paiement', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.phone_android, color: Colors.orange),
              ),
              title: const Text('Orange Money', style: TextStyle(fontWeight: FontWeight.w600)),
              subtitle: const Text('*144*10*65 46 70 70*12000#'),
              onTap: () {
                Navigator.pop(ctx);
                _demanderAbonnement('Orange Money');
              },
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.phone_android, color: Colors.blue),
              ),
              title: const Text('Moov Money', style: TextStyle(fontWeight: FontWeight.w600)),
              subtitle: const Text('*555*10*65 46 70 70*12000#'),
              onTap: () {
                Navigator.pop(ctx);
                _demanderAbonnement('Moov Money');
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const LogoWidget(size: 100, borderRadius: 20),
            const SizedBox(height: 16),
            const Text('EF-FORT.BF v2.0', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            const Text('Concours Directs', style: TextStyle(fontSize: 14, color: AppColors.secondary, fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            Text(
              'Plateforme de preparation aux concours directs de la Fonction Publique du Burkina Faso.\n\nProprietaire : Marc LOMPO\nWhatsApp : +226 65 46 70 70',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: AppColors.textLight, height: 1.5),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Fermer')),
        ],
      ),
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
