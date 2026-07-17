import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import '../core/theme/app_colors.dart';
import '../data/demoQuestions.dart';
import '../services/api_service.dart';
import '../services/bell_service.dart';
import '../services/pdf_service.dart';
import '../widgets/logo_widget.dart';
import '../widgets/math_text_widget.dart';

// ══════════════════════════════════════════════════════════════
// DEMO EXAMEN SCREEN — Démo gratuite EF-FORT.BF
// ══════════════════════════════════════════════════════════════
//
// Objectif : permettre aux visiteurs de tester l'application
// avec 50 questions FIXES (extraites des séries 242 / 259 / 264)
// avant de s'abonner à la simulation payante.
//
// Architecture :
//   - Source de données : lib/data/demoQuestions.dart (en dur)
//   - AUCUN appel Supabase / API
//   - AUCUNE notion d'abonnement / quota
//   - Même interface que SimulationExamScreen :
//       • Cases à noircir A/B/C/D/E
//       • Chronomètre (1h30 par défaut)
//       • Sons cloche (BellService)
//       • Soumission impossible avant 30 min
//       • Écran de résultats avec correction détaillée
//
// ⚠️ Cet écran est volontairement INDÉPENDANT du flux
// SimulationLaunchScreen / ApiService. Il peut être supprimé
// ou désactivé sans toucher à la simulation payante.
// ══════════════════════════════════════════════════════════════

const int _kDemoDurationSeconds = 90 * 60; // 1h30
// ⚠️ MISSION 3 : la soumission avant l'heure est désormais POSSIBLE
// (plus de blocage à 30 min). On garde la constante pour compatibilité
// mais la propriété _canSubmit retourne maintenant toujours true.
const int _kDemoMinSecondsBeforeSubmit = 30 * 60; // (informatif uniquement)

// ══════════════════════════════════════════════════════════════
// ÉCRAN DE LANCEMENT — page d'accueil de la démo
// ══════════════════════════════════════════════════════════════
class DemoExamenScreen extends StatelessWidget {
  const DemoExamenScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Démo gratuite — Examen blanc',
          style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700),
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.primary, AppColors.primaryDark],
            ),
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
              'Démo gratuite',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: AppColors.textDark,
                fontFamily: 'Poppins',
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Testez EF-FORT.BF avec 50 questions officielles',
              style: TextStyle(fontSize: 14, color: AppColors.textLight),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            // Carte d'info — démo
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppColors.primary, AppColors.primaryDark],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.35),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.lock_open_rounded,
                          color: Colors.white, size: 22),
                      SizedBox(width: 8),
                      Text(
                        'Accès libre — sans inscription',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Cette démo reproduit fidèlement les conditions de la simulation officielle : 50 questions, 1h30 chrono, cases à noircir, sons d\'examen.',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.92),
                      fontSize: 13,
                      height: 1.5,
                      fontFamily: 'Georgia',
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Consignes
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
                    'CONSIGNES',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                      letterSpacing: 0.5,
                      fontFamily: 'Poppins',
                    ),
                  ),
                  const SizedBox(height: 12),
                  ..._buildConsignes(),
                ],
              ),
            ),

            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const DemoExamScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.play_circle_filled_rounded, size: 24),
                label: const Text(
                  'DÉMARRER LA DÉMO',
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
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
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

  List<Widget> _buildConsignes() {
    final consignes = [
      '50 questions de niveau concours professionnel.',
      'Lisez attentivement chaque question avant de répondre.',
      'Plusieurs réponses peuvent être correctes pour une même question.',
      'Noircissez les cases (A, B, C, D, E) sur la feuille de réponses.',
      'Une mauvaise réponse entraîne une pénalité ; sans réponse = 0 point.',
      'Durée totale : 1h30 — soumission possible après 30 minutes.',
      'À la fin, accédez gratuitement à la correction détaillée de chaque question.',
    ];
    return consignes
        .map((c) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '●  ',
                    style: TextStyle(
                        fontSize: 16, color: AppColors.primary, height: 1.4),
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
            ))
        .toList();
  }
}

// ══════════════════════════════════════════════════════════════
// ÉCRAN EXAMEN — Interface 2 colonnes (questions / feuille de réponses)
// ══════════════════════════════════════════════════════════════
class DemoExamScreen extends StatefulWidget {
  const DemoExamScreen({super.key});

  @override
  State<DemoExamScreen> createState() => _DemoExamScreenState();
}

