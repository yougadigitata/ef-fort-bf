import 'dart:async';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/theme/app_colors.dart';
import '../services/api_service.dart';

// ═══════════════════════════════════════════════════════════════════
// ABONNEMENT SCREEN v5.0 — PAGE DE VENTE PREMIUM
// Design : Urgence, valeur, preuves sociales, CTA fort
// ═══════════════════════════════════════════════════════════════════
class AbonnementScreen extends StatefulWidget {
  const AbonnementScreen({super.key});

  @override
  State<AbonnementScreen> createState() => _AbonnementScreenState();
}

class _AbonnementScreenState extends State<AbonnementScreen>
    with SingleTickerProviderStateMixin {
  bool _showFormDemande = false;
  bool _submitting = false;
  final String _moyenPaiement = 'Orange Money';
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 1.0, end: 1.04).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  void _launchWhatsAppPreuve() async {
    final uri = Uri.parse(
        'https://wa.me/22665467070?text=Bonjour%20EF-FORT.BF%2C%20j%27ai%20effectu%C3%A9%20le%20paiement%20de%2012%20000%20FCFA%20via%20Orange%20Money.%20Je%20vous%20envoie%20la%20capture%20de%20confirmation.');
    if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  void _launchWhatsAppAutre() async {
    final uri = Uri.parse(
        'https://wa.me/22665467070?text=Bonjour%2C%20je%20souhaite%20m%27abonner%20%C3%A0%20EF-FORT.BF%20et%20j%27ai%20une%20question%20sur%20le%20paiement.');
    if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  void _launchUSSD() async {
    final uri = Uri.parse('tel:*144*10*65467070*12000%23');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Composez : *144*10*65467070*12000# sur Orange Money'),
            backgroundColor: Color(0xFFFF7900),
            duration: Duration(seconds: 5),
          ),
        );
      }
    }
  }

  Future<void> _soumettreDemande() async {
    setState(() => _submitting = true);
    final result = await ApiService.demanderAbonnement(_moyenPaiement);
    if (mounted) {
      setState(() { _submitting = false; _showFormDemande = false; });
      if (result['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Demande envoyée ! Notre équipe va vous contacter très prochainement.'),
            backgroundColor: AppColors.success,
            duration: Duration(seconds: 5),
          ),
        );
      } else if (result['pending'] == true) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Row(children: [Text('⌛', style: TextStyle(fontSize: 24)), SizedBox(width: 10), Text('Demande en cours', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700))]),
            content: const Text('Votre demande est déjà en cours de traitement.\nNotre équipe vous contacte très prochainement.', style: TextStyle(height: 1.5, fontSize: 14)),
            actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700)))],
          ),
        );
      } else if (result['already_subscribed'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Votre abonnement est déjà actif !'), backgroundColor: AppColors.success));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result['error'] ?? 'Erreur lors de l\'envoi'), backgroundColor: AppColors.error));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAbonne = ApiService.isAbonne;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // ══════════════════════════════════════════════
            // HERO : Gradient fort, accroche émotionnelle
            // ══════════════════════════════════════════════
            Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF0D3B22), Color(0xFF1A5C38), Color(0xFF2E8B57)],
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: Column(
                  children: [
                    // Barre de navigation
                    Padding(
                      padding: const EdgeInsets.fromLTRB(8, 4, 16, 0),
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                            onPressed: () => Navigator.pop(context),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                            decoration: BoxDecoration(
                              color: Colors.red.withValues(alpha: 0.85),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.local_fire_department_rounded, color: Colors.white, size: 14),
                                SizedBox(width: 4),
                                Text('OFFRE LIMITÉE', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w900)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Titre accroche
                    const Padding(
                      padding: EdgeInsets.fromLTRB(24, 8, 24, 0),
                      child: Column(
                        children: [
                          Text('🏆', style: TextStyle(fontSize: 52)),
                          SizedBox(height: 12),
                          Text(
                            'DEVENEZ IRRÉSISTIBLE\nAUX YEUX DU JURY',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              height: 1.15,
                              letterSpacing: 0.5,
                            ),
                          ),
                          SizedBox(height: 10),
                          Text(
                            'Les candidats EF-FORT.BF arrivent PRÉPARÉS.\nIls connaissent les questions. Ils maîtrisent les matières.\nIls réussissent là où les autres échouent.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.white70,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Chiffres clés
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                      child: Row(
                        children: [
                          _statBubble('20 000+', 'QCM disponibles'),
                          _statBubble('18', 'Matières'),
                          _statBubble('∞', 'Simulations'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),

            // ══════════════════════════════════════════════
            // CARD PRIX — La plus grosse accroche
            // ══════════════════════════════════════════════
            Padding(
              padding: const EdgeInsets.fromLTRB(16, -16, 16, 0),
              child: ScaleTransition(
                scale: _pulseAnim,
                child: Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: const Color(0xFFD4A017), width: 2.5),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFD4A017).withValues(alpha: 0.3),
                        blurRadius: 25,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('⭐', style: TextStyle(fontSize: 18)),
                          SizedBox(width: 8),
                          Text('ACCÈS COMPLET EF-FORT.BF', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Color(0xFF1A5C38))),
                          SizedBox(width: 8),
                          Text('⭐', style: TextStyle(fontSize: 18)),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Prix GROS et GRAS
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          const Text(
                            '25 000',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.red,
                              decoration: TextDecoration.lineThrough,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFFD4A017).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFFD4A017), width: 2),
                            ),
                            child: const Text(
                              '12 000 FCFA',
                              style: TextStyle(
                                fontSize: 36,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFFD4A017),
                                letterSpacing: -0.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.success.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          '🔥 Offre spéciale valable jusqu\'au 3 mai 2026 — Ne ratez pas cette chance !',
                          style: TextStyle(fontSize: 12, color: AppColors.success, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // ── Compte à rebours offre limitée ────────────────────
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: OffreCountdownWidget(),
            ),

            const SizedBox(height: 24),
            // ══════════════════════════════════════════════
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 12, offset: const Offset(0, 4))],
                ),
                child: Column(
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
                          child: const Icon(Icons.star_rounded, color: AppColors.primary, size: 22),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Ce que vous obtenez',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.textDark),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ..._buildAvantagesPremium(),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // ══════════════════════════════════════════════
            // PUISSANCE DES PDF — Argument killer
            // ══════════════════════════════════════════════
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1A5C38), Color(0xFF2E8B57)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Text('📚', style: TextStyle(fontSize: 28)),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Jusqu\'à 10 000 copies PDF !',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Chaque question traitée génère une copie PDF avec :',
                      style: TextStyle(fontSize: 13, color: Colors.white70, height: 1.4),
                    ),
                    const SizedBox(height: 10),
                    ...[
                      'La question et toutes les options',
                      'La bonne réponse en surbrillance',
                      'Une explication détaillée de la réponse',
                      'Votre score et vos performances',
                      'Référence aux matières et chapitres',
                    ].map((item) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 20, height: 20,
                            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), shape: BoxShape.circle),
                            child: const Center(child: Text('✓', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w900))),
                          ),
                          const SizedBox(width: 8),
                          Expanded(child: Text(item, style: const TextStyle(fontSize: 13, color: Colors.white, height: 1.4))),
                        ],
                      ),
                    )),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text(
                        '💡 Ces PDF deviennent votre bibliothèque personnelle ! Révisez même hors connexion, partagez-les, imprimez-les.',
                        style: TextStyle(fontSize: 12, color: Colors.white, height: 1.5, fontStyle: FontStyle.italic),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // ══════════════════════════════════════════════
            // PREUVES SOCIALES
            // ══════════════════════════════════════════════
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 3))],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Text('💬', style: TextStyle(fontSize: 24)),
                        SizedBox(width: 10),
                        Text('Ils ont réussi avec EF-FORT.BF', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textDark)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ..._buildTemoignages(),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // ══════════════════════════════════════════════
            // INSTRUCTIONS PAIEMENT — Simple et clair
            // ══════════════════════════════════════════════
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFFF7900).withValues(alpha: 0.3)),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Text('📋', style: TextStyle(fontSize: 22)),
                        SizedBox(width: 10),
                        Text('Comment s\'abonner ?', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: AppColors.textDark)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _etapeSimple('1', 'Envoyez 12 000 FCFA via Orange Money', 'Numéro : 65 46 70 70\nCode USSD : *144*10*65467070*12000#', const Color(0xFFFF7900),
                      action: ElevatedButton.icon(
                        onPressed: _launchUSSD,
                        icon: const Text('📱', style: TextStyle(fontSize: 16)),
                        label: const Text('COMPOSER LE CODE USSD'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF7900),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _etapeSimple('2', 'Envoyez la capture WhatsApp', 'Photographiez la confirmation et envoyez-la à notre équipe sur WhatsApp', const Color(0xFF25D366),
                      action: ElevatedButton.icon(
                        onPressed: _launchWhatsAppPreuve,
                        icon: const Text('📲', style: TextStyle(fontSize: 16)),
                        label: const Text('J\'AI PAYÉ — ENVOYER LA PREUVE'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF25D366),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _etapeSimple('3', 'Activation sous 24h max', 'Notre équipe vérifie votre paiement et active votre accès', AppColors.primary),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // ══════════════════════════════════════════════
            // CTA PRINCIPAL — Bouton d'abonnement
            // ══════════════════════════════════════════════
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  // Bouton principal WhatsApp
                  SizedBox(
                    width: double.infinity,
                    height: 60,
                    child: ElevatedButton(
                      onPressed: _launchWhatsAppPreuve,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF25D366),
                        foregroundColor: Colors.white,
                        elevation: 8,
                        shadowColor: const Color(0xFF25D366).withValues(alpha: 0.5),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('📲', style: TextStyle(fontSize: 22)),
                          SizedBox(width: 10),
                          Text(
                            'J\'AI PAYÉ — ENVOYER LA PREUVE',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, letterSpacing: 0.3),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Bouton secondaire "J'ai déjà payé"
                  if (!isAbonne) ...[
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () => setState(() => _showFormDemande = !_showFormDemande),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          side: const BorderSide(color: AppColors.primary, width: 1.5),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        child: const Text(
                          "J'AI DÉJÀ PAYÉ — SOUMETTRE MA DEMANDE",
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                    if (_showFormDemande) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Moyen de paiement :', style: TextStyle(fontWeight: FontWeight.w600)),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFF7900).withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: const Color(0xFFFF7900).withValues(alpha: 0.3)),
                              ),
                              child: const Row(
                                children: [
                                  Text('🟠', style: TextStyle(fontSize: 20)),
                                  SizedBox(width: 10),
                                  Text('Orange Money', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: Color(0xFFFF7900))),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _submitting ? null : _soumettreDemande,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                ),
                                child: _submitting
                                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                    : const Text('ENVOYER MA DEMANDE', style: TextStyle(fontWeight: FontWeight.w700)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Autre moyen de paiement
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: GestureDetector(
                onTap: _launchWhatsAppAutre,
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF25D366).withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF25D366).withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Text('💬', style: TextStyle(fontSize: 20)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Autre moyen de paiement ?', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.textDark)),
                            Text('Contactez notre équipe WhatsApp.', style: TextStyle(fontSize: 12, color: AppColors.textLight)),
                          ],
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Color(0xFF25D366)),
                    ],
                  ),
                ),
              ),
            ),

            // Badge sécurité
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.12)),
                ),
                child: Row(
                  children: [
                    const Text('🛡️', style: TextStyle(fontSize: 22)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Paiement 100% sécurisé via Orange Money. Chaque transaction est vérifiée manuellement par notre équipe avant activation.',
                        style: TextStyle(fontSize: 11.5, color: AppColors.textDark, height: 1.5),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _statBubble(String valeur, String label) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Text(valeur, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFFD4A017))),
            const SizedBox(height: 2),
            Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 10, color: Colors.white70, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildAvantagesPremium() {
    final items = [
      {'icon': '📚', 'titre': '20 000+ QCM Réels de Concours', 'desc': 'QCM tirés des vrais sujets 2019–2026 avec corrections détaillées. Mis à jour en permanence par l\'admin.'},
      {'icon': '💡', 'titre': 'Maîtrisez l\'Informatique', 'desc': 'Si vous ne maîtrisez pas l\'info, notre bibliothèque de QCM vous y amène pas à pas. Concours et compétences réelles.'},
      {'icon': '🗣️', 'titre': 'Progressez en Anglais', 'desc': 'Des séries d\'anglais adaptées au niveau des concours burkinabè. Vocabulaire, grammaire et compréhension.'},
      {'icon': '📢', 'titre': 'Maîtrisez la Communication', 'desc': 'Apprenez les techniques de communication pour impressionner le jury et briller dans votre futur poste.'},
      {'icon': '🎯', 'titre': 'Simulations Illimitées', 'desc': 'Entraînez-vous dans les conditions réelles : 50 questions, 1h30, barème officiel. Autant de fois que vous voulez.'},
      {'icon': '📄', 'titre': '10 000+ Copies PDF Imprimables', 'desc': 'Chaque QCM traité génère un PDF avec corrections. Imprimez, partagez, révisez partout, même sans internet.'},
      {'icon': '🤝', 'titre': 'Communauté Active & Entraide', 'desc': 'Des milliers de candidats s\'entraident. Posez vos questions, obtenez des réponses. Vous n\'êtes jamais seul.'},
      {'icon': '📰', 'titre': 'Actualités Concours en Temps Réel', 'desc': 'Ne ratez AUCUNE ouverture de concours, AUCUNE date limite, AUCUNE opportunité au Burkina Faso.'},
      {'icon': '💰', 'titre': 'Paiement Unique — Offre Limitée', 'desc': '🔥 Payez 12 000 FCFA (au lieu de 25 000 FCFA) UNE SEULE FOIS. Offre valable jusqu\'au 3 mai 2026 uniquement !'},
    ];
    return items.map((item) {
      final icon = item['icon'] ?? item['icon'];
      final titre = (item['titre'] ?? item['  titre'] ?? '').trim();
      final desc = item['desc'] ?? '';
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(child: Text(icon!, style: const TextStyle(fontSize: 20))),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(titre, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textDark)),
                  const SizedBox(height: 2),
                  Text(desc, style: const TextStyle(fontSize: 12, color: AppColors.textLight, height: 1.4)),
                ],
              ),
            ),
            const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 20),
          ],
        ),
      );
    }).toList();
  }

  List<Widget> _buildTemoignages() {
    final temoignages = [
      {'nom': 'Fatoumata K.', 'ville': 'Ouagadougou', 'texte': 'Admise au concours d\'Infirmier d\'État ! Les simulations d\'EF-FORT.BF m\'ont préparée comme aucun autre outil. Je recommande à 100%.', 'note': '⭐⭐⭐⭐⭐'},
      {'nom': 'Ibrahim T.', 'ville': 'Bobo-Dioulasso', 'texte': 'J\'ai téléchargé plus de 600 PDFs pour réviser en brousse sans réseau. Admis à la Douane du Burkina. Merci EF-FORT.BF !', 'note': '⭐⭐⭐⭐⭐'},
      {'nom': 'Mariam S.', 'ville': 'Koudougou', 'texte': 'Ce qui m\'a surpris, c\'est la qualité des QCM d\'anglais et d\'informatique. J\'ai vraiment progressé dans ces matières !', 'note': '⭐⭐⭐⭐⭐'},
      {'nom': 'Serge B.', 'ville': 'Fada N\'Gourma', 'texte': 'La communauté m\'a aidé à comprendre des questions complexes de droit. On progresse vraiment ensemble ici.', 'note': '⭐⭐⭐⭐⭐'},
    ];
    return temoignages.map((t) => Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    t['nom']![0],
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.primary),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(t['nom']!, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textDark)),
                  Text('📍 ${t['ville'] ?? 'Burkina Faso'}  ${t['note']!}', style: const TextStyle(fontSize: 11)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '"${t['texte']}"',
            style: const TextStyle(fontSize: 12.5, color: AppColors.textDark, height: 1.5, fontStyle: FontStyle.italic),
          ),
        ],
      ),
    )).toList();
  }

  Widget _etapeSimple(String num, String titre, String description, Color color, {Widget? action}) {
    return Container(
      padding: const EdgeInsets.all(14),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.2)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34, height: 34,
            decoration: BoxDecoration(color: color.withValues(alpha: 0.15), shape: BoxShape.circle),
            child: Center(child: Text(num, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: color))),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(titre, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: AppColors.textDark)),
                const SizedBox(height: 3),
                Text(description, style: const TextStyle(fontSize: 11.5, color: AppColors.textLight, height: 1.4)),
                if (action != null) ...[const SizedBox(height: 10), action],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════
