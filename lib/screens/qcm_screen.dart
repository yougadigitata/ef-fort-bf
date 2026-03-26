import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../services/api_service.dart';

class QcmScreen extends StatefulWidget {
  final String matiere;
  final String label;
  final Color? couleur;
  final String? icone;

  const QcmScreen({
    super.key,
    required this.matiere,
    required this.label,
    this.couleur,
    this.icone,
  });

  @override
  State<QcmScreen> createState() => _QcmScreenState();
}

class _QcmScreenState extends State<QcmScreen> {
  List<dynamic> _questions = [];
  bool _loading = true;
  int _currentIndex = 0;
  String? _selectedAnswer;
  bool _answered = false;
  int _score = 0;
  int _totalAnswered = 0;

  @override
  void initState() {
    super.initState();
    _loadQuestions();
  }

  Future<void> _loadQuestions() async {
    final isAbonne = ApiService.isAbonne;
    final limit = isAbonne ? 30 : 5;
    final questions = await ApiService.getQuestions(widget.matiere, limit: limit);
    if (mounted) {
      setState(() {
        _questions = questions;
        _loading = false;
      });
    }
  }

  void _selectAnswer(String answer) {
    if (_answered) return;
    setState(() {
      _selectedAnswer = answer;
      _answered = true;
      _totalAnswered++;
      final correct = (_questions[_currentIndex]['bonne_reponse'] ?? '').toString();
      if (answer == correct) _score++;
    });
  }

  void _nextQuestion() {
    if (_currentIndex < _questions.length - 1) {
      setState(() {
        _currentIndex++;
        _selectedAnswer = null;
        _answered = false;
      });
    } else {
      _showResults();
    }
  }

  void _showResults() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Resultats QCM', style: TextStyle(fontWeight: FontWeight.w700)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: _score >= _totalAnswered * 0.6
                    ? AppColors.success.withValues(alpha: 0.1)
                    : AppColors.error.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Text(
                '$_score/$_totalAnswered',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: _score >= _totalAnswered * 0.6 ? AppColors.success : AppColors.error,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _score >= _totalAnswered * 0.8
                  ? 'Excellent !'
                  : _score >= _totalAnswered * 0.6
                      ? 'Bien !'
                      : _score >= _totalAnswered * 0.4
                          ? 'Passable'
                          : 'A revoir',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            if (!ApiService.isAbonne && _questions.length <= 5) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.secondaryLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  'Abonnez-vous pour acceder a toutes les questions !',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: AppColors.secondary, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            child: const Text('Retour aux matieres'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() {
                _currentIndex = 0;
                _selectedAnswer = null;
                _answered = false;
                _score = 0;
                _totalAnswered = 0;
              });
            },
            child: const Text('Recommencer'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(widget.label),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.primary, AppColors.primaryDark],
            ),
          ),
        ),
        actions: [
          if (_questions.isNotEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Text(
                  '${_currentIndex + 1}/${_questions.length}',
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                ),
              ),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _questions.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.quiz_rounded, size: 64, color: AppColors.textLight.withValues(alpha: 0.3)),
                      const SizedBox(height: 16),
                      const Text('Aucune question disponible', style: TextStyle(color: AppColors.textLight, fontSize: 16)),
                    ],
                  ),
                )
              : _buildQuestion(),
    );
  }

  Widget _buildQuestion() {
    final q = _questions[_currentIndex] as Map<String, dynamic>;
    final correct = (q['bonne_reponse'] ?? '').toString();
    final options = {'A': q['option_a'], 'B': q['option_b'], 'C': q['option_c'], 'D': q['option_d']};

    return SingleChildScrollView(
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
                  'Question ${_currentIndex + 1}',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.primary),
                ),
              ),
              const Spacer(),
              Text('Score: $_score/$_totalAnswered', style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textLight)),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
            ),
            child: Text(
              q['enonce'] ?? q['question'] ?? '',
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600, height: 1.5, color: AppColors.textDark),
            ),
          ),
          const SizedBox(height: 20),
          ...options.entries.map((entry) {
            final letter = entry.key;
            final text = entry.value ?? '';
            final isSelected = _selectedAnswer == letter;
            final isCorrect = letter == correct;

            Color bgColor = AppColors.white;
            Color borderColor = Colors.transparent;
            Color textColor = AppColors.textDark;

            if (_answered) {
              if (isCorrect) {
                bgColor = AppColors.success.withValues(alpha: 0.1);
                borderColor = AppColors.success;
                textColor = AppColors.success;
              } else if (isSelected && !isCorrect) {
                bgColor = AppColors.error.withValues(alpha: 0.1);
                borderColor = AppColors.error;
                textColor = AppColors.error;
              }
            } else if (isSelected) {
              bgColor = AppColors.primary.withValues(alpha: 0.08);
              borderColor = AppColors.primary;
            }

            return GestureDetector(
              onTap: () => _selectAnswer(letter),
              child: Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: borderColor, width: 2),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 4, offset: const Offset(0, 2))],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: _answered && isCorrect
                            ? AppColors.success
                            : _answered && isSelected && !isCorrect
                                ? AppColors.error
                                : AppColors.primary.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: _answered && isCorrect
                            ? const Icon(Icons.check, color: AppColors.white, size: 18)
                            : _answered && isSelected && !isCorrect
                                ? const Icon(Icons.close, color: AppColors.white, size: 18)
                                : Text(letter, style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.primary)),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(child: Text(text.toString(), style: TextStyle(fontSize: 15, color: textColor, fontWeight: isSelected || (_answered && isCorrect) ? FontWeight.w600 : FontWeight.normal))),
                  ],
                ),
              ),
            );
          }),
          if (_answered) ...[
            const SizedBox(height: 16),
            if (q['explication'] != null && (q['explication'] as String).isNotEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.lightbulb_rounded, color: AppColors.secondary, size: 20),
                        SizedBox(width: 8),
                        Text('Explication', style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.primary)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(q['explication'].toString(), style: const TextStyle(fontSize: 14, height: 1.5, color: AppColors.textDark)),
                  ],
                ),
              ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _nextQuestion,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: Text(
                  _currentIndex < _questions.length - 1 ? 'Question suivante' : 'Voir les resultats',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}