class _DemoExamScreenState extends State<DemoExamScreen> {
  late List<Map<String, dynamic>> _questions;
  final Map<int, Set<String>> _answers = {};

  late int _remainingSeconds;
  Timer? _timer;
  bool _finished = false;
  bool _bellStartPlayed = false;

  // ── Surveillant virtuel ─────────────────────────────────────────────
  // Messages contextuels diffusés à des moments précis de l'examen
  // pour reproduire l'effet "surveillant" qui motive et rappelle
  // les consignes le jour J.
  final Set<int> _surveillantTriggers = {};
  String? _surveillantMessage;
  Timer? _surveillantHideTimer;

  final ScrollController _questionsScroll = ScrollController();
  final ScrollController _reponseScroll = ScrollController();

  // ⚠️ MISSION 3 : soumission TOUJOURS possible (plus de blocage 30min).
  // Si l'utilisateur soumet avant 30min, on lui affichera un message
  // d'encouragement bienveillant dans _showConfirmSubmit().

  /// Indique si l'utilisateur soumet "avant l'heure" (utilisé pour
  /// adapter le message d'encouragement dans le dialog de confirmation).
  bool get _isSubmittingEarly =>
      _remainingSeconds > (_kDemoDurationSeconds - _kDemoMinSecondsBeforeSubmit);

