import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../core/theme/app_colors.dart';
import '../services/api_service.dart';
import '../services/supabase_service.dart';
import '../services/bell_service.dart';
import '../widgets/logo_widget.dart';
import '../widgets/math_text_widget.dart';
import 'abonnement_screen.dart';

// ══════════════════════════════════════════════════════════════
// SIMULATION SCREEN v6 — MEGA PROMPT v3.0
// Slides bienvenue · Feuille 2 colonnes · Cases A-E ·
// Sons cloche Web Audio API · Consignes officielles
// ══════════════════════════════════════════════════════════════

// ── Sons cloche via BellService (multi-plateforme) ──
Future<void> _playBellAsset(String assetName) async {
  if (assetName.contains('start')) {
    await BellService.playStart();
  } else {
    await BellService.playEnd();
  }
}

// ══════════════════════════════════════════════════════════════
// ÉCRAN DE LANCEMENT SIMULATION (avec 4 slides animés - TÂCHE 9)
// ══════════════════════════════════════════════════════════════
class SimulationLaunchScreen extends StatefulWidget {
  const SimulationLaunchScreen({super.key});

  @override
  State<SimulationLaunchScreen> createState() => _SimulationLaunchScreenState();
}

class _SimulationLaunchScreenState extends State<SimulationLaunchScreen> {
  int _currentSlide = 0;
  late Timer _slideTimer;
  final PageController _pageController = PageController();

  // ── TÂCHE 9 : 4 slides animés ──
  final List<Map<String, dynamic>> _slides = [
    {
      'icon': Icons.center_focus_strong_rounded,
      'emoji': '🎯',
      'titre': '50 Questions officielles',
      'sous_titre': 'Réparties selon le type de concours choisi',
      'color': const Color(0xFF1A5C38),
    },
    {
      'icon': Icons.timer_rounded,
      'emoji': '⏱',
      'titre': '1h30 chrono',
      'sous_titre': 'Soumission impossible avant 30 minutes',
      'color': const Color(0xFF2980B9),
    },
    {
      'icon': Icons.assignment_rounded,
      'emoji': '📄',
      'titre': 'Feuille de réponse officielle',
      'sous_titre': 'Noircissez les cases comme à l\'examen réel',
      'color': const Color(0xFF8E44AD),
    },
    {
      'icon': Icons.bar_chart_rounded,
      'emoji': '📊',
      'titre': 'Correction détaillée',
      'sous_titre': 'Téléchargez votre copie corrigée après l\'examen',
      'color': const Color(0xFFD4A017),
    },
  ];

  @override
  void initState() {
    super.initState();
    _slideTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (_currentSlide < _slides.length - 1) {
        setState(() => _currentSlide++);
        _pageController.animateToPage(
          _currentSlide,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      } else {
        setState(() => _currentSlide = 0);
        _pageController.animateToPage(
          0,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _slideTimer.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Mode Examen',
          style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700),
        ),
        automaticallyImplyLeading: false,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(colors: [AppColors.primary, AppColors.primaryDark]),
          ),
        ),
        foregroundColor: AppColors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 10),
            const LogoWidget(size: 80, borderRadius: 18),
            const SizedBox(height: 16),
            const Text(
              'Simulation d\'Examen',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: AppColors.textDark,
                fontFamily: 'Poppins',
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Conditions réelles du concours',
              style: TextStyle(fontSize: 14, color: AppColors.textLight),
            ),
            const SizedBox(height: 24),

            // ── TÂCHE 9 : 4 Slides animés ──
            SizedBox(
              height: 180,
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (i) => setState(() => _currentSlide = i),
                itemCount: _slides.length,
                itemBuilder: (ctx, i) {
                  final slide = _slides[i];
                  final color = slide['color'] as Color;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [color, color.withValues(alpha: 0.75)],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: color.withValues(alpha: 0.35),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              slide['emoji'] as String,
                              style: const TextStyle(fontSize: 36),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                slide['titre'] as String,
                                style: const TextStyle(
                                  fontSize: 19,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  height: 1.2,
                                  fontFamily: 'Poppins',
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                slide['sous_titre'] as String,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.white.withValues(alpha: 0.85),
                                  height: 1.4,
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

            // Dots indicateurs
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_slides.length, (i) {
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: _currentSlide == i ? 20 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _currentSlide == i
                        ? AppColors.primary
                        : Colors.grey.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(4),
                  ),
                );
              }),
            ),

            const SizedBox(height: 24),

            // ── TÂCHE 10 : Consignes officielles sans emoji ──
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.25),
                  width: 1.5,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'CONSIGNES OFFICIELLES',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                      letterSpacing: 0.5,
                      fontFamily: 'Poppins',
                    ),
                  ),
                  const SizedBox(height: 12),
                  ..._buildConsignesOff(),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Bouton DÉMARRER — redirige vers slide bienvenue candidat
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: () {
                  // Récupérer le nom du candidat depuis l'état de connexion
                  final user = ApiService.currentUser;
                  final nom = user != null
                      ? '${user['prenom'] ?? ''} ${user['nom'] ?? ''}'.trim()
                      : 'Candidat';
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ExamWelcomeSlide(candidatName: nom),
                    ),
                  );
                },
                icon: const Icon(Icons.play_circle_filled_rounded, size: 24),
                label: const Text(
                  'DÉMARRER LA SIMULATION',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                    fontFamily: 'Poppins',
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 5,
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // ── TÂCHE 10 : Consignes sans emoji ──
  List<Widget> _buildConsignesOff() {
    final consignes = [
      'Ce questionnaire comporte 50 questions réparties en plusieurs matières.',
      'Lisez attentivement chaque question avant de répondre.',
      'Pour chaque question, une ou plusieurs réponses peuvent être exactes.',
      'Noircissez les cases correspondant à vos réponses sur la feuille de réponses.',
      'Une réponse incorrecte entraîne une pénalité de points.',
      'Il est permis de ne pas répondre à une question si vous n\'êtes pas certain.',
      'La durée de l\'épreuve est de 2 heures.',
      'Vous ne pouvez pas soumettre votre copie avant 30 minutes.',
      'Toute tentative de fraude entraîne l\'annulation de votre résultat.',
      'Bonne chance !',
    ];
    return consignes.map((c) => Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '●  ',
            style: TextStyle(fontSize: 16, color: AppColors.primary, height: 1.4),
          ),
          Expanded(
            child: Text(
              c,
              style: const TextStyle(
                fontSize: 13,
                fontFamily: 'Georgia',
                height: 1.5,
                color: AppColors.textDark,
              ),
            ),
          ),
        ],
      ),
    )).toList();
  }
}

// ══════════════════════════════════════════════════════════════
// SLIDE 1 : BIENVENUE AU CANDIDAT (MEGA PROMPT v3.0 - PHASE 1.1)
// ══════════════════════════════════════════════════════════════
class ExamWelcomeSlide extends StatefulWidget {
  final String candidatName;
  final String examenNom;
  final String? simulationAdminId;

  const ExamWelcomeSlide({
    super.key,
    required this.candidatName,
    this.examenNom = '',
    this.simulationAdminId,
  });

  @override
  State<ExamWelcomeSlide> createState() => _ExamWelcomeSlideState();
}

