import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/theme/app_colors.dart';
import '../services/api_service.dart';
import 'abonnement_screen.dart';

// ══════════════════════════════════════════════════════════════════════
// QCM WHATSAPP SCREEN — Style bulles WhatsApp vert/gris
// Questions en bulle verte (droite) · Réponses en bulle grise (gauche)
// Timer live · Navigation Prev/Suiv/Sauter · Score temps réel
// ══════════════════════════════════════════════════════════════════════

// ─── Couleurs WhatsApp ─────────────────────────────────────────────
const _waGreen = Color(0xFF25D366);        // Vert WhatsApp signature
const _waDarkGreen = Color(0xFF128C7E);    // Vert foncé header
const _waLightGreen = Color(0xFFDCF8C6);  // Bulle question (vert clair)
const _waGray = Color(0xFFF0F0F0);        // Bulle réponse (gris)
const _waBlue = Color(0xFF34B7F1);        // Sélection active
const _waBg = Color(0xFFECE5DD);          // Fond papier peint WhatsApp

class QcmWhatsappScreen extends StatefulWidget {
  final String matiere;        // ex: "hg", "droit", "ang"...
  final String label;          // ex: "Histoire-Géographie"
  final Color? couleur;
  final String? icone;
  final String? serieId;       // UUID série optionnel
  final int? serieNumero;      // numéro de série

  const QcmWhatsappScreen({
    super.key,
    required this.matiere,
    required this.label,
    this.couleur,
    this.icone,
    this.serieId,
    this.serieNumero,
  });

  @override
  State<QcmWhatsappScreen> createState() => _QcmWhatsappScreenState();
}