  @override
  void initState() {
    super.initState();
    _questions = getDemoQuestions();
    _remainingSeconds = _kDemoDurationSeconds;
    // Lance la cloche de démarrage et le timer après 1er frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_bellStartPlayed) {
        _bellStartPlayed = true;
        BellService.playExamStart();
      }
      _startTimer();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _surveillantHideTimer?.cancel();
    _questionsScroll.dispose();
    _reponseScroll.dispose();
    super.dispose();
  }

  // ── Surveillant virtuel : affiche un message bienveillant pendant
  //    quelques secondes en surimpression au-dessus de l'examen.
  void _showSurveillantMessage(String message,
      {Duration duration = const Duration(seconds: 5)}) {
    if (!mounted) return;
    _surveillantHideTimer?.cancel();
    setState(() => _surveillantMessage = message);
    _surveillantHideTimer = Timer(duration, () {
      if (mounted) setState(() => _surveillantMessage = null);
    });
  }

  void _startTimer() {
    // Message d'accueil du surveillant virtuel
    _showSurveillantMessage(
      "👮 Surveillant : Bienvenue ! Lisez bien chaque question avant de répondre. Bon courage !",
      duration: const Duration(seconds: 6),
    );

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_remainingSeconds <= 0) {
        timer.cancel();
        _finishExam();
      } else {
        setState(() => _remainingSeconds--);
        _checkSurveillantTriggers();
      }
    });
  }

  /// Déclenche les messages contextuels du surveillant virtuel à des
  /// moments précis de l'examen. Chaque trigger n'est joué qu'une fois.
  void _checkSurveillantTriggers() {
    final elapsed = _kDemoDurationSeconds - _remainingSeconds;

    // Triggers basés sur le temps ÉCOULÉ (clé unique = temps en secondes)
    final byElapsed = <int, String>{
      5 * 60: "👮 Surveillant : Concentrez-vous, vous êtes lancé(e). Prenez votre temps sur chaque énoncé.",
      15 * 60: "👮 Surveillant : Vous avez fait 15 minutes — gardez le rythme et n'oubliez pas de cocher la feuille de réponses.",
      30 * 60: "👮 Surveillant : 30 minutes écoulées. Vous pouvez désormais soumettre votre copie quand vous le souhaitez.",
      45 * 60: "👮 Surveillant : Mi-parcours ! Si une question vous bloque, passez à la suivante et revenez plus tard.",
      60 * 60: "👮 Surveillant : Plus qu'une demi-heure. Relisez attentivement vos réponses si vous avez fini.",
    };

    // Triggers basés sur le temps RESTANT
    final byRemaining = <int, String>{
      30 * 60: "👮 Surveillant : Plus que 30 minutes — gardez le cap !",
      15 * 60: "👮 Surveillant : Plus que 15 minutes ! Pensez à vérifier les questions sans réponse.",
      10 * 60: "👮 Surveillant : 10 minutes restantes. Concentrez-vous sur les questions les plus rapides.",
      5 * 60: "🔔 ATTENTION : 5 minutes restantes ! Finalisez votre feuille de réponses.",
      2 * 60: "🔔 Plus que 2 minutes ! Soumettez votre copie dès que vous êtes prêt.",
      30: "🔔 Derniers instants — la cloche va sonner !",
    };

    if (byElapsed.containsKey(elapsed) &&
        !_surveillantTriggers.contains(elapsed)) {
      _surveillantTriggers.add(elapsed);
      _showSurveillantMessage(byElapsed[elapsed]!);
      // Petit "ding" discret pour les rappels mi-parcours
      if (elapsed == 30 * 60 || elapsed == 45 * 60) {
        BellService.playClick();
      }
    }

    if (byRemaining.containsKey(_remainingSeconds) &&
        !_surveillantTriggers.contains(-_remainingSeconds)) {
      _surveillantTriggers.add(-_remainingSeconds);
      _showSurveillantMessage(byRemaining[_remainingSeconds]!);
      if (_remainingSeconds == 5 * 60 ||
          _remainingSeconds == 2 * 60 ||
          _remainingSeconds == 30) {
        BellService.playReminder();
      }
    }
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
        BellService.playClick();
      }
    });
  }

  String _getMatiereLabel(int idx) {
    if (idx >= _questions.length) return '';
    final q = _questions[idx];
    return (q['matiere'] ?? 'Culture Générale').toString();
  }

  bool _showMatiereSeparator(int idx) {
    if (idx == 0) return true;
    return _getMatiereLabel(idx) != _getMatiereLabel(idx - 1);
  }

  Future<void> _finishExam() async {
    if (_finished) return;
    _timer?.cancel();
    _surveillantHideTimer?.cancel();
    // Cloche de fin + applaudissements pour célébrer la soumission
    await BellService.playEnd();
    BellService.playApplause();
    if (!mounted) return;
    setState(() => _finished = true);

    int bonnes = 0, mauvaises = 0, sansReponse = 0;
    final Map<String, List<int>> scoreParMatiere = {};

    for (int i = 0; i < _questions.length; i++) {
      final q = _questions[i];
      final bonneStr = (q['bonne_reponse'] ?? '').toString().toUpperCase();
      final bonneSet = bonneStr
          .split('')
          .where((c) => ['A', 'B', 'C', 'D', 'E'].contains(c))
          .toSet();
      final matiere = (q['matiere'] ?? 'autre').toString();
      scoreParMatiere.putIfAbsent(matiere, () => [0, 0]);
      final choisies = _answers[i] ?? {};

      if (choisies.isEmpty) {
        sansReponse++;
      } else if (choisies.containsAll(bonneSet) &&
          bonneSet.containsAll(choisies)) {
        bonnes++;
        scoreParMatiere[matiere]![0]++;
      } else {
        mauvaises++;
      }
      scoreParMatiere[matiere]![1]++;
    }

    final score = (bonnes - mauvaises).clamp(0, _questions.length);
    final tempsUtilise = _kDemoDurationSeconds - _remainingSeconds;

    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => DemoResultScreen(
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
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 700;
    final answeredCount =
        _answers.values.where((s) => s.isNotEmpty).length;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          _showEncouragementExitDialog();
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
              gradient: LinearGradient(
                  colors: [AppColors.primary, AppColors.primaryDark]),
            ),
          ),
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: _showEncouragementExitDialog,
          ),
          actions: [
            Center(
              child: Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$answeredCount/${_questions.length}',
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 13),
                  ),
                ),
              ),
            ),
          ],
        ),
        body: Stack(
          children: [
            Column(
              children: [
                Expanded(
                  child: isWide ? _buildTwoColumns() : _buildSingleColumn(),
                ),
                _buildSubmitBar(answeredCount),
              ],
            ),
            // ── Surveillant virtuel : message contextuel en surimpression
            if (_surveillantMessage != null)
              Positioned(
                top: 12,
                left: 12,
                right: 12,
                child: _buildSurveillantBanner(_surveillantMessage!),
              ),
          ],
        ),
      ),
    );
  }

  // ── Bandeau du surveillant virtuel ──────────────────────────────────
  Widget _buildSurveillantBanner(String message) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: Material(
        key: ValueKey(message),
        color: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1A5C38), Color(0xFF0F3D24)],
            ),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: const Color(0xFFD4A017).withValues(alpha: 0.6),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFFD4A017).withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFFD4A017).withValues(alpha: 0.5),
                  ),
                ),
                child: const Center(
                  child: Text('👮', style: TextStyle(fontSize: 18)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    height: 1.4,
                  ),
                ),
              ),
              GestureDetector(
                onTap: () {
                  _surveillantHideTimer?.cancel();
                  setState(() => _surveillantMessage = null);
                },
                child: Icon(
                  Icons.close_rounded,
                  size: 18,
                  color: Colors.white.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTwoColumns() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 60,
          child: Container(
            decoration: const BoxDecoration(
              border: Border(
                  right: BorderSide(color: Color(0xFFE0E0E0), width: 1)),
            ),
            child: _buildQuestionsList(),
          ),
        ),
        Expanded(
          flex: 40,
          child: _buildAnswerSheet(),
        ),
      ],
    );
  }

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

  Widget _buildQuestionsList() {
    return Column(
      children: [
        Container(
          width: double.infinity,
          margin: const EdgeInsets.fromLTRB(12, 10, 12, 0),
          padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 14),
          decoration: BoxDecoration(
            color: const Color(0xFFE8F5E9),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.3), width: 1),
          ),
          child: const Row(
            children: [
              Icon(Icons.menu_book_rounded,
                  color: AppColors.primary, size: 18),
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
              final q = _questions[i];
              final texte = (q['enonce'] ?? '').toString();
              final showSep = _showMatiereSeparator(i);
              final matiereLabel = _getMatiereLabel(i);
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
                  if (showSep) ...[
                    if (i > 0) const SizedBox(height: 14),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          vertical: 7, horizontal: 12),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.07),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color:
                                AppColors.primary.withValues(alpha: 0.2)),
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
                  Container(
                    margin: const EdgeInsets.only(bottom: 14),
                    padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: const Color(0xFFE0E0E0), width: 1),
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
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 28,
                              height: 28,
                              decoration: const BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  '${i + 1}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 14,
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
                                  fontSize: 15,
                                  fontFamily: 'Georgia',
                                  height: 1.5,
                                  color: AppColors.textDark,
                                  fontWeight: FontWeight.w600,
                                ),
                                mathSize: 15.0,
                                mathColor: AppColors.textDark,
                              ),
                            ),
                          ],
                        ),
                        if (options.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          const Divider(
                              height: 1,
                              thickness: 0.5,
                              color: Color(0xFFEEEEEE)),
                          const SizedBox(height: 6),
                          ...options.map((opt) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: Row(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 26,
                                    height: 26,
                                    decoration: BoxDecoration(
                                      color: AppColors.primary
                                          .withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(5),
                                      border: Border.all(
                                        color: AppColors.primary
                                            .withValues(alpha: 0.3),
                                        width: 1,
                                      ),
                                    ),
                                    child: Center(
                                      child: Text(
                                        opt.key,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w800,
                                          fontSize: 13,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: MathTextWidget(
                                      text: opt.value,
                                      textStyle: const TextStyle(
                                        fontSize: 14,
                                        fontFamily: 'Georgia',
                                        height: 1.4,
                                        color: AppColors.textDark,
                                      ),
                                      mathSize: 14.0,
                                      mathColor: AppColors.textDark,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
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

  Widget _buildAnswerSheet() {
    return Container(
      color: const Color(0xFFFAFAFA),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            margin: const EdgeInsets.fromLTRB(8, 10, 8, 0),
            padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFE3F2FD),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                  color: const Color(0xFF1565C0).withValues(alpha: 0.3),
                  width: 1),
            ),
            child: const Row(
              children: [
                Icon(Icons.edit_rounded,
                    color: Color(0xFF1565C0), size: 18),
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
                          width: 44,
                          child: Text('N°',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 12)),
                        ),
                        Expanded(
                            child: Text('A',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 13))),
                        Expanded(
                            child: Text('B',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 13))),
                        Expanded(
                            child: Text('C',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 13))),
                        Expanded(
                            child: Text('D',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 13))),
                        Expanded(
                            child: Text('E',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 13))),
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
                        color: isEven ? Colors.white : const Color(0xFFF5F5F5),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        children: [
                          const SizedBox(width: 4),
                          SizedBox(
                            width: 44,
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
                            final isSelected =
                                selectedLetters.contains(letter);
                            return Expanded(
                              child: GestureDetector(
                                onTap: () => _toggleAnswer(i, letter),
                                child: Container(
                                  height: 32,
                                  margin: const EdgeInsets.all(2),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: isSelected
                                        ? AppColors.primary
                                        : Colors.white,
                                    border: Border.all(
                                      color: isSelected
                                          ? AppColors.primary
                                          : Colors.grey
                                              .withValues(alpha: 0.4),
                                      width: isSelected ? 2 : 1.5,
                                    ),
                                    boxShadow: isSelected
                                        ? [
                                            BoxShadow(
                                              color: AppColors.primary
                                                  .withValues(alpha: 0.3),
                                              blurRadius: 3,
                                              offset: const Offset(0, 1),
                                            ),
                                          ]
                                        : null,
                                  ),
                                  child: Center(
                                    child: Text(
                                      letter,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w800,
                                        color: isSelected
                                            ? Colors.white
                                            : Colors.grey.shade500,
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

  Widget _buildSubmitBar(int answeredCount) {
    // ⚠️ MISSION 3 : la soumission est désormais TOUJOURS possible.
    // Si l'utilisateur soumet avant 30 min, on affichera un message
    // d'encouragement bienveillant dans le dialog de confirmation.
    return Container(
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
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
          child: SizedBox(
            width: double.infinity,
            height: 60,
            child: ElevatedButton(
              onPressed: () => _showConfirmSubmit(answeredCount),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                elevation: 4,
              ),
              child: const Text(
                'SOUMETTRE MA COPIE',
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    fontFamily: 'Poppins'),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════
  // DIALOG DE SORTIE ANTICIPÉE — Message d'encouragement bienveillant
  // ════════════════════════════════════════════════════════════════
  // L'utilisateur peut quitter à tout moment, mais on l'encourage
  // chaleureusement à rester pour découvrir les 50 questions.
  void _showEncouragementExitDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Text('💚', style: TextStyle(fontSize: 26)),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Tu quittes déjà ?',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.2)),
              ),
              child: const Text(
                'Prends le temps de découvrir les 50 questions. '
                'Cette démo est gratuite, sans abonnement.\n\n'
                'Reste un peu, tu pourrais être surpris(e) ! 🚀',
                style: TextStyle(
                  fontSize: 14.5,
                  height: 1.55,
                  color: AppColors.textDark,
                  fontFamily: 'Georgia',
                ),
              ),
            ),
          ],
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _timer?.cancel();
              Navigator.pop(context);
            },
            child: const Text(
              'Quitter quand même',
              style: TextStyle(
                  color: AppColors.error, fontWeight: FontWeight.w600),
            ),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(ctx),
            icon: const Icon(Icons.play_arrow_rounded, size: 20),
            label: const Text(
              'Rester et continuer',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            ),
          ),
        ],
      ),
    );
  }

  void _showConfirmSubmit(int answeredCount) {
    final isEarly = _isSubmittingEarly;
    final minutesEcoulees =
        (_kDemoDurationSeconds - _remainingSeconds) ~/ 60;

    // Message d'encouragement bienveillant si soumission avant 30 min
    final encouragementMessage = isEarly
        ? "Tu soumets après seulement $minutesEcoulees min. C'est ton choix : "
            "tu peux soumettre quand tu veux ! 💪\n\n"
            "Astuce : sur l'examen réel, on conseille de prendre le temps "
            "de relire ses réponses avant de rendre la copie."
        : "Tu as bien utilisé ton temps. Soumets ta copie quand tu es prêt(e) !";

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Text(
              isEarly ? '⚡' : '✅',
              style: const TextStyle(fontSize: 26),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'Terminer la démo ?',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tu as répondu à $answeredCount/${_questions.length} questions.',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: (isEarly
                        ? const Color(0xFFE67E22)
                        : AppColors.primary)
                    .withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: (isEarly
                          ? const Color(0xFFE67E22)
                          : AppColors.primary)
                      .withValues(alpha: 0.3),
                ),
              ),
              child: Text(
                encouragementMessage,
                style: const TextStyle(
                  fontSize: 13.5,
                  height: 1.55,
                  color: AppColors.textDark,
                  fontFamily: 'Georgia',
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Continuer la démo'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _finishExam();
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
// ÉCRAN DES RÉSULTATS — score + correction détaillée
// ══════════════════════════════════════════════════════════════
class DemoResultScreen extends StatefulWidget {
  final int score, total, bonnes, mauvaises, sansReponse, tempsUtilise;
  final List<Map<String, dynamic>> questions;
  final Map<int, Set<String>> answers;
  final Map<String, List<int>> scoreParMatiere;

  const DemoResultScreen({
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

  @override
  State<DemoResultScreen> createState() => _DemoResultScreenState();
}

class _DemoResultScreenState extends State<DemoResultScreen> {
  bool _generatingSujet = false;
  bool _generatingCorrection = false;

  // Raccourcis pour accéder aux propriétés du widget
  int get score => widget.score;
  int get total => widget.total;
  int get bonnes => widget.bonnes;
  int get mauvaises => widget.mauvaises;
  int get sansReponse => widget.sansReponse;
  int get tempsUtilise => widget.tempsUtilise;
  List<Map<String, dynamic>> get questions => widget.questions;
  Map<int, Set<String>> get answers => widget.answers;
  Map<String, List<int>> get scoreParMatiere => widget.scoreParMatiere;

  // ────────────────────────────────────────────────────────────
  // Conversion des questions de la démo → PdfQuestion (pour PdfService)
  // ────────────────────────────────────────────────────────────
  List<PdfQuestion> _toPdfQuestions({required bool withAnswers}) {
    final result = <PdfQuestion>[];
    for (int i = 0; i < questions.length; i++) {
      final q = questions[i];
      final options = <String, String>{};
      for (final l in ['A', 'B', 'C', 'D', 'E']) {
        final key = 'option_${l.toLowerCase()}';
        final v = (q[key] ?? '').toString();
        if (v.trim().isNotEmpty) options[l] = v;
      }

      if (!withAnswers) {
        result.add(PdfQuestion(
          numero: i + 1,
          categorie: (q['categorie'] ?? q['matiere'] ?? '').toString(),
          enonce: (q['enonce'] ?? '').toString(),
          options: options,
          pointsMax: 1,
        ));
        continue;
      }

      final bonneStr = (q['bonne_reponse'] ?? '').toString().toUpperCase();
      final bonneSet = bonneStr
          .split('')
          .where((c) => ['A', 'B', 'C', 'D', 'E'].contains(c))
          .toSet();
      final choisies = answers[i] ?? <String>{};
      final correct = choisies.isNotEmpty &&
          choisies.containsAll(bonneSet) &&
          bonneSet.containsAll(choisies);
      final noAns = choisies.isEmpty;
      final bonneDisplay = (bonneSet.toList()..sort()).join('+');
      final choisiesDisplay =
          choisies.isEmpty ? '' : (choisies.toList()..sort()).join('+');

      result.add(PdfQuestion(
        numero: i + 1,
        categorie: (q['categorie'] ?? q['matiere'] ?? '').toString(),
        enonce: (q['enonce'] ?? '').toString(),
        reponseEleve: choisiesDisplay,
        bonneReponse: bonneDisplay,
        explication: (q['explication'] ?? '').toString(),
        points: correct ? 1 : 0,
        pointsMax: 1,
        correct: correct,
        nonRepondu: noAns,
        options: options,
      ));
    }
    return result;
  }

  // ────────────────────────────────────────────────────────────
  // MISSION 3 : récupération dynamique du nom du candidat
  // - Si l'utilisateur est connecté → "Prénom Nom"
  // - Sinon → "Invité – Démo gratuite"
  // ────────────────────────────────────────────────────────────
  String _getNomCandidatPourPdf() {
    final user = ApiService.currentUser;
    if (user != null) {
      final prenom = (user['prenom'] ?? '').toString().trim();
      final nom = (user['nom'] ?? '').toString().trim();
      final fullName = '$prenom $nom'.trim();
      if (fullName.isNotEmpty) return fullName;
    }
    return 'Invité – Démo gratuite';
  }

  // ────────────────────────────────────────────────────────────
  // Génère le PDF SUJET (50 questions seulement, sans réponses)
  // ────────────────────────────────────────────────────────────
  Future<void> _generatePdfSujet() async {
    if (_generatingSujet) return;
    setState(() => _generatingSujet = true);
    try {
      final pdfBytes = await PdfService.genererSujetVierge(
        nomCandidat: _getNomCandidatPourPdf(),
        sujet: 'Démo gratuite EF-FORT.BF — 50 questions',
        questions: _toPdfQuestions(withAnswers: false),
        duree: '1h30',
        titrePdf: 'Démo gratuite – Sujet (50 questions)',
      );
      await Printing.sharePdf(
        bytes: pdfBytes,
        filename: 'EF-FORT_Demo_Sujet.pdf',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur PDF sujet : $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _generatingSujet = false);
    }
  }

  // ────────────────────────────────────────────────────────────
  // Génère le PDF CORRECTION (50 questions + réponses + explications)
  // ────────────────────────────────────────────────────────────
  Future<void> _generatePdfCorrection() async {
    if (_generatingCorrection) return;
    setState(() => _generatingCorrection = true);
    try {
      final Uint8List pdfBytes = await PdfService.genererCopieCorrigee(
        kind: PdfKind.examen,
        nomCandidat: _getNomCandidatPourPdf(),
        sujet: 'Démo gratuite EF-FORT.BF — 50 questions',
        questions: _toPdfQuestions(withAnswers: true),
        scoreObtenu: bonnes,
        scoreTotal: total,
        titrePdf: 'Démo gratuite – Correction détaillée (50 questions)',
      );
      await Printing.sharePdf(
        bytes: pdfBytes,
        filename: 'EF-FORT_Demo_Correction.pdf',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur PDF correction : $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _generatingCorrection = false);
    }
  }

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
        title: const Text('Résultats — Démo'),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
                colors: [AppColors.primary, AppColors.primaryDark]),
          ),
        ),
        foregroundColor: AppColors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    _mentionColor,
                    _mentionColor.withValues(alpha: 0.7)
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  Text(
                    '$score / $total',
                    style: const TextStyle(
                        fontSize: 42,
                        fontWeight: FontWeight.w900,
                        color: AppColors.white,
                        fontFamily: 'Poppins'),
                  ),
                  Text(
                    '$pct%  —  $_mention',
                    style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.white),
                  ),
                  const SizedBox(height: 16),
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
                          total > 0
                              ? (score / total * 20).toStringAsFixed(1)
                              : '0',
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
                    style: TextStyle(
                        fontSize: 14,
                        color: AppColors.white.withValues(alpha: 0.8)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
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

            if (scoreParMatiere.isNotEmpty) ...[
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Score par matière',
                  style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textDark),
                ),
              ),
              const SizedBox(height: 10),
              ...scoreParMatiere.entries.map((entry) {
                final matNom =
                    entry.key.replaceAll('_', ' ').toUpperCase();
                final b = entry.value[0];
                final t = entry.value[1];
                final p = t > 0 ? b / t : 0.0;
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 6)
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                          child: Text(matNom,
                              style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600))),
                      Text('$b / $t',
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: p >= 0.6
                                  ? AppColors.success
                                  : AppColors.error)),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 20),
            ],

            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Correction détaillée',
                style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark),
              ),
            ),
            const SizedBox(height: 10),

            ...questions.asMap().entries.map((entry) {
              final i = entry.key;
              final q = entry.value;
              final bonneStr =
                  (q['bonne_reponse'] ?? '').toString().toUpperCase();
              final bonneSet = bonneStr
                  .split('')
                  .where((c) => ['A', 'B', 'C', 'D', 'E'].contains(c))
                  .toSet();
              final choisies = answers[i] ?? {};
              final correct = choisies.containsAll(bonneSet) &&
                  bonneSet.containsAll(choisies) &&
                  choisies.isNotEmpty;
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
                          style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 17,
                              color: AppColors.primary),
                        ),
                        const SizedBox(width: 6),
                        Icon(
                          noAns
                              ? Icons.remove_circle_outline
                              : (correct
                                  ? Icons.check_circle_outline
                                  : Icons.cancel_outlined),
                          size: 22,
                          color: noAns
                              ? Colors.grey
                              : (correct
                                  ? AppColors.success
                                  : AppColors.error),
                        ),
                        const Spacer(),
                        Text(
                          noAns
                              ? 'Non répondu'
                              : (correct ? 'Correct' : 'Incorrect'),
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: noAns
                                ? Colors.grey
                                : (correct
                                    ? AppColors.success
                                    : AppColors.error),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    MathTextWidget(
                      text: (q['enonce'] ?? '').toString(),
                      textStyle: const TextStyle(
                          fontSize: 17,
                          fontFamily: 'Georgia',
                          height: 1.6,
                          fontWeight: FontWeight.w500),
                      mathSize: 17,
                      mathColor: AppColors.textDark,
                    ),
                    const SizedBox(height: 8),
                    ...options.entries.map((opt) {
                      final l = opt.key;
                      final t = opt.value;
                      if (t.isEmpty) return const SizedBox.shrink();
                      final isBonne = bonneSet.contains(l);
                      final isChoisie = choisies.contains(l);

                      if (!isBonne && !isChoisie) {
                        return const SizedBox.shrink();
                      }

                      return Container(
                        margin: const EdgeInsets.only(bottom: 4),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: isBonne
                              ? AppColors.success.withValues(alpha: 0.1)
                              : AppColors.error.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(7),
                        ),
                        child: Row(
                          children: [
                            Text(
                              '$l.  ',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: isBonne
                                    ? AppColors.success
                                    : AppColors.error,
                                fontSize: 16,
                              ),
                            ),
                            Expanded(
                              child: MathTextWidget(
                                text: t,
                                textStyle: TextStyle(
                                  fontSize: 15,
                                  color: isBonne
                                      ? AppColors.success
                                      : AppColors.error,
                                  fontFamily: 'Georgia',
                                ),
                                mathSize: 15,
                                mathColor: isBonne
                                    ? AppColors.success
                                    : AppColors.error,
                              ),
                            ),
                            Icon(
                              isBonne ? Icons.check : Icons.close,
                              size: 18,
                              color: isBonne
                                  ? AppColors.success
                                  : AppColors.error,
                            ),
                          ],
                        ),
                      );
                    }),
                    if (q['explication'] != null &&
                        (q['explication'] as String).isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1A5C38)
                              .withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: MathTextWidget(
                          text: q['explication'].toString(),
                          textStyle: const TextStyle(
                            fontSize: 15,
                            fontStyle: FontStyle.italic,
                            height: 1.6,
                            color: AppColors.textDark,
                          ),
                          mathSize: 15,
                          mathColor: AppColors.textDark,
                        ),
                      ),
                    ],
                  ],
                ),
              );
            }),

            const SizedBox(height: 24),

            // ══════════════════════════════════════════════════
            // SECTION PDF — Sujet + Correction
            // ══════════════════════════════════════════════════
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.25),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.picture_as_pdf_rounded,
                          color: AppColors.primary, size: 22),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Téléchargez vos PDF',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textDark,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Imprimez ou partagez vos copies — qualité professionnelle, logo EF-FORT.BF inclus.',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textLight,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 14),
                  // Bouton PDF Sujet
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton.icon(
                      onPressed: _generatingSujet ? null : _generatePdfSujet,
                      icon: _generatingSujet
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.primary,
                              ),
                            )
                          : const Icon(Icons.description_outlined, size: 20),
                      label: const Text(
                        'PDF — Sujet (50 questions)',
                        style: TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w700),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: BorderSide(
                            color: AppColors.primary.withValues(alpha: 0.5),
                            width: 1.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Bouton PDF Correction
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed:
                          _generatingCorrection ? null : _generatePdfCorrection,
                      icon: _generatingCorrection
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.fact_check_outlined, size: 20),
                      label: const Text(
                        'PDF — Correction détaillée',
                        style: TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w700),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ══════════════════════════════════════════════════
            // PARCOURS FINAL — Message d'encouragement + boutons
            // ══════════════════════════════════════════════════
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppColors.primary, AppColors.primaryDark],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.35),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const Text('🎉', style: TextStyle(fontSize: 38)),
                  const SizedBox(height: 8),
                  const Text(
                    'Bravo !',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      fontFamily: 'Poppins',
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Tu as découvert notre démo gratuite. '
                    'Continue ton aventure avec EF-FORT.BF et donne-toi '
                    'toutes les chances de réussir tes concours !',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withValues(alpha: 0.95),
                      height: 1.55,
                      fontFamily: 'Georgia',
                    ),
                  ),
                  const SizedBox(height: 18),
                  // Bouton "S'abonner maintenant" (or)
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => Container(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.workspace_premium_rounded,
                          size: 22),
                      label: const Text(
                        "S'abonner maintenant",
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.3,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFD4A017),
                        foregroundColor: Colors.white,
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Bouton "Entrer au cœur de l'application"
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        // Retour à l'accueil (splash → flux normal)
                        Navigator.popUntil(
                            context, (route) => route.isFirst);
                      },
                      icon: const Icon(Icons.dashboard_rounded, size: 20),
                      label: const Text(
                        "Entrer au cœur de l'application",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: BorderSide(
                            color: Colors.white.withValues(alpha: 0.7),
                            width: 1.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
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
            Text(value,
                style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: color)),
            Text(label,
                style: TextStyle(
                    fontSize: 15,
                    color: color,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}