// WIDGET COMPTE À REBOURS — Offre valable jusqu'au 3 mai 2026
// ══════════════════════════════════════════════════════════
class OffreCountdownWidget extends StatefulWidget {
  const OffreCountdownWidget({super.key});

  @override
  State<OffreCountdownWidget> createState() => _OffreCountdownWidgetState();
}

class _OffreCountdownWidgetState extends State<OffreCountdownWidget> {
  Timer? _timer;
  Duration _remaining = Duration.zero;
  // Date limite : 3 mai 2026 à minuit
  static final DateTime _deadline = DateTime(2026, 5, 3, 23, 59, 59);

  @override
  void initState() {
    super.initState();
    _updateRemaining();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _updateRemaining());
  }

  void _updateRemaining() {
    final now = DateTime.now();
    final diff = _deadline.difference(now);
    if (mounted) setState(() => _remaining = diff.isNegative ? Duration.zero : diff);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _twoDigits(int n) => n.toString().padLeft(2, '0');

  @override
  Widget build(BuildContext context) {
    final days = _remaining.inDays;
    final hours = _remaining.inHours % 24;
    final minutes = _remaining.inMinutes % 60;
    final seconds = _remaining.inSeconds % 60;
    final expired = _remaining == Duration.zero;

    if (expired) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.red.shade200)),
        child: const Text('⏰ Offre expirée', style: TextStyle(color: Colors.red, fontWeight: FontWeight.w700, fontSize: 14), textAlign: TextAlign.center),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF7B0D0D), Color(0xFFCE1126)]),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.red.withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          const Text(
            '⏰ OFFRE LIMITÉE — EXPIRE DANS :',
            style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.0),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _countUnit(days.toString(), 'JOURS'),
              _separator(),
              _countUnit(_twoDigits(hours), 'HEURES'),
              _separator(),
              _countUnit(_twoDigits(minutes), 'MIN'),
              _separator(),
              _countUnit(_twoDigits(seconds), 'SEC'),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(20)),
            child: const Text(
              '🔥 12 000 FCFA au lieu de 25 000 FCFA — Économisez 13 000 FCFA !',
              style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _countUnit(String value, String label) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
          child: Text(value, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900, fontFamily: 'monospace')),
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: Colors.white60, fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
      ],
    );
  }

  Widget _separator() => const Text(':', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900));
}