class _ExamWelcomeSlideState extends State<ExamWelcomeSlide>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnim;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 900),
      vsync: this,
    )..forward();
    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    _scaleAnim = Tween<double>(begin: 0.82, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.primary, AppColors.primaryDark],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo EF-FORT
                Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 20,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: const LogoWidget(size: 70, borderRadius: 16),
                ),

                const SizedBox(height: 36),

                // Texte de bienvenue animé
                FadeTransition(
                  opacity: _fadeAnim,
                  child: ScaleTransition(
                    scale: _scaleAnim,
                    child: Column(
                      children: [
                        const Text(
                          'Bienvenue',
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            fontFamily: 'Poppins',
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          widget.candidatName.isNotEmpty
                              ? widget.candidatName
                              : 'Candidat',
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFFD4A017),
                            fontFamily: 'Poppins',
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 36),

                // Message d'encouragement
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.2),
                    ),
                  ),
                  child: const Text(
                    'Vous vous apprêtez à passer une simulation d\'examen blanc.\n\n'
                    'Concentrez-vous, lisez attentivement chaque question et gérez votre temps avec intelligence.\n\n'
                    'Vous disposez de 1h30 pour répondre à 50 questions.\n\n'
                    'Bonne chance ! Vous pouvez y arriver.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white,
                      height: 1.6,
                      fontFamily: 'Georgia',
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),

                const SizedBox(height: 40),

                // Bouton Suivant
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ExamRulesSlide(
                            simulationAdminId: widget.simulationAdminId,
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.arrow_forward_rounded),
                    label: const Text(
                      'Suivant — Règles de l\'examen',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'Poppins',
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD4A017),
                      foregroundColor: AppColors.primaryDark,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      elevation: 4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// SLIDE 2 : RÈGLES ET CONSIGNES (MEGA PROMPT v3.0 - PHASE 1.2)
