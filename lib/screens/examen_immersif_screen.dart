import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../core/theme/app_colors.dart';
import '../services/api_service.dart';
import '../services/bell_service.dart';
import '../widgets/math_text_widget.dart';

// ══════════════════════════════════════════════════════════════════════
// EXAMENS TYPES IMMERSION — Structure nouvelle : examens_types_immersion
// 3 pages : Accueil → Examen 2 colonnes → Résultats + PDF
// Cloches : démarrage, rappel 5min, fin + applaudissements
// Timer 1h30, soumission bloquée 30min sauf admin
// Inspiré de la vraie feuille d'examen (feuille de questions + réponses)
// ══════════════════════════════════════════════════════════════════════

// ─── Couleurs par catégorie d'examen ───────────────────────────────────
const Map<int, Color> _kExamColors = {
  66: Color(0xFF2980B9), // Administration
  67: Color(0xFFC0392B), // Justice
  68: Color(0xFF27AE60), // Économie
  69: Color(0xFF8E44AD), // Santé
  70: Color(0xFF1A5C38), // Éducation
  71: Color(0xFFD4A017), // Techniques
  72: Color(0xFF16A085), // Agriculture
  73: Color(0xFF2980B9), // Informatique
  74: Color(0xFF8E44AD), // Travaux publics
  75: Color(0xFF5D6D7E), // Statistiques
  76: Color(0xFF2980B9),
  77: Color(0xFFC0392B),
  78: Color(0xFF27AE60),
  79: Color(0xFF8E44AD),
  80: Color(0xFF1A5C38),
  81: Color(0xFFD4A017),
  82: Color(0xFF16A085),
  83: Color(0xFF2980B9),
  84: Color(0xFF8E44AD),
  85: Color(0xFF5D6D7E),
};

// ══════════════════════════════════════════════════════════════════════
// 1. PAGE D'ACCUEIL — Choix d'examen + Consignes + Top Départ
// ══════════════════════════════════════════════════════════════════════
class ExamenImmersifAccueilScreen extends StatefulWidget {
  const ExamenImmersifAccueilScreen({super.key});

  @override
  State<ExamenImmersifAccueilScreen> createState() =>
      _ExamenImmersifAccueilScreenState();
}

