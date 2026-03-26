import 'dart:async';
import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../services/api_service.dart';
import '../widgets/logo_widget.dart';

class SimulationLaunchScreen extends StatelessWidget {
  const SimulationLaunchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Mode Examen'),
        automaticallyImplyLeading: false,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(colors: [AppColors.primary, AppColors.primaryDark]),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 20),
            const LogoWidget(size: 100, borderRadius: 20),
            const SizedBox(height: 28),
            const Text(
              'Simulation d\'Examen',
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: AppColors.textDark),
            ),
            const SizedBox(height: 12),
            Text(
              'Conditions reelles du concours',
              style: TextStyle(fontSize: 15, color: AppColors.textLight),
            ),
            const SizedBox(height: 32),
            _buildInfoCard(Icons.quiz_rounded, '50 Questions', 'QCM multi-matieres'),
            _buildInfoCard(Icons.timer_rounded, '1h30 Chronometre', 'Temps reel d\'examen'),
            _buildInfoCard(Icons.gavel_rounded, 'Bareme officiel', '+1 bonne | -1 mauvaise | 0 sans reponse'),
            _buildInfoCard(Icons.emoji_events_rounded, 'Score et corrections', 'Resultats detailles par matiere'),
            const SizedBox(height: 32),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.secondaryLight,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.secondary.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded, color: AppColors.secondary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Une fois lancee, la simulation ne peut pas etre mise en pause. Score minimum : 0/50',
                      style: TextStyle(fontSize: 13, color: AppColors.textDark, height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SimulationExamScreen()),
                  );
                },
                icon: const Icon(Icons.play_circle_filled_rounded, size: 24),
                label: const Text('DEMARRER LA SIMULATION', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 4,
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(IconData icon, String title, String subtitle) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.primary, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textDark)),
                const SizedBox(height: 2),
                Text(subtitle, style: TextStyle(fontSize: 13, color: AppColors.textLight)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

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
  int _currentIndex = 0;
  final Map<int, String> _answers = {};
  late int _remainingSeconds;
  Timer? _timer;
  bool _finished = false;
  bool _consignesAccepted = false;

  // Blocage soumission avant 30 minutes
  static const int _minSecondsBeforeSubmit = 30 * 60; // 30 min
  bool get _canSubmit =>
      _remainingSeconds <= (90 * 60 - _minSecondsBeforeSubmit);
  int get _secondsBeforeCanSubmit =>
      _remainingSeconds > (90 * 60 - _minSecondsBeforeSubmit)
          ? _remainingSeconds - (90 * 60 - _minSecondsBeforeSubmit)
          : 0;

  @override
  void initState() {
    super.initState();
    _remainingSeconds = 90 * 60;
    _startSimulation();
  }

  Future<void> _startSimulation() async {
    final result = await ApiService.demarrerSimulation();
    if (!mounted) return;

    if (result['error'] != null) {
      setState(() {
        _error = result['error'] as String;
        _loading = false;
      });
      return;
    }

    setState(() {
      _sessionId = result['session_id'] as String?;
      _questions = (result['questions'] as List?) ?? [];
      _remainingSeconds = ((result['duree'] ?? 90) as int) * 60;
      _loading = false;
    });

    // Afficher les consignes officielles avant de démarrer
    if (mounted && !_consignesAccepted) {
      _showConsignesDialog();
    } else {
      _startTimer();
    }
  }

  void _showConsignesDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Text('📋', style: TextStyle(fontSize: 24)),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'CONSIGNES OFFICIELLES',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textDark,
                ),
              ),
            ),
          ],
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
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 12),
              _consigne('📌', '50 questions — Durée : 1h30'),
              _consigne('✅', 'Noircissez complètement la case choisie'),
              _consigne('❌', 'Ne mettez pas de croix (X) ni de trait'),
              _consigne('⚠️', 'Une mauvaise réponse = −1 point'),
              _consigne('⭕', 'Sans réponse = 0 point (ne pénalise pas)'),
              _consigne('🔒', 'Impossible de soumettre avant 30 minutes'),
              _consigne('✔️', 'Vous pouvez sauter une question (0 point)'),
              _consigne('📝', 'Une question peut avoir plusieurs réponses'),
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
                _startTimer();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: const Text(
                "✅ J'ai compris — Démarrer l'examen",
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _consigne(String emoji, String texte) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              texte,
              style: const TextStyle(fontSize: 13, height: 1.4),
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
        _finishSimulation();
      } else {
        setState(() => _remainingSeconds--);
        // Alertes sonores (simulation via debug print — sons réels nécessiteraient audioplayers)
        if (_remainingSeconds == 15 * 60 && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('⚠️ Plus que 15 minutes !'),
              backgroundColor: AppColors.secondary,
              duration: Duration(seconds: 3),
            ),
          );
        }
        if (_remainingSeconds == 5 * 60 && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('🚨 ATTENTION : 5 minutes restantes !'),
              backgroundColor: AppColors.error,
              duration: Duration(seconds: 4),
            ),
          );
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
    if (_remainingSeconds <= 900) return AppColors.secondary;
    return AppColors.white;
  }

  void _selectAnswer(String letter) {
    if (_finished) return;
    setState(() => _answers[_currentIndex] = letter);
  }

  Future<void> _finishSimulation() async {
    if (_finished) return;
    _timer?.cancel();
    setState(() => _finished = true);

    final reponses = <Map<String, String>>[];
    for (int i = 0; i < _questions.length; i++) {
      final q = _questions[i] as Map<String, dynamic>;
      reponses.add({
        'question_id': (q['id'] ?? '').toString(),
        'reponse': _answers[i] ?? '',
      });
    }

    final tempsUtilise = (90 * 60) - _remainingSeconds;

    if (_sessionId != null) {
      await ApiService.terminerSimulation(
        sessionId: _sessionId!,
        reponses: reponses,
        tempsUtilise: tempsUtilise,
      );
    }

    if (!mounted) return;

    int bonnes = 0;
    int mauvaises = 0;
    int sansReponse = 0;
    Map<String, List<int>> scoreParMatiere = {};

    for (int i = 0; i < _questions.length; i++) {
      final q = _questions[i] as Map<String, dynamic>;
      final correct = (q['bonne_reponse'] ?? '').toString();
      final matiere = (q['matiere'] ?? 'autre').toString();
      scoreParMatiere.putIfAbsent(matiere, () => [0, 0]);

      if (_answers[i] == null || _answers[i]!.isEmpty) {
        sansReponse++;
      } else if (_answers[i] == correct) {
        bonnes++;
        scoreParMatiere[matiere]![0]++;
      } else {
        mauvaises++;
      }
      scoreParMatiere[matiere]![1]++;
    }

    final score = (bonnes - mauvaises).clamp(0, _questions.length);

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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(color: AppColors.primary),
              const SizedBox(height: 20),
              const Text('Chargement de la simulation...', style: TextStyle(fontSize: 16, color: AppColors.textLight)),
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

    final q = _questions[_currentIndex] as Map<String, dynamic>;
    final options = {'A': q['option_a'], 'B': q['option_b'], 'C': q['option_c'], 'D': q['option_d']};
    final answeredCount = _answers.length;

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
          title: Text(_timerDisplay, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: _timerColor)),
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
            LinearProgressIndicator(
              value: (_currentIndex + 1) / _questions.length,
              backgroundColor: AppColors.primary.withValues(alpha: 0.1),
              color: AppColors.primary,
              minHeight: 3,
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Q${_currentIndex + 1}/${_questions.length}',
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.primary),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.secondary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            (q['matiere'] ?? '').toString().replaceAll('_', ' '),
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.secondary),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)],
                      ),
                      child: Text(
                        q['question'] ?? '',
                        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600, height: 1.5),
                      ),
                    ),
                    const SizedBox(height: 20),
                    ...options.entries.map((entry) {
                      final isSelected = _answers[_currentIndex] == entry.key;
                      return GestureDetector(
                        onTap: () => _selectAnswer(entry.key),
                        child: Container(
                          width: double.infinity,
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isSelected ? AppColors.primary.withValues(alpha: 0.08) : AppColors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isSelected ? AppColors.primary : Colors.transparent,
                              width: 2,
                            ),
                            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 4)],
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: isSelected ? AppColors.primary : AppColors.primary.withValues(alpha: 0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: isSelected
                                      ? const Icon(Icons.check, color: AppColors.white, size: 18)
                                      : Text(entry.key, style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.primary)),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Text(
                                  (entry.value ?? '').toString(),
                                  style: TextStyle(
                                    fontSize: 15,
                                    color: AppColors.textDark,
                                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.white,
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 8, offset: const Offset(0, -2))],
              ),
              child: Row(
                children: [
                  if (_currentIndex > 0)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => setState(() => _currentIndex--),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: const BorderSide(color: AppColors.primary),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Precedent', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600)),
                      ),
                    ),
                  if (_currentIndex > 0) const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        if (_currentIndex < _questions.length - 1) {
                          setState(() => _currentIndex++);
                        } else {
                          // Vérifier si 30 min se sont écoulées
                          if (!_canSubmit) {
                            final minsLeft = (_secondsBeforeCanSubmit ~/ 60);
                            final secsLeft = (_secondsBeforeCanSubmit % 60);
                            showDialog(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: const Text('⏰ Trop tôt pour soumettre'),
                                content: Text(
                                  'Vous devez attendre encore ${minsLeft}min ${secsLeft}s avant de pouvoir soumettre.\n\nCette règle simule les conditions réelles du concours.',
                                ),
                                actions: [
                                  ElevatedButton(
                                    onPressed: () => Navigator.pop(ctx),
                                    style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.primary),
                                    child: const Text('Continuer l\'examen'),
                                  ),
                                ],
                              ),
                            );
                            return;
                          }
                          showDialog(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('Terminer la simulation ?'),
                              content: Text(
                                  'Vous avez répondu à $answeredCount/${_questions.length} questions.\n\nÊtes-vous sûr de vouloir terminer ?'),
                              actions: [
                                TextButton(
                                    onPressed: () => Navigator.pop(ctx),
                                    child: const Text('Continuer')),
                                ElevatedButton(
                                  onPressed: () {
                                    Navigator.pop(ctx);
                                    _finishSimulation();
                                  },
                                  style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.primary),
                                  child: const Text('Terminer'),
                                ),
                              ],
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        backgroundColor: _currentIndex == _questions.length - 1
                            ? (_canSubmit ? AppColors.error : AppColors.textLight)
                            : AppColors.primary,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(
                        _currentIndex < _questions.length - 1
                            ? 'Suivant'
                            : (_canSubmit
                                ? 'Terminer 🏁'
                                : 'Disponible dans ${_secondsBeforeCanSubmit ~/ 60}min'),
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SimulationResultScreen extends StatelessWidget {
  final int score, total, bonnes, mauvaises, sansReponse, tempsUtilise;
  final List<dynamic> questions;
  final Map<int, String> answers;
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
    if (score >= 40) return 'Excellent';
    if (score >= 30) return 'Bien';
    if (score >= 20) return 'Passable';
    return 'Insuffisant';
  }

  Color get _mentionColor {
    if (score >= 40) return AppColors.success;
    if (score >= 30) return AppColors.primaryLight;
    if (score >= 20) return AppColors.secondary;
    return AppColors.error;
  }

  String get _tempsFormate {
    final m = tempsUtilise ~/ 60;
    final s = tempsUtilise % 60;
    return '${m}min ${s}s';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Resultats'),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(colors: [AppColors.primary, AppColors.primaryDark]),
          ),
        ),
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
                  colors: [_mentionColor, _mentionColor.withValues(alpha: 0.7)],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  Text(
                    '$score/$total',
                    style: const TextStyle(fontSize: 52, fontWeight: FontWeight.w900, color: AppColors.white),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _mention,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.white),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Temps: $_tempsFormate',
                    style: TextStyle(fontSize: 14, color: AppColors.white.withValues(alpha: 0.8)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                _buildStatCard('Bonnes', '$bonnes', AppColors.success),
                const SizedBox(width: 10),
                _buildStatCard('Mauvaises', '$mauvaises', AppColors.error),
                const SizedBox(width: 10),
                _buildStatCard('Sans reponse', '$sansReponse', AppColors.textLight),
              ],
            ),
            const SizedBox(height: 24),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Score par matiere', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 14),
                  ...scoreParMatiere.entries.map((e) {
                    final correct = e.value[0];
                    final totalM = e.value[1];
                    final pct = totalM > 0 ? correct / totalM : 0.0;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                e.key.replaceAll('_', ' ').toUpperCase(),
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                              ),
                              Text('$correct/$totalM', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                            ],
                          ),
                          const SizedBox(height: 6),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: pct,
                              minHeight: 6,
                              backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                              color: pct >= 0.6 ? AppColors.success : pct >= 0.4 ? AppColors.secondary : AppColors.error,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text('Retour a l\'accueil', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)],
        ),
        child: Column(
          children: [
            Text(value, style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: color)),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(fontSize: 11, color: AppColors.textLight, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}