// ══════════════════════════════════════════════════════════════
class ExamRulesSlide extends StatelessWidget {
  final String? simulationAdminId;
  const ExamRulesSlide({super.key, this.simulationAdminId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Règles de l\'examen',
          style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700),
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
                colors: [AppColors.primary, AppColors.primaryDark]),
          ),
        ),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // En-tête
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.2)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.assignment_outlined,
                            color: AppColors.primary, size: 28),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'RÈGLES OFFICIELLES DE L\'EXAMEN BLANC',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primary,
                              fontFamily: 'Poppins',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Règles officielles
                  _buildRule('1. Durée stricte',
                      'Vous disposez de 1 heure 30 minutes (90 minutes) pour répondre aux 50 questions.'),
                  _buildRule('2. Lecture attentive',
                      'Lisez chaque question entièrement avant de noircir votre case de réponse.'),
                  _buildRule('3. Feuille de réponses OMR',
                      'Utilisez la feuille de réponses (colonne droite) pour cocher les cases A, B, C, D ou E.'),
                  _buildRule('4. Réponses multiples possibles',
                      'Certaines questions peuvent avoir plusieurs bonnes réponses. Cochez toutes les bonnes réponses.'),
                  _buildRule('5. Pénalité pour erreur',
                      'Une mauvaise réponse entraîne une pénalité. Sans réponse = 0 point, ne pénalise pas.'),
                  _buildRule('6. Minimum 30 minutes obligatoire',
                      'Vous ne pourrez soumettre votre copie qu\'après 30 minutes de composition.'),
                  _buildRule('7. Soumission automatique',
                      'À l\'expiration du temps, votre copie sera soumise automatiquement avec les réponses cochées.'),
                  _buildRule('8. Alertes de temps',
                      'Des alertes vous seront envoyées à 15 minutes et à 5 minutes restantes.'),
                  _buildRule('9. Concentration maximale',
                      'Fermez les autres applications. Cette simulation reproduit les conditions réelles du concours.'),
                  _buildRule('10. Corrigé immédiat',
                      'Après soumission, vous accédez au corrigé détaillé question par question avec explications.'),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),

          // Bouton Commencer (fixé en bas)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: () {
                  // Remplacer toute la pile : aller directement à l'examen
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                      builder: (_) => SimulationExamScreen(
                        simulationAdminId: simulationAdminId,
                      ),
                    ),
                    (route) => route.isFirst,
                  );
                },
                icon: const Icon(Icons.play_circle_filled_rounded, size: 24),
                label: const Text(
                  'COMMENCER L\'EXAMEN',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                    fontFamily: 'Poppins',
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  elevation: 5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRule(String title, String description) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: const Border(
          left: BorderSide(color: AppColors.primary, width: 4),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.textDark,
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 5),
          Text(
            description,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textLight,
              height: 1.5,
              fontFamily: 'Georgia',
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// ÉCRAN EXAMEN — INTERFACE 2 COLONNES (TÂCHE 7)
// ══════════════════════════════════════════════════════════════
class SimulationExamScreen extends StatefulWidget {
  final String? simulationAdminId;
  const SimulationExamScreen({super.key, this.simulationAdminId});
  @override
  State<SimulationExamScreen> createState() => _SimulationExamScreenState();
}

class _SimulationExamScreenState extends State<SimulationExamScreen> {
  List<dynamic> _questions = [];
  String? _sessionId;
  bool _loading = true;
  String? _error;

  // Feuille de réponses — Set de lettres par question (multi-select)
  final Map<int, Set<String>> _answers = {};

  late int _remainingSeconds;
  Timer? _timer;
  bool _finished = false;
  bool _consignesAccepted = false;
  bool _bellStartPlayed = false;

  // Scroll controllers
  final ScrollController _questionsScroll = ScrollController();
  final ScrollController _reponseScroll = ScrollController();

  static const int _minSecondsBeforeSubmit = 30 * 60;
  static const int _durationSeconds = 90 * 60; // 1h30

  // ── Admin bypass : l'admin peut soumettre à tout moment ──
  bool get _isAdminUser => ApiService.isAdmin;

  bool get _canSubmit =>
      _isAdminUser ||
      _remainingSeconds <= (_durationSeconds - _minSecondsBeforeSubmit);

  int get _secondsBeforeCanSubmit =>
      (!_isAdminUser && _remainingSeconds > (_durationSeconds - _minSecondsBeforeSubmit))
          ? _remainingSeconds - (_durationSeconds - _minSecondsBeforeSubmit)
          : 0;

  @override
  void initState() {
    super.initState();
    _remainingSeconds = _durationSeconds;
    _startSimulation();
  }

  Future<void> _startSimulation() async {
    // Si simulation admin désignée, la charger directement
    if (widget.simulationAdminId != null) {
      final result = await ApiService.demarrerSimulationAdmin(widget.simulationAdminId!);
      if (!mounted) return;
      if (result['error'] != null) {
        setState(() { _error = result['error']?.toString() ?? 'Erreur.'; _loading = false; });
        return;
      }
      final questions = (result['questions'] as List?) ?? [];
      if (questions.isEmpty) {
        setState(() { _error = 'Simulation vide. Contactez l\'administrateur.'; _loading = false; });
        return;
      }
      setState(() {
        _sessionId = result['session_id'] as String?;
        _questions = questions;
        final dureeMin = (result['duree_minutes'] ?? 90) as int;
        _remainingSeconds = dureeMin * 60;
        _loading = false;
      });
      if (mounted && !_consignesAccepted) {
        _showConsignesDialog();
      } else {
        _startTimerAndBell();
      }
      return;
    }

    // Simulation classique via API
    final result = await ApiService.demarrerSimulation();
    if (!mounted) return;
    List<dynamic> questions = (result['questions'] as List?) ?? [];
    if (result['error'] != null || questions.isEmpty) {
      final sbQuestions = await SupabaseService.getExamenBlanc50Questions();
      if (!mounted) return;
      if (sbQuestions.isNotEmpty) {
        setState(() {
          _sessionId = null;
          _questions = sbQuestions;
          _remainingSeconds = _durationSeconds;
          _loading = false;
        });
        if (mounted && !_consignesAccepted) {
          _showConsignesDialog();
        } else {
          _startTimerAndBell();
        }
        return;
      }
      if (result['error'] != null && questions.isEmpty) {
        setState(() { _error = 'Aucune question disponible. Vérifiez votre connexion.'; _loading = false; });
        return;
      }
    }
    if (!mounted) return;
    setState(() {
      _sessionId = result['session_id'] as String?;
      _questions = questions;
      final dureeMin = (result['duree'] ?? 90) as int;
      _remainingSeconds = dureeMin * 60;
      _loading = false;
    });
    if (mounted && !_consignesAccepted) {
      _showConsignesDialog();
    } else {
      _startTimerAndBell();
    }
  }

  void _startTimerAndBell() {
    // ── TÂCHE 8 : Son de démarrage (audioplayers) ──
    if (!_bellStartPlayed) {
      _bellStartPlayed = true;
      Future.delayed(const Duration(milliseconds: 500), () => _playBellAsset('bell_start.mp3'));
    }
    _startTimer();
  }

  void _playBell(double freq, double dur) {
    // Conservé pour compatibilité - utilise maintenant audioplayers
    _playBellAsset(dur > 2.0 ? 'bell_end.mp3' : 'bell_start.mp3');
  }

  void _showQuotaDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Text('👑', style: TextStyle(fontSize: 28)),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Simulation Premium',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3CD),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFFFD700)),
              ),
              child: const Text(
                'Vous avez utilisé votre simulation gratuite.\n\nAbonnez-vous pour accéder aux simulations illimitées avec corrigé détaillé et export PDF.',
                style: TextStyle(fontSize: 13, height: 1.5),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              '✅ Simulations illimitées\n✅ Corrigé détaillé\n✅ Export PDF\n✅ 25 séries par matière\n✅ Toutes les 16 matières',
              style: TextStyle(fontSize: 13, height: 1.7, color: Color(0xFF128C7E)),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            child: const Text('Plus tard', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AbonnementScreen()),
              );
            },
            icon: const Icon(Icons.star_rounded, size: 18),
            label: const Text('S\'abonner maintenant'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD4A017),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ],
      ),
    );
  }

  void _showConsignesDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'CONSIGNES OFFICIELLES',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: AppColors.primary,
            fontFamily: 'Poppins',
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'À LIRE ATTENTIVEMENT',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                  fontSize: 12,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 10),
              ...[
                '50 questions — Durée : 1h30',
                'Noircissez les cases (A, B, C, D, E) sur la feuille de réponses',
                'Vous pouvez cocher plusieurs cases par question',
                'Une mauvaise réponse entraîne une pénalité',
                'Sans réponse : 0 point (ne pénalise pas)',
                'Soumission impossible avant 30 minutes',
                'Une question peut avoir plusieurs réponses exactes',
              ].map((c) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('●  ', style: TextStyle(color: AppColors.primary, fontSize: 14, height: 1.4)),
                    Expanded(
                      child: Text(
                        c,
                        style: const TextStyle(fontSize: 13, fontFamily: 'Georgia', height: 1.5),
                      ),
                    ),
                  ],
                ),
              )),
            ],
          ),
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                setState(() => _consignesAccepted = true);
                _startTimerAndBell();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: const Text(
                "J'ai compris — Démarrer l'examen",
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds <= 0) {
        timer.cancel();
        // ── TÂCHE 8 : Son de fin ──
        _playBell(440, 2.5);
        _finishSimulation();
      } else {
        setState(() => _remainingSeconds--);
        // Alertes visuelles + sonores
        if (_remainingSeconds == 15 * 60 && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Plus que 15 minutes !'),
              backgroundColor: AppColors.secondary,
              duration: Duration(seconds: 3),
            ),
          );
        }
        if (_remainingSeconds == 5 * 60 && mounted) {
          // ── TÂCHE 8 : Son d'alerte 5min ──
          _playBell(660, 1.0);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('ATTENTION : 5 minutes restantes !'),
              backgroundColor: AppColors.error,
              duration: Duration(seconds: 4),
            ),
          );
        }
        // Fin du temps → son grave
        if (_remainingSeconds == 0) {
          _playBell(440, 2.5);
        }
      }
    });
  }

  String get _timerDisplay {
    final h = _remainingSeconds ~/ 3600;
    final m = (_remainingSeconds % 3600) ~/ 60;
    final s = _remainingSeconds % 60;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  Color get _timerColor {
    if (_remainingSeconds <= 300) return AppColors.error;
    if (_remainingSeconds <= 900) return const Color(0xFFE67E22);
    return AppColors.white;
  }

  void _toggleAnswer(int qIndex, String letter) {
    if (_finished) return;
    setState(() {
      _answers.putIfAbsent(qIndex, () => {});
      final ans = _answers[qIndex]!;
      if (ans.contains(letter)) {
        ans.remove(letter);
      } else {
        ans.add(letter);
        // Son de clic différent du son de démarrage
        BellService.playClick();
      }
    });
  }

  // Groupe de matière : retourne le label section pour la question n°i
  String _getMatiereLabel(int idx) {
    if (idx >= _questions.length) return '';
    final q = _questions[idx] as Map<String, dynamic>;
    final mat = (q['matiere'] ?? '').toString();
    return mat
        .replaceAll('_', ' ')
        .split(' ')
        .map((w) => w.isEmpty ? '' : w[0].toUpperCase() + w.substring(1))
        .join(' ');
  }

  // Vérifie si on doit afficher un séparateur de matière
  bool _showMatiereSeparator(int idx) {
    if (idx == 0) return true;
    final cur = (_questions[idx] as Map<String, dynamic>)['matiere'] ?? '';
    final prev = (_questions[idx - 1] as Map<String, dynamic>)['matiere'] ?? '';
    return cur != prev;
  }

  Future<void> _finishSimulation() async {
    if (_finished) return;
    _timer?.cancel();
    // ── TÂCHE 8 : Son de fin (bell_end.mp3) ──
    await _playBellAsset('bell_end.mp3');
    setState(() => _finished = true);

    final reponses = <Map<String, String>>[];
    for (int i = 0; i < _questions.length; i++) {
      final q = _questions[i] as Map<String, dynamic>;
      final ans = _answers[i]?.join('') ?? '';
      reponses.add({
        'question_id': (q['id'] ?? '').toString(),
        'reponse': ans,
      });
    }

    final tempsUtilise = _durationSeconds - _remainingSeconds;

    if (!mounted) return;

    // Calculer les scores d'abord
    int bonnes = 0, mauvaises = 0, sansReponse = 0;
    final Map<String, List<int>> scoreParMatiere = {};

    for (int i = 0; i < _questions.length; i++) {
      final q = _questions[i] as Map<String, dynamic>;
      final bonneStr = (q['bonne_reponse'] ?? '').toString().toUpperCase();
      final bonneSet = bonneStr.split('').where((c) => ['A','B','C','D','E'].contains(c)).toSet();
      final matiere = (q['matiere'] ?? 'autre').toString();
      scoreParMatiere.putIfAbsent(matiere, () => [0, 0]);
      final choisies = _answers[i] ?? {};

      if (choisies.isEmpty) {
        sansReponse++;
      } else if (choisies.containsAll(bonneSet) && bonneSet.containsAll(choisies)) {
        bonnes++;
        scoreParMatiere[matiere]![0]++;
      } else {
        mauvaises++;
      }
      scoreParMatiere[matiere]![1]++;
    }

    final score = (bonnes - mauvaises).clamp(0, _questions.length);

    // Sauvegarder les résultats après calcul des scores
    final user = ApiService.currentUser;
    if (_sessionId != null) {
      await ApiService.terminerSimulation(
        sessionId: _sessionId!,
        reponses: reponses,
        tempsUtilise: tempsUtilise,
      );
    } else if (user != null) {
      // Fallback: sauvegarder directement via Supabase
      await SupabaseService.saveExamenBlanc(
        userId: user['id'].toString(),
        score: score,
        total: _questions.length,
        tempsUtilise: tempsUtilise,
        reponses: _answers,
      );
    }

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => SimulationResultScreen(
          score: score,
          total: _questions.length,
          bonnes: bonnes,
          mauvaises: mauvaises,
          sansReponse: sansReponse,
          tempsUtilise: tempsUtilise,
          questions: _questions,
          answers: _answers,
          scoreParMatiere: scoreParMatiere,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _questionsScroll.dispose();
    _reponseScroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: AppColors.primary),
              SizedBox(height: 20),
              Text('Chargement de la simulation...', style: TextStyle(fontSize: 16, color: AppColors.textLight)),
            ],
          ),
        ),
      );
    }

    if (_error != null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(title: const Text('Erreur')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline_rounded, size: 64, color: AppColors.error),
                const SizedBox(height: 16),
                Text(_error!, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16)),
                const SizedBox(height: 24),
                ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text('Retour')),
              ],
            ),
          ),
        ),
      );
    }

    if (_questions.isEmpty) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(title: const Text('Simulation')),
        body: const Center(child: Text('Aucune question disponible')),
      );
    }

    final isWide = MediaQuery.of(context).size.width >= 700;
    final answeredCount = _answers.values.where((s) => s.isNotEmpty).length;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Quitter la simulation ?'),
              content: const Text('Votre progression sera perdue.'),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Continuer')),
                TextButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _timer?.cancel();
                    Navigator.pop(context);
                  },
                  child: const Text('Quitter', style: TextStyle(color: AppColors.error)),
                ),
              ],
            ),
          );
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: Text(
            _timerDisplay,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: _timerColor,
              fontFamily: 'Poppins',
            ),
          ),
          centerTitle: true,
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(colors: [AppColors.primary, AppColors.primaryDark]),
            ),
          ),
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.maybePop(context),
          ),
          actions: [
            Center(
              child: Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$answeredCount/${_questions.length}',
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                  ),
                ),
              ),
            ),
          ],
        ),
        body: Column(
          children: [
            // ── TÂCHE 7 : Interface 2 colonnes ──
            Expanded(
              child: isWide
                  ? _buildTwoColumns()
                  : _buildSingleColumn(),
            ),

            // ── Bouton SOUMETTRE ──
            _buildSubmitBar(answeredCount),
          ],
        ),
      ),
    );
  }

  // ── Disposition 2 colonnes (desktop/tablette) ──
  Widget _buildTwoColumns() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Colonne gauche : Feuille de questions (60%)
        Expanded(
          flex: 60,
          child: Container(
            decoration: const BoxDecoration(
              border: Border(right: BorderSide(color: Color(0xFFE0E0E0), width: 1)),
            ),
            child: _buildQuestionsList(),
          ),
        ),
        // Colonne droite : Feuille de réponses (40%)
        Expanded(
          flex: 40,
          child: _buildAnswerSheet(),
        ),
      ],
    );
  }

  // ── Disposition mobile (onglets) ──
  Widget _buildSingleColumn() {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          Container(
            color: AppColors.white,
            child: const TabBar(
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.textLight,
              indicatorColor: AppColors.primary,
              tabs: [
                Tab(text: 'QUESTIONS'),
                Tab(text: 'RÉPONSES'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildQuestionsList(),
                _buildAnswerSheet(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Feuille de questions — avec options A/B/C/D ──
  Widget _buildQuestionsList() {
    return Column(
      children: [
        // ── Bandeau d'accompagnement feuille de questions ──
        Container(
          width: double.infinity,
          margin: const EdgeInsets.fromLTRB(12, 10, 12, 0),
          padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 14),
          decoration: BoxDecoration(
            color: const Color(0xFFE8F5E9),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.3), width: 1),
          ),
          child: const Row(
            children: [
              Icon(Icons.menu_book_rounded, color: AppColors.primary, size: 18),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Lisez attentivement chaque question et ses propositions avant de répondre.',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.primary,
                    fontStyle: FontStyle.italic,
                    height: 1.4,
                    fontFamily: 'Georgia',
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Expanded(
          child: ListView.builder(
            controller: _questionsScroll,
            padding: const EdgeInsets.fromLTRB(12, 6, 12, 80),
            itemCount: _questions.length,
            itemBuilder: (ctx, i) {
              final q = _questions[i] as Map<String, dynamic>;
              final texte = (q['enonce'] ?? q['question'] ?? '').toString();
              final showSep = _showMatiereSeparator(i);
              final matiereLabel = _getMatiereLabel(i);
              // Options de réponse
              final optionA = (q['option_a'] ?? '').toString();
              final optionB = (q['option_b'] ?? '').toString();
              final optionC = (q['option_c'] ?? '').toString();
              final optionD = (q['option_d'] ?? '').toString();
              final options = <MapEntry<String, String>>[
                if (optionA.isNotEmpty) MapEntry('A', optionA),
                if (optionB.isNotEmpty) MapEntry('B', optionB),
                if (optionC.isNotEmpty) MapEntry('C', optionC),
                if (optionD.isNotEmpty) MapEntry('D', optionD),
              ];

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Séparateur de matière
                  if (showSep) ...[
                    if (i > 0) const SizedBox(height: 14),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 12),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.07),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                      ),
                      child: Text(
                        '─────── ${matiereLabel.toUpperCase()} ───────',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary,
                          letterSpacing: 1,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],

                  // Carte question
                  Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFE0E0E0), width: 1),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Énoncé
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 26,
                              height: 26,
                              decoration: const BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  '${i + 1}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 12,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: MathTextWidget(
                                text: texte,
                                textStyle: const TextStyle(
                                  fontSize: 13.5,
                                  fontFamily: 'Georgia',
                                  height: 1.5,
                                  color: AppColors.textDark,
                                  fontWeight: FontWeight.w600,
                                ),
                                mathSize: 13.5,
                                mathColor: AppColors.textDark,
                              ),
                            ),
                          ],
                        ),
                        // Options A/B/C/D
                        if (options.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          const Divider(height: 1, thickness: 0.5, color: Color(0xFFEEEEEE)),
                          const SizedBox(height: 6),
                          ...options.map((opt) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 5),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 22,
                                    height: 22,
                                    decoration: BoxDecoration(
                                      color: AppColors.primary.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(5),
                                      border: Border.all(
                                        color: AppColors.primary.withValues(alpha: 0.3),
                                        width: 1,
                                      ),
                                    ),
                                    child: Center(
                                      child: Text(
                                        opt.key,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w800,
                                          fontSize: 11,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 7),
                                  Expanded(
                                    child: MathTextWidget(
                                      text: opt.value,
                                      textStyle: const TextStyle(
                                        fontSize: 12.5,
                                        fontFamily: 'Georgia',
                                        height: 1.45,
                                        color: AppColors.textDark,
                                      ),
                                      mathSize: 12.5,
                                      mathColor: AppColors.textDark,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                        ] else ...[
                          // Si pas d'options en DB → message placeholder
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF8E1),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: const Color(0xFFFFD54F), width: 1),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.info_outline, size: 14, color: Color(0xFF795548)),
                                SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    'Propositions à venir — Cochez votre réponse sur la feuille de droite',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Color(0xFF795548),
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  // ── Feuille de réponses style examen ──
  Widget _buildAnswerSheet() {
    return Container(
      color: const Color(0xFFFAFAFA),
      child: Column(
        children: [
          // ── Bandeau d'accompagnement feuille de réponses ──
          Container(
            width: double.infinity,
            margin: const EdgeInsets.fromLTRB(8, 10, 8, 0),
            padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFE3F2FD),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFF1565C0).withValues(alpha: 0.3), width: 1),
            ),
            child: const Row(
              children: [
                Icon(Icons.edit_rounded, color: Color(0xFF1565C0), size: 18),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Noircissez attentivement les cases correspondant à vos réponses.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF1565C0),
                      fontStyle: FontStyle.italic,
                      height: 1.4,
                      fontFamily: 'Georgia',
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Expanded(
          child: SingleChildScrollView(
            controller: _reponseScroll,
            padding: const EdgeInsets.fromLTRB(8, 4, 8, 80),
            child: Column(
              children: [
                // En-tête tableau
            Container(
              padding: const EdgeInsets.symmetric(vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  SizedBox(width: 4),
                  SizedBox(
                    width: 36,
                    child: Text('N°', textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 12)),
                  ),
                  Expanded(child: Text('A', textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13))),
                  Expanded(child: Text('B', textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13))),
                  Expanded(child: Text('C', textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13))),
                  Expanded(child: Text('D', textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13))),
                  Expanded(child: Text('E', textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13))),
                  SizedBox(width: 4),
                ],
              ),
            ),
            const SizedBox(height: 4),

            ...List.generate(_questions.length, (i) {
              final selectedLetters = _answers[i] ?? {};
              final isEven = i % 2 == 0;
              return Container(
                margin: const EdgeInsets.only(bottom: 2),
                decoration: BoxDecoration(
                  color: isEven
                      ? Colors.white
                      : const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  children: [
                    const SizedBox(width: 4),
                    SizedBox(
                      width: 36,
                      child: Text(
                        '${i + 1}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textLight,
                        ),
                      ),
                    ),
                    ...['A', 'B', 'C', 'D', 'E'].map((letter) {
                      final isSelected = selectedLetters.contains(letter);
                      return Expanded(
                        child: GestureDetector(
                          onTap: () => _toggleAnswer(i, letter),
                          child: Container(
                            height: 36,
                            margin: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isSelected
                                  ? AppColors.primary
                                  : Colors.white,
                              border: Border.all(
                                color: isSelected
                                    ? AppColors.primary
                                    : Colors.grey.withValues(alpha: 0.4),
                                width: isSelected ? 2 : 1.5,
                              ),
                              boxShadow: isSelected ? [
                                BoxShadow(
                                  color: AppColors.primary.withValues(alpha: 0.3),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ] : null,
                            ),
                            child: Center(
                              child: Text(
                                letter,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: isSelected ? Colors.white : Colors.grey.shade500,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                    const SizedBox(width: 4),
                  ],
                ),
              );
            }),
              ],
            ),
          ),
          ),
        ],
      ),
    );
  }

  // ── Barre de soumission ──
  Widget _buildSubmitBar(int answeredCount) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
      decoration: BoxDecoration(
        color: AppColors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.07),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: _canSubmit
          ? Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_isAdminUser) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                    margin: const EdgeInsets.only(bottom: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF3E0),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFFF6F00).withValues(alpha: 0.4)),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.admin_panel_settings_rounded, size: 14, color: Color(0xFFE65100)),
                        SizedBox(width: 5),
                        Text(
                          'MODE ADMIN — Soumission débloquée',
                          style: TextStyle(fontSize: 11, color: Color(0xFFE65100), fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ),
                ],
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () => _showConfirmSubmit(answeredCount),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.error,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 4,
                    ),
                    child: const Text(
                      'SOUMETTRE MA COPIE',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, fontFamily: 'Poppins'),
                    ),
                  ),
                ),
              ],
            )
          : Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.grey.withValues(alpha: 0.25)),
              ),
              child: Column(
                children: [
                  Text(
                    'Soumission disponible dans ${_secondsBeforeCanSubmit ~/ 60}min ${_secondsBeforeCanSubmit % 60}s',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textLight,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Text(
                    'Vous ne pouvez pas soumettre avant 30 minutes.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 11, color: AppColors.textLight),
                  ),
                ],
              ),
            ),
    );
  }

  void _showConfirmSubmit(int answeredCount) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Terminer la simulation ?'),
        content: Text(
          'Vous avez répondu à $answeredCount/${_questions.length} questions.\n\nÊtes-vous sûr de vouloir soumettre votre copie ?',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Continuer l\'examen')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _finishSimulation();
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('Soumettre'),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// ÉCRAN DE RÉSULTATS
// ══════════════════════════════════════════════════════════════
class SimulationResultScreen extends StatelessWidget {
  final int score, total, bonnes, mauvaises, sansReponse, tempsUtilise;
  final List<dynamic> questions;
  final Map<int, Set<String>> answers;
  final Map<String, List<int>> scoreParMatiere;