class _ExamenImmersifAccueilScreenState
    extends State<ExamenImmersifAccueilScreen> {
  // 20 séries : IDs 66-75 (Série 1) et 76-85 (Série 2)
  static const List<Map<String, dynamic>> _kExamensTypes = [
    {'id': 66, 'nom': 'Administration générale', 'serie': 1, 'icone': '🎓', 'description': 'Adjoints et agents administratifs'},
    {'id': 67, 'nom': 'Justice & sécurité', 'serie': 1, 'icone': '⚖️', 'description': 'Greffiers, police, gendarmerie, douane'},
    {'id': 68, 'nom': 'Économie & finances', 'serie': 1, 'icone': '💰', 'description': 'Impôts, trésor, contrôleurs des finances'},
    {'id': 69, 'nom': 'Concours de la santé', 'serie': 1, 'icone': '⚕️', 'description': 'Infirmiers, sages-femmes, agents de santé'},
    {'id': 70, 'nom': 'Éducation & formation', 'serie': 1, 'icone': '📚', 'description': 'Enseignants du primaire et secondaire'},
    {'id': 71, 'nom': 'Concours techniques', 'serie': 1, 'icone': '🔧', 'description': 'Génie civil, électricité, mécanique'},
    {'id': 72, 'nom': 'Agriculture & environnement', 'serie': 1, 'icone': '🌾', 'description': 'Agents agricoles, élevage, environnement'},
    {'id': 73, 'nom': 'Informatique & numérique', 'serie': 1, 'icone': '💻', 'description': 'Techniciens informatiques, développement'},
    {'id': 74, 'nom': 'Travaux publics & urbanisme', 'serie': 1, 'icone': '🏗️', 'description': 'BTP, urbanisme, infrastructures'},
    {'id': 75, 'nom': 'Statistiques & planification', 'serie': 1, 'icone': '📊', 'description': 'Statisticiens, analyse de données'},
    {'id': 76, 'nom': 'Administration générale', 'serie': 2, 'icone': '🎓', 'description': 'Adjoints et agents administratifs'},
    {'id': 77, 'nom': 'Justice & sécurité', 'serie': 2, 'icone': '⚖️', 'description': 'Greffiers, police, gendarmerie, douane'},
    {'id': 78, 'nom': 'Économie & finances', 'serie': 2, 'icone': '💰', 'description': 'Impôts, trésor, contrôleurs des finances'},
    {'id': 79, 'nom': 'Concours de la santé', 'serie': 2, 'icone': '⚕️', 'description': 'Infirmiers, sages-femmes, agents de santé'},
    {'id': 80, 'nom': 'Éducation & formation', 'serie': 2, 'icone': '📚', 'description': 'Enseignants du primaire et secondaire'},
    {'id': 81, 'nom': 'Concours techniques', 'serie': 2, 'icone': '🔧', 'description': 'Génie civil, électricité, mécanique'},
    {'id': 82, 'nom': 'Agriculture & environnement', 'serie': 2, 'icone': '🌾', 'description': 'Agents agricoles, élevage, environnement'},
    {'id': 83, 'nom': 'Informatique & numérique', 'serie': 2, 'icone': '💻', 'description': 'Techniciens informatiques, développement'},
    {'id': 84, 'nom': 'Travaux publics & urbanisme', 'serie': 2, 'icone': '🏗️', 'description': 'BTP, urbanisme, infrastructures'},
    {'id': 85, 'nom': 'Statistiques & planification', 'serie': 2, 'icone': '📊', 'description': 'Statisticiens, analyse de données'},
  ];

  int _selectedSerieTab = 0; // 0 = Série 1, 1 = Série 2
  Map<String, dynamic>? _selectedExamen;
  bool _consignesExpanded = false;

  List<Map<String, dynamic>> get _serie1 =>
      _kExamensTypes.where((e) => e['serie'] == 1).toList();
  List<Map<String, dynamic>> get _serie2 =>
      _kExamensTypes.where((e) => e['serie'] == 2).toList();
  List<Map<String, dynamic>> get _currentList =>
      _selectedSerieTab == 0 ? _serie1 : _serie2;

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 700;
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F0),
      body: Column(
        children: [
          _buildHeader(context),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                  horizontal: isWide ? 32 : 16, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildConsignesCard(),
                  const SizedBox(height: 16),
                  _buildSerieSelector(),
                  const SizedBox(height: 12),
                  _buildExamensGrid(isWide),
                  const SizedBox(height: 20),
                  if (_selectedExamen != null) _buildDemarrerButton(context),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 16,
        bottom: 20,
        left: 20,
        right: 20,
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 8),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '📋 Examens Types',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    fontFamily: 'Poppins',
                  ),
                ),
                Text(
                  '20 séries • 50 questions • 1h30 chrono',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white30),
            ),
            child: const Text(
              'IMMERSIF',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 10,
                letterSpacing: 1,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConsignesCard() {
    return GestureDetector(
      onTap: () =>
          setState(() => _consignesExpanded = !_consignesExpanded),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.3), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.07),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Center(
                        child: Text('📜', style: TextStyle(fontSize: 20))),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'CONSIGNES OFFICIELLES',
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 13,
                            color: AppColors.primary,
                            letterSpacing: 0.5,
                            fontFamily: 'Poppins',
                          ),
                        ),
                        Text(
                          'Règles et conditions de l\'examen',
                          style:
                              TextStyle(fontSize: 11, color: AppColors.textLight),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    _consignesExpanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: AppColors.primary,
                  ),
                ],
              ),
            ),
            if (_consignesExpanded) ...[
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 16),
                child: Column(
                  children: [
                    _buildConsigneLigne(
                        '🔢', '50 questions réparties en plusieurs matières'),
                    _buildConsigneLigne(
                        '⏱️', 'Durée de l\'épreuve : 1h30 (90 minutes)'),
                    _buildConsigneLigne(
                        '🔒', 'Soumission impossible avant 30 minutes'),
                    _buildConsigneLigne(
                        '📝', 'Noircissez les cases sur la feuille de réponses'),
                    _buildConsigneLigne(
                        '❌', 'Réponse incorrecte = pénalité de points'),
                    _buildConsigneLigne(
                        '🔕', 'Zéro point si vous n\'avez pas répondu'),
                    _buildConsigneLigne(
                        '🔔', 'Une cloche marque le démarrage et la fin'),
                    _buildConsigneLigne(
                        '⚠️', 'Toute fraude entraîne l\'annulation'),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildConsigneLigne(String emoji, String texte) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              texte,
              style: const TextStyle(
                fontSize: 12.5,
                color: AppColors.textDark,
                height: 1.4,
                fontFamily: 'Georgia',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSerieSelector() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          _buildSerieTab(0, 'Série 1', '10 examens'),
          _buildSerieTab(1, 'Série 2', '10 examens'),
        ],
      ),
    );
  }

  Widget _buildSerieTab(int index, String titre, String sousTitre) {
    final isSelected = _selectedSerieTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() {
          _selectedSerieTab = index;
          _selectedExamen = null;
        }),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            children: [
              Text(
                titre,
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                  color: isSelected ? Colors.white : AppColors.textLight,
                  fontFamily: 'Poppins',
                ),
              ),
              Text(
                sousTitre,
                style: TextStyle(
                  fontSize: 10,
                  color: isSelected
                      ? Colors.white70
                      : AppColors.textLight,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExamensGrid(bool isWide) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: isWide ? 4 : 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.85,
      ),
      itemCount: _currentList.length,
      itemBuilder: (ctx, i) => _buildExamenCard(_currentList[i], i),
    );
  }

  Widget _buildExamenCard(Map<String, dynamic> examen, int index) {
    final id = examen['id'] as int;
    final color = _kExamColors[id] ?? AppColors.primary;
    final nom = examen['nom'] as String;
    final icone = examen['icone'] as String;
    final desc = examen['description'] as String;
    final isSelected = _selectedExamen?['id'] == id;

    return GestureDetector(
      onTap: () {
        if (!ApiService.isAbonne && !ApiService.isAdmin) {
          _showAbonnementRequired();
          return;
        }
        setState(() => _selectedExamen = isSelected ? null : examen);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? color
                : color.withValues(alpha: 0.25),
            width: isSelected ? 2.5 : 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: isSelected ? 0.3 : 0.1),
              blurRadius: isSelected ? 14 : 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 12, 10, 10),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.white.withValues(alpha: 0.2)
                      : color.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected
                        ? Colors.white.withValues(alpha: 0.4)
                        : color.withValues(alpha: 0.3),
                    width: 1.5,
                  ),
                ),
                child: Center(
                  child: Text(icone, style: const TextStyle(fontSize: 22)),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                nom,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: isSelected ? Colors.white : color,
                  height: 1.2,
                  fontFamily: 'Poppins',
                ),
              ),
              const SizedBox(height: 3),
              Text(
                desc,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 9,
                  color: isSelected
                      ? Colors.white70
                      : Colors.black45,
                ),
              ),
              const Spacer(),
              if (isSelected)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                    border:
                        Border.all(color: Colors.white.withValues(alpha: 0.5)),
                  ),
                  child: const Text(
                    '✓ Sélectionné',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(20),
                    border:
                        Border.all(color: color.withValues(alpha: 0.25)),
                  ),
                  child: Text(
                    'Sér. ${examen['serie']}',
                    style: TextStyle(
                      fontSize: 10,
                      color: color,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDemarrerButton(BuildContext context) {
    final examen = _selectedExamen!;
    final id = examen['id'] as int;
    final color = _kExamColors[id] ?? AppColors.primary;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border:
            Border.all(color: color.withValues(alpha: 0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.12),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                examen['icone'] as String,
                style: const TextStyle(fontSize: 28),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${examen['nom']} — Série ${examen['serie']}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: color,
                        fontFamily: 'Poppins',
                      ),
                    ),
                    const Text(
                      '50 questions • 1h30 • Simulation officielle',
                      style: TextStyle(
                          fontSize: 11, color: AppColors.textLight),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: () => _lancerExamen(context, examen, color),
              icon: const Icon(Icons.notifications_active_rounded, size: 22),
              label: const Text(
                'TOP DÉPART — COMMENCER',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                  fontFamily: 'Poppins',
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                elevation: 4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _lancerExamen(
      BuildContext context, Map<String, dynamic> examen, Color color) {
    final user = ApiService.currentUser;
    final nomCandidat = user != null
        ? '${user['prenom'] ?? ''} ${user['nom'] ?? ''}'.trim()
        : 'Candidat';
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ExamenImmersifScreen(
          simulationId: (examen['id'] as int).toString(),
          nomExamen: '${examen['nom']} — Série ${examen['serie']}',
          icone: examen['icone'] as String,
          couleur: color,
          nomCandidat: nomCandidat.isNotEmpty ? nomCandidat : 'Candidat',
        ),
      ),
    );
  }

  void _showAbonnementRequired() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(children: [
          Text('👑', style: TextStyle(fontSize: 22)),
          SizedBox(width: 8),
          Text('Accès Premium',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
        ]),
        content: const Text(
          'Les Examens Types sont réservés aux abonnés Premium.\n\nAbonnez-vous pour accéder à toutes les 20 séries et pratiquer dans des conditions réelles.',
          style: TextStyle(fontSize: 13, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Plus tard'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            style:
                ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text("S'abonner",
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════
// 2. ÉCRAN D'EXAMEN IMMERSIF — Interface 2 colonnes style vraie feuille
// ══════════════════════════════════════════════════════════════════════
class ExamenImmersifScreen extends StatefulWidget {
  final String simulationId;
  final String nomExamen;
  final String icone;
  final Color couleur;
  final String nomCandidat;

  const ExamenImmersifScreen({
    super.key,
    required this.simulationId,
    required this.nomExamen,
    required this.icone,
    required this.couleur,
    required this.nomCandidat,
  });

  @override
  State<ExamenImmersifScreen> createState() => _ExamenImmersifScreenState();
}

class _ExamenImmersifScreenState extends State<ExamenImmersifScreen> {
  List<dynamic> _questions = [];
  bool _loading = true;
  String? _error;

  // Feuille de réponses — une seule lettre par question (examen officiel)
  final Map<int, String> _answers = {};

  static const int _durationSeconds = 90 * 60; // 1h30
  static const int _minBeforeSubmit = 30 * 60; // 30min

  int _remainingSeconds = _durationSeconds;
  Timer? _timer;
  bool _finished = false;
  bool _bellStartPlayed = false;
  bool _bell5MinPlayed = false;

  final ScrollController _questionsScroll = ScrollController();
  final ScrollController _reponsesScroll = ScrollController();

  bool get _isAdmin => ApiService.isAdmin;
  bool get _canSubmit =>
      _isAdmin ||
      _remainingSeconds <= (_durationSeconds - _minBeforeSubmit);

  int get _secondsBeforeCanSubmit =>
      (!_isAdmin && !_canSubmit)
          ? _remainingSeconds - (_durationSeconds - _minBeforeSubmit)
          : 0;

  String get _timerDisplay {
    final h = _remainingSeconds ~/ 3600;
    final m = (_remainingSeconds % 3600) ~/ 60;
    final s = _remainingSeconds % 60;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  Color get _timerColor {
    if (_remainingSeconds > 1800) return Colors.white;
    if (_remainingSeconds > 600) return const Color(0xFFFFD700);
    return const Color(0xFFFF6B6B);
  }

  @override
  void initState() {
    super.initState();
    _loadQuestions();
  }

  Future<void> _loadQuestions() async {
    setState(() { _loading = true; _error = null; });
    try {
      final result = await ApiService.demarrerSimulationAdmin(widget.simulationId);
      if (!mounted) return;
      if (result['error'] != null) {
        setState(() {
          _error = result['error']?.toString() ?? 'Erreur de chargement.';
          _loading = false;
        });
        return;
      }
      final questions = (result['questions'] as List?) ?? [];
      if (questions.isEmpty) {
        setState(() {
          _error = 'Aucune question disponible pour cet examen.';
          _loading = false;
        });
        return;
      }
      final dureeMin = (result['duree_minutes'] ?? 90) as int;
      setState(() {
        _questions = questions;
        _remainingSeconds = dureeMin * 60;
        _loading = false;
      });
      _startTimerWithBell();
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Erreur de connexion. Vérifiez votre internet.';
          _loading = false;
        });
      }
    }
  }

  void _startTimerWithBell() {
    if (!_bellStartPlayed) {
      _bellStartPlayed = true;
      Future.delayed(const Duration(milliseconds: 600), () async {
        await BellService.playStart();
      });
    }
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) { t.cancel(); return; }
      setState(() => _remainingSeconds--);

      // Rappel 5 minutes
      if (_remainingSeconds == 5 * 60 && !_bell5MinPlayed) {
        _bell5MinPlayed = true;
        BellService.playStart();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Text('🔔', style: TextStyle(fontSize: 18)),
                  SizedBox(width: 8),
                  Text(
                    'Plus que 5 minutes !',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                  ),
                ],
              ),
              backgroundColor: Colors.orange[800],
              duration: const Duration(seconds: 4),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          );
        }
      }

      // Fin automatique
      if (_remainingSeconds <= 0) {
        t.cancel();
        _terminerExamen(autoSubmit: true);
      }
    });
  }

  void _toggleAnswer(int qIndex, String letter) {
    if (_finished) return;
    setState(() {
      if (_answers[qIndex] == letter) {
        _answers.remove(qIndex);
      } else {
        _answers[qIndex] = letter;
        BellService.playClick();
      }
    });
    // Synchroniser la position verticale des listes
    _syncScroll(qIndex);
  }

  void _syncScroll(int qIndex) {
    // Défiler la feuille de réponses pour suivre la question active
    final itemHeight = 38.0;
    final offset = qIndex * itemHeight;
    if (_reponsesScroll.hasClients) {
      _reponsesScroll.animateTo(
        offset,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _terminerExamen({bool autoSubmit = false}) async {
    if (_finished) return;
    _timer?.cancel();

    if (!autoSubmit) {
      final nonRep = _questions.length - _answers.length;
      if (nonRep > 0) {
        final confirm = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
            title: const Text('Soumettre l\'examen ?',
                style: TextStyle(fontWeight: FontWeight.w800)),
            content: Text(
              '$nonRep question(s) sans réponse.\nVoulez-vous quand même soumettre ?',
              style: const TextStyle(fontSize: 13, height: 1.4),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Continuer'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary),
                child: const Text('Soumettre',
                    style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        );
        if (confirm != true) {
          _startTimerWithBell();
          return;
        }
      }
    }

    setState(() => _finished = true);
    await BellService.playEnd();
    if (!mounted) return;

    final tempsUtilise = _durationSeconds - _remainingSeconds;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => ExamenImmersifResultatsScreen(
          questions: _questions,
          answers: _answers,
          nomExamen: widget.nomExamen,
          icone: widget.icone,
          couleur: widget.couleur,
          nomCandidat: widget.nomCandidat,
          tempsUtilise: tempsUtilise,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _questionsScroll.dispose();
    _reponsesScroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        backgroundColor: const Color(0xFFF5F5F0),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: widget.couleur),
              const SizedBox(height: 20),
              Text(
                'Chargement de l\'examen...\n${widget.nomExamen}',
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 14, color: AppColors.textLight),
              ),
            ],
          ),
        ),
      );
    }

    if (_error != null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF5F5F0),
        appBar: AppBar(
          backgroundColor: widget.couleur,
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
                Text(_error!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontSize: 14, color: AppColors.textDark)),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _loadQuestions,
                  style: ElevatedButton.styleFrom(
                      backgroundColor: widget.couleur),
                  child: const Text('Réessayer',
                      style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_questions.isEmpty) {
      return Scaffold(
        backgroundColor: const Color(0xFFF5F5F0),
        appBar: AppBar(
          backgroundColor: widget.couleur,
          foregroundColor: Colors.white,
          title: Text(widget.nomExamen),
        ),
        body: const Center(
          child: Text('Aucune question disponible.',
              style: TextStyle(fontSize: 15, color: AppColors.textLight)),
        ),
      );
    }

    final isWide = MediaQuery.of(context).size.width >= 700;
    final answeredCount = _answers.length;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Quitter l\'examen ?'),
              content: const Text(
                  'Votre progression sera perdue. Êtes-vous sûr ?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Continuer'),
                ),
                TextButton(
                  onPressed: () {
                    _timer?.cancel();
                    Navigator.pop(ctx);
                    Navigator.pop(context);
                  },
                  child: const Text('Quitter',
                      style: TextStyle(color: Colors.red)),
                ),
              ],
            ),
          );
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F5F0),
        body: Column(
          children: [
            _buildExamBar(context, answeredCount),
            Expanded(
              child: isWide
                  ? _buildDeuxColonnes()
                  : _buildMobileView(),
            ),
            _buildSubmitBar(answeredCount),
          ],
        ),
      ),
    );
  }

  // ── Barre supérieure avec timer ───────────────────────────────
  Widget _buildExamBar(BuildContext context, int answeredCount) {
    return Container(
      decoration: BoxDecoration(
        color: widget.couleur,
        boxShadow: [
          BoxShadow(
            color: widget.couleur.withValues(alpha: 0.4),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 8,
        bottom: 10,
        left: 12,
        right: 12,
      ),
      child: Row(
        children: [
          // Bouton quitter
          GestureDetector(
            onTap: () => Navigator.maybePop(context),
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.close_rounded,
                  color: Colors.white, size: 20),
            ),
          ),
          const SizedBox(width: 10),

          // Nom de l'examen
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.nomExamen,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    fontFamily: 'Poppins',
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '$answeredCount/${_questions.length} réponses',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.white.withValues(alpha: 0.75),
                  ),
                ),
              ],
            ),
          ),

          // Timer
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(
              color: _remainingSeconds <= 600
                  ? Colors.red.withValues(alpha: 0.3)
                  : Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: _timerColor.withValues(alpha: 0.6), width: 1.5),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.timer_rounded, size: 14, color: _timerColor),
                const SizedBox(width: 5),
                Text(
                  _timerDisplay,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: _timerColor,
                    fontFamily: 'monospace',
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Interface 2 colonnes (desktop / tablette ≥ 700px) ───────
  Widget _buildDeuxColonnes() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // COLONNE GAUCHE — Feuille de questions (58%)
        Expanded(
          flex: 58,
          child: Container(
            color: const Color(0xFFFFFDF8),
            child: _buildFeuilleQuestions(),
          ),
        ),

        // Séparateur vertical
        Container(
          width: 1,
          color: const Color(0xFFDDD8D0),
        ),

        // COLONNE DROITE — Feuille de réponses (42%)
        Expanded(
          flex: 42,
          child: Container(
            color: const Color(0xFFF8F6F2),
            child: _buildFeuilleReponses(),
          ),
        ),
      ],
    );
  }

  // ── Vue mobile (onglets questions / réponses) ───────────────
  Widget _buildMobileView() {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          Container(
            color: Colors.white,
            child: TabBar(
              labelColor: widget.couleur,
              unselectedLabelColor: AppColors.textLight,
              indicatorColor: widget.couleur,
              indicatorWeight: 3,
              tabs: [
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.menu_book_rounded, size: 16,
                          color: widget.couleur),
                      const SizedBox(width: 6),
                      const Text('QUESTIONS',
                          style: TextStyle(
                              fontSize: 12, fontWeight: FontWeight.w800)),
                    ],
                  ),
                ),
                const Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.edit_rounded, size: 16),
                      SizedBox(width: 6),
                      Text('RÉPONSES',
                          style: TextStyle(
                              fontSize: 12, fontWeight: FontWeight.w800)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildFeuilleQuestions(),
                _buildFeuilleReponses(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── FEUILLE DE QUESTIONS ─────────────────────────────────────
  Widget _buildFeuilleQuestions() {
    return Column(
      children: [
        // En-tête "Feuille de questions" — style examen officiel
        Container(
          width: double.infinity,
          padding:
              const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            border: const Border(
                bottom: BorderSide(color: Color(0xFFE0DDD5), width: 1)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  border: Border.all(
                      color: widget.couleur.withValues(alpha: 0.5),
                      width: 1.5),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Feuille de questions',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: widget.couleur,
                    fontFamily: 'Georgia',
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                '${_questions.length} questions',
                style: const TextStyle(
                    fontSize: 11, color: AppColors.textLight),
              ),
            ],
          ),
        ),

        // Liste des questions
        Expanded(
          child: ListView.builder(
            controller: _questionsScroll,
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 80),
            itemCount: _questions.length,
            itemBuilder: (ctx, i) =>
                _buildQuestionItem(i, _questions[i] as Map<String, dynamic>),
          ),
        ),
      ],
    );
  }

  Widget _buildQuestionItem(int i, Map<String, dynamic> q) {
    final texte = (q['enonce'] ?? q['question'] ?? '').toString();
    final optA = (q['option_a'] ?? '').toString();
    final optB = (q['option_b'] ?? '').toString();
    final optC = (q['option_c'] ?? '').toString();
    final optD = (q['option_d'] ?? '').toString();
    final optE = (q['option_e'] ?? '').toString();
    final options = <MapEntry<String, String>>[
      if (optA.isNotEmpty) MapEntry('A', optA),
      if (optB.isNotEmpty) MapEntry('B', optB),
      if (optC.isNotEmpty) MapEntry('C', optC),
      if (optD.isNotEmpty) MapEntry('D', optD),
      if (optE.isNotEmpty) MapEntry('E', optE),
    ];
    final answered = _answers.containsKey(i);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: answered
            ? widget.couleur.withValues(alpha: 0.04)
            : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: answered
              ? widget.couleur.withValues(alpha: 0.3)
              : const Color(0xFFE0DDD5),
          width: answered ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Numéro + énoncé
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    color: answered
                        ? widget.couleur
                        : Colors.grey[200],
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '${i + 1}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        color: answered ? Colors.white : Colors.grey[600],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: MathTextWidget(
                    text: texte,
                    textStyle: const TextStyle(
                      fontSize: 13,
                      fontFamily: 'Georgia',
                      height: 1.55,
                      color: AppColors.textDark,
                      fontWeight: FontWeight.w600,
                    ),
                    mathSize: 13,
                    mathColor: AppColors.textDark,
                  ),
                ),
              ],
            ),

            // Options A/B/C/D
            if (options.isNotEmpty) ...[
              const SizedBox(height: 8),
              const Divider(height: 1, thickness: 0.5, color: Color(0xFFEEEAE0)),
              const SizedBox(height: 6),
              ...options.map((opt) => Padding(
                    padding: const EdgeInsets.only(bottom: 5),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            color: widget.couleur.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(5),
                            border: Border.all(
                              color:
                                  widget.couleur.withValues(alpha: 0.3),
                              width: 1,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              opt.key,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                color: widget.couleur,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 7),
                        Expanded(
                          child: MathTextWidget(
                            text: opt.value,
                            textStyle: const TextStyle(
                              fontSize: 12,
                              fontFamily: 'Georgia',
                              height: 1.4,
                              color: AppColors.textDark,
                            ),
                            mathSize: 12,
                            mathColor: AppColors.textDark,
                          ),
                        ),
                      ],
                    ),
                  )),
            ],
          ],
        ),
      ),
    );
  }

  // ── FEUILLE DE RÉPONSES ──────────────────────────────────────
  Widget _buildFeuilleReponses() {
    return Column(
      children: [
        // En-tête "Feuille de réponse"
        Container(
          width: double.infinity,
          padding:
              const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            border: const Border(
                bottom: BorderSide(color: Color(0xFFE0DDD5), width: 1)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  border: Border.all(
                      color: const Color(0xFF1565C0).withValues(alpha: 0.5),
                      width: 1.5),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'Feuille de réponse',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1565C0),
                    fontFamily: 'Georgia',
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                '${_answers.length}/${_questions.length}',
                style: TextStyle(
                  fontSize: 11,
                  color: _answers.length == _questions.length
                      ? Colors.green[700]
                      : AppColors.textLight,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),

        // Bandeau instruction
        Container(
          width: double.infinity,
          padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          color: const Color(0xFFE8F4FD),
          child: const Text(
            'Noircissez attentivement la case correspondant à votre réponse.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 10,
              color: Color(0xFF1565C0),
              fontStyle: FontStyle.italic,
              fontFamily: 'Georgia',
            ),
          ),
        ),

        // Tableau de réponses
        Expanded(
          child: SingleChildScrollView(
            controller: _reponsesScroll,
            padding: const EdgeInsets.fromLTRB(8, 6, 8, 80),
            child: Column(
              children: [
                // En-tête du tableau
                Container(
                  padding:
                      const EdgeInsets.symmetric(vertical: 7, horizontal: 4),
                  decoration: BoxDecoration(
                    color: widget.couleur,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const SizedBox(
                        width: 38,
                        child: Text('N°',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 11,
                            )),
                      ),
                      ...['A', 'B', 'C', 'D', 'E'].map(
                        (l) => Expanded(
                          child: Text(l,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                fontSize: 13,
                              )),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 3),

                // Lignes du tableau
                ...List.generate(_questions.length, (i) {
                  final q = _questions[i] as Map<String, dynamic>;
                  // Détecter les options disponibles pour cette question
                  final hasE =
                      (q['option_e'] ?? '').toString().isNotEmpty;
                  final selectedLetter = _answers[i];
                  final isEven = i % 2 == 0;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 2),
                    decoration: BoxDecoration(
                      color: isEven ? Colors.white : const Color(0xFFF7F5F0),
                      borderRadius: BorderRadius.circular(6),
                      border: selectedLetter != null
                          ? Border.all(
                              color: widget.couleur.withValues(alpha: 0.3),
                              width: 1)
                          : null,
                    ),
                    child: Row(
                      children: [
                        // Numéro
                        SizedBox(
                          width: 38,
                          height: 36,
                          child: Center(
                            child: Text(
                              '${i + 1}',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: selectedLetter != null
                                    ? widget.couleur
                                    : Colors.grey[500],
                              ),
                            ),
                          ),
                        ),

                        // Cases A B C D (E si dispo)
                        ...['A', 'B', 'C', 'D', 'E'].map((letter) {
                          // Masquer E si l'option n'existe pas
                          if (letter == 'E' && !hasE) {
                            return const Expanded(child: SizedBox.shrink());
                          }
                          final isSelected = selectedLetter == letter;
                          return Expanded(
                            child: GestureDetector(
                              onTap: () => _toggleAnswer(i, letter),
                              child: Container(
                                height: 34,
                                margin: const EdgeInsets.symmetric(
                                    horizontal: 2, vertical: 1),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isSelected
                                      ? widget.couleur
                                      : Colors.white,
                                  border: Border.all(
                                    color: isSelected
                                        ? widget.couleur
                                        : Colors.grey
                                            .withValues(alpha: 0.35),
                                    width: isSelected ? 2 : 1.2,
                                  ),
                                  boxShadow: isSelected
                                      ? [
                                          BoxShadow(
                                            color: widget.couleur
                                                .withValues(alpha: 0.35),
                                            blurRadius: 5,
                                            offset: const Offset(0, 2),
                                          ),
                                        ]
                                      : null,
                                ),
                                child: Center(
                                  child: Text(
                                    letter,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      color: isSelected
                                          ? Colors.white
                                          : Colors.grey.shade400,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ── Barre de soumission ───────────────────────────────────────
  Widget _buildSubmitBar(int answeredCount) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: _canSubmit
          ? Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_isAdmin)
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 6),
                    padding: const EdgeInsets.symmetric(
                        vertical: 4, horizontal: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF3E0),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: const Color(0xFFFF6F00)
                              .withValues(alpha: 0.4)),
                    ),
                    child: const Text(
                      '⚙️  MODE ADMIN — Soumission débloquée',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 11,
                          color: Color(0xFFE65100),
                          fontWeight: FontWeight.w700),
                    ),
                  ),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () => _terminerExamen(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: widget.couleur,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      elevation: 3,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.check_circle_rounded, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'REMETTRE MA COPIE ($answeredCount/${_questions.length})',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            )
          : Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '🔒  Soumission dans '
                    '${_secondsBeforeCanSubmit ~/ 60}min '
                    '${_secondsBeforeCanSubmit % 60}s',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textLight,
                        fontWeight: FontWeight.w700),
                  ),
                  const Text(
                    'Vous ne pouvez pas soumettre avant 30 minutes',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 10, color: AppColors.textLight),
                  ),
                ],
              ),
            ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════
// 3. PAGE DE RÉSULTATS — Score, correction détaillée, PDF
// ══════════════════════════════════════════════════════════════════════
class ExamenImmersifResultatsScreen extends StatefulWidget {
  final List<dynamic> questions;
  final Map<int, String> answers;
  final String nomExamen;
  final String icone;
  final Color couleur;
  final String nomCandidat;
  final int tempsUtilise;

  const ExamenImmersifResultatsScreen({
    super.key,
    required this.questions,
    required this.answers,
    required this.nomExamen,
    required this.icone,
    required this.couleur,
    required this.nomCandidat,
    required this.tempsUtilise,
  });

  @override
  State<ExamenImmersifResultatsScreen> createState() =>
      _ExamenImmersifResultatsScreenState();
}

class _ExamenImmersifResultatsScreenState
    extends State<ExamenImmersifResultatsScreen>
    with TickerProviderStateMixin {
  late AnimationController _applaudsController;
  late AnimationController _scoreController;
  late Animation<double> _scoreFade;
  late Animation<double> _scoreScale;
  bool _showApplauds = false;
  bool _correctionVisible = false;

  @override
  void initState() {
    super.initState();
    _applaudsController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _scoreController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..forward();
    _scoreFade = Tween<double>(begin: 0, end: 1)
        .animate(CurvedAnimation(parent: _scoreController, curve: Curves.easeIn));
    _scoreScale = Tween<double>(begin: 0.6, end: 1)
        .animate(CurvedAnimation(parent: _scoreController, curve: Curves.elasticOut));

    Future.delayed(const Duration(milliseconds: 600), () {
      BellService.playEnd();
      if (mounted) {
        setState(() => _showApplauds = true);
        _applaudsController.forward();
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) setState(() => _showApplauds = false);
        });
      }
    });
  }

  @override
  void dispose() {
    _applaudsController.dispose();
    _scoreController.dispose();
    super.dispose();
  }

  int get _correct {
    int c = 0;
    for (int i = 0; i < widget.questions.length; i++) {
      final q = widget.questions[i] as Map<String, dynamic>;
      final br = (q['bonne_reponse'] as String?)?.toUpperCase() ?? '';
      if ((widget.answers[i] ?? '') == br) c++;
    }
    return c;
  }

  int get _score => _correct;
  int get _total => widget.questions.length;
  double get _pct => _total > 0 ? (_correct / _total * 100) : 0;

  String get _mention {
    if (_pct >= 80) return 'Excellent ! 🏆';
    if (_pct >= 60) return 'Bien 👍';
    if (_pct >= 50) return 'Passable';
    if (_pct >= 40) return 'Insuffisant';
    return 'À améliorer';
  }

  Color get _mentionColor {
    if (_pct >= 80) return const Color(0xFF27AE60);
    if (_pct >= 60) return const Color(0xFF2980B9);
    if (_pct >= 50) return const Color(0xFFE67E22);
    return const Color(0xFFC0392B);
  }

  String get _tempsFormate {
    final h = widget.tempsUtilise ~/ 3600;
    final m = (widget.tempsUtilise % 3600) ~/ 60;
    final s = widget.tempsUtilise % 60;
    if (h > 0) return '${h}h ${m}min ${s}s';
    return '${m}min ${s}s';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F0),
      body: Stack(
        children: [
          Column(
            children: [
              _buildResultHeader(context),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 30),
                  child: Column(
                    children: [
                      _buildScoreCard(),
                      const SizedBox(height: 16),
                      _buildStatsRow(),
                      const SizedBox(height: 16),
                      _buildPdfButtons(context),
                      const SizedBox(height: 16),
                      _buildCorrectionToggle(),
                      if (_correctionVisible) ...[
                        const SizedBox(height: 12),
                        _buildCorrectionDetaille(),
                      ],
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () =>
                              Navigator.of(context).popUntil((r) => r.isFirst),
                          icon: const Icon(Icons.home_rounded),
                          label: const Text('Retour à l\'accueil',
                              style: TextStyle(
                                  fontSize: 14, fontWeight: FontWeight.w700)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Applaudissements overlay
          if (_showApplauds)
            Positioned.fill(
              child: IgnorePointer(
                child: FadeTransition(
                  opacity: Tween<double>(begin: 1, end: 0).animate(
                      CurvedAnimation(
                          parent: _applaudsController, curve: Curves.easeOut)),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('🎉', style: TextStyle(fontSize: 80)),
                        const SizedBox(height: 12),
                        Text(
                          _pct >= 50 ? 'Bravo !' : 'Continuez vos efforts !',
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            shadows: [
                              Shadow(
                                  color: Colors.black45,
                                  blurRadius: 8,
                                  offset: Offset(0, 2))
                            ],
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildResultHeader(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [widget.couleur, widget.couleur.withValues(alpha: 0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 12,
        bottom: 16,
        left: 16,
        right: 16,
      ),
      child: Row(
        children: [
          Text(widget.icone, style: const TextStyle(fontSize: 28)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Résultats de l\'examen',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    fontFamily: 'Poppins',
                  ),
                ),
                Text(
                  widget.nomExamen,
                  style: TextStyle(
                      fontSize: 11,
                      color: Colors.white.withValues(alpha: 0.8)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreCard() {
    return FadeTransition(
      opacity: _scoreFade,
      child: ScaleTransition(
        scale: _scoreScale,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [_mentionColor, _mentionColor.withValues(alpha: 0.7)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: _mentionColor.withValues(alpha: 0.4),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            children: [
              Text(
                widget.nomCandidat,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withValues(alpha: 0.85),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 12),
              // Cercle score style examen officiel
              Container(
                width: 130,
                height: 130,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  border: Border.all(
                      color: Colors.white.withValues(alpha: 0.6), width: 3),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 12,
                        offset: const Offset(0, 4)),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '$_score',
                      style: TextStyle(
                        fontSize: 46,
                        fontWeight: FontWeight.w900,
                        color: _mentionColor,
                        height: 1,
                        fontFamily: 'Poppins',
                      ),
                    ),
                    Text(
                      '/ $_total',
                      style: TextStyle(
                        fontSize: 18,
                        color: _mentionColor.withValues(alpha: 0.7),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Text(
                '${_pct.round()}%  —  $_mention',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  fontFamily: 'Poppins',
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Note sur 20 : ${(_pct / 100 * 20).toStringAsFixed(1)} / 20',
                style: TextStyle(
                    fontSize: 13,
                    color: Colors.white.withValues(alpha: 0.85)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsRow() {
    return Row(
      children: [
        _buildStatCard('Correctes', '$_correct', Icons.check_circle_outline,
            const Color(0xFF27AE60)),
        const SizedBox(width: 10),
        _buildStatCard('Incorrectes', '${_total - _correct - _unanswered}',
            Icons.cancel_outlined, const Color(0xFFC0392B)),
        const SizedBox(width: 10),
        _buildStatCard(
            'Sans rep.', '$_unanswered', Icons.remove_circle_outline, Colors.grey),
        const SizedBox(width: 10),
        _buildStatCard('Temps', _tempsFormate, Icons.timer_outlined, widget.couleur),
      ],
    );
  }

  int get _unanswered =>
      widget.questions.length - widget.answers.length;

  Widget _buildStatCard(
      String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.25), width: 1),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 4,
                offset: const Offset(0, 1)),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w900,
                color: color,
                fontFamily: 'Poppins',
              ),
            ),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 9, color: AppColors.textLight, height: 1.2),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPdfButtons(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.2), width: 1),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 6,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.picture_as_pdf_rounded,
                  color: AppColors.primary, size: 18),
              SizedBox(width: 8),
              Text(
                'Télécharger en PDF',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                  color: AppColors.primary,
                  fontFamily: 'Poppins',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildPdfButton(
                  context,
                  label: 'Sujet seul',
                  icon: Icons.article_outlined,
                  color: const Color(0xFF2980B9),
                  onTap: () => _generatePdfSujet(context),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildPdfButton(
                  context,
                  label: 'Correction',
                  icon: Icons.grading_rounded,
                  color: const Color(0xFF27AE60),
                  onTap: () => _generatePdfCorrection(context),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPdfButton(
    BuildContext context, {
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.3), width: 1.2),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 26),
            const SizedBox(height: 5),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: color,
                fontFamily: 'Poppins',
              ),
            ),
            Text(
              label == 'Sujet seul'
                  ? 'Questions uniquement'
                  : 'Questions + réponses + explications',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 9,
                color: color.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCorrectionToggle() {
    return GestureDetector(
      onTap: () =>
          setState(() => _correctionVisible = !_correctionVisible),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: widget.couleur.withValues(alpha: 0.3), width: 1),
        ),
        child: Row(
          children: [
            Icon(Icons.library_books_rounded,
                color: widget.couleur, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'CORRECTION DÉTAILLÉE',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                  color: widget.couleur,
                  letterSpacing: 0.5,
                  fontFamily: 'Poppins',
                ),
              ),
            ),
            Icon(
              _correctionVisible
                  ? Icons.keyboard_arrow_up_rounded
                  : Icons.keyboard_arrow_down_rounded,
              color: widget.couleur,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCorrectionDetaille() {
    return Column(
      children: List.generate(widget.questions.length, (i) {
        final q = widget.questions[i] as Map<String, dynamic>;
        final texte = (q['enonce'] ?? q['question'] ?? '').toString();
        final br = (q['bonne_reponse'] as String?)?.toUpperCase() ?? '';
        final rep = widget.answers[i] ?? '—';
        final isOk = rep == br;
        final explication = (q['explication'] ?? '').toString();

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isOk
                ? const Color(0xFFF0FFF4)
                : const Color(0xFFFFF5F5),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isOk
                  ? const Color(0xFF27AE60).withValues(alpha: 0.35)
                  : const Color(0xFFC0392B).withValues(alpha: 0.35),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Ligne statut
              Row(
                children: [
                  Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: isOk
                          ? const Color(0xFF27AE60)
                          : const Color(0xFFC0392B),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Icon(
                        isOk ? Icons.check : Icons.close,
                        size: 13,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Q${i + 1}',
                    style: const TextStyle(
                        fontWeight: FontWeight.w900, fontSize: 13),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: Colors.grey.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      'Votre : $rep  |  Correct : $br',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: isOk
                            ? const Color(0xFF27AE60)
                            : const Color(0xFFC0392B),
                      ),
                    ),
                  ),
                ],
              ),

              if (texte.isNotEmpty) ...[
                const SizedBox(height: 7),
                MathTextWidget(
                  text: texte,
                  textStyle: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textDark,
                      height: 1.4,
                      fontFamily: 'Georgia'),
                  mathSize: 12,
                  mathColor: AppColors.textDark,
                ),
              ],

              if (explication.isNotEmpty) ...[
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: MathTextWidget(
                    text: '💡 $explication',
                    textStyle: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF1565C0),
                        height: 1.35,
                        fontStyle: FontStyle.italic,
                        fontFamily: 'Georgia'),
                    mathSize: 11,
                    mathColor: const Color(0xFF1565C0),
                  ),
                ),
              ],
            ],
          ),
        );
      }),
    );
  }

  // ── Génération PDF — Sujet seul ──────────────────────────────
  Future<void> _generatePdfSujet(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    if (!kIsWeb) {
      messenger.showSnackBar(
        const SnackBar(content: Text('PDF disponible uniquement sur le web')),
      );
      return;
    }
    try {
      final pdf = pw.Document();
      final font = await PdfGoogleFonts.notoSansRegular();
      final fontBold = await PdfGoogleFonts.notoSansBold();

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(28),
          header: (ctx) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'EF-FORT.BF — ${widget.nomExamen}',
                style: pw.TextStyle(
                  font: fontBold,
                  fontSize: 14,
                  color: PdfColors.teal800,
                ),
              ),
              pw.Text(
                'Candidat : ${widget.nomCandidat}  |  Date : ${DateTime.now().toString().substring(0, 10)}',
                style: pw.TextStyle(font: font, fontSize: 10, color: PdfColors.grey700),
              ),
              pw.Divider(thickness: 1, color: PdfColors.teal800),
              pw.SizedBox(height: 6),
            ],
          ),
          build: (ctx) => [
            pw.Center(
              child: pw.Text(
                'FEUILLE DE QUESTIONS',
                style: pw.TextStyle(
                  font: fontBold,
                  fontSize: 16,
                  color: PdfColors.teal900,
                ),
              ),
            ),
            pw.SizedBox(height: 14),
            ...widget.questions.asMap().entries.map((e) {
              final i = e.key;
              final q = e.value as Map<String, dynamic>;
              final texte = (q['enonce'] ?? q['question'] ?? '').toString();
              return pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 14),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      '${i + 1}. $texte',
                      style: pw.TextStyle(font: fontBold, fontSize: 11),
                    ),
                    ...['A', 'B', 'C', 'D', 'E'].map((l) {
                      final opt = (q['option_${l.toLowerCase()}'] ?? '').toString();
                      if (opt.isEmpty) return pw.SizedBox();
                      return pw.Padding(
                        padding: const pw.EdgeInsets.only(left: 16, top: 3),
                        child: pw.Text('$l. $opt',
                            style: pw.TextStyle(font: font, fontSize: 10)),
                      );
                    }),
                  ],
                ),
              );
            }),
          ],
        ),
      );

      await Printing.layoutPdf(
        onLayout: (fmt) async => pdf.save(),
        name:
            'EF-FORT_Sujet_${widget.nomExamen.replaceAll(' ', '_')}.pdf',
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Erreur PDF : $e')),
      );
    }
  }

  // ── Génération PDF — Correction détaillée ───────────────────
  Future<void> _generatePdfCorrection(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    if (!kIsWeb) {
      messenger.showSnackBar(
        const SnackBar(content: Text('PDF disponible uniquement sur le web')),
      );
      return;
    }
    try {
      final pdf = pw.Document();
      final font = await PdfGoogleFonts.notoSansRegular();
      final fontBold = await PdfGoogleFonts.notoSansBold();
      final fontItalic = await PdfGoogleFonts.notoSansItalic();

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(28),
          header: (ctx) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'EF-FORT.BF — Correction — ${widget.nomExamen}',
                style: pw.TextStyle(
                    font: fontBold, fontSize: 13, color: PdfColors.teal800),
              ),
              pw.Text(
                'Candidat : ${widget.nomCandidat}  |  Score : $_correct/$_total (${_pct.round()}%)  |  Temps : $_tempsFormate',
                style: pw.TextStyle(
                    font: font, fontSize: 10, color: PdfColors.grey700),
              ),
              pw.Divider(thickness: 1, color: PdfColors.teal800),
              pw.SizedBox(height: 4),
            ],
          ),
          build: (ctx) => [
            pw.Center(
              child: pw.Text(
                'CORRECTION DÉTAILLÉE',
                style: pw.TextStyle(
                    font: fontBold,
                    fontSize: 15,
                    color: PdfColors.teal900),
              ),
            ),
            pw.SizedBox(height: 14),
            ...widget.questions.asMap().entries.map((e) {
              final i = e.key;
              final q = e.value as Map<String, dynamic>;
              final texte = (q['enonce'] ?? q['question'] ?? '').toString();
              final br =
                  (q['bonne_reponse'] as String?)?.toUpperCase() ?? '?';
              final rep = widget.answers[i] ?? '—';
              final isOk = rep == br;
              final explication = (q['explication'] ?? '').toString();

              return pw.Container(
                margin: const pw.EdgeInsets.only(bottom: 12),
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  color: isOk
                      ? PdfColors.green50
                      : PdfColors.red50,
                  border: pw.Border.all(
                    color: isOk ? PdfColors.green700 : PdfColors.red700,
                    width: 0.8,
                  ),
                  borderRadius:
                      const pw.BorderRadius.all(pw.Radius.circular(5)),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Row(
                      children: [
                        pw.Text(
                          '${i + 1}. ',
                          style: pw.TextStyle(
                              font: fontBold, fontSize: 11),
                        ),
                        pw.Expanded(
                          child: pw.Text(
                            texte,
                            style: pw.TextStyle(font: fontBold, fontSize: 11),
                          ),
                        ),
                        pw.Text(
                          '  [${isOk ? "✓" : "✗"}] Votre: $rep  |  Correct: $br',
                          style: pw.TextStyle(
                            font: font,
                            fontSize: 10,
                            color: isOk
                                ? PdfColors.green700
                                : PdfColors.red700,
                          ),
                        ),
                      ],
                    ),
                    if (explication.isNotEmpty) ...[
                      pw.SizedBox(height: 5),
                      pw.Text(
                        '💡 $explication',
                        style: pw.TextStyle(
                          font: fontItalic,
                          fontSize: 9.5,
                          color: PdfColors.blue800,
                        ),
                      ),
                    ],
                  ],
                ),
              );
            }),
          ],
        ),
      );

      await Printing.layoutPdf(
        onLayout: (fmt) async => pdf.save(),
        name:
            'EF-FORT_Correction_${widget.nomExamen.replaceAll(' ', '_')}.pdf',
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Erreur PDF : $e')),
      );
    }
  }
}
