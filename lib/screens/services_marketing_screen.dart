import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/theme/app_colors.dart';

// ══════════════════════════════════════════════════════════════
// SERVICES MARKETING SCREEN — Youga Digital Services
// Marc LOMPO — Consultant Digital & Formateur
// ══════════════════════════════════════════════════════════════

class ServicesMarketingScreen extends StatelessWidget {
  const ServicesMarketingScreen({super.key});

  static const String _whatsappUrl =
      'https://wa.me/22672662161?text=Bonjour%20Marc%2C%20je%20vous%20contacte%20depuis%20EF-FORT.BF%20pour%20en%20savoir%20plus%20sur%20vos%20services.';

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          // ── Hero section ──
          _buildHeroSection(context),

          // ── Services ──
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Titre services ──
                const SizedBox(height: 8),
                const Center(
                  child: Text(
                    '🚀 Mes Services',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: AppColors.textDark,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                const Center(
                  child: Text(
                    'Professionnel du digital à votre service',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textLight,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // ── Grille de services ──
                _buildServiceCard(
                  context,
                  emoji: '🎯',
                  titre: 'Stratégie Digitale & Identité de Marque',
                  description:
                      'Définition de votre présence en ligne, création de votre identité visuelle, stratégie de communication digitale adaptée à l\'Afrique.',
                  color: AppColors.primary,
                ),
                _buildServiceCard(
                  context,
                  emoji: '📱',
                  titre: 'Création d\'Applications & Logiciels',
                  description:
                      'Développement d\'applications mobiles (Android, iOS), web apps, logiciels de gestion sur mesure pour vos besoins spécifiques.',
                  color: Colors.blue.shade700,
                ),
                _buildServiceCard(
                  context,
                  emoji: '🔐',
                  titre: 'Cybersécurité & Protection des Données',
                  description:
                      'Audit de sécurité, mise en conformité RGPD, formation à la cybersécurité, protection de vos systèmes informatiques.',
                  color: Colors.red.shade700,
                ),
                _buildServiceCard(
                  context,
                  emoji: '🎮',
                  titre: 'Développement de Jeux Vidéo & Gamification',
                  description:
                      'Conception de jeux éducatifs, gamification de vos plateformes e-learning, serious games pour la formation professionnelle.',
                  color: Colors.purple.shade700,
                ),
                _buildServiceCard(
                  context,
                  emoji: '📣',
                  titre: 'Gestion des Réseaux Sociaux',
                  description:
                      'Community management, création de contenu, campagnes publicitaires Facebook/Instagram/TikTok, croissance organique.',
                  color: Colors.orange.shade700,
                ),
                _buildServiceCard(
                  context,
                  emoji: '🏫',
                  titre: 'Formation & Coaching Privé',
                  description:
                      'Formations en présentiel et en ligne sur l\'informatique, le digital et la cybersécurité. Coaching personnalisé pour entrepreneurs.',
                  color: AppColors.secondary,
                ),

                const SizedBox(height: 24),

                // ── Boutons CTA ──
                _buildCtaSection(context),

                const SizedBox(height: 24),

                // ── Citation / Valeurs ──
                _buildQuoteSection(),

                const SizedBox(height: 24),

                // ── Témoignages ──
                _buildTestimonialsSection(),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Hero Section avec photo / avatar ────────────────────────────
  Widget _buildHeroSection(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1A5C38), Color(0xFF0F3D26)],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 30, 24, 30),
          child: Column(
            children: [
              // Avatar / Photo
              Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.secondary, width: 4),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.secondary.withValues(alpha: 0.4),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(55),
                  child: Container(
                    color: const Color(0xFF2D8F5E),
                    child: const Center(
                      child: Text(
                        'ML',
                        style: TextStyle(
                          fontSize: 40,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Nom
              const Text(
                'Marc LOMPO',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 6),

              // Titre
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.secondary.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.secondary.withValues(alpha: 0.5)),
                ),
                child: const Text(
                  'Consultant Digital · Formateur · Développeur',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.secondary,
                    fontWeight: FontWeight.w700,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 20),

              // Slogans
              const Text(
                '« Susciter l\'envie de comprendre la technologie »',
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.white,
                  fontStyle: FontStyle.italic,
                  fontWeight: FontWeight.w500,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Faciliter la technologie pour tous,\nnotamment pour les jeunes Africains.',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withValues(alpha: 0.8),
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),

              // Mini description
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                ),
                child: Text(
                  'Je m\'appelle Marc LOMPO, consultant en stratégie digitale, '
                  'cybersécurité et formateur basé au Burkina Faso. '
                  'Je vous accompagne dans vos projets digitaux avec passion '
                  'et expertise pour que la technologie soit accessible à tous.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withValues(alpha: 0.9),
                    height: 1.6,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

              const SizedBox(height: 20),

              // Bouton WhatsApp principal
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton.icon(
              onPressed: () => launchUrl(Uri.parse(_whatsappUrl), mode: LaunchMode.externalApplication),
              icon: const Text('💬', style: TextStyle(fontSize: 20)),
                  label: const Text(
                    'Contacter sur WhatsApp',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF25D366),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 4,
                  ),
                ),
              ),

              const SizedBox(height: 8),
              Text(
                '+226 72 66 21 61',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.white.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Card de service ─────────────────────────────────────────────
  Widget _buildServiceCard(
    BuildContext context, {
    required String emoji,
    required String titre,
    required String description,
    required Color color,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
          child: InkWell(
                  onTap: () => launchUrl(Uri.parse(_whatsappUrl), mode: LaunchMode.externalApplication),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icône
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: color.withValues(alpha: 0.3)),
                  ),
                  child: Center(
                    child: Text(emoji, style: const TextStyle(fontSize: 24)),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        titre,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: color,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        description,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textLight,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Text(
                            'En savoir plus →',
                            style: TextStyle(
                              fontSize: 13,
                              color: color,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Section CTA ─────────────────────────────────────────────────
  Widget _buildCtaSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFD4A017), Color(0xFFB8860B)],
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFD4A017).withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            '🤝 Travaillons ensemble !',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Un projet ? Une idée ? Une formation ?\nContactez-moi, je vous répondrai rapidement.',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),

          // Bouton WhatsApp
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: () => launchUrl(Uri.parse(_whatsappUrl), mode: LaunchMode.externalApplication),
              icon: const Text('💬', style: TextStyle(fontSize: 22)),
              label: const Text(
                'Démarrer sur WhatsApp',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF25D366),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 3,
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Bouton formations
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton.icon(
              onPressed: () => launchUrl(Uri.parse('https://wa.me/22672662161?text=Bonjour%20Marc%2C%20je%20voudrais%20en%20savoir%20plus%20sur%20vos%20formations.'), mode: LaunchMode.externalApplication),
              icon: const Text('🏫', style: TextStyle(fontSize: 18)),
              label: const Text(
                'Voir les formations disponibles',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: const BorderSide(color: Colors.white, width: 1.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Citation ────────────────────────────────────────────────────
  Widget _buildQuoteSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          const Text(
            '"',
            style: TextStyle(
              fontSize: 48,
              color: AppColors.primary,
              height: 0.8,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'La technologie n\'est pas seulement pour les experts. '
            'Ma mission est de la rendre accessible à chaque Africain, '
            'chaque entrepreneur, chaque jeune qui veut bâtir quelque chose de grand.',
            style: TextStyle(
              fontSize: 15,
              color: AppColors.primary,
              fontStyle: FontStyle.italic,
              height: 1.6,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          const Text(
            '— Marc LOMPO',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: AppColors.primary,
            ),
          ),
          const Text(
            'Youga Digital Services',
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textLight,
            ),
          ),
        ],
      ),
    );
  }

  // ── Témoignages ─────────────────────────────────────────────────
  Widget _buildTestimonialsSection() {
    final temoignages = [
      {
        'nom': 'Aminata K.',
        'role': 'Entrepreneur, Ouagadougou',
        'texte': 'Marc m\'a aidé à créer mon application mobile en un temps record. '
            'Son expertise et sa disponibilité sont remarquables !',
        'note': 5,
      },
      {
        'nom': 'Ibrahim T.',
        'role': 'Chef d\'entreprise',
        'texte': 'La formation en cybersécurité a vraiment transformé notre façon '
            'de gérer nos données. Très professionnel !',
        'note': 5,
      },
      {
        'nom': 'Fatima S.',
        'role': 'Étudiante, Bobo-Dioulasso',
        'texte': 'EF-FORT.BF créé par Youga Digital m\'a permis de me préparer '
            'efficacement aux concours. Merci beaucoup !',
        'note': 5,
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Text('⭐ ', style: TextStyle(fontSize: 20)),
            Text(
              'Ce que disent nos clients',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.textDark,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        ...temoignages.map((t) => _buildTemoignageCard(
              nom: t['nom'] as String,
              role: t['role'] as String,
              texte: t['texte'] as String,
              note: t['note'] as int,
            )),
      ],
    );
  }

  Widget _buildTemoignageCard({
    required String nom,
    required String role,
    required String texte,
    required int note,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.secondary.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary.withValues(alpha: 0.1),
                ),
                child: Center(
                  child: Text(
                    nom[0],
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(nom, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                    Text(role, style: const TextStyle(fontSize: 12, color: AppColors.textLight)),
                  ],
                ),
              ),
              Row(
                children: List.generate(
                  note,
                  (_) => const Text('⭐', style: TextStyle(fontSize: 12)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '"$texte"',
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textDark,
              fontStyle: FontStyle.italic,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
