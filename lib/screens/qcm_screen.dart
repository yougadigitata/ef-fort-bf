import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../services/api_service.dart';
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
    if (_currentIndex < _questions.length - 1) {
      setState(() => _currentIndex++);
    } else {
      _showCorrectionFin();
    }
  }

  void _showCorrectionFin() {
    setState(() => _serieTerminee = true);
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
            fontSize: 17,
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
                    fontSize: 15,
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
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
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
                          fontSize: 13,
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
                  child: Text(
                    texteQuestion,
                    style: const TextStyle(
                      fontSize: 17,
                      fontFamily: 'Georgia',
                      height: 1.6,
                      color: AppColors.textDark,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),

                const SizedBox(height: 16),
                Text(
                  'Cochez la ou les réponses exactes :',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textLight,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(height: 10),

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
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
                            width: 32,
                            height: 32,
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
                                  ? const Icon(Icons.check, color: Colors.white, size: 16)
                                  : Text(
                                      letter,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 14,
                                        color: Colors.grey.withValues(alpha: 0.7),
                                      ),
                                    ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Text(
                              text,
                              style: TextStyle(
                                fontSize: 15,
                                fontFamily: 'Georgia',
                                height: 1.45,
                                color: isSelected ? _couleur.withValues(alpha: 0.9) : AppColors.textDark,
                                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),

                const SizedBox(height: 24),

                // ── Boutons PASSER / VALIDER (TÂCHE 6) ──
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _passerQuestion,
                        icon: const Icon(Icons.arrow_back_rounded, size: 18),
                        label: const Text('PASSER SANS RÉPONDRE'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.textLight,
                          side: BorderSide(color: Colors.grey.withValues(alpha: 0.4)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _validerEtSuivre,
                        icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                        label: Text(
                          _currentIndex < _questions.length - 1 ? 'VALIDER' : 'TERMINER',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _couleur,
                          foregroundColor: AppColors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 3,
                        ),
                      ),
                    ),
                  ],
                ),

                // Bannière abonnement si version gratuite
                if (!ApiService.isAbonne && _currentIndex >= 4) ...[
                  const SizedBox(height: 20),
                  _buildPremiumBanner(),
                ],

                const SizedBox(height: 40),
              ],
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
                          fontSize: 12,
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
                  Text(
                    (q['enonce'] ?? q['question'] ?? '').toString(),
                    style: const TextStyle(
                      fontSize: 14,
                      fontFamily: 'Georgia',
                      height: 1.5,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textDark,
                    ),
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
                      trailingIcon = const Icon(Icons.check, color: AppColors.success, size: 16);
                    } else if (isChoisie && !isBonne) {
                      optBg = AppColors.error.withValues(alpha: 0.1);
                      optBorder = AppColors.error.withValues(alpha: 0.4);
                      trailingIcon = const Icon(Icons.close, color: AppColors.error, size: 16);
                    }

                    return Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                              fontSize: 13,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              t,
                              style: TextStyle(
                                fontSize: 13,
                                fontFamily: 'Georgia',
                                color: isBonne
                                    ? AppColors.success
                                    : isChoisie ? AppColors.error : AppColors.textDark,
                                fontWeight: isBonne ? FontWeight.w600 : FontWeight.normal,
                              ),
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
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Retour aux matières'),
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
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Recommencer', style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
            ],
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

  Widget _buildPremiumBanner() {
    return GestureDetector(
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
