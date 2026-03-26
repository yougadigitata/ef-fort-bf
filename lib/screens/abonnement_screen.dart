import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/theme/app_colors.dart';
import '../services/api_service.dart';

class AbonnementScreen extends StatefulWidget {
  const AbonnementScreen({super.key});

  @override
  State<AbonnementScreen> createState() => _AbonnementScreenState();
}

class _AbonnementScreenState extends State<AbonnementScreen> {
  bool _showFormDemande = false;
  bool _submitting = false;
  String _moyenPaiement = 'Orange Money';

  void _launchWhatsApp() async {
    final uri = Uri.parse(
        'https://wa.me/22665467070?text=Bonjour%20EF-FORT%2C%20je%20veux%20m%27abonner%20pour%2012%20000%20FCFA');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _launchUSSD() async {
    // Orange Money BF : *144*10*65467070*12000#
    final uri = Uri.parse('tel:*144*10*65467070*12000%23');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Composez manuellement : *144*10*65467070*12000# sur Orange Money'),
            backgroundColor: AppColors.primary,
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
      setState(() {
        _submitting = false;
        _showFormDemande = false;
      });
      if (result['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                '✅ Demande envoyée ! Notre équipe activera votre accès rapidement.'),
            backgroundColor: AppColors.success,
            duration: Duration(seconds: 4),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                result['error'] ?? 'Erreur lors de l\'envoi de la demande'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAbonne = ApiService.isAbonne;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // ─── HERO SECTION ──────────────────────────────────────────
            Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [AppColors.primary, AppColors.primaryDark],
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_back_rounded,
                                color: AppColors.white),
                            onPressed: () => Navigator.pop(context),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFD4A017).withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                  color: const Color(0xFFD4A017)
                                      .withValues(alpha: 0.5)),
                            ),
                            child: const Text(
                              'OFFRE SPÉCIALE',
                              style: TextStyle(
                                color: Color(0xFFD4A017),
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Icône trophée 3D
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppColors.white.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Text('🏆',
                            style: TextStyle(fontSize: 56)),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Devenez un Champion\ndes Concours',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          color: AppColors.white,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Rejoignez des centaines de candidats\nqui se préparent avec EF-FORT.BF',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 15,
                          color: AppColors.white.withValues(alpha: 0.85),
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // ─── CARD PRIX ─────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, -20, 20, 0),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                      color: const Color(0xFFD4A017).withValues(alpha: 0.4),
                      width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFD4A017).withValues(alpha: 0.2),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('⭐', style: TextStyle(fontSize: 20)),
                        SizedBox(width: 8),
                        Text(
                          'ACCÈS COMPLET EF-FORT',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textDark,
                          ),
                        ),
                        SizedBox(width: 8),
                        Text('⭐', style: TextStyle(fontSize: 20)),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Prix barré + prix actuel
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        const Text(
                          '15 000 FCFA',
                          style: TextStyle(
                            fontSize: 16,
                            color: AppColors.error,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          '12 000 FCFA',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFFD4A017),
                          ),
                        ),
                      ],
                    ),
                    const Text(
                      'Offre promotionnelle',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.success,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.access_time_rounded,
                            size: 14, color: AppColors.textLight),
                        const SizedBox(width: 4),
                        Text(
                          'Valable jusqu\'au 31 décembre 2028',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textLight,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    const Divider(),
                    const SizedBox(height: 12),

                    // Avantages
                    ..._buildAvantages(),
                  ],
                ),
              ),
            ),

            // ─── INSTRUCTIONS DE PAIEMENT ────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '📋 Comment payer ?',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildEtape(
                    '①',
                    'Envoyez 12 000 FCFA via Orange Money',
                    'Numéro : 65 46 70 70\nCode : *144*10*65467070*12000#',
                    const Color(0xFFFF7900),
                    action: ElevatedButton.icon(
                      onPressed: _launchUSSD,
                      icon: const Text('📱', style: TextStyle(fontSize: 16)),
                      label: const Text('COMPOSER LE CODE'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF7900),
                        foregroundColor: AppColors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildEtape(
                    '②',
                    'Envoyez la capture sur WhatsApp',
                    'Envoyez la preuve de paiement à notre équipe',
                    const Color(0xFF25D366),
                    action: ElevatedButton.icon(
                      onPressed: _launchWhatsApp,
                      icon: const Text('📲', style: TextStyle(fontSize: 16)),
                      label: const Text('ENVOYER SUR WHATSAPP'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF25D366),
                        foregroundColor: AppColors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildEtape(
                    '③',
                    'Attendez l\'activation',
                    '⏱️ Activation en moins de 24h après vérification',
                    AppColors.primary,
                  ),
                ],
              ),
            ),

            // ─── BOUTON PRINCIPAL ──────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: _launchWhatsApp,
                  icon: const Text('📲', style: TextStyle(fontSize: 22)),
                  label: const Text(
                    'CONTACTER L\'ÉQUIPE SUR WHATSAPP',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF25D366),
                    foregroundColor: AppColors.white,
                    elevation: 6,
                    shadowColor: const Color(0xFF25D366).withValues(alpha: 0.4),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ),
            ),

            // Bouton "J'ai déjà payé"
            if (!isAbonne) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () =>
                        setState(() => _showFormDemande = !_showFormDemande),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: AppColors.primary),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    child: const Text(
                      "J'AI DÉJÀ PAYÉ — SOUMETTRE MA DEMANDE",
                      style:
                          TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ),
              if (_showFormDemande) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(16),
                      border:
                          Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Moyen de paiement utilisé :',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          initialValue: _moyenPaiement,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10)),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                          ),
                          items: const [
                            DropdownMenuItem(
                                value: 'Orange Money',
                                child: Text('🟠 Orange Money')),
                            DropdownMenuItem(
                                value: 'Moov Money',
                                child: Text('🔵 Moov Money')),
                            DropdownMenuItem(
                                value: 'Virement',
                                child: Text('🏦 Virement bancaire')),
                          ],
                          onChanged: (v) =>
                              setState(() => _moyenPaiement = v!),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _submitting ? null : _soumettreDemande,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: AppColors.white,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10)),
                            ),
                            child: _submitting
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                        color: AppColors.white, strokeWidth: 2),
                                  )
                                : const Text(
                                    'ENVOYER MA DEMANDE',
                                    style: TextStyle(fontWeight: FontWeight.w700),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],

            // ─── MESSAGE SÉCURITÉ ─────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(14),
                  border:
                      Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
                ),
                child: Row(
                  children: [
                    const Text('🛡️', style: TextStyle(fontSize: 24)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Pour garantir la sécurité de chaque transaction, notre équipe vérifie manuellement chaque paiement. Votre accès est activé rapidement après validation.',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textDark,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Autre moyen de paiement
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: GestureDetector(
                onTap: _launchWhatsApp,
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF25D366).withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: const Color(0xFF25D366).withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Text('💬', style: TextStyle(fontSize: 20)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Vous souhaitez payer autrement (Moov Money, virement) ? Contactez notre équipe sur WhatsApp',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textDark,
                            height: 1.4,
                          ),
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios_rounded,
                          size: 14, color: Color(0xFF25D366)),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildAvantages() {
    final items = [
      'Toutes les matières débloquées',
      'Séries illimitées par matière',
      'Simulations d\'examen illimitées',
      'Copies corrigées téléchargeables en PDF',
      'Documents officiels partagés',
      'Espace entraide communautaire',
      'Accès complet jusqu\'au 31/12/2028',
    ];
    return items
        .map(
          (item) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: const BoxDecoration(
                    color: Color(0xFF1A5C38),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Text('✓',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w800)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    item,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textDark,
                      height: 1.3,
                    ),
                  ),
                ),
              ],
            ),
          ),
        )
        .toList();
  }

  Widget _buildEtape(
    String numero,
    String titre,
    String description,
    Color color, {
    Widget? action,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
              border: Border.all(color: color.withValues(alpha: 0.3)),
            ),
            child: Center(
              child: Text(
                numero,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: color,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titre,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textLight,
                    height: 1.4,
                  ),
                ),
                if (action != null) ...[
                  const SizedBox(height: 10),
                  action,
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
