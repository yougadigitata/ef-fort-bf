import 'dart:async';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import '../core/theme/app_colors.dart';
import '../services/api_service.dart';
import '../services/bell_service.dart';
import '../services/pdf_service.dart';
import '../services/progression_service.dart';
import '../widgets/math_text_widget.dart';

// ══════════════════════════════════════════════════════════════
// QCM LINÉAIRE SCREEN — Mode Gamifié v1.0
// Feedback immédiat · Émoticônes · Animations · Résumé final
// Une seule réponse sélectionnable (radio) + NEXT auto
// ══════════════════════════════════════════════════════════════

class QcmLineaireScreen extends StatefulWidget {
  final String matiere;
  final String label;
  final Color? couleur;
  final String? icone;
  final String? matiereId;

  const QcmLineaireScreen({
    super.key,
    required this.matiere,
    required this.label,
    this.couleur,
    this.icone,
    this.matiereId,
  });

  @override
  State<QcmLineaireScreen> createState() => _QcmLineaireScreenState();
}

class _QcmLineaireScreenState extends State<QcmLineaireScreen>
    with TickerProviderStateMixin {
  List<dynamic> _questions = [];
  bool _loading = true;
  int _currentIndex = 0;

  // Réponse choisie pour la question actuelle (sélection unique)
  String? _selectedAnswer;
  // Map stockant TOUTES les réponses : questionIndex → lettre choisie
  final Map<int, String?> _allAnswers = {};
  // Indique si feedback immédiat est visible
  bool _showFeedback = false;
  // Série terminée
  bool _serieTerminee = false;

  // Animations
  late AnimationController _feedbackCtrl;
  late AnimationController _emojiCtrl;
  late AnimationController _scoreCtrl;
  late Animation<double> _feedbackScale;
  late Animation<double> _emojiScale;
  late Animation<double> _emojiBounce;
  late Animation<double> _scoreAnim;

  // Timer pour auto-avancer (optionnel)
  Timer? _autoNextTimer;

  // Résultat de la réponse actuelle
  bool _lastAnswerCorrect = false;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _loadQuestions();
  }

  void _initAnimations() {
    _feedbackCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _emojiCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _scoreCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _feedbackScale = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _feedbackCtrl, curve: Curves.elasticOut),
    );
    _emojiScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _emojiCtrl, curve: Curves.elasticOut),
    );
    _emojiBounce = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(parent: _emojiCtrl, curve: Curves.easeInOut),
    );
    _scoreAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _scoreCtrl, curve: Curves.easeOut),
    );
  }

  Future<void> _loadQuestions() async {
    const limit = 20;
    final questions = await ApiService.getQuestions(widget.matiere, limit: limit);
    if (mounted) {
      setState(() {
        _questions = questions;
        _loading = false;
      });
    }
  }

  Color get _couleur => widget.couleur ?? AppColors.primary;

  Set<String> _getBonnesReponses(Map<String, dynamic> q) {
    final rep = (q['bonne_reponse'] ?? '').toString().toUpperCase();
    return rep.split('').where((c) => ['A', 'B', 'C', 'D', 'E'].contains(c)).toSet();
  }

  bool _isCorrect(int index) {
    final q = _questions[index] as Map<String, dynamic>;
    final bonnes = _getBonnesReponses(q);
    final chose = _allAnswers[index];
    if (chose == null) return false;
    return bonnes.contains(chose);
  }

  int _calculerScore() {
    int score = 0;
    for (int i = 0; i < _questions.length; i++) {
      if (_isCorrect(i)) score++;
    }
    return score;
  }

  void _selectAnswer(String letter) {
    if (_showFeedback || _serieTerminee) return;
    BellService.playClick();
    setState(() {
      _selectedAnswer = letter;
    });
  }

  void _valider() {
    if (_selectedAnswer == null || _showFeedback) return;
    final q = _questions[_currentIndex] as Map<String, dynamic>;
    final bonnes = _getBonnesReponses(q);
    final correct = bonnes.contains(_selectedAnswer);

    _lastAnswerCorrect = correct;
    _allAnswers[_currentIndex] = _selectedAnswer;

    // Sons
    if (correct) {
      BellService.playCorrect();
    } else {
      BellService.playWrong();
    }

    // Enregistrer en BDD
    _saveReponse(correct);

    setState(() {
      _showFeedback = true;
    });

    // Animations
    _feedbackCtrl.reset();
    _emojiCtrl.reset();
    _feedbackCtrl.forward();
    Future.delayed(const Duration(milliseconds: 150), () {
      if (mounted) _emojiCtrl.forward();
    });
  }

  void _suivant() {
    _autoNextTimer?.cancel();
    setState(() {
      _showFeedback = false;
      _selectedAnswer = null;
    });

    if (_currentIndex < _questions.length - 1) {
      setState(() => _currentIndex++);
    } else {
      _terminer();
    }
  }

  void _precedent() {
    if (_currentIndex <= 0 || _showFeedback) return;
    setState(() {
      _currentIndex--;
      _selectedAnswer = _allAnswers[_currentIndex];
      _showFeedback = false;
    });
  }

  void _terminer() {
    setState(() => _serieTerminee = true);
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) {
        BellService.playApplause();
        _scoreCtrl.forward();
      }
    });
    _saveProgression();
  }

  Future<void> _saveProgression() async {
    if (widget.matiereId == null) return;
    final score = _calculerScore();
    try {
      await ProgressionService.enregistrerSessionQCM(
        matiereId: widget.matiereId!,
        questionsVues: _questions.length,
        questionsCorrectes: score,
      );
    } catch (_) {}
  }

  Future<void> _saveReponse(bool estCorrect) async {
    if (widget.matiereId == null) return;
    try {
      final q = _questions[_currentIndex] as Map<String, dynamic>;
      final questionId = (q['id'] ?? q['numero'] ?? _currentIndex).toString();
      await ProgressionService.enregistrerReponse(
        questionId: questionId,
        estCorrect: estCorrect,
        matiereId: widget.matiereId,
        serieId: null,
        reponseDonnee: _selectedAnswer,
      );
    } catch (_) {}
  }

  void _recommencer() {
    setState(() {
      _currentIndex = 0;
      _selectedAnswer = null;
      _allAnswers.clear();
      _showFeedback = false;
      _serieTerminee = false;
    });
    _scoreCtrl.reset();
    _feedbackCtrl.reset();
    _emojiCtrl.reset();
  }

  @override
  void dispose() {
    _autoNextTimer?.cancel();
    _feedbackCtrl.dispose();
    _emojiCtrl.dispose();
    _scoreCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          '⚡ ${widget.label}',
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [_couleur, _couleur.withValues(alpha: 0.8)],
            ),
          ),
        ),
        foregroundColor: AppColors.white,
        actions: [
          if (_questions.isNotEmpty && !_serieTerminee)
            Center(
              child: Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${_currentIndex + 1}/${_questions.length}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _questions.isEmpty
              ? _buildEmpty()
              : _serieTerminee
                  ? _buildResultatFinal()
                  : _buildQuestionPage(),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.quiz_rounded, size: 64, color: AppColors.textLight.withValues(alpha: 0.3)),
          const SizedBox(height: 16),
          const Text('Aucune question disponible.', textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textLight, fontSize: 16)),
        ],
      ),
    );
  }

  // ── PAGE QUESTION ──────────────────────────────────────────────────
  Widget _buildQuestionPage() {
    final q = _questions[_currentIndex] as Map<String, dynamic>;
    final texte = (q['enonce'] ?? q['question'] ?? '').toString();
    final options = <String, String>{};
    for (final l in ['A', 'B', 'C', 'D', 'E']) {
      final v = (q['option_${l.toLowerCase()}'] ?? '').toString();
      if (v.trim().isNotEmpty) options[l] = v;
    }
    final bonnes = _getBonnesReponses(q);

    return Column(
      children: [
        // Barre de progression animée
        TweenAnimationBuilder<double>(
          tween: Tween(begin: _currentIndex / _questions.length,
              end: (_currentIndex + 1) / _questions.length),
          duration: const Duration(milliseconds: 300),
          builder: (_, value, __) => LinearProgressIndicator(
            value: value,
            backgroundColor: Colors.grey.withValues(alpha: 0.15),
            valueColor: AlwaysStoppedAnimation<Color>(_couleur),
            minHeight: 5,
          ),
        ),

        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Numéro + indicateur ──
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(
                        color: _couleur.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: _couleur.withValues(alpha: 0.3)),
                      ),
                      child: Text(
                        '📝 Question ${_currentIndex + 1}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: _couleur,
                        ),
                      ),
                    ),
                    const Spacer(),
                    // Indicateurs de réponses précédentes (mini dots)
                    ...List.generate(
                      _questions.length.clamp(0, 10),
                      (i) => Container(
                        margin: const EdgeInsets.only(left: 2),
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: i < _currentIndex
                              ? (_allAnswers[i] != null && _isCorrect(i)
                                  ? AppColors.success
                                  : (_allAnswers[i] != null ? AppColors.error : Colors.grey.withValues(alpha: 0.3)))
                              : i == _currentIndex
                                  ? _couleur
                                  : Colors.grey.withValues(alpha: 0.2),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // ── Texte de la question ──
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A5C38).withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFF1A5C38).withValues(alpha: 0.15),
                      width: 1.5,
                    ),
                  ),
                  child: MathTextWidget(
                    text: texte,
                    textStyle: const TextStyle(
                      fontSize: 19,
                      fontFamily: 'Georgia',
                      height: 1.7,
                      color: AppColors.textDark,
                      fontWeight: FontWeight.w500,
                    ),
                    mathSize: 20.0,
                  ),
                ),
                const SizedBox(height: 16),

                // ── Feedback immédiat (visible après validation) ──
                if (_showFeedback) _buildFeedbackBanner(q, bonnes),

                if (!_showFeedback)
                  Text(
                    'Choisissez une réponse :',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textLight,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                const SizedBox(height: 10),

                // ── Options ──
                ...options.entries.map((entry) {
                  final letter = entry.key;
                  final text = entry.value;
                  return _buildOptionTile(letter, text, bonnes);
                }),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),

        // ── Boutons de navigation ──
        _buildNavigationButtons(),
      ],
    );
  }

  // ── Tile pour une option (avec feedback coloré) ──────────────────
  Widget _buildOptionTile(String letter, String text, Set<String> bonnes) {
    final isSelected = _selectedAnswer == letter;
    final isBonne = bonnes.contains(letter);
    final isWrong = _showFeedback && isSelected && !isBonne;
    final isGood = _showFeedback && isBonne;

    Color bg;
    Color border;
    Widget? trailing;

    if (_showFeedback) {
      if (isGood) {
        bg = AppColors.success.withValues(alpha: 0.12);
        border = AppColors.success;
        trailing = const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 22);
      } else if (isWrong) {
        bg = AppColors.error.withValues(alpha: 0.10);
        border = AppColors.error;
        trailing = const Icon(Icons.cancel_rounded, color: AppColors.error, size: 22);
      } else {
        bg = Colors.white;
        border = Colors.grey.withValues(alpha: 0.2);
        trailing = null;
      }
    } else {
      bg = isSelected ? _couleur.withValues(alpha: 0.09) : Colors.white;
      border = isSelected ? _couleur : Colors.grey.withValues(alpha: 0.25);
      trailing = null;
    }

    return GestureDetector(
      onTap: () => _selectAnswer(letter),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: border, width: isSelected || _showFeedback ? 2 : 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Cercle lettre
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _showFeedback
                    ? (isGood ? AppColors.success : isWrong ? AppColors.error : Colors.grey.withValues(alpha: 0.15))
                    : isSelected
                        ? _couleur
                        : Colors.grey.withValues(alpha: 0.1),
                border: Border.all(
                  color: _showFeedback
                      ? (isGood ? AppColors.success : isWrong ? AppColors.error : Colors.grey.withValues(alpha: 0.3))
                      : isSelected
                          ? _couleur
                          : Colors.grey.withValues(alpha: 0.4),
                  width: 1.5,
                ),
              ),
              child: Center(
                child: isSelected && !_showFeedback
                    ? const Icon(Icons.check, color: Colors.white, size: 18)
                    : Text(
                        letter,
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                          color: _showFeedback
                              ? (isGood || isWrong ? Colors.white : Colors.grey)
                              : isSelected
                                  ? Colors.white
                                  : Colors.grey,
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: MathTextWidget(
                text: text,
                textStyle: TextStyle(
                  fontSize: 16,
                  fontFamily: 'Georgia',
                  height: 1.45,
                  color: _showFeedback
                      ? (isGood ? AppColors.success : isWrong ? AppColors.error : AppColors.textDark)
                      : isSelected
                          ? _couleur
                          : AppColors.textDark,
                  fontWeight: (isGood || isWrong || isSelected) ? FontWeight.w600 : FontWeight.normal,
                ),
                mathSize: 17.0,
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: 8),
              trailing,
            ],
          ],
        ),
      ),
    );
  }

  // ── Bandeau de feedback immédiat avec animation ──────────────────
  Widget _buildFeedbackBanner(Map<String, dynamic> q, Set<String> bonnes) {
    final explication = (q['explication'] ?? '').toString();
    final bonneStr = (bonnes.toList()..sort()).join(', ');

    return ScaleTransition(
      scale: _feedbackScale,
      child: Column(
        children: [
          // Bandeau principal résultat
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 14),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _lastAnswerCorrect
                  ? AppColors.success.withValues(alpha: 0.1)
                  : AppColors.error.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: _lastAnswerCorrect
                    ? AppColors.success.withValues(alpha: 0.5)
                    : AppColors.error.withValues(alpha: 0.4),
                width: 2,
              ),
            ),
            child: Row(
              children: [
                // Emoji animé
                ScaleTransition(
                  scale: _emojiScale,
                  child: Text(
                    _lastAnswerCorrect ? '👏' : '🎯',
                    style: const TextStyle(fontSize: 36),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _lastAnswerCorrect
                            ? 'Bravo ! Bonne réponse ! 🎉'
                            : 'Mauvaise réponse 😕',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                          color: _lastAnswerCorrect ? AppColors.success : AppColors.error,
                        ),
                      ),
                      if (!_lastAnswerCorrect)
                        Text(
                          'Bonne réponse : $bonneStr',
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.success,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Explication (si disponible)
          if (explication.isNotEmpty)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 14),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF8E7),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFFD4A017).withValues(alpha: 0.5),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.lightbulb_rounded, color: Color(0xFFD4A017), size: 18),
                      SizedBox(width: 8),
                      Text(
                        '💡 Explication',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF8B6914),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  MathTextWidget(
                    text: explication,
                    textStyle: const TextStyle(
                      fontSize: 14,
                      fontStyle: FontStyle.italic,
                      height: 1.6,
                      color: Color(0xFF5D4037),
                    ),
                    mathSize: 15.0,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // ── Boutons de navigation ────────────────────────────────────────
  Widget _buildNavigationButtons() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        border: Border(
          top: BorderSide(color: Colors.grey.withValues(alpha: 0.15), width: 1),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: _showFeedback
              ? SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton.icon(
                    onPressed: _suivant,
                    icon: Icon(
                      _currentIndex < _questions.length - 1
                          ? Icons.arrow_forward_rounded
                          : Icons.flag_rounded,
                      size: 22,
                    ),
                    label: Text(
                      _currentIndex < _questions.length - 1
                          ? '➡️  Question suivante'
                          : '🏁  Voir mes résultats',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _lastAnswerCorrect ? AppColors.success : _couleur,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 3,
                    ),
                  ),
                )
              : Row(
                  children: [
                    // Bouton précédent
                    if (_currentIndex > 0)
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _precedent,
                          icon: const Icon(Icons.arrow_back_rounded, size: 18),
                          label: const Text('Préc.'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.textLight,
                            side: BorderSide(color: Colors.grey.withValues(alpha: 0.4)),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                    if (_currentIndex > 0) const SizedBox(width: 12),

                    // Bouton valider
                    Expanded(
                      flex: 2,
                      child: ElevatedButton.icon(
                        onPressed: _selectedAnswer != null ? _valider : null,
                        icon: const Icon(Icons.check_circle_rounded, size: 20),
                        label: Text(
                          _selectedAnswer == null ? 'Choisir une réponse' : '✅ Valider',
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _selectedAnswer != null ? _couleur : Colors.grey.withValues(alpha: 0.3),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: _selectedAnswer != null ? 3 : 0,
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  // ── RÉSULTAT FINAL ───────────────────────────────────────────────
  Widget _buildResultatFinal() {
    final score = _calculerScore();
    final total = _questions.length;
    final pct = total > 0 ? (score / total * 100).round() : 0;
    final note = total > 0 ? (score / total * 20) : 0.0;

    String emoji;
    String mention;
    Color mentionColor;
    if (pct >= 80) {
      emoji = '🏆';
      mention = 'Excellent !';
      mentionColor = AppColors.success;
    } else if (pct >= 60) {
      emoji = '👍';
      mention = 'Bien !';
      mentionColor = Colors.blue;
    } else if (pct >= 40) {
      emoji = '📚';
      mention = 'Passable — Continue !';
      mentionColor = Colors.orange;
    } else {
      emoji = '💪';
      mention = 'À revoir — Ne lâche pas !';
      mentionColor = AppColors.error;
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // ── Animation finale "arbitre" ──
          AnimatedBuilder(
            animation: _scoreCtrl,
            builder: (_, __) {
              return Opacity(
                opacity: _scoreCtrl.value,
                child: Transform.scale(
                  scale: 0.5 + _scoreCtrl.value * 0.5,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [_couleur, _couleur.withValues(alpha: 0.7)],
                      ),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: _couleur.withValues(alpha: 0.4),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Emoji fin de match
                        Text(
                          '🚨 $emoji',
                          style: const TextStyle(fontSize: 48),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'MATCH TERMINÉ !',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: 2,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Cercle rouge note sur 20
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.red.shade700,
                            border: Border.all(color: Colors.red.shade900, width: 3),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.red.withValues(alpha: 0.5),
                                blurRadius: 16,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                note.toStringAsFixed(1),
                                style: const TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                  height: 1.0,
                                ),
                              ),
                              const Text(
                                '/ 20',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          '$score / $total bonnes réponses  •  $pct%',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          mention,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: mentionColor == AppColors.success
                                ? Colors.white
                                : const Color(0xFFFFE082),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 20),

          // ── Statistiques rapides ──
          Row(
            children: [
              _buildStatCard('✅ Bonnes', '$score', AppColors.success),
              const SizedBox(width: 10),
              _buildStatCard('❌ Faux', '${total - score}', AppColors.error),
              const SizedBox(width: 10),
              _buildStatCard('📊 Score', '$pct%', _couleur),
            ],
          ),
          const SizedBox(height: 16),

          // ── Correction par question (résumé compact) ──
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '📋 Résumé question par question',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: List.generate(_questions.length, (i) {
                    final correct = _isCorrect(i);
                    final answered = _allAnswers[i] != null;
                    return Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: !answered
                            ? Colors.grey.withValues(alpha: 0.15)
                            : correct
                                ? AppColors.success.withValues(alpha: 0.15)
                                : AppColors.error.withValues(alpha: 0.15),
                        border: Border.all(
                          color: !answered
                              ? Colors.grey.withValues(alpha: 0.3)
                              : correct
                                  ? AppColors.success
                                  : AppColors.error,
                          width: 2,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          !answered ? '—' : correct ? '✓' : '✗',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: !answered
                                ? Colors.grey
                                : correct
                                    ? AppColors.success
                                    : AppColors.error,
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── Boutons d'action ──
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back_rounded, size: 18),
                  label: const Text('Retour'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _couleur,
                    side: BorderSide(color: _couleur),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _recommencer,
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: const Text('Rejouer', style: TextStyle(fontWeight: FontWeight.w800)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _couleur,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // ── Bouton PDF ──
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _exportPdf(context),
              icon: const Icon(Icons.picture_as_pdf_rounded, size: 18),
              label: const Text('📄 Télécharger la correction PDF',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFC62828),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: color,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: color.withValues(alpha: 0.8),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _exportPdf(BuildContext ctx) async {
    ScaffoldMessenger.of(ctx).showSnackBar(
      const SnackBar(
        content: Text('Génération du PDF en cours...'),
        backgroundColor: Color(0xFF1A5C38),
        duration: Duration(seconds: 2),
      ),
    );
    try {
      final user = ApiService.currentUser;
      final nomCandidat = user != null
          ? '${user['prenom'] ?? ''} ${user['nom'] ?? ''}'.trim()
          : 'Candidat';
      final score = _calculerScore();
      final total = _questions.length;

      final pdfQuestions = <PdfQuestion>[];
      for (int i = 0; i < _questions.length; i++) {
        final q = _questions[i] as Map<String, dynamic>;
        final bonnesSet = _getBonnesReponses(q);
        final choisie = _allAnswers[i];
        final correct = choisie != null && bonnesSet.contains(choisie);
        final noAns = choisie == null;
        final bonneStr = (bonnesSet.toList()..sort()).join('+');

        final options = <String, String>{};
        for (final l in ['A', 'B', 'C', 'D', 'E']) {
          final v = (q['option_${l.toLowerCase()}'] ?? '').toString();
          if (v.trim().isNotEmpty) options[l] = v;
        }

        pdfQuestions.add(PdfQuestion(
          numero: i + 1,
          categorie: (q['categorie'] ?? q['chapitre'] ?? '').toString(),
          enonce: (q['enonce'] ?? q['question'] ?? '').toString(),
          reponseEleve: choisie ?? '',
          bonneReponse: bonneStr,
          explication: (q['explication'] ?? '').toString(),
          points: correct ? 1 : 0,
          pointsMax: 1,
          correct: correct,
          nonRepondu: noAns,
          options: options,
        ));
      }

      final pdfBytes = await PdfService.genererCopieCorrigee(
        kind: PdfKind.matiere,
        nomCandidat: nomCandidat,
        sujet: '⚡ Mode Libre — ${widget.label}',
        questions: pdfQuestions,
        scoreObtenu: score,
        scoreTotal: total,
        titrePdf: 'Mode Libre – ${widget.label}',
      );

      final safe = widget.label
          .replaceAll(RegExp(r'[^a-zA-Z0-9\u00C0-\u024F_-]'), '_')
          .replaceAll(RegExp(r'_+'), '_');
      await Printing.sharePdf(
        bytes: pdfBytes,
        filename: 'EF-FORT_Lineaire_$safe.pdf',
      );
    } catch (e) {
      if (ctx.mounted) {
        ScaffoldMessenger.of(ctx).showSnackBar(
          SnackBar(content: Text('Erreur PDF : $e'), backgroundColor: Colors.red),
        );
      }
    }
  }
}
