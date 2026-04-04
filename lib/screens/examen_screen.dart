import 'dart:async';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../widgets/math_text_widget.dart';

/// PHASE 4 — Interface Examen Noir/Blanc (simulation vraie feuille)
class ExamenScreen extends StatefulWidget {
  final String examenId;
  final String nomExamen;
  final Color couleur;
  final int serie;

  const ExamenScreen({
    super.key,
    required this.examenId,
    required this.nomExamen,
    this.couleur = const Color(0xFF1A5C38),
    this.serie = 1,
  });

  @override
  State<ExamenScreen> createState() => _ExamenScreenState();
}

class _ExamenScreenState extends State<ExamenScreen> {
  List<dynamic> _questions = [];
  final Map<int, String> _answers = {};
  int _currentIndex = 0;
  bool _loading = true;
  String? _error;
  late Timer _timer;
  int _remainingSeconds = 5400; // 1h30 (90 minutes)
  bool _submitted = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadQuestions());
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) { t.cancel(); return; }
      setState(() => _remainingSeconds--);
      if (_remainingSeconds <= 0) {
        t.cancel();
        _submitExam();
      }
    });
  }

  Future<void> _loadQuestions() async {
    setState(() { _loading = true; _error = null; });
    try {
      final data = await ApiService.getExamenQuestions(widget.examenId, serie: widget.serie);
      if (mounted) {
        setState(() {
          _questions = data;
          _loading = false;
        });
        _startTimer();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Impossible de charger les questions. Vérifiez votre connexion.';
          _loading = false;
        });
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
    if (_remainingSeconds > 1800) return Colors.white;
    if (_remainingSeconds > 600) return Colors.orange;
    return Colors.red;
  }

  void _selectAnswer(String letter) {
    if (_submitted) return;
    setState(() => _answers[_currentIndex] = letter);
  }

  Future<void> _submitExam() async {
    if (_submitted) return;
    if (mounted && _timer.isActive) _timer.cancel();

    // Vérifier si toutes les questions sont répondues
    final nonRepondues = _questions.length - _answers.length;
    if (nonRepondues > 0 && !_submitted) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: Colors.white,
          title: const Text('Soumettre l\'examen ?',
              style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          content: Text(
            '$nonRepondues question(s) sans réponse.\nVoulez-vous quand même soumettre ?',
            style: const TextStyle(color: Colors.black87),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Continuer', style: TextStyle(color: Colors.black54)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.black),
              child: const Text('Soumettre', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
      if (confirm != true) return;
    }

    setState(() => _submitted = true);
    _showResults();
  }

  void _showResults() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => ResultatsExamenScreen(
          questions: _questions,
          answers: _answers,
          nomExamen: widget.nomExamen,
          couleur: widget.couleur,
          tempsUtilise: 5400 - _remainingSeconds,
        ),
      ),
    );
  }

  @override
  void dispose() {
    if (!_submitted) _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: widget.couleur),
              const SizedBox(height: 16),
              Text(
                'Chargement de l\'examen...\n${widget.nomExamen}',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.black54, fontSize: 14),
              ),
            ],
          ),
        ),
      );
    }

    if (_error != null) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          title: Text(widget.nomExamen),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text(_error!, textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 15, color: Colors.black87)),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _loadQuestions,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.black),
                  child: const Text('Réessayer', style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_questions.isEmpty) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          title: Text(widget.nomExamen),
        ),
        body: const Center(
          child: Text('Aucune question disponible pour cet examen.',
              style: TextStyle(fontSize: 15, color: Colors.black54)),
        ),
      );
    }

    final q = _questions[_currentIndex];
    final options = ['A', 'B', 'C', 'D', 'E'];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.nomExamen,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
            Text(
              'Question ${_currentIndex + 1} / ${_questions.length}',
              style: const TextStyle(fontSize: 11, color: Colors.white70),
            ),
          ],
        ),
        actions: [
          // Timer
          Container(
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _remainingSeconds <= 600 ? Colors.red.withValues(alpha: 0.2) : Colors.white12,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _timerColor.withValues(alpha: 0.5)),
            ),
            child: Row(
              children: [
                Icon(Icons.timer, size: 14, color: _timerColor),
                const SizedBox(width: 4),
                Text(
                  _timerDisplay,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: _timerColor,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Barre de progression
          LinearProgressIndicator(
            value: (_currentIndex + 1) / _questions.length,
            backgroundColor: Colors.grey[200],
            color: Colors.black,
            minHeight: 3,
          ),

          // Contenu principal
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Numéro de question
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Text(
                      'QUESTION ${_currentIndex + 1}',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Énoncé avec support formules
                  MathTextWidget(
                    text: q['enonce'] as String? ?? '',
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                      height: 1.7,
                    ),
                    mathSize: 16,
                    mathColor: Colors.black,
                  ),
                  const SizedBox(height: 24),

                  // Séparateur
                  Container(height: 1, color: Colors.grey[200]),
                  const SizedBox(height: 16),

                  // Options de réponse
                  ...options.map((letter) {
                    final key = 'option_${letter.toLowerCase()}';
                    final optionText = q[key] as String?;
                    if (optionText == null || optionText.trim().isEmpty) {
                      return const SizedBox.shrink();
                    }
                    final isSelected = _answers[_currentIndex] == letter;
                    return _buildOption(letter, optionText, isSelected);
                  }),

                  const SizedBox(height: 28),

                  // Navigation
                  Row(
                    children: [
                      if (_currentIndex > 0) ...[
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => setState(() => _currentIndex--),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.black,
                              side: const BorderSide(color: Colors.black),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text('← Précédent'),
                          ),
                        ),
                        const SizedBox(width: 12),
                      ],
                      Expanded(
                        flex: _currentIndex > 0 ? 1 : 2,
                        child: _currentIndex < _questions.length - 1
                            ? ElevatedButton(
                                onPressed: () => setState(() => _currentIndex++),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.black,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: const Text('Suivant →'),
                              )
                            : ElevatedButton(
                                onPressed: _submitExam,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF1A5C38),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: const Text('Soumettre ✓',
                                    style: TextStyle(fontWeight: FontWeight.bold)),
                              ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Compteur réponses
                  Center(
                    child: Text(
                      '${_answers.length}/${_questions.length} réponses données',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),

      // Navigation rapide (mini grid en bas)
      bottomNavigationBar: Container(
        color: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(height: 1, color: Colors.grey[200]),
            const SizedBox(height: 8),
            SizedBox(
              height: 36,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _questions.length,
                itemBuilder: (ctx, i) {
                  final isAnswered = _answers.containsKey(i);
                  final isCurrent = i == _currentIndex;
                  return GestureDetector(
                    onTap: () => setState(() => _currentIndex = i),
                    child: Container(
                      width: 32,
                      height: 32,
                      margin: const EdgeInsets.only(right: 4),
                      decoration: BoxDecoration(
                        color: isCurrent
                            ? Colors.black
                            : isAnswered
                                ? Colors.green[700]
                                : Colors.grey[200],
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Center(
                        child: Text(
                          '${i + 1}',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: (isCurrent || isAnswered)
                                ? Colors.white
                                : Colors.black54,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOption(String letter, String text, bool isSelected) {
    return GestureDetector(
      onTap: () => _selectAnswer(letter),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected ? Colors.black : Colors.white,
          border: Border.all(
            color: isSelected ? Colors.black : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Case à cocher style examen officiel
            Container(
              width: 24,
              height: 24,
              margin: const EdgeInsets.only(top: 1),
              decoration: BoxDecoration(
                color: isSelected ? Colors.white : Colors.transparent,
                border: Border.all(
                  color: isSelected ? Colors.white : Colors.grey[400]!,
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(4),
              ),
              child: isSelected
                  ? const Center(
                      child: Icon(Icons.check, size: 14, color: Colors.black),
                    )
                  : Center(
                      child: Text(
                        letter,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[500],
                        ),
                      ),
                    ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: MathTextWidget(
                text: '$letter.   $text',
                textStyle: TextStyle(
                  fontSize: 14,
                  color: isSelected ? Colors.white : Colors.black,
                  height: 1.5,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
                mathSize: 14,
                mathColor: isSelected ? Colors.white : Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════
/// PHASE 4 — Écran de Résultats Noir/Blanc
// ══════════════════════════════════════════════════════════
class ResultatsExamenScreen extends StatelessWidget {
  final List<dynamic> questions;
  final Map<int, String> answers;
  final String nomExamen;
  final Color couleur;
  final int tempsUtilise;

  const ResultatsExamenScreen({
    super.key,
    required this.questions,
    required this.answers,
    required this.nomExamen,
    required this.couleur,
    required this.tempsUtilise,
  });

  String get _tempsFormate {
    final m = tempsUtilise ~/ 60;
    final s = tempsUtilise % 60;
    return '${m}min ${s}s';
  }

  @override
  Widget build(BuildContext context) {
    int correct = 0;
    final List<Map<String, dynamic>> details = [];

    for (int i = 0; i < questions.length; i++) {
      final q = questions[i];
      final userAnswer = answers[i];
      final correctAnswer = (q['bonne_reponse'] as String?)?.toUpperCase();
      final isCorrect = userAnswer == correctAnswer;
      if (isCorrect) correct++;
      details.add({
        'enonce': q['enonce'] ?? '',
        'user': userAnswer ?? '—',
        'correct': correctAnswer ?? '?',
        'isCorrect': isCorrect,
        'explication': q['explication'] ?? '',
      });
    }

    final score = questions.isNotEmpty
        ? (correct / questions.length * 50).round()
        : 0;
    final percentage = questions.isNotEmpty
        ? (correct / questions.length * 100).round()
        : 0;
    final mention = percentage >= 80
        ? 'Excellent !'
        : percentage >= 60
            ? 'Bien'
            : percentage >= 50
                ? 'Passable'
                : 'À améliorer';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Résultats', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Nom de l'examen
            Text(
              nomExamen,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.black54,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 20),

            // Score principal
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.black, width: 2),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Text(
                    '$score',
                    style: const TextStyle(
                      fontSize: 72,
                      fontWeight: FontWeight.w900,
                      color: Colors.black,
                      height: 1,
                    ),
                  ),
                  Text(
                    '/ ${questions.isNotEmpty ? 50 : 0}',
                    style: const TextStyle(
                      fontSize: 24,
                      color: Colors.black54,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '$percentage% — $mention',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Statistiques
            Row(
              children: [
                _buildStat('Correctes', '$correct', Colors.black),
                const SizedBox(width: 10),
                _buildStat('Incorrectes', '${questions.length - correct}', Colors.grey),
                const SizedBox(width: 10),
                _buildStat('Temps', _tempsFormate, Colors.black),
              ],
            ),
            const SizedBox(height: 24),

            // Titre correction
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'CORRECTION DÉTAILLÉE',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                  color: Colors.black54,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Container(height: 1, color: Colors.black),
            const SizedBox(height: 12),

            // Liste des corrections
            ...details.asMap().entries.map((e) {
              final idx = e.key;
              final d = e.value;
              return _buildCorrectionItem(idx + 1, d);
            }),

            const SizedBox(height: 24),

            // Boutons
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('Retour à l\'accueil',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
              ),
            ),
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
          color: Colors.white,
          border: Border.all(color: color == Colors.grey ? Colors.grey[300]! : Colors.black, width: 1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(fontSize: 11, color: Colors.black54),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCorrectionItem(int num, Map<String, dynamic> d) {
    final isCorrect = d['isCorrect'] as bool;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isCorrect ? Colors.white : Colors.grey[50],
        border: Border.all(
          color: isCorrect ? Colors.grey[300]! : Colors.grey[400]!,
          width: 1,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: isCorrect ? Colors.black : Colors.grey[300],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Center(
                  child: Icon(
                    isCorrect ? Icons.check : Icons.close,
                    size: 14,
                    color: isCorrect ? Colors.white : Colors.black54,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Q$num',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const Spacer(),
              Text(
                'Votre réponse: ${d['user']}   |   Bonne: ${d['correct']}',
                style: TextStyle(
                  fontSize: 11,
                  color: isCorrect ? Colors.black54 : Colors.red[700],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          if ((d['enonce'] as String).isNotEmpty) ...[
            const SizedBox(height: 8),
            MathTextWidget(
              text: d['enonce'] as String,
              textStyle: const TextStyle(fontSize: 12, color: Colors.black87, height: 1.4),
              mathSize: 12,
              mathColor: Colors.black87,
            ),
          ],
          if ((d['explication'] as String).isNotEmpty) ...[
            const SizedBox(height: 6),
            MathTextWidget(
              text: '💡 ${d['explication']}',
              textStyle: const TextStyle(fontSize: 11, color: Colors.black54, height: 1.3),
              mathSize: 11,
              mathColor: Colors.black54,
            ),
          ],
        ],
      ),
    );
  }
}
