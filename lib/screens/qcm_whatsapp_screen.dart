import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../core/theme/app_colors.dart';
import '../services/api_service.dart';
import '../widgets/math_text_widget.dart';
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
  final String label;          // ex: titre de la série ou nom de la matière
  final String? matiereNom;    // Nom de la matière (affiché en titre principal)
  final Color? couleur;
  final String? icone;
  final String? serieId;       // UUID série optionnel
  final int? serieNumero;      // numéro de série

  const QcmWhatsappScreen({
    super.key,
    required this.matiere,
    required this.label,
    this.matiereNom,
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
    // 20 questions par série — standard officiel EF-FORT
    const serieLimit = 20;
    List<dynamic> questions;

    if (widget.serieId != null) {
      // Charger les questions de la série (limité à 20)
      final all = await ApiService.getQuestionsBySerie(widget.serieId!, limit: 1000);
      // Prendre exactement 20 questions (les premières de la série)
      questions = all.length > serieLimit ? all.sublist(0, serieLimit) : all;
    } else {
      questions = await ApiService.getQuestions(widget.matiere, limit: serieLimit);
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
                // Titre principal = nom de la matière (jamais un UUID)
                Text(
                  widget.matiereNom ?? widget.label,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                // Sous-titre = titre de la série OU progression
                if (!_loading && _questions.isNotEmpty && !_serieTerminee)
                  Text(
                    '${widget.matiereNom != null ? widget.label + ' · ' : ''}$q',
                    style: const TextStyle(
                      fontSize: 11,
                      color: Colors.white70,
                    ),
                    overflow: TextOverflow.ellipsis,
                  )
                else if (widget.matiereNom != null && widget.label != widget.matiereNom)
                  Text(
                    widget.label,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Colors.white70,
                    ),
                    overflow: TextOverflow.ellipsis,
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
                // Texte question (GRAS avec support formules)
                MathTextWidget(
                  text: texte,
                  textStyle: const TextStyle(
                    fontSize: 15.5,
                    fontFamily: 'Roboto',
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A1A1A),
                    height: 1.5,
                  ),
                  mathSize: 15.5,
                  mathColor: const Color(0xFF1A1A1A),
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
                            child: MathTextWidget(
                              text: text,
                              textStyle: TextStyle(
                                fontSize: 14,
                                fontFamily: 'Roboto',
                                color: textColor,
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                                height: 1.4,
                              ),
                              mathSize: 14,
                              mathColor: textColor,
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
                          color: Colors.red.withValues(alpha: 0.35),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          sur20,
                          style: const TextStyle(
                            fontSize: 34,
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

            // ── Message de motivation — Micro-amélioration #4 ────
            _buildMotivationMessage(pct),
            const SizedBox(height: 12),

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
                    MathTextWidget(
                      text: (q['enonce'] ?? q['question'] ?? '').toString(),
                      textStyle: const TextStyle(
                        fontFamily: 'Roboto',
                        fontWeight: FontWeight.w600,
                        fontSize: 13.5,
                        color: Color(0xFF1A1A1A),
                        height: 1.45,
                      ),
                      mathSize: 13.5,
                      mathColor: const Color(0xFF1A1A1A),
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
                              child: MathTextWidget(
                                text: opt.value,
                                textStyle: TextStyle(
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
                                mathSize: 12.5,
                                mathColor: isBonne
                                    ? _waDarkGreen
                                    : isChoisie && !isBonne
                                        ? Colors.red.shade700
                                        : Colors.grey.shade700,
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
                              child: MathTextWidget(
                                text: q['explication'].toString(),
                                textStyle: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade700,
                                  height: 1.4,
                                ),
                                mathSize: 12,
                                mathColor: Colors.grey.shade700,
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

            // ── Boutons action résultats ──────────────────────────
            ..._buildPDFButton(),
            const SizedBox(height: 8),
            ..._buildRecommencerButton(),

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

  // ── Message de motivation selon le score — Micro-amélioration #4 ─
  Widget _buildMotivationMessage(int pct) {
    String message;
    String emoji;
    Color bgColor;
    Color textColor;

    if (pct >= 90) {
      emoji = '🏆';
      message = 'Extraordinaire ! Tu es au sommet. Le concours n\'a aucun secret pour toi, continue à briller !';
      bgColor = const Color(0xFF1A5C38).withValues(alpha: 0.1);
      textColor = const Color(0xFF1A5C38);
    } else if (pct >= 70) {
      emoji = '🦁';
      message = 'Excellent travail, futur admis ! Avec cette régularité, ton admission est inévitable. L\'étalon du Faso est fier de toi !';
      bgColor = const Color(0xFF2196F3).withValues(alpha: 0.08);
      textColor = const Color(0xFF1565C0);
    } else if (pct >= 50) {
      emoji = '💪';
      message = 'Bonne progression ! Chaque série te rapproche de l\'admission. Recommence, corrige tes erreurs, tu vas y arriver !';
      bgColor = const Color(0xFFFF9800).withValues(alpha: 0.1);
      textColor = const Color(0xFFE65100);
    } else if (pct >= 30) {
      emoji = '📚';
      message = 'Ne lâche pas ! Tous les champions ont d\'abord échoué avant de réussir. Relis le cours et recommence cette série.';
      bgColor = const Color(0xFFFF5722).withValues(alpha: 0.08);
      textColor = const Color(0xFFBF360C);
    } else {
      emoji = '🌱';
      message = 'Courage, candidat ! Chaque effort planté aujourd\'hui fleurira le jour du concours. Relis attentivement et reviens plus fort !';
      bgColor = Colors.grey.shade100;
      textColor = Colors.grey.shade700;
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: textColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 28)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  pct >= 70 ? '🎉 Félicitations !' : pct >= 50 ? '👏 Bien joué !' : '💡 Conseil du coach',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: TextStyle(
                    fontSize: 12.5,
                    color: textColor.withValues(alpha: 0.85),
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Bouton Enregistrer PDF (disponible pour tous) ─────────────────
  List<Widget> _buildPDFButton() {
    return [
      SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: () => _exportResultsPDF(),
          icon: const Icon(Icons.save_alt_rounded, size: 20),
          label: const Text(
            'Enregistrer PDF',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1A5C38),
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

  // ── Export PDF des résultats — Disponible pour tous ───────────────
  void _exportResultsPDF() {
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

    // Copier dans le presse-papiers
    Clipboard.setData(ClipboardData(text: buffer.toString()));

    // Générer et partager le PDF via printing
    _generateAndSharePDF(buffer.toString(), score, total, pct, sur20);
  }

  Future<void> _generateAndSharePDF(String content, int score, int total, int pct, String sur20) async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Génération du PDF en cours...'),
        duration: Duration(seconds: 2),
        backgroundColor: Color(0xFF1A5C38),
      ),
    );

    try {
      final user = ApiService.currentUser;
      final nom = user != null
          ? '${user['prenom'] ?? ''} ${user['nom'] ?? ''}'.trim()
          : 'Candidat';
      final now = DateTime.now();
      final dateStr = '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}';
      final noteDouble = total > 0 ? (score / total * 20) : 0.0;
      final noteStr = noteDouble.toStringAsFixed(1);

      final pdf = pw.Document();
      // ── Palette couleurs PDF ──────────────────────────────────────
      final primaryColor  = PdfColor.fromHex('1A5C38');
      final primaryDark   = PdfColor.fromHex('0E3D24');
      final greyColor     = PdfColor.fromHex('6C757D');
      final successColor  = PdfColor.fromHex('2E7D32');
      final errorColor    = PdfColor.fromHex('C62828');
      final greyDark      = PdfColor.fromHex('424242');
      final lightGreen    = PdfColor.fromHex('E8F5E9');
      final lightRed      = PdfColor.fromHex('FFEBEE');
      final lightGrey     = PdfColor.fromHex('F5F5F5');
      final borderGreen   = PdfColor.fromHex('A5D6A7');
      final borderRed     = PdfColor.fromHex('EF9A9A');
      final borderGrey    = PdfColor.fromHex('BDBDBD');
      final orangeColor   = PdfColor.fromHex('E67E22');
      final redCircle     = PdfColor.fromHex('C62828');
      final redCircleDark = PdfColor.fromHex('8B0000');

      // ── Appréciation selon score ──────────────────────────────────
      String getAppreciation() {
        if (pct >= 90) return 'Excellent ! Vous maitrisez parfaitement le sujet. Continuez ainsi !';
        if (pct >= 80) return 'Excellent travail ! Vous maitrisez bien les notions essentielles. Continuez sur cette lancee et visez la perfection.';
        if (pct >= 70) return 'Tres bien ! Vous avez un bon niveau. Quelques revisions supplementaires vous permettront d\'atteindre l\'excellence.';
        if (pct >= 60) return 'Bien ! Vous avez assimile les fondamentaux. Concentrez-vous sur les points manques pour progresser.';
        if (pct >= 50) return 'Passable. Il vous faut revoir certaines notions importantes. Perseverez dans vos revisions !';
        return 'Des efforts supplementaires sont necessaires. Revoyez attentivement le cours et recommencez. Vous pouvez y arriver !';
      }

      String getMention() {
        if (pct >= 90) return 'EXCELLENT';
        if (pct >= 80) return 'TRES BIEN';
        if (pct >= 70) return 'BIEN';
        if (pct >= 60) return 'ASSEZ BIEN';
        if (pct >= 50) return 'PASSABLE';
        return 'INSUFFISANT';
      }

      PdfColor getMentionColor() {
        if (pct >= 70) return successColor;
        if (pct >= 50) return orangeColor;
        return errorColor;
      }

      // ── Polices ───────────────────────────────────────────────────
      final fontRegular    = pw.Font.helvetica();
      final fontBold       = pw.Font.helveticaBold();
      final fontItalic     = pw.Font.helveticaOblique();
      final fontBoldItalic = pw.Font.helveticaBoldOblique();

      // ── Logo ──────────────────────────────────────────────────────
      pw.MemoryImage? logoImage;
      try {
        final ByteData logoData = await rootBundle.load('assets/images/logo_effort.png');
        logoImage = pw.MemoryImage(logoData.buffer.asUint8List());
      } catch (_) {
        try {
          final ByteData logoData = await rootBundle.load('assets/icons/logo_effort.png');
          logoImage = pw.MemoryImage(logoData.buffer.asUint8List());
        } catch (_) {
          logoImage = null;
        }
      }

      // ── Nettoyeur texte ───────────────────────────────────────────
      String cleanText(String text) {
        if (text.isEmpty) return text;
        return text
            .replaceAll(RegExp(r'[\u{1F000}-\u{1FFFF}]', unicode: true), '')
            .replaceAll(RegExp(r'[\u{2600}-\u{27BF}]', unicode: true), '')
            .replaceAll(RegExp(r'[\u{1F300}-\u{1F9FF}]', unicode: true), '')
            .replaceAll(RegExp(r'[^\x20-\x7E\u00A0-\u024F]'), ' ')
            .replaceAll(RegExp(r' {2,}'), ' ')
            .trim();
      }

      final theme = pw.ThemeData.withFont(
        base: fontRegular,
        bold: fontBold,
        italic: fontItalic,
        boldItalic: fontBoldItalic,
      );

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.fromLTRB(28, 20, 28, 20),
          theme: theme,
          // ════════════════════════════════════════════════════════
          // HEADER — Logo + titre + bandeau vert résultats
          // ════════════════════════════════════════════════════════
          header: (ctx) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Ligne principale logo + infos + cercle note
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  // Logo EF-FORT
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
                        : pw.Center(
                            child: pw.Text('EF',
                                style: pw.TextStyle(
                                  fontSize: 20,
                                  fontWeight: pw.FontWeight.bold,
                                  color: PdfColors.white,
                                ))),
                  ),
                  pw.SizedBox(width: 12),
                  // Nom + slogan + bandeau résultats
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('EF-FORT.BF',
                            style: pw.TextStyle(
                              fontSize: 20,
                              fontWeight: pw.FontWeight.bold,
                              color: primaryColor,
                            )),
                        pw.Text('Plateforme N1 des Concours au Burkina Faso',
                            style: pw.TextStyle(fontSize: 9.5, color: greyColor)),
                        pw.Text('"Chaque effort te rapproche de ton admission finale"',
                            style: pw.TextStyle(
                              fontSize: 9,
                              color: orangeColor,
                              fontStyle: pw.FontStyle.italic,
                            )),
                        pw.SizedBox(height: 5),
                        // Bandeau vert résultats
                        pw.Container(
                          padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: pw.BoxDecoration(
                            color: lightGreen,
                            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5)),
                            border: pw.Border.all(color: borderGreen, width: 0.8),
                          ),
                          child: pw.Text(
                            'Resultats ${cleanText(widget.label)}  —  Correction Detaillee',
                            style: pw.TextStyle(fontSize: 9, color: primaryColor, fontWeight: pw.FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),
                  pw.SizedBox(width: 10),
                  // ── Cercle note ────────────────────────────────
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
                              pw.Text(
                                noteStr,
                                style: pw.TextStyle(
                                  fontSize: 22,
                                  fontWeight: pw.FontWeight.bold,
                                  color: redCircle,
                                ),
                              ),
                              pw.Container(
                                width: 40,
                                height: 1,
                                color: redCircleDark,
                              ),
                              pw.Text(
                                '20',
                                style: pw.TextStyle(fontSize: 14, color: redCircle),
                              ),
                            ],
                          ),
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                        decoration: pw.BoxDecoration(
                          color: getMentionColor(),
                          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5)),
                        ),
                        child: pw.Text(
                          getMention(),
                          style: pw.TextStyle(
                            fontSize: 10,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 10),

              // ── Fiche candidat ─────────────────────────────────
              pw.Container(
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  color: PdfColors.white,
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                  border: pw.Border.all(color: PdfColors.grey300, width: 0.8),
                ),
                child: pw.Row(
                  children: [
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          _pdfInfoRow('Candidat', cleanText(nom.isEmpty ? 'Candidat' : nom), fontBold, greyColor, primaryColor),
                          pw.SizedBox(height: 3),
                          _pdfInfoRow('Matiere', cleanText(widget.label), fontBold, greyColor, greyDark),
                          pw.SizedBox(height: 3),
                          _pdfInfoRow('Date', dateStr, fontBold, greyColor, greyDark),
                          pw.SizedBox(height: 5),
                          // Barre score
                          pw.Container(
                            padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: pw.BoxDecoration(
                              color: lightGreen,
                              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                              border: pw.Border.all(color: borderGreen, width: 0.8),
                            ),
                            child: pw.Text(
                              'Score : $score/$total ($pct%)   |   Note /20 : $noteStr',
                              style: pw.TextStyle(
                                fontSize: 11,
                                fontWeight: pw.FontWeight.bold,
                                color: primaryColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 8),

              // ── Appréciation ───────────────────────────────────
              pw.Container(
                padding: const pw.EdgeInsets.fromLTRB(12, 8, 12, 8),
                decoration: pw.BoxDecoration(
                  color: lightGreen,
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                  border: pw.Border.all(color: borderGreen, width: 0.8),
                ),
                child: pw.Row(
                  children: [
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text('Appreciation',
                              style: pw.TextStyle(
                                fontSize: 11,
                                fontWeight: pw.FontWeight.bold,
                                color: primaryColor,
                              )),
                          pw.SizedBox(height: 3),
                          pw.Text(getAppreciation(),
                              style: pw.TextStyle(fontSize: 10, color: greyDark)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 10),
            ],
          ),

          // ════════════════════════════════════════════════════════
          // FOOTER
          // ════════════════════════════════════════════════════════
          footer: (ctx) => pw.Container(
            padding: const pw.EdgeInsets.only(top: 6),
            decoration: pw.BoxDecoration(
              border: pw.Border(top: pw.BorderSide(color: PdfColors.grey300, width: 0.5)),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Ne lache rien — la reussite est au bout du chemin',
                    style: pw.TextStyle(fontSize: 8, color: greyColor)),
                pw.Text('Page ${ctx.pageNumber}/${ctx.pagesCount}',
                    style: pw.TextStyle(fontSize: 8, color: greyColor, fontStyle: pw.FontStyle.italic)),
              ],
            ),
          ),

          // ════════════════════════════════════════════════════════
          // CONTENU — Questions Q1..Qn
          // ════════════════════════════════════════════════════════
          build: (ctx) => [
            // Titre section
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: pw.BoxDecoration(
                color: primaryColor,
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(7)),
              ),
              child: pw.Text(
                'CORRIGE DETAILLE',
                style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, color: PdfColors.white),
              ),
            ),
            pw.SizedBox(height: 10),

            // Questions détaillées avec correction complète
            ...List.generate(_questions.length, (i) {
              final q = _questions[i] as Map<String, dynamic>;
              final bonnes = _getBonnesReponses(q);
              final choisies = _selectedAnswers[i] ?? {};
              final skipped = _skipped.contains(i);
              final correct = !skipped && choisies.isNotEmpty &&
                  choisies.containsAll(bonnes) && bonnes.containsAll(choisies);
              final noAns = choisies.isEmpty || skipped;

              final bgColor      = noAns ? lightGrey   : (correct ? lightGreen : lightRed);
              final borderColor  = noAns ? borderGrey  : (correct ? borderGreen : borderRed);
              final circleColor  = noAns ? greyColor   : (correct ? successColor : errorColor);
              final statusText   = noAns ? 'NON REPONDU' : (correct ? 'CORRECT' : 'INCORRECT');
              final enonce       = cleanText((q['enonce'] ?? q['question'] ?? '').toString());
              final rawExp       = (q['explication'] ?? '').toString().trim();
              final explication  = cleanText(rawExp);
              
              // Options A/B/C/D/E pour la correction détaillée
              final optA = cleanText((q['option_a'] ?? '').toString());
              final optB = cleanText((q['option_b'] ?? '').toString());
              final optC = cleanText((q['option_c'] ?? '').toString());
              final optD = cleanText((q['option_d'] ?? '').toString());
              final optE = cleanText((q['option_e'] ?? '').toString());
              
              // Construire l'explication à afficher (même si le champ est vide)
              final bonnesStr = bonnes.isEmpty ? '?' : bonnes.join(', ');
              final explicationFinale = explication.isNotEmpty 
                  ? explication
                  : 'La bonne reponse est $bonnesStr. Reportez-vous au cours correspondant pour approfondir cette notion.';

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
                    // En-tête Q + statut
                    pw.Container(
                      padding: const pw.EdgeInsets.fromLTRB(10, 7, 10, 6),
                      decoration: pw.BoxDecoration(
                        color: bgColor,
                        border: pw.Border(bottom: pw.BorderSide(color: borderColor, width: 0.5)),
                        borderRadius: const pw.BorderRadius.only(
                          topLeft: pw.Radius.circular(7),
                          topRight: pw.Radius.circular(7),
                        ),
                      ),
                      child: pw.Row(
                        children: [
                          // Cercle numéro
                          pw.Container(
                            width: 24,
                            height: 24,
                            decoration: pw.BoxDecoration(
                              color: circleColor,
                              shape: pw.BoxShape.circle,
                            ),
                            child: pw.Center(
                              child: pw.Text(
                                'Q${i + 1}',
                                style: pw.TextStyle(
                                  fontSize: 9,
                                  fontWeight: pw.FontWeight.bold,
                                  color: PdfColors.white,
                                ),
                              ),
                            ),
                          ),
                          pw.SizedBox(width: 8),
                          pw.Expanded(
                            child: pw.Text(
                              enonce.isNotEmpty ? enonce : 'Question ${i + 1}',
                              style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: greyDark),
                            ),
                          ),
                          // Badge statut
                          pw.Container(
                            padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: pw.BoxDecoration(
                              color: circleColor,
                              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5)),
                            ),
                            child: pw.Text(
                              statusText,
                              style: pw.TextStyle(
                                fontSize: 9,
                                fontWeight: pw.FontWeight.bold,
                                color: PdfColors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Détails réponse avec options et explication
                    pw.Padding(
                      padding: const pw.EdgeInsets.fromLTRB(10, 5, 10, 8),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          // Ligne votre réponse / bonne réponse
                          pw.Text(
                            'Votre reponse : ${choisies.isEmpty ? "-" : choisies.join(", ")}   |   Bonne(s) : $bonnesStr',
                            style: pw.TextStyle(fontSize: 10, color: greyColor),
                          ),
                          pw.SizedBox(height: 5),
                          // Options A/B/C/D affichées avec la bonne réponse mise en évidence
                          ...([
                            if (optA.isNotEmpty) pw.Row(children: [
                              pw.Container(
                                width: 18, height: 18,
                                decoration: pw.BoxDecoration(
                                  color: bonnes.contains('A') ? successColor : PdfColors.grey300,
                                  shape: pw.BoxShape.circle,
                                ),
                                child: pw.Center(child: pw.Text('A', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.white))),
                              ),
                              pw.SizedBox(width: 5),
                              pw.Expanded(child: pw.Text(optA, style: pw.TextStyle(fontSize: 9.5, color: bonnes.contains('A') ? successColor : greyDark, fontWeight: bonnes.contains('A') ? pw.FontWeight.bold : pw.FontWeight.normal))),
                              if (bonnes.contains('A')) pw.Text(' CORRECT', style: pw.TextStyle(fontSize: 8, color: successColor, fontWeight: pw.FontWeight.bold)),
                            ]),
                            if (optB.isNotEmpty) pw.Row(children: [
                              pw.Container(
                                width: 18, height: 18,
                                decoration: pw.BoxDecoration(
                                  color: bonnes.contains('B') ? successColor : PdfColors.grey300,
                                  shape: pw.BoxShape.circle,
                                ),
                                child: pw.Center(child: pw.Text('B', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.white))),
                              ),
                              pw.SizedBox(width: 5),
                              pw.Expanded(child: pw.Text(optB, style: pw.TextStyle(fontSize: 9.5, color: bonnes.contains('B') ? successColor : greyDark, fontWeight: bonnes.contains('B') ? pw.FontWeight.bold : pw.FontWeight.normal))),
                              if (bonnes.contains('B')) pw.Text(' CORRECT', style: pw.TextStyle(fontSize: 8, color: successColor, fontWeight: pw.FontWeight.bold)),
                            ]),
                            if (optC.isNotEmpty) pw.Row(children: [
                              pw.Container(
                                width: 18, height: 18,
                                decoration: pw.BoxDecoration(
                                  color: bonnes.contains('C') ? successColor : PdfColors.grey300,
                                  shape: pw.BoxShape.circle,
                                ),
                                child: pw.Center(child: pw.Text('C', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.white))),
                              ),
                              pw.SizedBox(width: 5),
                              pw.Expanded(child: pw.Text(optC, style: pw.TextStyle(fontSize: 9.5, color: bonnes.contains('C') ? successColor : greyDark, fontWeight: bonnes.contains('C') ? pw.FontWeight.bold : pw.FontWeight.normal))),
                              if (bonnes.contains('C')) pw.Text(' CORRECT', style: pw.TextStyle(fontSize: 8, color: successColor, fontWeight: pw.FontWeight.bold)),
                            ]),
                            if (optD.isNotEmpty) pw.Row(children: [
                              pw.Container(
                                width: 18, height: 18,
                                decoration: pw.BoxDecoration(
                                  color: bonnes.contains('D') ? successColor : PdfColors.grey300,
                                  shape: pw.BoxShape.circle,
                                ),
                                child: pw.Center(child: pw.Text('D', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.white))),
                              ),
                              pw.SizedBox(width: 5),
                              pw.Expanded(child: pw.Text(optD, style: pw.TextStyle(fontSize: 9.5, color: bonnes.contains('D') ? successColor : greyDark, fontWeight: bonnes.contains('D') ? pw.FontWeight.bold : pw.FontWeight.normal))),
                              if (bonnes.contains('D')) pw.Text(' CORRECT', style: pw.TextStyle(fontSize: 8, color: successColor, fontWeight: pw.FontWeight.bold)),
                            ]),
                            if (optE.isNotEmpty) pw.Row(children: [
                              pw.Container(
                                width: 18, height: 18,
                                decoration: pw.BoxDecoration(
                                  color: bonnes.contains('E') ? successColor : PdfColors.grey300,
                                  shape: pw.BoxShape.circle,
                                ),
                                child: pw.Center(child: pw.Text('E', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.white))),
                              ),
                              pw.SizedBox(width: 5),
                              pw.Expanded(child: pw.Text(optE, style: pw.TextStyle(fontSize: 9.5, color: bonnes.contains('E') ? successColor : greyDark, fontWeight: bonnes.contains('E') ? pw.FontWeight.bold : pw.FontWeight.normal))),
                              if (bonnes.contains('E')) pw.Text(' CORRECT', style: pw.TextStyle(fontSize: 8, color: successColor, fontWeight: pw.FontWeight.bold)),
                            ]),
                          ].map((w) => pw.Padding(padding: const pw.EdgeInsets.only(bottom: 3), child: w)).toList()),
                          pw.SizedBox(height: 5),
                          // Explication (toujours affichée)
                          pw.Container(
                            padding: const pw.EdgeInsets.all(6),
                            decoration: pw.BoxDecoration(
                              color: PdfColors.white,
                              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5)),
                              border: pw.Border.all(color: borderColor, width: 0.5),
                            ),
                            child: pw.Row(
                              crossAxisAlignment: pw.CrossAxisAlignment.start,
                              children: [
                                pw.Text('Expl. : ', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: greyDark)),
                                pw.Expanded(
                                  child: pw.Text(
                                    explicationFinale,
                                    style: pw.TextStyle(
                                      fontSize: 9,
                                      color: greyDark,
                                      fontStyle: pw.FontStyle.italic,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),

            pw.SizedBox(height: 14),
            // Pied de document
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                color: lightGreen,
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(7)),
                border: pw.Border.all(color: borderGreen, width: 0.8),
              ),
              child: pw.Text(
                'Ne lache rien, la reussite est au bout du chemin — EF-FORT.BF',
                textAlign: pw.TextAlign.center,
                style: pw.TextStyle(fontSize: 10, color: primaryColor, fontStyle: pw.FontStyle.italic),
              ),
            ),
          ],
        ),
      );

      await Printing.sharePdf(
        bytes: await pdf.save(),
        filename: 'EF-FORT_Serie_${widget.label.replaceAll(' ', '_')}.pdf',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur PDF: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // ── Helper ligne info PDF ─────────────────────────────────────────
  pw.Widget _pdfInfoRow(String label, String value, pw.Font fontBold, PdfColor labelColor, PdfColor valueColor) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('$label : ', style: pw.TextStyle(fontSize: 11, font: fontBold, color: labelColor)),
        pw.Expanded(
          child: pw.Text(value, style: pw.TextStyle(fontSize: 11, color: valueColor)),
        ),
      ],
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
