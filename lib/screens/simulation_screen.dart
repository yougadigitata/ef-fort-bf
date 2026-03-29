import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../core/theme/app_colors.dart';
import '../services/api_service.dart';
import '../services/supabase_service.dart';
import '../services/bell_service.dart';
import '../widgets/logo_widget.dart';
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

  const ExamWelcomeSlide({
    super.key,
    required this.candidatName,
    this.examenNom = '',
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
                          builder: (_) => const ExamRulesSlide(),
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
  const ExamRulesSlide({super.key});

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
                      builder: (_) => const SimulationExamScreen(),
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
  const SimulationExamScreen({super.key});

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

  bool get _canSubmit =>
      _remainingSeconds <= (_durationSeconds - _minSecondsBeforeSubmit);

  int get _secondsBeforeCanSubmit =>
      _remainingSeconds > (_durationSeconds - _minSecondsBeforeSubmit)
          ? _remainingSeconds - (_durationSeconds - _minSecondsBeforeSubmit)
          : 0;

  @override
  void initState() {
    super.initState();
    _remainingSeconds = _durationSeconds;
    _startSimulation();
  }

  Future<void> _startSimulation() async {
    // Tentative via API
    final result = await ApiService.demarrerSimulation();
    if (!mounted) return;

    List<dynamic> questions = (result['questions'] as List?) ?? [];

    // Si l'API retourne une erreur OU quota atteint → charger directement depuis Supabase
    // Aucun blocage premium : tous les utilisateurs connectés ont accès
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
      // Si vraiment aucune question disponible
      if (result['error'] != null && questions.isEmpty) {
        setState(() {
          _error = 'Aucune question disponible. Vérifiez votre connexion.';
          _loading = false;
        });
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

  // ── Feuille de questions (TÂCHE 7) ──
  Widget _buildQuestionsList() {
    return ListView.builder(
      controller: _questionsScroll,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
      itemCount: _questions.length,
      itemBuilder: (ctx, i) {
        final q = _questions[i] as Map<String, dynamic>;
        final texte = (q['enonce'] ?? q['question'] ?? '').toString();
        final showSep = _showMatiereSeparator(i);
        final matiereLabel = _getMatiereLabel(i);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Séparateur de matière
            if (showSep) ...[
              if (i > 0) const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
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
              const SizedBox(height: 10),
            ],

            // Question
            Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${i + 1}. ',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: AppColors.primary,
                      fontFamily: 'Poppins',
                    ),
                  ),
                  Expanded(
                    child: Text(
                      texte,
                      style: const TextStyle(
                        fontSize: 14,
                        fontFamily: 'Georgia',
                        height: 1.55,
                        color: AppColors.textDark,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  // ── Feuille de réponses style examen (TÂCHE 7) ──
  Widget _buildAnswerSheet() {
    return Container(
      color: const Color(0xFFFAFAFA),
      child: SingleChildScrollView(
        controller: _reponseScroll,
        padding: const EdgeInsets.fromLTRB(8, 12, 8, 80),
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

            // Lignes de réponses
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
                                  : Colors.transparent,
                              border: Border.all(
                                color: isSelected
                                    ? AppColors.primary
                                    : Colors.grey.withValues(alpha: 0.35),
                                width: 1.5,
                              ),
                            ),
                            child: Center(
                              child: isSelected
                                  ? const Icon(Icons.circle, color: Colors.white, size: 14)
                                  : Container(
                                      width: 14,
                                      height: 14,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: Colors.grey.withValues(alpha: 0.3),
                                          width: 1,
                                        ),
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
          ? SizedBox(
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
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textLight,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
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
                    style: const TextStyle(fontSize: 52, fontWeight: FontWeight.w900, color: AppColors.white, fontFamily: 'Poppins'),
                  ),
                  Text(
                    '$pct%  —  $_mention',
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.white),
                  ),
                  const SizedBox(height: 8),
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
                    Text(
                      (q['enonce'] ?? q['question'] ?? '').toString(),
                      style: const TextStyle(fontSize: 13, fontFamily: 'Georgia', height: 1.5, fontWeight: FontWeight.w500),
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
                              child: Text(
                                t,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isBonne ? AppColors.success : AppColors.error,
                                  fontFamily: 'Georgia',
                                ),
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
                        child: Text(
                          q['explication'].toString(),
                          style: const TextStyle(
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                            height: 1.5,
                            color: AppColors.textDark,
                          ),
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

      correction.add({
        'num': i + 1,
        'enonce': (q['enonce'] ?? q['question'] ?? '').toString(),
        'choisies': choisies.join(', '),
        'bonne': bonneStr.isEmpty ? '?' : bonneStr,
        'correct': correct,
        'noAns': noAns,
        'explication': q['explication']?.toString() ?? '',
      });
    }

    final total = questions.length;
    final pct = total > 0 ? (bonnes / total * 100).round() : 0;
    final mention = pct >= 70 ? 'Félicitations !' : pct >= 50 ? 'Bonne progression, continuez !' : 'Courage ! Chaque effort compte.';

    final primaryColor = PdfColor.fromHex('1A5C38');
    // ignore: unused_local_variable
    final accentColor = PdfColor.fromHex('D4A017');
    final errorColor = PdfColor.fromHex('D32F2F');
    final successColor = PdfColor.fromHex('22C55E');
    final greyColor = PdfColor.fromHex('6C757D');

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(30),
        header: (context) => pw.Container(
          padding: const pw.EdgeInsets.only(bottom: 10),
          decoration: pw.BoxDecoration(
            border: pw.Border(bottom: pw.BorderSide(color: primaryColor, width: 2)),
          ),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('EF-FORT.BF',
                      style: pw.TextStyle(
                        fontSize: 20,
                        fontWeight: pw.FontWeight.bold,
                        color: primaryColor,
                      )),
                  pw.Text('Résultats Examen Blanc',
                      style: pw.TextStyle(fontSize: 12, color: greyColor)),
                ],
              ),
              pw.Text('ef-fort-bf.pages.dev',
                  style: pw.TextStyle(fontSize: 10, color: greyColor)),
            ],
          ),
        ),
        footer: (context) => pw.Container(
          alignment: pw.Alignment.center,
          padding: const pw.EdgeInsets.only(top: 8),
          decoration: pw.BoxDecoration(
            border: pw.Border(top: pw.BorderSide(color: PdfColors.grey300)),
          ),
          child: pw.Text(
            'EF-FORT.BF — Transformer l\'effort en réussite  |  Page ${context.pageNumber}/${context.pagesCount}',
            style: pw.TextStyle(fontSize: 9, color: greyColor),
          ),
        ),
        build: (context) => [
          // Informations candidat
          pw.Container(
            padding: const pw.EdgeInsets.all(14),
            decoration: pw.BoxDecoration(
              color: PdfColor.fromHex('F8F9FA'),
              border: pw.Border.all(color: PdfColor.fromHex('E9ECEF')),
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Candidat : $nomCandidat',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 13)),
                    pw.SizedBox(height: 4),
                    pw.Text('Date : $dateStr',
                        style: const pw.TextStyle(fontSize: 11)),
                  ],
                ),
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: pw.BoxDecoration(
                    color: pct >= 50 ? successColor : errorColor,
                    borderRadius: pw.BorderRadius.circular(8),
                  ),
                  child: pw.Text(
                    '$bonnes / $total   ($pct%)',
                    style: pw.TextStyle(
                      color: PdfColors.white,
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 16),

          // Statistiques
          pw.Row(
            children: [
              _pdfStat('Bonnes réponses', '$bonnes', successColor),
              pw.SizedBox(width: 10),
              _pdfStat('Mauvaises', '$mauvaises', errorColor),
              pw.SizedBox(width: 10),
              _pdfStat('Sans réponse', '$sansRep', greyColor),
              pw.SizedBox(width: 10),
              _pdfStat('Score %', '$pct%', pct >= 50 ? successColor : errorColor),
            ],
          ),
          pw.SizedBox(height: 16),

          // Message d'encouragement
          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              color: pct >= 70 ? PdfColor.fromHex('E8F5E9') : PdfColor.fromHex('FFF3E0'),
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Text(
              mention,
              style: pw.TextStyle(
                fontSize: 13,
                fontWeight: pw.FontWeight.bold,
                color: pct >= 70 ? primaryColor : PdfColor.fromHex('E65100'),
              ),
            ),
          ),
          pw.SizedBox(height: 20),

          // Titre corrigé
          pw.Text(
            'CORRIGÉ DÉTAILLÉ',
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
              color: primaryColor,
            ),
          ),
          pw.Divider(color: primaryColor, thickness: 1.5),
          pw.SizedBox(height: 8),

          // Correction question par question
          ...correction.map((c) {
            final correct = c['correct'] as bool;
            final noAns = c['noAns'] as bool;
            final bgColor = noAns
                ? PdfColor.fromHex('F5F5F5')
                : correct
                    ? PdfColor.fromHex('E8F5E9')
                    : PdfColor.fromHex('FFEBEE');
            final statusIcon = noAns ? '—' : correct ? '✓' : '✗';
            final statusColor = noAns ? greyColor : correct ? successColor : errorColor;

            return pw.Container(
              margin: const pw.EdgeInsets.only(bottom: 8),
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                color: bgColor,
                borderRadius: pw.BorderRadius.circular(6),
                border: pw.Border.all(
                  color: noAns ? PdfColors.grey300 : correct ? PdfColor.fromHex('A5D6A7') : PdfColor.fromHex('FFCDD2'),
                ),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                        'Q${c['num']}.  ${(c['enonce'] as String).length > 80 ? '${(c['enonce'] as String).substring(0, 80)}...' : c['enonce']}',
                        style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
                      ),
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: pw.BoxDecoration(
                          color: statusColor,
                          borderRadius: pw.BorderRadius.circular(4),
                        ),
                        child: pw.Text(
                          statusIcon,
                          style: pw.TextStyle(color: PdfColors.white, fontSize: 10, fontWeight: pw.FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 4),
                  pw.Row(
                    children: [
                      pw.Text('Votre réponse: ', style: const pw.TextStyle(fontSize: 9)),
                      pw.Text(
                        c['choisies'].toString().isEmpty ? 'Aucune' : c['choisies'].toString(),
                        style: pw.TextStyle(
                          fontSize: 9,
                          fontWeight: pw.FontWeight.bold,
                          color: correct ? successColor : errorColor,
                        ),
                      ),
                      pw.SizedBox(width: 12),
                      pw.Text('Bonne réponse: ', style: const pw.TextStyle(fontSize: 9)),
                      pw.Text(
                        c['bonne'].toString(),
                        style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: successColor),
                      ),
                    ],
                  ),
                  if ((c['explication'] as String).isNotEmpty) ...[
                    pw.SizedBox(height: 3),
                    pw.Text(
                      '📖 ${c['explication']}',
                      style: pw.TextStyle(fontSize: 8, color: greyColor, fontStyle: pw.FontStyle.italic),
                    ),
                  ],
                ],
              ),
            );
          }),
        ],
      ),
    );

    return pdf.save();
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
            pw.Text(value, style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 16)),
            pw.Text(label, style: const pw.TextStyle(color: PdfColors.white, fontSize: 8)),
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