  const SimulationResultScreen({
    super.key,
    required this.score,
    required this.total,
    required this.bonnes,
    required this.mauvaises,
    required this.sansReponse,
    required this.tempsUtilise,
    required this.questions,
    required this.answers,
    required this.scoreParMatiere,
  });

  String get _mention {
    final pct = total > 0 ? score / total * 100 : 0;
    if (pct >= 80) return 'Excellent';
    if (pct >= 60) return 'Bien';
    if (pct >= 40) return 'Passable';
    return 'Insuffisant';
  }

  Color get _mentionColor {
    final pct = total > 0 ? score / total * 100 : 0;
    if (pct >= 80) return AppColors.success;
    if (pct >= 60) return const Color(0xFF2980B9);
    if (pct >= 40) return const Color(0xFFE67E22);
    return AppColors.error;
  }

  String get _tempsFormate {
    final h = tempsUtilise ~/ 3600;
    final m = (tempsUtilise % 3600) ~/ 60;
    final s = tempsUtilise % 60;
    if (h > 0) return '${h}h ${m}min';
    return '${m}min ${s}s';
  }

  @override
  Widget build(BuildContext context) {
    final pct = total > 0 ? (score / total * 100).round() : 0;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Résultats'),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(colors: [AppColors.primary, AppColors.primaryDark]),
          ),
        ),
        foregroundColor: AppColors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Score
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [_mentionColor, _mentionColor.withValues(alpha: 0.7)],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  Text(
                    '$score / $total',
                    style: const TextStyle(fontSize: 42, fontWeight: FontWeight.w900, color: AppColors.white, fontFamily: 'Poppins'),
                  ),
                  Text(
                    '$pct%  —  $_mention',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.white),
                  ),
                  const SizedBox(height: 16),
                  // Note sur 20 — CERCLE ROUGE
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.red.shade700,
                      border: Border.all(color: Colors.red.shade900, width: 3),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.red.withValues(alpha: 0.4),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          total > 0 ? (score / total * 20).toStringAsFixed(1) : '0',
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            height: 1.0,
                          ),
                        ),
                        Text(
                          '/ 20',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Colors.white.withValues(alpha: 0.9),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Durée : $_tempsFormate',
                    style: TextStyle(fontSize: 14, color: AppColors.white.withValues(alpha: 0.8)),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Stats
            Row(
              children: [
                _buildStat('Bonnes', '$bonnes', AppColors.success),
                const SizedBox(width: 10),
                _buildStat('Mauvaises', '$mauvaises', AppColors.error),
                const SizedBox(width: 10),
                _buildStat('Sans réponse', '$sansReponse', Colors.grey),
              ],
            ),

            const SizedBox(height: 20),

            // Score par matière
            if (scoreParMatiere.isNotEmpty) ...[
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Score par matière',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textDark),
                ),
              ),
              const SizedBox(height: 10),
              ...scoreParMatiere.entries.map((entry) {
                final matNom = entry.key.replaceAll('_', ' ').toUpperCase();
                final b = entry.value[0];
                final t = entry.value[1];
                final p = t > 0 ? b / t : 0.0;
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6)],
                  ),
                  child: Row(
                    children: [
                      Expanded(child: Text(matNom, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600))),
                      Text('$b / $t', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: p >= 0.6 ? AppColors.success : AppColors.error)),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 20),
            ],

            // Correction détaillée
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Correction détaillée',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textDark),
              ),
            ),
            const SizedBox(height: 10),

            ...questions.asMap().entries.map((entry) {
              final i = entry.key;
              final q = entry.value as Map<String, dynamic>;
              final bonneStr = (q['bonne_reponse'] ?? '').toString().toUpperCase();
              final bonneSet = bonneStr.split('').where((c) => ['A','B','C','D','E'].contains(c)).toSet();
              final choisies = answers[i] ?? {};
              final correct = choisies.containsAll(bonneSet) && bonneSet.containsAll(choisies) && choisies.isNotEmpty;
              final noAns = choisies.isEmpty;

              Color bg;
              Color border;
              if (noAns) {
                bg = Colors.grey.withValues(alpha: 0.06);
                border = Colors.grey.withValues(alpha: 0.2);
              } else if (correct) {
                bg = AppColors.success.withValues(alpha: 0.06);
                border = AppColors.success.withValues(alpha: 0.35);
              } else {
                bg = AppColors.error.withValues(alpha: 0.06);
                border = AppColors.error.withValues(alpha: 0.3);
              }

              final options = {
                'A': q['option_a']?.toString() ?? '',
                'B': q['option_b']?.toString() ?? '',
                'C': q['option_c']?.toString() ?? '',
                'D': q['option_d']?.toString() ?? '',
              };

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: border, width: 1.5),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Q${i + 1}.',
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: AppColors.primary),
                        ),
                        const SizedBox(width: 6),
                        Icon(
                          noAns ? Icons.remove_circle_outline : (correct ? Icons.check_circle_outline : Icons.cancel_outlined),
                          size: 16,
                          color: noAns ? Colors.grey : (correct ? AppColors.success : AppColors.error),
                        ),
                        const Spacer(),
                        Text(
                          noAns ? 'Non répondu' : (correct ? 'Correct' : 'Incorrect'),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: noAns ? Colors.grey : (correct ? AppColors.success : AppColors.error),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    MathTextWidget(
                      text: (q['enonce'] ?? q['question'] ?? '').toString(),
                      textStyle: const TextStyle(fontSize: 13, fontFamily: 'Georgia', height: 1.5, fontWeight: FontWeight.w500),
                      mathSize: 13,
                      mathColor: AppColors.textDark,
                    ),
                    const SizedBox(height: 8),
                    ...options.entries.map((opt) {
                      final l = opt.key;
                      final t = opt.value;
                      if (t.isEmpty) return const SizedBox.shrink();
                      final isBonne = bonneSet.contains(l);
                      final isChoisie = choisies.contains(l);

                      if (!isBonne && !isChoisie) return const SizedBox.shrink();

                      return Container(
                        margin: const EdgeInsets.only(bottom: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: isBonne ? AppColors.success.withValues(alpha: 0.1) : AppColors.error.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(7),
                        ),
                        child: Row(
                          children: [
                            Text(
                              '$l.  ',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: isBonne ? AppColors.success : AppColors.error,
                                fontSize: 13,
                              ),
                            ),
                            Expanded(
                              child: MathTextWidget(
                                text: t,
                                textStyle: TextStyle(
                                  fontSize: 12,
                                  color: isBonne ? AppColors.success : AppColors.error,
                                  fontFamily: 'Georgia',
                                ),
                                mathSize: 12,
                                mathColor: isBonne ? AppColors.success : AppColors.error,
                              ),
                            ),
                            Icon(
                              isBonne ? Icons.check : Icons.close,
                              size: 14,
                              color: isBonne ? AppColors.success : AppColors.error,
                            ),
                          ],
                        ),
                      );
                    }),
                    if (q['explication'] != null && (q['explication'] as String).isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1A5C38).withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: MathTextWidget(
                          text: q['explication'].toString(),
                          textStyle: const TextStyle(
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                            height: 1.5,
                            color: AppColors.textDark,
                          ),
                          mathSize: 12,
                          mathColor: AppColors.textDark,
                        ),
                      ),
                    ],
                  ],
                ),
              );
            }),

            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: () => _exportPDF(context),
                icon: const Icon(Icons.file_download_rounded),
                label: const Text('Telecharger copie (PDF)'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF27AE60),
                  foregroundColor: AppColors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.home_rounded),
                label: const Text('Retour au tableau de bord'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Future<void> _exportPDF(BuildContext ctx) async {
    ScaffoldMessenger.of(ctx).showSnackBar(
      const SnackBar(
        content: Text('Génération du PDF en cours...'),
        duration: Duration(seconds: 2),
        backgroundColor: AppColors.primary,
      ),
    );

    try {
      final pdfBytes = await _generatePdfBytes(ctx);
      await Printing.sharePdf(
        bytes: pdfBytes,
        filename: 'EF-FORT_Resultats_Examen.pdf',
      );
    } catch (e) {
      if (ctx.mounted) {
        ScaffoldMessenger.of(ctx).showSnackBar(
          SnackBar(
            content: Text('Erreur PDF: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<Uint8List> _generatePdfBytes(BuildContext ctx) async {
    final pdf = pw.Document();
    final user = ApiService.currentUser;
    final nomCandidat = user != null
        ? '${user['prenom'] ?? ''} ${user['nom'] ?? ''}'.trim()
        : 'Candidat';

    // ── Charger le VRAI logo de l'application ──
    pw.MemoryImage? logoImage;
    try {
      final ByteData data = await rootBundle.load('assets/images/logo_effort.png');
      logoImage = pw.MemoryImage(data.buffer.asUint8List());
    } catch (_) {
      try {
        final ByteData data = await rootBundle.load('assets/icons/logo_effort.png');
        logoImage = pw.MemoryImage(data.buffer.asUint8List());
      } catch (_) {
        logoImage = null;
      }
    }
    final now = DateTime.now();
    final dateStr = '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}  ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    // Calcul score
    int bonnes = 0;
    int mauvaises = 0;
    int sansRep = 0;
    final List<Map<String, dynamic>> correction = [];

    for (int i = 0; i < questions.length; i++) {
      final q = questions[i] as Map<String, dynamic>;
      final bonneStr = (q['bonne_reponse'] ?? '').toString().toUpperCase();
      final bonneSet = bonneStr.split('').where((c) => ['A','B','C','D','E'].contains(c)).toSet();
      final choisies = answers[i] ?? {};
      final correct = choisies.isNotEmpty && choisies.containsAll(bonneSet) && bonneSet.containsAll(choisies);
      final noAns = choisies.isEmpty;

      if (noAns) {
        sansRep++;
      } else if (correct) {
        bonnes++;
      } else {
        mauvaises++;
      }

      // Convertir le LaTeX en texte lisible pour le PDF
      final enonceRaw = (q['enonce'] ?? q['question'] ?? '').toString();
      final explicRaw = q['explication']?.toString() ?? '';
      final optA = _cleanLatexForPdf((q['option_a'] ?? '').toString());
      final optB = _cleanLatexForPdf((q['option_b'] ?? '').toString());
      final optC = _cleanLatexForPdf((q['option_c'] ?? '').toString());
      final optD = _cleanLatexForPdf((q['option_d'] ?? '').toString());
      correction.add({
        'num': i + 1,
        'enonce': _cleanLatexForPdf(enonceRaw),
        'choisies': choisies.join(', '),
        'bonne': bonneStr.isEmpty ? '?' : bonneStr,
        'correct': correct,
        'noAns': noAns,
        'explication': _cleanLatexForPdf(explicRaw),
        'option_a': optA,
        'option_b': optB,
        'option_c': optC,
        'option_d': optD,
      });
    }

    final total = questions.length;
    final pct = total > 0 ? (bonnes / total * 100).round() : 0;
    final mention = pct >= 70 ? 'Félicitations !' : pct >= 50 ? 'Bonne progression, continuez !' : 'Courage ! Chaque effort compte.';

    final primaryColor   = PdfColor.fromHex('1A5C38');
    final primaryDark    = PdfColor.fromHex('0E3D24');
    final accentColor    = PdfColor.fromHex('D4A017');
    final errorColor     = PdfColor.fromHex('C62828');
    final successColor   = PdfColor.fromHex('2E7D32');
    final greyColor      = PdfColor.fromHex('6C757D');
    final greyDark       = PdfColor.fromHex('424242');
    final lightGreen     = PdfColor.fromHex('E8F5E9');
    final lightRed       = PdfColor.fromHex('FFEBEE');
    final lightGrey      = PdfColor.fromHex('F5F5F5');
    final borderGreen    = PdfColor.fromHex('A5D6A7');
    final borderRed      = PdfColor.fromHex('EF9A9A');
    final borderGrey     = PdfColor.fromHex('BDBDBD');
    final redCircle      = PdfColor.fromHex('C62828');
    final redCircleDark  = PdfColor.fromHex('8B0000');
    final noteDouble2    = total > 0 ? (bonnes / total * 20) : 0.0;
    final noteStr2       = noteDouble2.toStringAsFixed(1);

    String getMention2() {
      if (pct >= 90) return 'EXCELLENT';
      if (pct >= 80) return 'TRES BIEN';
      if (pct >= 70) return 'BIEN';
      if (pct >= 60) return 'ASSEZ BIEN';
      if (pct >= 50) return 'PASSABLE';
      return 'INSUFFISANT';
    }

    PdfColor getMentionColor2() {
      if (pct >= 70) return successColor;
      if (pct >= 50) return accentColor;
      return errorColor;
    }

    String getAppreciation2() {
      if (pct >= 90) return 'Excellent ! Vous maitrisez parfaitement le sujet. Continuez ainsi !';
      if (pct >= 80) return 'Excellent travail ! Vous maitrisez bien les notions. Continuez sur cette lancee et visez la perfection.';
      if (pct >= 70) return 'Tres bien ! Bon niveau. Quelques revisions vous permettront d\'atteindre l\'excellence.';
      if (pct >= 60) return 'Bien ! Fondamentaux assimiles. Concentrez-vous sur les points manques.';
      if (pct >= 50) return 'Passable. Revoyez certaines notions importantes. Perseverez !';
      return 'Des efforts supplementaires sont necessaires. Revoyez le cours attentivement. Vous pouvez y arriver !';
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(28, 20, 28, 20),
        header: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Container(
                  width: 58,
                  height: 58,
                  decoration: pw.BoxDecoration(
                    color: primaryColor,
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(10)),
                    border: pw.Border.all(color: primaryDark, width: 2),
                  ),
                  padding: const pw.EdgeInsets.all(4),
                  child: logoImage != null
                      ? pw.Image(logoImage, fit: pw.BoxFit.contain)
                      : pw.Center(child: pw.Text('EF', style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold, color: PdfColors.white))),
                ),
                pw.SizedBox(width: 12),
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('EF-FORT.BF', style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold, color: primaryColor)),
                      pw.Text('Plateforme N1 des Concours au Burkina Faso', style: pw.TextStyle(fontSize: 9.5, color: greyColor)),
                      pw.Text('"Chaque effort te rapproche de ton admission finale"', style: pw.TextStyle(fontSize: 9, color: accentColor, fontStyle: pw.FontStyle.italic)),
                      pw.SizedBox(height: 5),
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: pw.BoxDecoration(
                          color: lightGreen,
                          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5)),
                          border: pw.Border.all(color: borderGreen, width: 0.8),
                        ),
                        child: pw.Text('Resultats Examen Blanc  •  ef-fort-bf.pages.dev',
                            style: pw.TextStyle(fontSize: 9, color: primaryColor, fontWeight: pw.FontWeight.bold)),
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(width: 10),
                pw.Column(
                  children: [
                    pw.Container(
                      width: 80,
                      height: 80,
                      decoration: pw.BoxDecoration(
                        color: PdfColors.white,
                        shape: pw.BoxShape.circle,
                        border: pw.Border.all(color: redCircle, width: 3),
                      ),
                      child: pw.Center(
                        child: pw.Column(
                          mainAxisAlignment: pw.MainAxisAlignment.center,
                          children: [
                            pw.Text(noteStr2, style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold, color: redCircle)),
                            pw.Container(width: 40, height: 1, color: redCircleDark),
                            pw.Text('20', style: pw.TextStyle(fontSize: 14, color: redCircle)),
                          ],
                        ),
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                      decoration: pw.BoxDecoration(
                        color: getMentionColor2(),
                        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5)),
                      ),
                      child: pw.Text(getMention2(), style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.white)),
                    ),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 10),
            // Fiche candidat
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                color: PdfColors.white,
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                border: pw.Border.all(color: PdfColors.grey300, width: 0.8),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Row(children: [pw.Text('Candidat : ', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: primaryColor)), pw.Text(nomCandidat.isEmpty ? 'Candidat' : nomCandidat, style: pw.TextStyle(fontSize: 11, color: greyDark))]),
                  pw.SizedBox(height: 3),
                  pw.Row(children: [pw.Text('Date     : ', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: greyColor)), pw.Text(dateStr, style: pw.TextStyle(fontSize: 11, color: greyDark))]),
                  pw.SizedBox(height: 5),
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: pw.BoxDecoration(
                      color: lightGreen,
                      borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                      border: pw.Border.all(color: borderGreen, width: 0.8),
                    ),
                    child: pw.Text('Score : $bonnes/$total ($pct%)   |   Note /20 : $noteStr2',
                        style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: primaryColor)),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 8),
            // Appréciation
            pw.Container(
              padding: const pw.EdgeInsets.fromLTRB(12, 8, 12, 8),
              decoration: pw.BoxDecoration(
                color: lightGreen,
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                border: pw.Border.all(color: borderGreen, width: 0.8),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('Appreciation', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: primaryColor)),
                  pw.SizedBox(height: 3),
                  pw.Text(getAppreciation2(), style: pw.TextStyle(fontSize: 10, color: greyDark)),
                ],
              ),
            ),
            pw.SizedBox(height: 10),
          ],
        ),
        footer: (context) => pw.Container(
          padding: const pw.EdgeInsets.only(top: 6),
          decoration: pw.BoxDecoration(
            border: pw.Border(top: pw.BorderSide(color: PdfColors.grey300, width: 0.5)),
          ),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('EF-FORT.BF  •  Chaque effort te rapproche de ton admission',
                  style: pw.TextStyle(fontSize: 8, color: greyColor)),
              pw.Text('ef-fort-bf.pages.dev  |  Page ${context.pageNumber}/${context.pagesCount}',
                  style: pw.TextStyle(fontSize: 8, color: greyColor)),
            ],
          ),
        ),
        build: (context) => [
          // Titre section corrigé
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: pw.BoxDecoration(
              color: primaryColor,
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(7)),
            ),
            child: pw.Text('CORRIGE DETAILLE',
                style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, color: PdfColors.white)),
          ),
          pw.SizedBox(height: 10),
          // Statistiques
          pw.Row(
            children: [
              _pdfStat('Bonnes', '$bonnes', successColor),
              pw.SizedBox(width: 8),
              _pdfStat('Fausses', '$mauvaises', errorColor),
              pw.SizedBox(width: 8),
              _pdfStat('Sans rep.', '$sansRep', greyColor),
              pw.SizedBox(width: 8),
              _pdfStat('Score', '$pct%', pct >= 50 ? successColor : errorColor),
            ],
          ),
          pw.SizedBox(height: 12),
          ...correction.map((c) {
            final correct = c['correct'] as bool;
            final noAns   = c['noAns'] as bool;
            final bgColor     = noAns ? lightGrey  : (correct ? lightGreen : lightRed);
            final borderColor = noAns ? borderGrey : (correct ? borderGreen : borderRed);
            final circleColor = noAns ? greyColor  : (correct ? successColor : errorColor);
            final statusText  = noAns ? 'NON REPONDU' : (correct ? 'CORRECT' : 'INCORRECT');
            final enonce = c['enonce'] as String;
            final shortEnonce = enonce.length > 140 ? '${enonce.substring(0, 140)}...' : enonce;
            return pw.Container(
              margin: const pw.EdgeInsets.only(bottom: 8),
              decoration: pw.BoxDecoration(
                color: bgColor,
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(7)),
                border: pw.Border.all(color: borderColor, width: 0.8),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Padding(
                    padding: const pw.EdgeInsets.fromLTRB(10, 7, 10, 6),
                    child: pw.Row(
                      children: [
                        pw.Container(
                          width: 24, height: 24,
                          decoration: pw.BoxDecoration(color: circleColor, shape: pw.BoxShape.circle),
                          child: pw.Center(
                            child: pw.Text('Q${c["num"]}',
                                style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.white)),
                          ),
                        ),
                        pw.SizedBox(width: 8),
                        pw.Expanded(
                          child: pw.Text(shortEnonce,
                              style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: greyDark)),
                        ),
                        pw.Container(
                          padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: pw.BoxDecoration(
                            color: circleColor,
                            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5)),
                          ),
                          child: pw.Text(statusText,
                              style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.white)),
                        ),
                      ],
                    ),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.fromLTRB(10, 3, 10, 7),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'Votre reponse : ${c["choisies"].toString().isEmpty ? "-" : c["choisies"]}   |   Bonne(s) : ${c["bonne"]}',
                          style: pw.TextStyle(fontSize: 10, color: greyColor),
                        ),
                        // ── Options A/B/C/D dans le PDF ──
                        ...['A', 'B', 'C', 'D'].where((l) {
                          final key = 'option_${l.toLowerCase()}';
                          return (c[key] as String? ?? '').isNotEmpty;
                        }).map((l) {
                          final key = 'option_${l.toLowerCase()}';
                          final optText = c[key] as String;
                          final bonnes = (c['bonne'] as String).toUpperCase();
                          final choisiesStr = (c['choisies'] as String).toUpperCase();
                          final isBonne = bonnes.contains(l);
                          final isChoisie = choisiesStr.contains(l);
                          if (!isBonne && !isChoisie) return pw.SizedBox();
                          final optColor = isBonne ? successColor : errorColor;
                          return pw.Padding(
                            padding: const pw.EdgeInsets.only(top: 3),
                            child: pw.Row(
                              crossAxisAlignment: pw.CrossAxisAlignment.start,
                              children: [
                                pw.Container(
                                  width: 18, height: 18,
                                  decoration: pw.BoxDecoration(
                                    color: optColor,
                                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(3)),
                                  ),
                                  child: pw.Center(
                                    child: pw.Text(l,
                                        style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.white)),
                                  ),
                                ),
                                pw.SizedBox(width: 5),
                                pw.Expanded(
                                  child: pw.Text(optText,
                                      style: pw.TextStyle(fontSize: 9.5, color: isBonne ? successColor : errorColor)),
                                ),
                                pw.Text(isBonne ? '✓' : '✗',
                                    style: pw.TextStyle(fontSize: 10, color: optColor, fontWeight: pw.FontWeight.bold)),
                              ],
                            ),
                          );
                        }),
                        if ((c['explication'] as String).isNotEmpty) ...[
                          pw.SizedBox(height: 4),
                          pw.Container(
                            padding: const pw.EdgeInsets.all(5),
                            decoration: pw.BoxDecoration(
                              color: lightGrey,
                              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                            ),
                            child: pw.Row(
                              crossAxisAlignment: pw.CrossAxisAlignment.start,
                              children: [
                                pw.Expanded(
                                  child: pw.Text('Explication : ${c["explication"]}',
                                      style: pw.TextStyle(fontSize: 9.5, color: greyColor, fontStyle: pw.FontStyle.italic)),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
          pw.SizedBox(height: 14),
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              color: lightGreen,
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(7)),
              border: pw.Border.all(color: borderGreen, width: 0.8),
            ),
            child: pw.Text(
              'EF-FORT.BF  •  Chaque effort te rapproche de ton admission finale  •  ef-fort-bf.pages.dev',
              textAlign: pw.TextAlign.center,
              style: pw.TextStyle(fontSize: 10, color: primaryColor, fontStyle: pw.FontStyle.italic),
            ),
          ),
        ],
      ),
    );

    return pdf.save();
  }

  // ── Convertir le LaTeX en texte lisible pour le PDF ──────────────────
  // Gère : délimiteurs $...$ et $$...$$, LaTeX brut sans délimiteurs
  static String _cleanLatexForPdf(String text) {
    if (text.isEmpty) return text;
    String result = text;
    // Remplacer les blocs $$...$$ d'abord
    result = result.replaceAllMapped(
      RegExp(r'\$\$([^$]*)\$\$'),
      (m) => MathTextWidget.latexToReadablePublic(m.group(1)!.trim()),
    );
    // Remplacer les blocs $...$
    result = result.replaceAllMapped(
      RegExp(r'\$([^$]+)\$'),
      (m) => MathTextWidget.latexToReadablePublic(m.group(1)!.trim()),
    );
    // Nettoyer les commandes LaTeX résiduelles hors délimiteurs
    // (cas où le texte contient \sqrt, \frac etc. directement sans $)
    if (result.contains(r'\')) {
      result = MathTextWidget.latexToReadablePublic(result);
    }
    return result.isEmpty ? text : result;
  }

  pw.Widget _pdfStat(String label, String value, PdfColor color) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.all(10),
        decoration: pw.BoxDecoration(
          color: color,
          borderRadius: pw.BorderRadius.circular(6),
        ),
        child: pw.Column(
          children: [
            pw.Text(value, style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 22)),
            pw.SizedBox(height: 2),
            pw.Text(label, style: const pw.TextStyle(color: PdfColors.white, fontSize: 11)),
          ],
        ),
      ),
    );
  }

  Widget _buildStat(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Column(
          children: [
            Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: color)),
            Text(label, style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}