class _QcmWhatsappScreenState extends State<QcmWhatsappScreen>
    with TickerProviderStateMixin {
  // ─── Données ──────────────────────────────────────────────────────
  List<dynamic> _questions = [];
  bool _loading = true;
  int _currentIndex = 0;

  // ─── Réponses ─────────────────────────────────────────────────────
  final Map<int, Set<String>> _selectedAnswers = {};
  final Set<int> _skipped = {};
  bool _serieTerminee = false;
  // Note: Correction uniquement en fin de série — PAS de correction instantanée (v2.1)

  // ─── Timer ────────────────────────────────────────────────────────
  int _secondsElapsed = 0;
  Timer? _timer;
  bool _isPaused = false;

  // ─── Animation scroll ─────────────────────────────────────────────
  final ScrollController _scrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadQuestions();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _scrollCtrl.dispose();
    super.dispose();
  }

  // ══ Chargement ════════════════════════════════════════════════════
  Future<void> _loadQuestions() async {
    final isAbonne = ApiService.isAbonne;
    final limit = isAbonne ? 20 : 5;
    List<dynamic> questions;

    if (widget.serieId != null) {
      questions = await ApiService.getQuestionsBySerie(widget.serieId!, limit: limit);
    } else {
      questions = await ApiService.getQuestions(widget.matiere, limit: limit);
    }

    if (mounted) {
      setState(() {
        _questions = questions;
        _loading = false;
      });
    }
  }

  // ══ Timer ══════════════════════════════════════════════════════════
  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!_isPaused && !_serieTerminee && mounted) {
        setState(() => _secondsElapsed++);
      }
    });
  }

  String get _timerDisplay {
    final m = (_secondsElapsed ~/ 60).toString().padLeft(2, '0');
    final s = (_secondsElapsed % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  void _togglePause() => setState(() => _isPaused = !_isPaused);

  // ══ Actions réponse ════════════════════════════════════════════════
  void _toggleAnswer(String letter) {
    if (_serieTerminee) return;
    setState(() {
      _selectedAnswers.putIfAbsent(_currentIndex, () => {});
      final sel = _selectedAnswers[_currentIndex]!;
      if (sel.contains(letter)) {
        sel.remove(letter);
      } else {
        sel.add(letter);
      }
    });
  }

  void _valider() {
    // Pas de correction instantanée — on passe directement à la question suivante
    if ((_selectedAnswers[_currentIndex] ?? {}).isEmpty) {
      // Pas de réponse → avertissement
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sélectionnez au moins une réponse ou utilisez "Sauter"'),
          backgroundColor: _waDarkGreen,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }
    // Aller directement à la prochaine question sans afficher la correction
    _goNext();
  }

  void _goNext() {
    if (_currentIndex < _questions.length - 1) {
      setState(() => _currentIndex++);
      _scrollToTop();
    } else {
      _finirSerie();
    }
  }

  void _goPrev() {
    if (_currentIndex > 0) {
      setState(() {
        _currentIndex--;
      });
      _scrollToTop();
    }
  }

  void _sauter() {
    setState(() {
      _skipped.add(_currentIndex);
      _selectedAnswers.remove(_currentIndex);
    });
    if (_currentIndex < _questions.length - 1) {
      setState(() => _currentIndex++);
      _scrollToTop();
    } else {
      _finirSerie();
    }
  }

  void _finirSerie() {
    _timer?.cancel();
    setState(() {
      _serieTerminee = true;
    });
    _scrollToTop();
  }

  // ══ Calculs ════════════════════════════════════════════════════════
  int get _scoreActuel {
    int score = 0;
    for (int i = 0; i <= _currentIndex && i < _questions.length; i++) {
      final q = _questions[i] as Map<String, dynamic>;
      final bonnes = _getBonnesReponses(q);
      final choisies = _selectedAnswers[i] ?? {};
      if (choisies.isNotEmpty &&
          choisies.containsAll(bonnes) &&
          bonnes.containsAll(choisies)) {
        score++;
      }
    }
    return score;
  }

  int _calculerScoreFinal() {
    int score = 0;
    for (int i = 0; i < _questions.length; i++) {
      final q = _questions[i] as Map<String, dynamic>;
      final bonnes = _getBonnesReponses(q);
      final choisies = _selectedAnswers[i] ?? {};
      if (choisies.isNotEmpty &&
          choisies.containsAll(bonnes) &&
          bonnes.containsAll(choisies)) {
        score++;
      }
    }
    return score;
  }

  Set<String> _getBonnesReponses(Map<String, dynamic> q) {
    final rep = (q['bonne_reponse'] ?? '').toString().toUpperCase();
    return rep.split('').where((c) => ['A', 'B', 'C', 'D', 'E'].contains(c)).toSet();
  }

  // ══ Scroll ═════════════════════════════════════════════════════════
  void _scrollToTop() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(0,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut);
      }
    });
  }

  // _scrollToBottom supprimé (correction instantanée désactivée)

  // ══ Build ══════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _waBg,
      appBar: _buildAppBar(),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _waGreen))
          : _questions.isEmpty
              ? _buildEmpty()
              : _serieTerminee
                  ? _buildResultatFinal()
                  : _buildChatInterface(),
    );
  }

  // ── AppBar style WhatsApp ──────────────────────────────────────────
  PreferredSizeWidget _buildAppBar() {
    final q = (!_loading && _questions.isNotEmpty && !_serieTerminee)
        ? 'Q${_currentIndex + 1}/${_questions.length}'
        : widget.label;

    return AppBar(
      backgroundColor: _waDarkGreen,
      foregroundColor: Colors.white,
      elevation: 2,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => Navigator.pop(context),
      ),
      title: Row(
        children: [
          // Avatar matière
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: _waGreen,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                widget.icone ?? '📚',
                style: const TextStyle(fontSize: 18),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.label,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                if (!_loading && _questions.isNotEmpty && !_serieTerminee)
                  Text(
                    q,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.white70,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        if (!_loading && _questions.isNotEmpty && !_serieTerminee) ...[
          // Timer
          Container(
            margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.black26,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.timer_outlined, size: 14, color: Colors.white),
                const SizedBox(width: 3),
                Text(
                  _timerDisplay,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
          ),
          // Pause
          IconButton(
            icon: Icon(
              _isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded,
              color: Colors.white,
            ),
            onPressed: _togglePause,
            tooltip: _isPaused ? 'Reprendre' : 'Pause',
          ),
        ],
      ],
    );
  }

  // ── Interface Chat principale ──────────────────────────────────────
  Widget _buildChatInterface() {
    return Column(
      children: [
        // Barre de progression
        _buildProgressBar(),

        // Zone de chat (scrollable)
        Expanded(
          child: SingleChildScrollView(
            controller: _scrollCtrl,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Bulle QUESTION (droite, verte)
                _buildQuestionBubble(),
                const SizedBox(height: 8),

                // Bulle RÉPONSES (gauche, grise)
                _buildReponsesBubble(),

                // Bannière abonnement
                if (!ApiService.isAbonne && _currentIndex >= 4) ...[
                  const SizedBox(height: 12),
                  _buildPremiumBanner(),
                ],

                const SizedBox(height: 80),
              ],
            ),
          ),
        ),

        // Barre de navigation (fixe en bas)
        _buildBottomNav(),
      ],
    );
  }

  // ── Barre de progression ───────────────────────────────────────────
  Widget _buildProgressBar() {
    return Container(
      color: _waDarkGreen,
      child: LinearProgressIndicator(
        value: (_currentIndex + 1) / _questions.length,
        backgroundColor: Colors.white24,
        valueColor: const AlwaysStoppedAnimation<Color>(_waGreen),
        minHeight: 3,
      ),
    );
  }

  // ── Bulle QUESTION (style message envoyé — droite — vert) ──────────
  Widget _buildQuestionBubble() {
    final q = _questions[_currentIndex] as Map<String, dynamic>;
    final texte = (q['enonce'] ?? q['question'] ?? '').toString();
    final theme = (q['tags'] ?? q['theme'] ?? '').toString();

    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Flexible(
          child: Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.82,
            ),
            margin: const EdgeInsets.only(left: 40),
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
            decoration: BoxDecoration(
              color: _waLightGreen,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(4),
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Badge "Question"
                Container(
                  margin: const EdgeInsets.only(bottom: 6),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: _waGreen.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.quiz_rounded, size: 13, color: _waDarkGreen),
                      const SizedBox(width: 4),
                      Text(
                        theme.isNotEmpty ? theme : 'Question ${_currentIndex + 1}',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: _waDarkGreen,
                        ),
                      ),
                    ],
                  ),
                ),
                // Texte question (GRAS)
                Text(
                  texte,
                  style: const TextStyle(
                    fontSize: 15.5,
                    fontFamily: 'Roboto',
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A1A1A),
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 5),
                // Heure + double coche style WhatsApp
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      _timerDisplay,
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.black.withValues(alpha: 0.4),
                      ),
                    ),
                    const SizedBox(width: 3),
                    Icon(Icons.done_all, size: 13,
                        color: Colors.black.withValues(alpha: 0.4)),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 4),
        // Petite queue de bulle
        _buildBubbleTail(isRight: true),
      ],
    );
  }

  // ── Bulle RÉPONSES (style message reçu — gauche — gris) ────────────
  Widget _buildReponsesBubble() {
    final q = _questions[_currentIndex] as Map<String, dynamic>;
    final opts = {
      'A': q['option_a']?.toString() ?? '',
      'B': q['option_b']?.toString() ?? '',
      'C': q['option_c']?.toString() ?? '',
      'D': q['option_d']?.toString() ?? '',
      'E': q['option_e']?.toString() ?? '',
    };
    final selected = _selectedAnswers[_currentIndex] ?? {};
    final bonnes = _getBonnesReponses(q);
    final nbBonnes = bonnes.length;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        _buildBubbleTail(isRight: false),
        const SizedBox(width: 4),
        Flexible(
          child: Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.88,
            ),
            margin: const EdgeInsets.only(right: 40),
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
            decoration: BoxDecoration(
              color: _waGray,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(4),
                topRight: Radius.circular(16),
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icône "répondant"
                Row(
                  children: [
                    const Icon(Icons.person_outline_rounded,
                        size: 14, color: _waDarkGreen),
                    const SizedBox(width: 5),
                    Text(
                      'Votre réponse',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: _waDarkGreen,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Options A/B/C/D/E
                ...opts.entries.where((e) => e.value.isNotEmpty).map((entry) {
                  final letter = entry.key;
                  final text = entry.value;
                  final isSelected = selected.contains(letter);
                  // Pas de correction instantanée — couleurs simples sélection/non-sélection
                  final Color bgColor = isSelected
                      ? _waBlue.withValues(alpha: 0.15)
                      : Colors.white.withValues(alpha: 0.7);
                  final Color borderColor = isSelected ? _waBlue : Colors.grey.shade300;
                  final Color textColor = isSelected ? _waDarkGreen : const Color(0xFF1A1A1A);
                  const Widget? trailingWidget = null;

                  return GestureDetector(
                    onTap: () => _toggleAnswer(letter),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 11),
                      decoration: BoxDecoration(
                        color: bgColor,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: borderColor, width: 1.5),
                      ),
                      child: Row(
                        children: [
                          // Cercle radio (simple, sans correction instantanée)
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isSelected ? _waBlue : Colors.white,
                              border: Border.all(
                                color: isSelected ? _waBlue : Colors.grey.shade400,
                                width: 1.5,
                              ),
                            ),
                            child: Center(
                              child: isSelected
                                  ? const Icon(Icons.check, color: Colors.white, size: 14)
                                  : Text(
                                      letter,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              text,
                              style: TextStyle(
                                fontSize: 14,
                                fontFamily: 'Roboto',
                                color: textColor,
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                                height: 1.4,
                              ),
                            ),
                          ),
                          if (trailingWidget != null) ...[
                            const SizedBox(width: 6),
                            trailingWidget,
                          ],
                        ],
                      ),
                    ),
                  );
                }),

                const SizedBox(height: 6),
                // Consigne
                Text(
                  nbBonnes > 1
                      ? 'Cochez $nbBonnes cases. Bonne=1pt. Vide=0pt'
                      : 'Cochez 1 case. Bonne=1pt. Vide=0pt',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade600,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // _buildCorrectionBubble supprimée — correction uniquement en fin de série

  // ── Queue de bulle ─────────────────────────────────────────────────
  Widget _buildBubbleTail({required bool isRight}) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: isRight ? _waLightGreen : _waGray,
        shape: BoxShape.circle,
      ),
    );
  }

  // ── Barre de navigation bas ────────────────────────────────────────
  Widget _buildBottomNav() {
    final isFirst = _currentIndex == 0;
    final isLast = _currentIndex == _questions.length - 1;
    // ignore: unused_local_variable
    final hasAnswer = (_selectedAnswers[_currentIndex] ?? {}).isNotEmpty;

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Score live
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Score: $_scoreActuel/${_currentIndex + 1}',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: _waDarkGreen,
                ),
              ),
              Row(
                children: [
                  _buildDot(_waGreen, 'Correct'),
                  const SizedBox(width: 8),
                  _buildDot(Colors.red, 'Incorrect'),
                  const SizedBox(width: 8),
                  _buildDot(Colors.grey, 'Sauté'),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Boutons navigation
          Row(
            children: [
              // Précédent
              _navBtn(
                icon: Icons.arrow_back_ios_new_rounded,
                label: 'Prev',
                onTap: isFirst ? null : _goPrev,
                color: Colors.grey.shade600,
                outlined: true,
              ),
              const SizedBox(width: 8),
              // Sauter
              _navBtn(
                icon: Icons.skip_next_rounded,
                label: 'Sauter',
                onTap: isLast ? null : _sauter,
                color: Colors.orange,
                outlined: true,
              ),
              const SizedBox(width: 8),
              // Valider / Terminer (pas de correction instantanée)
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  onPressed: _valider,
                  icon: Icon(
                    isLast ? Icons.check_circle_rounded : Icons.arrow_forward_rounded,
                    size: 18,
                  ),
                  label: Text(
                    isLast ? 'Terminer' : 'Valider & Suivant',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontFamily: 'Roboto',
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isLast ? _waDarkGreen : _waGreen,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    elevation: 2,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _navBtn({
    required IconData icon,
    required String label,
    required VoidCallback? onTap,
    required Color color,
    bool outlined = false,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedOpacity(
          opacity: onTap == null ? 0.35 : 1.0,
          duration: const Duration(milliseconds: 200),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: outlined ? Colors.transparent : color,
              border: outlined ? Border.all(color: color, width: 1.5) : null,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 18, color: outlined ? color : Colors.white),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: outlined ? color : Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8, height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 3),
        Text(label, style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
      ],
    );
  }

  // ══ Écran vide ═════════════════════════════════════════════════════
  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('📭', style: TextStyle(fontSize: 64)),
          const SizedBox(height: 16),
          const Text(
            'Aucune question disponible\npour cette matière.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textLight, fontSize: 16),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back),
            label: const Text('Retour'),
            style: ElevatedButton.styleFrom(backgroundColor: _waGreen),
          ),
        ],
      ),
    );
  }

  // ══ Résultat Final ═════════════════════════════════════════════════
  Widget _buildResultatFinal() {
    final score = _calculerScoreFinal();
    final total = _questions.length;
    final pct = total > 0 ? (score / total * 100).round() : 0;
    final sur20 = total > 0 ? (score / total * 20).toStringAsFixed(1) : '0';

    String emoji;
    String mention;
    Color mentionColor;
    if (pct >= 80) {
      emoji = '🏆';
      mention = 'Excellent !';
      mentionColor = _waGreen;
    } else if (pct >= 60) {
      emoji = '👍';
      mention = 'Bien !';
      mentionColor = Colors.blue;
    } else if (pct >= 40) {
      emoji = '📖';
      mention = 'Passable';
      mentionColor = Colors.orange;
    } else {
      emoji = '💪';
      mention = 'À revoir';
      mentionColor = Colors.red;
    }

    return Container(
      color: _waBg,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // ── Carte résultat (style bulle) ──────────────────────
            Container(
              margin: const EdgeInsets.only(bottom: 20),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: _waLightGreen,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: _waGreen.withValues(alpha: 0.5), width: 2),
                boxShadow: [
                  BoxShadow(
                    color: _waGreen.withValues(alpha: 0.2),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Text(emoji, style: const TextStyle(fontSize: 56)),
                  const SizedBox(height: 8),
                  Text(
                    mention,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: mentionColor,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Score sur 20
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                    decoration: BoxDecoration(
                      color: _waDarkGreen,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      '$sur20 / 20',
                      style: const TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '$score bonne(s) sur $total questions  •  $pct%',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  Text(
                    'Temps total : $_timerDisplay',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),

            // ── Correction question par question ──────────────────
            Text(
              '📋 Correction détaillée',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: _waDarkGreen,
              ),
            ),
            const SizedBox(height: 12),

            ..._questions.asMap().entries.map((entry) {
              final i = entry.key;
              final q = entry.value as Map<String, dynamic>;
              final bonnes = _getBonnesReponses(q);
              final choisies = _selectedAnswers[i] ?? {};
              final skipped = _skipped.contains(i);
              final correct = !skipped &&
                  choisies.isNotEmpty &&
                  choisies.containsAll(bonnes) &&
                  bonnes.containsAll(choisies);
              final opts = {
                'A': q['option_a']?.toString() ?? '',
                'B': q['option_b']?.toString() ?? '',
                'C': q['option_c']?.toString() ?? '',
                'D': q['option_d']?.toString() ?? '',
                'E': q['option_e']?.toString() ?? '',
              };

              Color bg, border;
              String status;
              if (skipped || choisies.isEmpty) {
                bg = Colors.grey.shade100;
                border = Colors.grey.shade300;
                status = 'Non répondu';
              } else if (correct) {
                bg = const Color(0xFFDCF8C6);
                border = _waGreen;
                status = '✅ Correct';
              } else {
                bg = const Color(0xFFFFEDED);
                border = Colors.red.shade300;
                status = '❌ Incorrect';
              }

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: border, width: 1.5),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: _waDarkGreen,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              '${i + 1}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          status,
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                            color: correct
                                ? _waDarkGreen
                                : skipped || choisies.isEmpty
                                    ? Colors.grey.shade600
                                    : Colors.red.shade700,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          'Réponse: ${bonnes.join(",")}',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: _waDarkGreen,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      (q['enonce'] ?? q['question'] ?? '').toString(),
                      style: const TextStyle(
                        fontFamily: 'Roboto',
                        fontWeight: FontWeight.w600,
                        fontSize: 13.5,
                        color: Color(0xFF1A1A1A),
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...opts.entries
                        .where((e) => e.value.isNotEmpty)
                        .map((opt) {
                      final isBonne = bonnes.contains(opt.key);
                      final isChoisie = choisies.contains(opt.key);
                      return Container(
                        margin: const EdgeInsets.only(bottom: 4),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: isBonne
                              ? _waGreen.withValues(alpha: 0.15)
                              : isChoisie && !isBonne
                                  ? Colors.red.withValues(alpha: 0.08)
                                  : Colors.white.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(7),
                          border: Border.all(
                            color: isBonne
                                ? _waGreen.withValues(alpha: 0.6)
                                : isChoisie && !isBonne
                                    ? Colors.red.shade300
                                    : Colors.transparent,
                          ),
                        ),
                        child: Row(
                          children: [
                            Text(
                              '${opt.key}.  ',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                color: isBonne
                                    ? _waDarkGreen
                                    : Colors.grey.shade600,
                                fontSize: 12,
                              ),
                            ),
                            Expanded(
                              child: Text(
                                opt.value,
                                style: TextStyle(
                                  fontSize: 12.5,
                                  color: isBonne
                                      ? _waDarkGreen
                                      : isChoisie && !isBonne
                                          ? Colors.red.shade700
                                          : Colors.grey.shade700,
                                  fontWeight: isBonne
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                                ),
                              ),
                            ),
                            if (isBonne)
                              const Icon(Icons.check, color: _waGreen, size: 14)
                            else if (isChoisie && !isBonne)
                              Icon(Icons.close,
                                  color: Colors.red.shade400, size: 14),
                          ],
                        ),
                      );
                    }),
                    if ((q['explication'] ?? '').toString().isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.7),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('💡',
                                style: TextStyle(fontSize: 13)),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                q['explication'].toString(),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade700,
                                  height: 1.4,
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

            // ── Bouton PDF (abonnés) ou Recommencer (gratuit) ──────
            if (ApiService.isAbonne) ...
              _buildPDFButton()
            else ...
              _buildRecommencerButton(),

            const SizedBox(height: 12),

            // ── Bouton Retour ─────────────────────────────────────
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back),
                label: const Text('Retour aux séries'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _waDarkGreen,
                  side: const BorderSide(color: _waDarkGreen, width: 1.5),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  // ── Bouton PDF pour abonnés ──────────────────────────────────────
  List<Widget> _buildPDFButton() {
    return [
      SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: () => _exportResultsPDF(),
          icon: const Icon(Icons.picture_as_pdf_rounded, size: 20),
          label: const Text(
            'Imprimer en PDF',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFC1672B),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            elevation: 2,
          ),
        ),
      ),
    ];
  }

  // ── Bouton Recommencer pour non-abonnés ───────────────────────────
  List<Widget> _buildRecommencerButton() {
    return [
      SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: () {
            setState(() {
              _questions = [];
              _loading = true;
              _currentIndex = 0;
              _selectedAnswers.clear();
              _skipped.clear();
              _serieTerminee = false;
              _secondsElapsed = 0;
              _isPaused = false;
            });
            _loadQuestions();
            _startTimer();
          },
          icon: const Icon(Icons.refresh_rounded),
          label: const Text('Recommencer',
              style: TextStyle(fontWeight: FontWeight.w700)),
          style: ElevatedButton.styleFrom(
            backgroundColor: _waGreen,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ),
    ];
  }

  // ── Export PDF des résultats ──────────────────────────────────────
  void _exportResultsPDF() {
    if (!ApiService.isAbonne) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const AbonnementScreen()),
      );
      return;
    }

    // Construire le contenu PDF textuel
    final score = _calculerScoreFinal();
    final total = _questions.length;
    final pct = total > 0 ? (score / total * 100).round() : 0;
    final sur20 = total > 0 ? (score / total * 20).toStringAsFixed(1) : '0';
    final dureeStr = _timerDisplay;

    final user = ApiService.currentUser;
    final nom = user != null
        ? '${user['prenom'] ?? ''} ${user['nom'] ?? ''}'.trim()
        : 'Candidat';

    final buffer = StringBuffer();
    buffer.writeln('EF-FORT.BF — Résultats de la Série');
    buffer.writeln('═══════════════════════════════════');
    buffer.writeln('Candidat : $nom');
    buffer.writeln('Matière  : ${widget.label}');
    buffer.writeln('Date     : ${DateTime.now().toString().substring(0, 16)}');
    buffer.writeln('');
    buffer.writeln('SCORE : $score/$total ($pct%) — /20 : $sur20');
    buffer.writeln('Temps écoulé : $dureeStr');
    buffer.writeln('');
    buffer.writeln('CORRIGÉ DÉTAILLÉ :');
    buffer.writeln('──────────────────');

    for (int i = 0; i < _questions.length; i++) {
      final q = _questions[i] as Map<String, dynamic>;
      final bonnes = _getBonnesReponses(q);
      final choisies = _selectedAnswers[i] ?? {};
      final skipped = _skipped.contains(i);
      final correct = !skipped &&
          choisies.isNotEmpty &&
          choisies.containsAll(bonnes) &&
          bonnes.containsAll(choisies);

      final status = skipped || choisies.isEmpty
          ? 'Non répondu'
          : correct
              ? 'CORRECT'
              : 'INCORRECT';
      buffer.writeln('Q${i + 1}. $status');
      buffer.writeln('  Énoncé : ${(q['enonce'] ?? q['question'] ?? '').toString()}');
      buffer.writeln('  Votre réponse : ${choisies.isEmpty ? '-' : choisies.join(', ')}');
      buffer.writeln('  Bonne(s) réponse(s) : ${bonnes.join(', ')}');
      if ((q['explication'] ?? '').toString().isNotEmpty) {
        buffer.writeln('  Explication : ${q['explication']}');
      }
      buffer.writeln('');
    }

    buffer.writeln('───────────────────────────────────');
    buffer.writeln('EF-FORT.BF — Transformer l\'effort en réussite');

    // Copier dans le presse-papiers et afficher dialog
    Clipboard.setData(ClipboardData(text: buffer.toString()));

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Text('📄', style: TextStyle(fontSize: 24)),
            SizedBox(width: 8),
            Text('Résultats copiés',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Score : $score/$total ($pct%) — Note /20 : $sur20',
              style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  color: Color(0xFF128C7E)),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFDCF8C6),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                '✅ Le corrigé complet a été copié dans le presse-papiers.\n\nCollez-le dans un document Word ou Google Docs pour l\'imprimer.',
                style: TextStyle(fontSize: 12, height: 1.5),
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF128C7E),
              foregroundColor: Colors.white,
            ),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  // ── Bannière Premium ──────────────────────────────────────────────
  Widget _buildPremiumBanner() {
    return GestureDetector(
      onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AbonnementScreen())),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFD4A017), Color(0xFFE67E22)],
          ),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            const Text('👑', style: TextStyle(fontSize: 28)),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Accès illimité avec Premium',
                      style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          fontSize: 14)),
                  Text('500+ QCM par matière · Corrections · Timer',
                      style: TextStyle(color: Colors.white70, fontSize: 12)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded,
                color: Colors.white, size: 16),
          ],
        ),
      ),
    );
  }
}
