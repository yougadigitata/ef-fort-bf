import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../core/theme/app_colors.dart';
import '../services/api_service.dart';
import '../services/bell_service.dart';
import '../widgets/math_text_widget.dart';
import 'abonnement_screen.dart';

// ══════════════════════════════════════════════════════════════
// QCM SCREEN — TÂCHE 6 : Nouvelle présentation académique
// Multi-sélection · Correction en fin de série · Polices sérieuses
// ══════════════════════════════════════════════════════════════

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

  // Multi-sélection : Map<questionIndex, Set<lettres choisies>>
  final Map<int, Set<String>> _selectedAnswers = {};
  // Questions passées sans répondre
  final Set<int> _skipped = {};
  // Indique si on a soumis la série
  bool _serieTerminee = false;

  @override
  void initState() {
    super.initState();
    _loadQuestions();
  }

  Future<void> _loadQuestions() async {
    // 20 questions standard par session
    const limit = 20;
    final questions = await ApiService.getQuestions(widget.matiere, limit: limit);
    if (mounted) {
      setState(() {
        _questions = questions;
        _loading = false;
      });
    }
  }

  void _toggleAnswer(String letter) {
    if (_serieTerminee) return;
    BellService.playClick();
    setState(() {
      _selectedAnswers.putIfAbsent(_currentIndex, () => {});
      final selected = _selectedAnswers[_currentIndex]!;
      if (selected.contains(letter)) {
        selected.remove(letter);
      } else {
        selected.add(letter);
      }
    });
  }

  void _passerQuestion() {
    setState(() {
      _skipped.add(_currentIndex);
      _selectedAnswers.remove(_currentIndex);
    });
    if (_currentIndex < _questions.length - 1) {
      setState(() => _currentIndex++);
    } else {
      _showCorrectionFin();
    }
  }

  void _validerEtSuivre() {
    // Son bonne/mauvaise réponse si une réponse est sélectionnée
    if (!_serieTerminee && _selectedAnswers.containsKey(_currentIndex)) {
      final q = _questions[_currentIndex] as Map<String, dynamic>;
      final bonnes = _getBonnesReponses(q);
      final choisies = _selectedAnswers[_currentIndex]!;
      if (choisies.isNotEmpty) {
        final correct = choisies.containsAll(bonnes) && bonnes.containsAll(choisies);
        if (correct) {
          BellService.playCorrect();
        } else {
          BellService.playWrong();
        }
      }
    }
    if (_currentIndex < _questions.length - 1) {
      setState(() => _currentIndex++);
    } else {
      _showCorrectionFin();
    }
  }

  void _showCorrectionFin() {
    setState(() => _serieTerminee = true);
    // Son applaudissements en fin de série
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) BellService.playApplause();
    });
    // Scroll vers le haut et afficher la correction complète
  }

  // Calculer le score
  int _calculerScore() {
    int score = 0;
    for (int i = 0; i < _questions.length; i++) {
      final q = _questions[i] as Map<String, dynamic>;
      final bonnes = _getBonnesReponses(q);
      final choisies = _selectedAnswers[i] ?? {};
      if (choisies.isNotEmpty && choisies.containsAll(bonnes) && bonnes.containsAll(choisies)) {
        score++;
      }
    }
    return score;
  }

  Set<String> _getBonnesReponses(Map<String, dynamic> q) {
    final rep = (q['bonne_reponse'] ?? '').toString().toUpperCase();
    return rep.split('').where((c) => ['A', 'B', 'C', 'D', 'E'].contains(c)).toSet();
  }

  Color get _couleur => widget.couleur ?? AppColors.primary;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          widget.label,
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w700,
            fontSize: 20,
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
                child: Text(
                  '${_currentIndex + 1} / ${_questions.length}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
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
                  ? _buildCorrectionComplete()
                  : _buildQuestion(),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.quiz_rounded, size: 64, color: AppColors.textLight.withValues(alpha: 0.3)),
          const SizedBox(height: 16),
          const Text(
            'Aucune question disponible\npour cette matière.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textLight, fontSize: 16),
          ),
        ],
      ),
    );
  }

  // ── Écran de question (TÂCHE 6 : Nouvelle présentation) ──
  Widget _buildQuestion() {
    final q = _questions[_currentIndex] as Map<String, dynamic>;
    final selected = _selectedAnswers[_currentIndex] ?? {};
    final texteQuestion = (q['enonce'] ?? q['question'] ?? '').toString();
    final options = {
      'A': q['option_a']?.toString() ?? '',
      'B': q['option_b']?.toString() ?? '',
      'C': q['option_c']?.toString() ?? '',
      'D': q['option_d']?.toString() ?? '',
    };

    return Column(
      children: [
        // Barre de progression
        LinearProgressIndicator(
          value: (_currentIndex + 1) / _questions.length,
          backgroundColor: Colors.grey.withValues(alpha: 0.2),
          valueColor: AlwaysStoppedAnimation<Color>(_couleur),
          minHeight: 4,
        ),

        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                // ── En-tête numéro de question ──
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(
                        color: _couleur.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: _couleur.withValues(alpha: 0.3)),
                      ),
                      child: Text(
                        'Question ${_currentIndex + 1}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: _couleur,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ),
                    const Spacer(),
                    if (!ApiService.isAbonne)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.orange.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'Essai gratuit',
                          style: TextStyle(fontSize: 11, color: Colors.orange, fontWeight: FontWeight.w600),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 14),

                // ── Texte de la question (TÂCHE 6 : fond vert clair) ──
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A5C38).withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: const Color(0xFF1A5C38).withValues(alpha: 0.15),
                      width: 1.5,
                    ),
                  ),
                  child: MathTextWidget(
                    text: texteQuestion,
                    textStyle: const TextStyle(
                      fontSize: 21,
                      fontFamily: 'Georgia',
                      height: 1.7,
                      color: AppColors.textDark,
                      fontWeight: FontWeight.w500,
                    ),
                    mathSize: 22.0,
                  ),
                ),

                const SizedBox(height: 16),
                Text(
                  'Cochez la ou les réponses exactes :',
                  style: TextStyle(
                    fontSize: 16,
                    color: AppColors.textLight,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(height: 14),

                // ── Options A/B/C/D (TÂCHE 6 : cercles à cocher, multi-select) ──
                ...options.entries.map((entry) {
                  final letter = entry.key;
                  final text = entry.value;
                  if (text.isEmpty) return const SizedBox.shrink();
                  final isSelected = selected.contains(letter);

                  return GestureDetector(
                    onTap: () => _toggleAnswer(letter),
                    child: Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 14),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? _couleur.withValues(alpha: 0.08)
                            : AppColors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? _couleur : Colors.grey.withValues(alpha: 0.25),
                          width: isSelected ? 2 : 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.03),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          // Cercle radio / check
                          Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isSelected
                                  ? _couleur
                                  : Colors.transparent,
                              border: Border.all(
                                color: isSelected ? _couleur : Colors.grey.withValues(alpha: 0.5),
                                width: 2,
                              ),
                            ),
                            child: Center(
                              child: isSelected
                                  ? const Icon(Icons.check, color: Colors.white, size: 20)
                                  : Text(
                                      letter,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 17,
                                        color: Colors.grey.withValues(alpha: 0.7),
                                      ),
                                    ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: MathTextWidget(
                              text: text,
                              textStyle: TextStyle(
                                fontSize: 18,
                                fontFamily: 'Georgia',
                                height: 1.55,
                                color: isSelected ? _couleur.withValues(alpha: 0.9) : AppColors.textDark,
                                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                              ),
                              mathSize: 19.0,
                              mathColor: isSelected ? _couleur.withValues(alpha: 0.9) : AppColors.textDark,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),

                // Bannière abonnement si version gratuite
                if (!ApiService.isAbonne && _currentIndex >= 4) ...[
                  const SizedBox(height: 20),
                  _buildPremiumBanner(),
                ],

                const SizedBox(height: 12),
              ],
            ),
          ),
        ),

        // ── Boutons PASSER / VALIDER — ZONE FIXE AVEC SafeArea ──
        // Positionnés au-dessus de la barre de navigation Android
        Container(
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
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _passerQuestion,
                      icon: const Icon(Icons.arrow_back_rounded, size: 20),
                      label: const Text('PASSER', style: TextStyle(fontSize: 15)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.textLight,
                        side: BorderSide(color: Colors.grey.withValues(alpha: 0.4)),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: _validerEtSuivre,
                      icon: const Icon(Icons.arrow_forward_rounded, size: 20),
                      label: Text(
                        _currentIndex < _questions.length - 1 ? 'VALIDER ET SUIVANT' : 'TERMINER',
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _couleur,
                        foregroundColor: AppColors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 3,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── Correction complète en fin de série (TÂCHE 6) ──
  Widget _buildCorrectionComplete() {
    final score = _calculerScore();
    final total = _questions.length;
    final pct = total > 0 ? (score / total * 100).round() : 0;

    String mention;
    // ignore: unused_local_variable
    Color mentionColor;
    if (pct >= 80) {
      mention = 'Excellent !';
      mentionColor = const Color(0xFF1A5C38);
    } else if (pct >= 60) {
      mention = 'Bien !';
      mentionColor = Colors.blue;
    } else if (pct >= 40) {
      mention = 'Passable';
      mentionColor = Colors.orange;
    } else {
      mention = 'À revoir';
      mentionColor = AppColors.error;
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Score central avec NOTE SUR 20 en cercle rouge
          Container(
            margin: const EdgeInsets.only(bottom: 20),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [_couleur, _couleur.withValues(alpha: 0.75)],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                // Cercle rouge avec note sur 20
                Container(
                  width: 130,
                  height: 130,
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
                          fontSize: 36,
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
                  '$score bonne(s) sur $total  •  $pct%  —  $mention',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.white.withValues(alpha: 0.95),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  'Correction détaillée ci-dessous',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white.withValues(alpha: 0.7),
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),

          // Correction question par question
          ..._questions.asMap().entries.map((entry) {
            final i = entry.key;
            final q = entry.value as Map<String, dynamic>;
            final bonnes = _getBonnesReponses(q);
            final choisies = _selectedAnswers[i] ?? {};
            final skipped = _skipped.contains(i);
            final correct = !skipped && choisies.containsAll(bonnes) && bonnes.containsAll(choisies);

            Color cardColor;
            Color borderColor;
            IconData statusIcon;
            if (skipped || choisies.isEmpty) {
              cardColor = Colors.grey.withValues(alpha: 0.08);
              borderColor = Colors.grey.withValues(alpha: 0.3);
              statusIcon = Icons.remove_circle_outline_rounded;
            } else if (correct) {
              cardColor = AppColors.success.withValues(alpha: 0.06);
              borderColor = AppColors.success.withValues(alpha: 0.4);
              statusIcon = Icons.check_circle_outline_rounded;
            } else {
              cardColor = AppColors.error.withValues(alpha: 0.06);
              borderColor = AppColors.error.withValues(alpha: 0.3);
              statusIcon = Icons.cancel_outlined;
            }

            final options = {
              'A': q['option_a']?.toString() ?? '',
              'B': q['option_b']?.toString() ?? '',
              'C': q['option_c']?.toString() ?? '',
              'D': q['option_d']?.toString() ?? '',
            };

            return Container(
              margin: const EdgeInsets.only(bottom: 14),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: borderColor, width: 1.5),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Numéro + statut
                  Row(
                    children: [
                      Text(
                        'Q${i + 1}.',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                          color: _couleur,
                          fontFamily: 'Poppins',
                        ),
                      ),
                      const SizedBox(width: 6),
                      Icon(
                        statusIcon,
                        size: 18,
                        color: skipped || choisies.isEmpty
                            ? Colors.grey
                            : correct ? AppColors.success : AppColors.error,
                      ),
                      const Spacer(),
                      Text(
                        skipped || choisies.isEmpty
                            ? 'Non répondu'
                            : correct ? 'Correct' : 'Incorrect',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: skipped || choisies.isEmpty
                              ? Colors.grey
                              : correct ? AppColors.success : AppColors.error,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Texte question
                  MathTextWidget(
                    text: (q['enonce'] ?? q['question'] ?? '').toString(),
                    textStyle: const TextStyle(
                      fontSize: 14,
                      fontFamily: 'Georgia',
                      height: 1.5,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textDark,
                    ),
                    mathSize: 15.0,
                  ),
                  const SizedBox(height: 10),

                  // Options avec couleurs
                  ...options.entries.map((opt) {
                    final l = opt.key;
                    final t = opt.value;
                    if (t.isEmpty) return const SizedBox.shrink();
                    final isBonne = bonnes.contains(l);
                    final isChoisie = choisies.contains(l);

                    Color optBg = Colors.transparent;
                    Color optBorder = Colors.transparent;
                    Widget? trailingIcon;

                    if (isBonne) {
                      optBg = AppColors.success.withValues(alpha: 0.1);
                      optBorder = AppColors.success.withValues(alpha: 0.5);
                      trailingIcon = const Icon(Icons.check, color: AppColors.success, size: 20);
                    } else if (isChoisie && !isBonne) {
                      optBg = AppColors.error.withValues(alpha: 0.1);
                      optBorder = AppColors.error.withValues(alpha: 0.4);
                      trailingIcon = const Icon(Icons.close, color: AppColors.error, size: 20);
                    }

                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                      decoration: BoxDecoration(
                        color: optBg,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: optBorder, width: 1),
                      ),
                      child: Row(
                        children: [
                          Text(
                            '$l.  ',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: isBonne ? AppColors.success : AppColors.textLight,
                              fontSize: 16,
                            ),
                          ),
                          Expanded(
                            child: MathTextWidget(
                              text: t,
                              textStyle: TextStyle(
                                fontSize: 16,
                                fontFamily: 'Georgia',
                                color: isBonne
                                    ? AppColors.success
                                    : isChoisie ? AppColors.error : AppColors.textDark,
                                fontWeight: isBonne ? FontWeight.w600 : FontWeight.normal,
                              ),
                              mathSize: 17.0,
                              mathColor: isBonne
                                  ? AppColors.success
                                  : isChoisie ? AppColors.error : AppColors.textDark,
                            ),
                          ),
                          if (trailingIcon != null) trailingIcon,
                        ],
                      ),
                    );
                  }),

                  // Explication
                  if (q['explication'] != null && (q['explication'] as String).isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A5C38).withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFF1A5C38).withValues(alpha: 0.15)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.lightbulb_rounded, color: Color(0xFFD4A017), size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: MathTextWidget(
                              text: q['explication'].toString(),
                              textStyle: const TextStyle(
                                fontSize: 15,
                                fontStyle: FontStyle.italic,
                                height: 1.6,
                                color: AppColors.textDark,
                              ),
                              mathSize: 16.0,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            );
          }),

          const SizedBox(height: 20),

          // Bouton recommencer
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _couleur,
                    side: BorderSide(color: _couleur),
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Retour aux matières', style: TextStyle(fontSize: 18)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _currentIndex = 0;
                      _selectedAnswers.clear();
                      _skipped.clear();
                      _serieTerminee = false;
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _couleur,
                    foregroundColor: AppColors.white,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Recommencer', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                ),
              ),
            ],
          ),

          // Bouton PDF Correction
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _exportPdfCorrection(context),
              icon: const Icon(Icons.picture_as_pdf_rounded, size: 18),
              label: const Text('Télécharger la correction PDF',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFC62828),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),

          // Bannière abonnement si gratuit
          if (!ApiService.isAbonne) ...[
            const SizedBox(height: 16),
            _buildPremiumBanner(),
          ],

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  // ── Nettoyer le texte pour PDF ──────────────────────────────────
  static String _cleanTextForPdf(String text) {
    if (text.isEmpty) return text;
    String s = text
        .replaceAll('\u2612', '').replaceAll('\u2611', '').replaceAll('\u2610', '')
        .replaceAll('\u2713', '').replaceAll('\u2714', '').replaceAll('\u2717', '').replaceAll('\u2718', '')
        .replaceAll('\u25A1', '').replaceAll('\u25A0', '').replaceAll('\u2B1C', '').replaceAll('\u2B1B', '');
    // Supprimer LaTeX $...$
    s = s.replaceAllMapped(RegExp(r'\$\$([^$]+)\$\$'), (m) => m.group(1) ?? '');
    s = s.replaceAllMapped(RegExp(r'\$([^$\n]+)\$'), (m) => m.group(1) ?? '');
    s = s.replaceAll(r'$', '').replaceAll('{', '').replaceAll('}', '');
    s = s.replaceAllMapped(RegExp(r'\\[a-zA-Z]+\s*'), (m) => '');
    s = s.replaceAll(RegExp(r'\\(?!\w)'), '');
    s = s.replaceAll(RegExp(r'\s{2,}'), ' ').trim();
    return s.isEmpty ? text : s;
  }

  // ── Export PDF correction matière (note sur 20) ─────────────────
  Future<void> _exportPdfCorrection(BuildContext ctx) async {
    ScaffoldMessenger.of(ctx).showSnackBar(
      const SnackBar(content: Text('Génération du PDF en cours...'),
          duration: Duration(seconds: 2), backgroundColor: Color(0xFF1A5C38)),
    );
    try {
      final pdf = pw.Document();
      final user = ApiService.currentUser;
      final nomCandidat = user != null
          ? '${user['prenom'] ?? ''} ${user['nom'] ?? ''}'.trim()
          : 'Candidat';
      final now = DateTime.now();
      final dateStr = '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}';
      final score = _calculerScore();
      final total = _questions.length;
      final pct = total > 0 ? (score / total * 100).round() : 0;
      final noteSur20 = total > 0 ? (score / total * 20) : 0.0;
      final noteStr = noteSur20.toStringAsFixed(1);

      // Charger logo
      pw.MemoryImage? logoImage;
      try {
        final ByteData data = await rootBundle.load('assets/images/logo_effort.png');
        logoImage = pw.MemoryImage(data.buffer.asUint8List());
      } catch (_) {
        try {
          final ByteData data = await rootBundle.load('assets/icons/logo_effort.png');
          logoImage = pw.MemoryImage(data.buffer.asUint8List());
        } catch (_) {}
      }

      // Couleurs
      final rouge      = PdfColor.fromHex('C62828');
      final rougeFonce = PdfColor.fromHex('8B0000');
      final vert       = PdfColor.fromHex('2E7D32');
      final vertClair  = PdfColor.fromHex('E8F5E9');
      final rougeClair = PdfColor.fromHex('FFEBEE');
      final greyLight  = PdfColor.fromHex('F5F5F5');
      final greyMed    = PdfColor.fromHex('BDBDBD');
      final greyDark   = PdfColor.fromHex('424242');
      final greyText   = PdfColor.fromHex('6C757D');
      final borderVert = PdfColor.fromHex('A5D6A7');
      final borderRge  = PdfColor.fromHex('EF9A9A');
      final noir       = PdfColors.black;

      String getMention() {
        if (pct >= 90) return 'EXCELLENT';
        if (pct >= 80) return 'TRES BIEN';
        if (pct >= 70) return 'BIEN';
        if (pct >= 60) return 'ASSEZ BIEN';
        if (pct >= 50) return 'PASSABLE';
        return 'INSUFFISANT';
      }

      PdfColor getMentionColor() {
        if (pct >= 70) return vert;
        if (pct >= 50) return PdfColor.fromHex('F57C00');
        return rouge;
      }

      String getAppreciation() {
        if (pct >= 90) return 'Excellent ! Vous maîtrisez parfaitement ce chapitre. Continuez ainsi !';
        if (pct >= 80) return 'Très bien ! Bon niveau. Quelques révisions pour atteindre l\'excellence.';
        if (pct >= 70) return 'Bien ! Bonne maîtrise. Concentrez-vous sur les points manqués.';
        if (pct >= 60) return 'Assez bien. Fondamentaux assimilés. Approfondissez davantage.';
        if (pct >= 50) return 'Passable. Revoyez les notions importantes. Persévérez !';
        return 'Des efforts supplémentaires sont nécessaires. Revoyez le cours attentivement.';
      }

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.fromLTRB(40, 36, 40, 36),
          header: (context) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.center,
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  if (logoImage != null) ...[
                    pw.Container(width: 52, height: 52,
                        child: pw.Image(logoImage, fit: pw.BoxFit.contain)),
                    pw.SizedBox(width: 12),
                  ],
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      pw.Text('EF-FORT.BF',
                          style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: noir)),
                      pw.Text('Plateforme N°1 des Concours du Burkina Faso',
                          style: pw.TextStyle(fontSize: 11, color: greyText)),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 6),
              pw.Divider(color: greyMed, thickness: 1),
              pw.SizedBox(height: 4),
            ],
          ),
          footer: (context) => pw.Column(
            children: [
              pw.Divider(color: greyMed, thickness: 0.5),
              pw.SizedBox(height: 4),
              pw.Text(
                'Chaque effort te rapproche de ton admission — EF-FORT.BF',
                textAlign: pw.TextAlign.center,
                style: pw.TextStyle(fontSize: 11, color: greyText, fontStyle: pw.FontStyle.italic),
              ),
              pw.SizedBox(height: 2),
              pw.Text('Page ${context.pageNumber}/${context.pagesCount}',
                  textAlign: pw.TextAlign.center,
                  style: pw.TextStyle(fontSize: 10, color: greyMed)),
            ],
          ),
          build: (context) {
            final List<pw.Widget> widgets = [];

            // ── Infos candidat + Score encerclé ──
            widgets.add(
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Expanded(
                    child: pw.Container(
                      padding: const pw.EdgeInsets.all(12),
                      decoration: pw.BoxDecoration(
                        border: pw.Border.all(color: greyMed, width: 0.8),
                        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                      ),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text('CORRECTION — ${_cleanTextForPdf(widget.label)}',
                              style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, color: greyDark)),
                          pw.SizedBox(height: 6),
                          pw.Text('Candidat(e) : ${nomCandidat.isEmpty ? "Candidat" : nomCandidat}',
                              style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                          pw.SizedBox(height: 3),
                          pw.Text('Matière : ${_cleanTextForPdf(widget.label)}   |   Date : $dateStr',
                              style: pw.TextStyle(fontSize: 12, color: greyText)),
                          pw.SizedBox(height: 8),
                          pw.Container(
                            padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: pw.BoxDecoration(
                              color: getMentionColor(),
                              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                            ),
                            child: pw.Text(getMention(),
                                style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColors.white)),
                          ),
                          pw.SizedBox(height: 6),
                          pw.Text(getAppreciation(),
                              style: pw.TextStyle(fontSize: 12, color: greyDark, fontStyle: pw.FontStyle.italic, lineSpacing: 3)),
                        ],
                      ),
                    ),
                  ),
                  pw.SizedBox(width: 16),
                  // ── SCORE ENCERCLE EN ROUGE ──
                  pw.Column(
                    mainAxisAlignment: pw.MainAxisAlignment.center,
                    children: [
                      pw.Container(
                        width: 90, height: 90,
                        decoration: pw.BoxDecoration(
                          color: PdfColors.white,
                          shape: pw.BoxShape.circle,
                          border: pw.Border.all(color: rouge, width: 4),
                        ),
                        child: pw.Center(
                          child: pw.Column(
                            mainAxisAlignment: pw.MainAxisAlignment.center,
                            children: [
                              pw.Text(noteStr,
                                  style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold, color: rouge)),
                              pw.Container(width: 40, height: 1.5, color: rougeFonce),
                              pw.Text('20',
                                  style: pw.TextStyle(fontSize: 14, color: rouge)),
                            ],
                          ),
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text('$score/$total  ($pct%)',
                          textAlign: pw.TextAlign.center,
                          style: pw.TextStyle(fontSize: 11, color: greyText)),
                    ],
                  ),
                ],
              ),
            );
            widgets.add(pw.SizedBox(height: 14));

            // ── Titre correction ──
            widgets.add(
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: pw.BoxDecoration(
                  color: greyDark,
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                ),
                child: pw.Text('CORRIGE DETAILLE — QUESTION PAR QUESTION',
                    style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, color: PdfColors.white)),
              ),
            );
            widgets.add(pw.SizedBox(height: 10));

            // ── Questions ──
            for (int i = 0; i < _questions.length; i++) {
              final q = _questions[i] as Map<String, dynamic>;
              final bonnesSet = _getBonnesReponses(q);
              final choisies = _selectedAnswers[i] ?? {};
              final correct = choisies.isNotEmpty && choisies.containsAll(bonnesSet) && bonnesSet.containsAll(choisies);
              final noAns = choisies.isEmpty;
              final bonneStr = bonnesSet.toList()..sort();

              final enonce = _cleanTextForPdf((q['enonce'] ?? q['question'] ?? '').toString());
              final bgColor   = noAns ? greyLight : (correct ? vertClair : rougeClair);
              final brdColor  = noAns ? greyMed   : (correct ? borderVert : borderRge);
              final numColor  = noAns ? greyText  : (correct ? vert : rouge);
              final statusTxt = noAns ? 'NON REPONDU' : (correct ? 'CORRECT' : 'INCORRECT');
              final choisiesDisplay = choisies.isEmpty ? 'Aucune' : (choisies.toList()..sort()).join('+');
              final bonneDisplay = bonneStr.isEmpty ? '?' : bonneStr.join('+');

              widgets.add(
                pw.Container(
                  margin: const pw.EdgeInsets.only(bottom: 10),
                  padding: const pw.EdgeInsets.fromLTRB(12, 10, 12, 10),
                  decoration: pw.BoxDecoration(
                    color: bgColor,
                    border: pw.Border.all(color: brdColor, width: 0.8),
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Row(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Container(
                            width: 26, height: 26,
                            decoration: pw.BoxDecoration(color: numColor, shape: pw.BoxShape.circle),
                            child: pw.Center(
                              child: pw.Text('${i + 1}',
                                  style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColors.white)),
                            ),
                          ),
                          pw.SizedBox(width: 8),
                          pw.Expanded(
                            child: pw.Text(enonce,
                                style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: greyDark, lineSpacing: 3)),
                          ),
                          pw.SizedBox(width: 6),
                          pw.Container(
                            padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: pw.BoxDecoration(
                              color: numColor,
                              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                            ),
                            child: pw.Text(statusTxt,
                                style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: PdfColors.white)),
                          ),
                        ],
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        'Votre réponse : $choisiesDisplay   |   Bonne(s) réponse(s) : $bonneDisplay',
                        style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold,
                            color: correct ? vert : rouge),
                      ),
                      pw.SizedBox(height: 4),
                      // Options
                      ...['A', 'B', 'C', 'D'].where((l) {
                        final key = 'option_${l.toLowerCase()}';
                        return (q[key]?.toString() ?? '').isNotEmpty;
                      }).map((l) {
                        final key = 'option_${l.toLowerCase()}';
                        final optText = _cleanTextForPdf(q[key]?.toString() ?? '');
                        final isBonne = bonnesSet.contains(l);
                        final isChoisie = choisies.contains(l);
                        final textColor = isBonne ? vert : (isChoisie ? rouge : greyText);
                        final fontW = isBonne ? pw.FontWeight.bold : pw.FontWeight.normal;
                        return pw.Padding(
                          padding: const pw.EdgeInsets.only(left: 34, bottom: 4),
                          child: pw.Row(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text('$l. ', style: pw.TextStyle(fontSize: 14, fontWeight: fontW, color: textColor)),
                              pw.Expanded(
                                child: pw.Text(
                                  optText + (isBonne ? '  ✓ Bonne réponse' : (isChoisie ? '  ✗ Votre réponse' : '')),
                                  style: pw.TextStyle(fontSize: 14, color: textColor, fontWeight: fontW, lineSpacing: 2),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                      if (q['explication'] != null && (q['explication'] as String).isNotEmpty) ...[
                        pw.SizedBox(height: 6),
                        pw.Container(
                          width: double.infinity,
                          padding: const pw.EdgeInsets.all(8),
                          decoration: pw.BoxDecoration(
                            color: PdfColor.fromHex('FFF8E1'),
                            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                            border: pw.Border.all(color: PdfColor.fromHex('FFD54F'), width: 0.8),
                          ),
                          child: pw.Row(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text('Explication : ',
                                  style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold,
                                      color: PdfColor.fromHex('E65100'))),
                              pw.Expanded(
                                child: pw.Text(
                                  _cleanTextForPdf(q['explication'].toString()),
                                  style: pw.TextStyle(fontSize: 14, color: greyDark, fontStyle: pw.FontStyle.italic, lineSpacing: 3),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            }
            return widgets;
          },
        ),
      );

      final matiereSafe = widget.label
          .replaceAll(RegExp(r'[^a-zA-Z0-9\u00C0-\u024F_-]'), '_')
          .replaceAll(RegExp(r'_+'), '_');
      await Printing.sharePdf(bytes: await pdf.save(),
          filename: 'EF-FORT_Correction_$matiereSafe.pdf');
    } catch (e) {
      if (ctx.mounted) {
        ScaffoldMessenger.of(ctx).showSnackBar(
          SnackBar(content: Text('Erreur PDF : $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Widget _buildPremiumBanner() {    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AbonnementScreen())),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1A5C38), Color(0xFF2E7D53)],
          ),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            const Text('🔒', style: TextStyle(fontSize: 24)),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Vous avez utilisé votre essai gratuit.',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    'Abonnez-vous pour accéder à toutes les séries illimitées.',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.white70,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFD4A017),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                'M\'abonner',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
