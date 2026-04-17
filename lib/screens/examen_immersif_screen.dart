import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../core/theme/app_colors.dart';
import '../services/api_service.dart';
import '../services/bell_service.dart';
import '../widgets/math_text_widget.dart';

// ══════════════════════════════════════════════════════════════════════
// EXAMENS TYPES IMMERSION v3.0 — Interface ultra-immersive
// Surveillant virtuel · Timer pulsant · Confettis · Sons enrichis
// Deux colonnes : Feuille de questions (gauche) + Feuille de réponses (droite)
// ══════════════════════════════════════════════════════════════════════

// ─── Mapping simulationId → (examenId, serie) ───────────────────────
// Les séries 66-75 = Série 1, 76-85 = Série 2, 107-116 = Série 3
// exam_001..010 → 10 examens types
const Map<int, Map<String, dynamic>> _kSimToExam = {
  66: {'exam_id': 'exam_001', 'serie': 1},
  67: {'exam_id': 'exam_002', 'serie': 1},
  68: {'exam_id': 'exam_003', 'serie': 1},
  69: {'exam_id': 'exam_004', 'serie': 1},
  70: {'exam_id': 'exam_005', 'serie': 1},
  71: {'exam_id': 'exam_006', 'serie': 1},
  72: {'exam_id': 'exam_007', 'serie': 1},
  73: {'exam_id': 'exam_008', 'serie': 1},
  74: {'exam_id': 'exam_009', 'serie': 1},
  75: {'exam_id': 'exam_010', 'serie': 1},
  76: {'exam_id': 'exam_001', 'serie': 2},
  77: {'exam_id': 'exam_002', 'serie': 2},
  78: {'exam_id': 'exam_003', 'serie': 2},
  79: {'exam_id': 'exam_004', 'serie': 2},
  80: {'exam_id': 'exam_005', 'serie': 2},
  81: {'exam_id': 'exam_006', 'serie': 2},
  82: {'exam_id': 'exam_007', 'serie': 2},
  83: {'exam_id': 'exam_008', 'serie': 2},
  84: {'exam_id': 'exam_009', 'serie': 2},
  85: {'exam_id': 'exam_010', 'serie': 2},
  // Série 3 — Examens Types (IDs 107–116)
  107: {'exam_id': 'exam_001', 'serie': 3},
  108: {'exam_id': 'exam_002', 'serie': 3},
  109: {'exam_id': 'exam_003', 'serie': 3},
  110: {'exam_id': 'exam_004', 'serie': 3},
  111: {'exam_id': 'exam_005', 'serie': 3},
  112: {'exam_id': 'exam_006', 'serie': 3},
  113: {'exam_id': 'exam_007', 'serie': 3},
  114: {'exam_id': 'exam_008', 'serie': 3},
  115: {'exam_id': 'exam_009', 'serie': 3},
  116: {'exam_id': 'exam_010', 'serie': 3},
  // Examens Blancs — 11e matière (IDs 97–106)
  97:  {'exam_id': 'exam_blanc_01', 'serie': 3},
  98:  {'exam_id': 'exam_blanc_02', 'serie': 3},
  99:  {'exam_id': 'exam_blanc_03', 'serie': 3},
  100: {'exam_id': 'exam_blanc_04', 'serie': 3},
  101: {'exam_id': 'exam_blanc_05', 'serie': 3},
  102: {'exam_id': 'exam_blanc_06', 'serie': 3},
  103: {'exam_id': 'exam_blanc_07', 'serie': 3},
  104: {'exam_id': 'exam_blanc_08', 'serie': 3},
  105: {'exam_id': 'exam_blanc_09', 'serie': 3},
  106: {'exam_id': 'exam_blanc_10', 'serie': 3},
};

// ─── Couleurs par catégorie d'examen ───────────────────────────────────
const Map<int, Color> _kExamColors = {
  66: Color(0xFF1A5276), // Administration Sér.1
  67: Color(0xFFC0392B), // Justice Sér.1
  68: Color(0xFF1E8449), // Économie Sér.1
  69: Color(0xFF8E44AD), // Santé Sér.1
  70: Color(0xFF1A5C38), // Éducation Sér.1
  71: Color(0xFFD4A017), // Techniques Sér.1
  72: Color(0xFF148A72), // Agriculture Sér.1
  73: Color(0xFF2471A3), // Informatique Sér.1
  74: Color(0xFF7D3C98), // Travaux publics Sér.1
  75: Color(0xFF4A5568), // Statistiques Sér.1
  76: Color(0xFF1A5276), // Sér.2
  77: Color(0xFFC0392B),
  78: Color(0xFF1E8449),
  79: Color(0xFF8E44AD),
  80: Color(0xFF1A5C38),
  81: Color(0xFFD4A017),
  82: Color(0xFF148A72),
  83: Color(0xFF2471A3),
  84: Color(0xFF7D3C98),
  85: Color(0xFF4A5568),
  // Série 3 — Examens Types (couleurs identiques)
  107: Color(0xFF1A5276), // Administration Sér.3
  108: Color(0xFFC0392B), // Justice Sér.3
  109: Color(0xFF1E8449), // Économie Sér.3
  110: Color(0xFF8E44AD), // Santé Sér.3
  111: Color(0xFF1A5C38), // Éducation Sér.3
  112: Color(0xFFD4A017), // Techniques Sér.3
  113: Color(0xFF148A72), // Agriculture Sér.3
  114: Color(0xFF2471A3), // Informatique Sér.3
  115: Color(0xFF7D3C98), // Travaux publics Sér.3
  116: Color(0xFF4A5568), // Statistiques Sér.3
  // Examens Blancs — couleur verte EF-FORT
  97:  Color(0xFF1A5C38),
  98:  Color(0xFF1A5C38),
  99:  Color(0xFF1A5C38),
  100: Color(0xFF1A5C38),
  101: Color(0xFF1A5C38),
  102: Color(0xFF1A5C38),
  103: Color(0xFF1A5C38),
  104: Color(0xFF1A5C38),
  105: Color(0xFF1A5C38),
  106: Color(0xFF1A5C38),
};

// ─── Messages du surveillant virtuel ────────────────────────────────
const List<String> _kGuidanceMessages = [
  '📖 Lisez attentivement chaque question avant de répondre.',
  '✏️ Noircissez bien la case de votre choix sur la feuille de réponse.',
  '⚖️ Une bonne réponse = +1 point. Mauvaise réponse = pénalité.',
  '🔕 Silence dans la salle. Toute fraude sera sanctionnée.',
  '⏱️ Gérez bien votre temps. 50 questions en 1h30.',
  '🧠 Faites confiance à votre première intuition.',
  '📋 Vérifiez que vous avez bien coché TOUTES vos réponses.',
  '🎯 Concentrez-vous. Vous êtes prêt(e) pour cet examen !',
];

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
    extends State<ExamenImmersifAccueilScreen>
    with TickerProviderStateMixin {

  static const List<Map<String, dynamic>> _kExamensTypes = [
    {'id': 66, 'nom': 'Administration générale', 'serie': 1, 'icone': '📋', 'description': 'Adjoints et agents administratifs'},
    {'id': 67, 'nom': 'Justice & sécurité', 'serie': 1, 'icone': '⚖️', 'description': 'Greffiers, police, gendarmerie, douane'},
    {'id': 68, 'nom': 'Économie & finances', 'serie': 1, 'icone': '💰', 'description': 'Impôts, trésor, contrôleurs des finances'},
    {'id': 69, 'nom': 'Concours de la santé', 'serie': 1, 'icone': '⚕️', 'description': 'Infirmiers, sages-femmes, agents de santé'},
    {'id': 70, 'nom': 'Éducation & formation', 'serie': 1, 'icone': '📚', 'description': 'Enseignants du primaire et secondaire'},
    {'id': 71, 'nom': 'Concours techniques', 'serie': 1, 'icone': '🔧', 'description': 'Génie civil, électricité, mécanique'},
    {'id': 72, 'nom': 'Agriculture & environnement', 'serie': 1, 'icone': '🌾', 'description': 'Agents agricoles, élevage, environnement'},
    {'id': 73, 'nom': 'Informatique & numérique', 'serie': 1, 'icone': '💻', 'description': 'Techniciens informatiques, développement'},
    {'id': 74, 'nom': 'Travaux publics & urbanisme', 'serie': 1, 'icone': '🏗️', 'description': 'BTP, urbanisme, infrastructures'},
    {'id': 75, 'nom': 'Statistiques & planification', 'serie': 1, 'icone': '📊', 'description': 'Statisticiens, analyse de données'},
    {'id': 76, 'nom': 'Administration générale', 'serie': 2, 'icone': '📋', 'description': 'Adjoints et agents administratifs'},
    {'id': 77, 'nom': 'Justice & sécurité', 'serie': 2, 'icone': '⚖️', 'description': 'Greffiers, police, gendarmerie, douane'},
    {'id': 78, 'nom': 'Économie & finances', 'serie': 2, 'icone': '💰', 'description': 'Impôts, trésor, contrôleurs des finances'},
    {'id': 79, 'nom': 'Concours de la santé', 'serie': 2, 'icone': '⚕️', 'description': 'Infirmiers, sages-femmes, agents de santé'},
    {'id': 80, 'nom': 'Éducation & formation', 'serie': 2, 'icone': '📚', 'description': 'Enseignants du primaire et secondaire'},
    {'id': 81, 'nom': 'Concours techniques', 'serie': 2, 'icone': '🔧', 'description': 'Génie civil, électricité, mécanique'},
    {'id': 82, 'nom': 'Agriculture & environnement', 'serie': 2, 'icone': '🌾', 'description': 'Agents agricoles, élevage, environnement'},
    {'id': 83, 'nom': 'Informatique & numérique', 'serie': 2, 'icone': '💻', 'description': 'Techniciens informatiques, développement'},
    {'id': 84, 'nom': 'Travaux publics & urbanisme', 'serie': 2, 'icone': '🏗️', 'description': 'BTP, urbanisme, infrastructures'},
    {'id': 85, 'nom': 'Statistiques & planification', 'serie': 2, 'icone': '📊', 'description': 'Statisticiens, analyse de données'},
    // Série 3 — Examens Types (IDs 107–116)
    {'id': 107, 'nom': 'Administration générale', 'serie': 3, 'icone': '📋', 'description': 'Adjoints et agents administratifs'},
    {'id': 108, 'nom': 'Justice & sécurité', 'serie': 3, 'icone': '⚖️', 'description': 'Greffiers, police, gendarmerie, douane'},
    {'id': 109, 'nom': 'Économie & finances', 'serie': 3, 'icone': '💰', 'description': 'Impôts, trésor, contrôleurs des finances'},
    {'id': 110, 'nom': 'Concours de la santé', 'serie': 3, 'icone': '⚕️', 'description': 'Infirmiers, sages-femmes, agents de santé'},
    {'id': 111, 'nom': 'Éducation & formation', 'serie': 3, 'icone': '📚', 'description': 'Enseignants du primaire et secondaire'},
    {'id': 112, 'nom': 'Concours techniques', 'serie': 3, 'icone': '🔧', 'description': 'Génie civil, électricité, mécanique'},
    {'id': 113, 'nom': 'Agriculture & environnement', 'serie': 3, 'icone': '🌾', 'description': 'Agents agricoles, élevage, environnement'},
    {'id': 114, 'nom': 'Informatique & numérique', 'serie': 3, 'icone': '💻', 'description': 'Techniciens informatiques, développement'},
    {'id': 115, 'nom': 'Travaux publics & urbanisme', 'serie': 3, 'icone': '🏗️', 'description': 'BTP, urbanisme, infrastructures'},
    {'id': 116, 'nom': 'Statistiques & planification', 'serie': 3, 'icone': '📊', 'description': 'Statisticiens, analyse de données'},
    // Examens Blancs — 11e matière (série 3)
    {'id': 97,  'nom': 'Examens Blancs', 'serie': 3, 'icone': '📝', 'description': 'Histoire-Géo & Culture Générale'},
    {'id': 98,  'nom': 'Examens Blancs', 'serie': 3, 'icone': '📝', 'description': 'Sciences & Culture Générale'},
    {'id': 99,  'nom': 'Examens Blancs', 'serie': 3, 'icone': '📝', 'description': 'Géopolitique & Organisations'},
    {'id': 100, 'nom': 'Examens Blancs', 'serie': 3, 'icone': '📝', 'description': 'Institutions & Littérature'},
    {'id': 101, 'nom': 'Examens Blancs', 'serie': 3, 'icone': '📝', 'description': 'Orthographe & Culture Diversifiée'},
    {'id': 102, 'nom': 'Examens Blancs', 'serie': 3, 'icone': '📝', 'description': 'Droit Foncier & Administration'},
    {'id': 103, 'nom': 'Examens Blancs', 'serie': 3, 'icone': '📝', 'description': 'Actualités & Langue Française'},
    {'id': 104, 'nom': 'Examens Blancs', 'serie': 3, 'icone': '📝', 'description': 'Économie, Géographie & Culture'},
    {'id': 105, 'nom': 'Examens Blancs', 'serie': 3, 'icone': '📝', 'description': 'Mathématiques, Logique & Sciences'},
    {'id': 106, 'nom': 'Examens Blancs', 'serie': 3, 'icone': '📝', 'description': 'Culture Générale & Langue Française'},
  ];

  int _selectedSerieTab = 0;
  Map<String, dynamic>? _selectedExamen;
  bool _consignesExpanded = true;

  late AnimationController _headerAnimCtrl;
  late Animation<double> _headerAnim;

  @override
  void initState() {
    super.initState();
    _headerAnimCtrl = AnimationController(
      duration: const Duration(milliseconds: 700),
      vsync: this,
    )..forward();
    _headerAnim = CurvedAnimation(parent: _headerAnimCtrl, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _headerAnimCtrl.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get _serie1 =>
      _kExamensTypes.where((e) => e['serie'] == 1).toList();
  List<Map<String, dynamic>> get _serie2 =>
      _kExamensTypes.where((e) => e['serie'] == 2).toList();
  // Série 3 — Examens Types (IDs 107–116)
  List<Map<String, dynamic>> get _serie3 =>
      _kExamensTypes.where((e) => e['serie'] == 3 && e['id']! >= 107).toList();
  // Examens Blancs — vrais examens officiels (IDs 97–106)
  List<Map<String, dynamic>> get _serieBlanche =>
      _kExamensTypes.where((e) => e['id']! >= 97 && e['id']! <= 106).toList();
  List<Map<String, dynamic>> get _currentList {
    if (_selectedSerieTab == 0) return _serie1;
    if (_selectedSerieTab == 1) return _serie2;
    if (_selectedSerieTab == 2) return _serie3;
    // Index 3 = Examens Blancs (vrais examens officiels)
    return _serieBlanche;
  }

  @override
  Widget build(BuildContext context) {
    // Guard abonnement — les examens immersifs sont réservés aux abonnés
    if (!ApiService.isAbonne && !ApiService.isAdmin) {
      return Scaffold(
        backgroundColor: const Color(0xFFF0F4F1),
        appBar: AppBar(
          title: const Text('Examens Types', style: TextStyle(fontWeight: FontWeight.w700)),
          automaticallyImplyLeading: true,
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(colors: [Color(0xFF1A5C38), Color(0xFF0E3D24)]),
            ),
          ),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 20),
                    ],
                  ),
                  child: Column(
                    children: [
                      const Text('🎓', style: TextStyle(fontSize: 52)),
                      const SizedBox(height: 16),
                      const Text(
                        'Examens Types — Premium',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFF1A5C38)),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Les examens types immersifs sont réservés aux abonnés Premium.\n\nPassez Premium pour vous entraîner dans les conditions réelles du concours.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 14, color: Colors.grey, height: 1.6),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F5E9),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFF4CAF50).withValues(alpha: 0.3)),
                        ),
                        child: const Text(
                          '✅ Plan gratuit : Accès à la 1ère série de chaque matière',
                          style: TextStyle(fontSize: 12, color: Color(0xFF2E7D32), fontWeight: FontWeight.w600),
                        ),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          icon: const Icon(Icons.arrow_back_rounded),
                          label: const Text("Retour", style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1A5C38),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
    final isWide = MediaQuery.of(context).size.width >= 700;
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F0),
      body: Column(
        children: [
          FadeTransition(
            opacity: _headerAnim,
            child: SlideTransition(
              position: Tween<Offset>(begin: const Offset(0, -0.3), end: Offset.zero)
                  .animate(_headerAnim),
              child: _buildHeader(context),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                  horizontal: isWide ? 32 : 16, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSurveillantCard(),
                  const SizedBox(height: 14),
                  _buildConsignesCard(),
                  const SizedBox(height: 16),
                  _buildSerieSelector(),
                  const SizedBox(height: 12),
                  _buildExamensGrid(isWide),
                  const SizedBox(height: 20),
                  if (_selectedExamen != null)
                    AnimatedSize(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOut,
                      child: _buildDemarrerButton(context),
                    ),
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
          colors: [Color(0xFF1A5C38), Color(0xFF0E3D24)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 16,
        bottom: 22,
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
                  '📋 Examens Types Officiels',
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    fontFamily: 'Poppins',
                  ),
                ),
                Text(
                  '40 séries · 50 questions · 1h30 · Conditions réelles',
                  style: TextStyle(fontSize: 11, color: Colors.white70),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFD4A017).withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFD4A017).withValues(alpha: 0.6)),
            ),
            child: const Text(
              'IMMERSIF',
              style: TextStyle(
                color: Color(0xFFD4A017),
                fontWeight: FontWeight.w900,
                fontSize: 10,
                letterSpacing: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Carte "Surveillant virtuel" ──────────────────────────────────
  Widget _buildSurveillantCard() {
    return _SurveillantBannerWidget();
  }

  Widget _buildConsignesCard() {
    return GestureDetector(
      onTap: () => setState(() => _consignesExpanded = !_consignesExpanded),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFF1A5C38).withValues(alpha: 0.3), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF1A5C38).withValues(alpha: 0.07),
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
                    width: 38, height: 38,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A5C38).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Center(child: Text('📜', style: TextStyle(fontSize: 20))),
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
                            color: Color(0xFF1A5C38),
                            letterSpacing: 0.5,
                            fontFamily: 'Poppins',
                          ),
                        ),
                        Text(
                          'Règles et conditions de l\'examen',
                          style: TextStyle(fontSize: 11, color: Colors.black54),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    _consignesExpanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: const Color(0xFF1A5C38),
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
                    _buildConsigneLigne('🔢', '50 questions réparties en plusieurs matières'),
                    _buildConsigneLigne('⏱️', 'Durée de l\'épreuve : 1h30 (90 minutes)'),
                    _buildConsigneLigne('🔒', 'Soumission impossible avant 30 minutes'),
                    _buildConsigneLigne('✏️', 'Noircissez les cases sur la feuille de réponses'),
                    _buildConsigneLigne('❌', 'Réponse incorrecte = pénalité de points'),
                    _buildConsigneLigne('🔔', 'Une cloche marque le démarrage et la fin'),
                    _buildConsigneLigne('⚠️', 'Toute fraude entraîne l\'annulation de l\'épreuve'),
                    _buildConsigneLigne('📱', 'Téléphones portables interdits pendant l\'épreuve'),
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
                color: Color(0xFF2C3E50),
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
          _buildSerieTab(2, 'Série 3', '10 examens'),
          _buildSerieTab(3, 'Examens Blancs', '10 examens'),
        ],
      ),
    );
  }

  Widget _buildSerieTab(int index, String titre, String sousTitre) {
    final isSelected = _selectedSerieTab == index;
    // L'onglet "Examens Blancs" (index=3) a un style distinctif bleu nuit
    final isBlancsTab = index == 3;
    final selectedColor = isBlancsTab
        ? const Color(0xFF1A3A5C)   // Bleu nuit pour Examens Blancs
        : const Color(0xFF1A5C38); // Vert pour Types

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() {
          _selectedSerieTab = index;
          _selectedExamen = null;
        }),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? selectedColor : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            children: [
              if (isBlancsTab && isSelected)
                const Icon(Icons.star_rounded, size: 11, color: Colors.white70),
              if (isBlancsTab && !isSelected)
                const Icon(Icons.star_rounded, size: 11, color: Colors.black38),
              Text(
                titre,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 11,
                  color: isSelected ? Colors.white : Colors.black54,
                  fontFamily: 'Poppins',
                ),
              ),
              Text(
                sousTitre,
                style: TextStyle(
                  fontSize: 8,
                  color: isSelected ? Colors.white70 : Colors.black38,
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
        childAspectRatio: 0.82,
      ),
      itemCount: _currentList.length,
      itemBuilder: (ctx, i) => _buildExamenCard(_currentList[i], i),
    );
  }

  // ── Icônes Material vectorielles pour les Examens Blancs (par index) ──────
  static const List<IconData> _kBlancsIcons = [
    Icons.menu_book_rounded,         // Blanc 1 — livre ouvert
    Icons.science_rounded,            // Blanc 2 — sciences
    Icons.public_rounded,             // Blanc 3 — géopolitique
    Icons.account_balance_rounded,    // Blanc 4 — institutions
    Icons.spellcheck_rounded,         // Blanc 5 — orthographe
    Icons.gavel_rounded,              // Blanc 6 — droit
    Icons.newspaper_rounded,          // Blanc 7 — actualités
    Icons.bar_chart_rounded,          // Blanc 8 — économie
    Icons.calculate_rounded,          // Blanc 9 — maths
    Icons.emoji_objects_rounded,      // Blanc 10 — culture générale
  ];

  Widget _buildExamenCard(Map<String, dynamic> examen, int index) {
    final id = examen['id'] as int;
    final serieNum = examen['serie'] as int;
    final isExamenBlanc = serieNum == 3 && id >= 97 && id <= 106;

    // ── Design distinct pour Examens Blancs ──────────────────────────
    if (isExamenBlanc) {
      return _buildExamenBlancCard(examen, index);
    }

    // ── Design standard pour Examens Types ───────────────────────────
    final color = _kExamColors[id] ?? const Color(0xFF1A5C38);
    final rawNom = examen['nom'] as String;
    final nom = rawNom;
    final serieBadge = 'Sér. $serieNum';
    final icone = examen['icone'] as String;
    final desc = examen['description'] as String;
    final isSelected = _selectedExamen?['id'] == id;

    return GestureDetector(
      onTap: () {
        if (!ApiService.isAbonne && !ApiService.isAdmin) {
          _showAbonnementRequired();
          return;
        }
        HapticFeedback.lightImpact();
        setState(() => _selectedExamen = isSelected ? null : examen);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? color : color.withValues(alpha: 0.25),
            width: isSelected ? 2.5 : 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: isSelected ? 0.35 : 0.1),
              blurRadius: isSelected ? 18 : 6,
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
                width: 52, height: 52,
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
                child: Center(child: Text(icone, style: const TextStyle(fontSize: 22))),
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
                  color: isSelected ? Colors.white70 : Colors.black45,
                ),
              ),
              const Spacer(),
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.white.withValues(alpha: 0.2)
                      : color.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected
                        ? Colors.white.withValues(alpha: 0.5)
                        : color.withValues(alpha: 0.25),
                  ),
                ),
                child: Text(
                  isSelected ? '✓ Sélectionné' : serieBadge,
                  style: TextStyle(
                    fontSize: 10,
                    color: isSelected ? Colors.white : color,
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

  // ── Carte EXAMEN BLANC — Design noir & blanc distinctif ─────────────
  Widget _buildExamenBlancCard(Map<String, dynamic> examen, int index) {
    final id = examen['id'] as int;
    final desc = examen['description'] as String;
    final isSelected = _selectedExamen?['id'] == id;
    final iconData = _kBlancsIcons[index % _kBlancsIcons.length];

    // Palette noir et blanc
    const darkColor = Color(0xFF1C1C1E);
    const lightGrey = Color(0xFFF2F2F7);
    const accentGrey = Color(0xFF6E6E73);

    return GestureDetector(
      onTap: () {
        if (!ApiService.isAbonne && !ApiService.isAdmin) {
          _showAbonnementRequired();
          return;
        }
        HapticFeedback.lightImpact();
        setState(() => _selectedExamen = isSelected ? null : examen);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          color: isSelected ? darkColor : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? darkColor : const Color(0xFF2C2C2E).withValues(alpha: 0.3),
            width: isSelected ? 2.5 : 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: darkColor.withValues(alpha: isSelected ? 0.35 : 0.1),
              blurRadius: isSelected ? 18 : 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 12, 10, 10),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              // ── Icône vectorielle Material (distinction visuelle) ──
              Container(
                width: 52, height: 52,
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.white.withValues(alpha: 0.12)
                      : lightGrey,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected
                        ? Colors.white.withValues(alpha: 0.3)
                        : darkColor.withValues(alpha: 0.2),
                    width: 1.5,
                  ),
                ),
                child: Center(
                  child: Icon(
                    iconData,
                    size: 24,
                    color: isSelected ? Colors.white : darkColor,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              // ── Titre "Série N" ────────────────────────────────────
              Text(
                'Série ${index + 1}',
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  color: isSelected ? Colors.white : darkColor,
                  height: 1.2,
                  fontFamily: 'Poppins',
                ),
              ),
              const SizedBox(height: 3),
              Text(
                desc,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 8.5,
                  color: isSelected ? Colors.white70 : accentGrey,
                  height: 1.3,
                ),
              ),
              const Spacer(),
              // ── Badge "Blanc" distinctif ────────────────────────────
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.white.withValues(alpha: 0.15)
                      : darkColor.withValues(alpha: 0.07),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected
                        ? Colors.white.withValues(alpha: 0.4)
                        : darkColor.withValues(alpha: 0.25),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.star_rounded,
                      size: 9,
                      color: isSelected ? Colors.white : darkColor,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      isSelected ? '✓ Sélectionné' : 'Blanc',
                      style: TextStyle(
                        fontSize: 9,
                        color: isSelected ? Colors.white : darkColor,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
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
    final color = _kExamColors[id] ?? const Color(0xFF1A5C38);
    final serieNum = examen['serie'] as int;
    // Nom affiché proprement dans le bouton démarrer
    final indexInList = _currentList.indexWhere((e) => e['id'] == id);
    final displayNom = (serieNum == 3 && id >= 97 && id <= 106)
        ? 'Examen Blanc ${indexInList + 1}'
        : '${examen['nom']} — Série $serieNum';

    final isBlancExamen = serieNum == 3 && id >= 97 && id <= 106;
    final btnColor = isBlancExamen ? const Color(0xFF1C1C1E) : color;
    // Icône dans le bouton: vectorielle pour blancs, emoji pour types
    final iconeWidget = isBlancExamen
        ? Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFF1C1C1E).withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _kBlancsIcons[(indexInList) % _kBlancsIcons.length],
              size: 20,
              color: const Color(0xFF1C1C1E),
            ),
          )
        : Text(examen['icone'] as String, style: const TextStyle(fontSize: 30));

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: btnColor.withValues(alpha: 0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: btnColor.withValues(alpha: 0.15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              iconeWidget,
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayNom,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: btnColor,
                        fontFamily: 'Poppins',
                      ),
                    ),
                    const Text(
                      '50 questions · 1h30 · Simulation officielle',
                      style: TextStyle(fontSize: 11, color: Colors.black45),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton.icon(
              onPressed: () => _lancerExamen(context, examen, btnColor),
              icon: const Icon(Icons.play_circle_fill_rounded, size: 24),
              label: const Text(
                '🔔 TOP DÉPART — COMMENCER',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                  fontFamily: 'Poppins',
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: btnColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _lancerExamen(BuildContext context, Map<String, dynamic> examen, Color color) {
    final user = ApiService.currentUser;
    final nomCandidat = user != null
        ? '${user['prenom'] ?? ''} ${user['nom'] ?? ''}'.trim()
        : 'Candidat';
    final id = examen['id'] as int;
    final serieNum = examen['serie'] as int;
    final indexInList = _currentList.indexWhere((e) => e['id'] == id);
    // Nom propre pour l'examen lancé
    final nomExamen = (serieNum == 3 && id >= 97 && id <= 106)
        ? 'Examen Blanc ${indexInList + 1}'
        : '${examen['nom']} — Série $serieNum';
    HapticFeedback.mediumImpact();
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, anim, __) => ExamenImmersifScreen(
          simulationId: (examen['id'] as int).toString(),
          nomExamen: nomExamen,
          icone: examen['icone'] as String,
          couleur: color,
          nomCandidat: nomCandidat.isNotEmpty ? nomCandidat : 'Candidat',
        ),
        transitionsBuilder: (_, anim, __, child) => FadeTransition(
          opacity: anim,
          child: child,
        ),
        transitionDuration: const Duration(milliseconds: 400),
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
          Text('Accès Premium', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
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
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1A5C38)),
            child: const Text("S'abonner", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════
// Widget : Banière surveillant virtuel animée
// ══════════════════════════════════════════════════════════════════════
class _SurveillantBannerWidget extends StatefulWidget {
  @override
  State<_SurveillantBannerWidget> createState() => _SurveillantBannerWidgetState();
}

class _SurveillantBannerWidgetState extends State<_SurveillantBannerWidget>
    with TickerProviderStateMixin {
  int _msgIndex = 0;
  Timer? _timer;
  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(duration: const Duration(milliseconds: 600), vsync: this)
      ..forward();
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeIn);

    _pulseCtrl = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.95, end: 1.05)
        .animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));

    _timer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!mounted) return;
      _fadeCtrl.reverse().then((_) {
        if (!mounted) return;
        setState(() => _msgIndex = (_msgIndex + 1) % _kGuidanceMessages.length);
        _fadeCtrl.forward();
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _fadeCtrl.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A5C38), Color(0xFF2E7D52)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1A5C38).withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          ScaleTransition(
            scale: _pulseAnim,
            child: Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withValues(alpha: 0.4), width: 1.5),
              ),
              child: const Center(child: Text('👨‍🏫', style: TextStyle(fontSize: 22))),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Surveillant',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 3),
                FadeTransition(
                  opacity: _fadeAnim,
                  child: Text(
                    _kGuidanceMessages[_msgIndex],
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12.5,
                      fontFamily: 'Georgia',
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════
// 2. ÉCRAN D'EXAMEN IMMERSIF — Interface 2 colonnes + timer pulsant
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

class _ExamenImmersifScreenState extends State<ExamenImmersifScreen>
    with TickerProviderStateMixin {
  List<dynamic> _questions = [];
  bool _loading = true;
  String? _error;

  // Réponses multiples : Set<String> pour chaque question (supporte A+B, A+C, etc.)
  final Map<int, Set<String>> _answers = {};
  // Dernier index coché (pour animation)
  int? _lastAnswered;

  static const int _durationSeconds = 90 * 60;
  static const int _minBeforeSubmit = 30 * 60;

  int _remainingSeconds = _durationSeconds;
  Timer? _timer;
  bool _finished = false;
  bool _bellStartPlayed = false;
  bool _bell5MinPlayed = false;

  final ScrollController _questionsScroll = ScrollController();
  final ScrollController _reponsesScroll = ScrollController();

  // Animation timer pulsation
  late AnimationController _timerPulseCtrl;
  late Animation<double> _timerPulseAnim;

  // Animation surveillance (message pendant exam)
  int _guidanceMsgIdx = 0;
  Timer? _guidanceTimer;
  late AnimationController _guidanceFadeCtrl;
  late Animation<double> _guidanceFadeAnim;

  bool get _isAdmin => ApiService.isAdmin;
  bool get _canSubmit =>
      _isAdmin || _remainingSeconds <= (_durationSeconds - _minBeforeSubmit);

  int get _secondsBeforeCanSubmit =>
      (!_isAdmin && !_canSubmit)
          ? _remainingSeconds - (_durationSeconds - _minBeforeSubmit)
          : 0;

  // Nombre de questions avec au moins une réponse cochée
  int get _answeredCount => _answers.length;

  String get _timerDisplay {
    final h = _remainingSeconds ~/ 3600;
    final m = (_remainingSeconds % 3600) ~/ 60;
    final s = _remainingSeconds % 60;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  Color get _timerColor {
    if (_remainingSeconds > 30 * 60) return Colors.white;
    if (_remainingSeconds > 10 * 60) return const Color(0xFFFFD700);
    return const Color(0xFFFF6B6B);
  }

  bool get _timerShouldPulse => _remainingSeconds <= 5 * 60;

  @override
  void initState() {
    super.initState();

    _timerPulseCtrl = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _timerPulseAnim = Tween<double>(begin: 1.0, end: 1.15)
        .animate(CurvedAnimation(parent: _timerPulseCtrl, curve: Curves.easeInOut));

    _guidanceFadeCtrl = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    )..forward();
    _guidanceFadeAnim = CurvedAnimation(parent: _guidanceFadeCtrl, curve: Curves.easeIn);

    _loadQuestions();
    _startGuidanceRotation();
  }

  void _startGuidanceRotation() {
    _guidanceTimer = Timer.periodic(const Duration(seconds: 8), (_) {
      if (!mounted) return;
      _guidanceFadeCtrl.reverse().then((_) {
        if (!mounted) return;
        setState(() {
          _guidanceMsgIdx = (_guidanceMsgIdx + 1) % _kGuidanceMessages.length;
        });
        _guidanceFadeCtrl.forward();
      });
    });
  }

  // ── Chargement des questions via la route correcte ───────────────
  Future<void> _loadQuestions() async {
    setState(() { _loading = true; _error = null; });
    try {
      final simIdInt = int.tryParse(widget.simulationId);
      if (simIdInt == null) {
        setState(() { _error = 'ID de simulation invalide.'; _loading = false; });
        return;
      }

      final mapping = _kSimToExam[simIdInt];
      if (mapping == null) {
        setState(() { _error = 'Examen introuvable (ID $simIdInt).'; _loading = false; });
        return;
      }

      final examenId = mapping['exam_id'] as String;
      final serie = mapping['serie'] as int;

      // Utiliser la route /api/examens/:id/questions?serie=X
      final questions = await ApiService.getExamenQuestions(examenId, serie: serie);

      if (!mounted) return;

      if (questions.isEmpty) {
        setState(() {
          _error = 'Aucune question disponible pour cet examen.\n(ID sim: $simIdInt → $examenId série $serie)';
          _loading = false;
        });
        return;
      }

      setState(() {
        _questions = questions;
        _remainingSeconds = _durationSeconds;
        _loading = false;
      });
      _startTimerWithBell();
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Erreur de connexion. Vérifiez votre internet.\n$e';
          _loading = false;
        });
      }
    }
  }

  void _startTimerWithBell() {
    if (!_bellStartPlayed) {
      _bellStartPlayed = true;
      Future.delayed(const Duration(milliseconds: 600), () async {
        await BellService.playExamStart();
      });
    }
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) { t.cancel(); return; }
      setState(() => _remainingSeconds--);

      // Pulsation quand < 5 min
      if (_timerShouldPulse) {
        if (!_timerPulseCtrl.isAnimating) {
          _timerPulseCtrl.repeat(reverse: true);
        }
      }

      // Rappel 5 minutes
      if (_remainingSeconds == 5 * 60 && !_bell5MinPlayed) {
        _bell5MinPlayed = true;
        BellService.playReminder();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Text('🔔', style: TextStyle(fontSize: 20)),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Attention ! Plus que 5 minutes !',
                      style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                    ),
                  ),
                ],
              ),
              backgroundColor: const Color(0xFFE65100),
              duration: const Duration(seconds: 5),
              behavior: SnackBarBehavior.floating,
              margin: const EdgeInsets.all(16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
        }
      }

      if (_remainingSeconds <= 0) {
        t.cancel();
        _terminerExamen(autoSubmit: true);
      }
    });
  }

  void _toggleAnswer(int qIndex, String letter) {
    if (_finished) return;
    HapticFeedback.lightImpact();
    setState(() {
      final current = _answers[qIndex] ?? <String>{};
      if (current.contains(letter)) {
        current.remove(letter);
        if (current.isEmpty) {
          _answers.remove(qIndex);
          _lastAnswered = null;
        } else {
          _answers[qIndex] = current;
          _lastAnswered = qIndex;
        }
      } else {
        current.add(letter);
        _answers[qIndex] = current;
        _lastAnswered = qIndex;
        BellService.playMark(); // Clic mécanique — noircissement case OMR
      }
    });
    _syncScroll(qIndex);
  }

  void _syncScroll(int qIndex) {
    const itemHeight = 38.0;
    final offset = qIndex * itemHeight;
    if (_reponsesScroll.hasClients) {
      _reponsesScroll.animateTo(
        offset.clamp(0.0, _reponsesScroll.position.maxScrollExtent),
        duration: const Duration(milliseconds: 250),
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
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                style: ElevatedButton.styleFrom(backgroundColor: widget.couleur),
                child: const Text('Soumettre', style: TextStyle(color: Colors.white)),
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
    HapticFeedback.heavyImpact();
    await BellService.playEnd();
    if (!mounted) return;

    final tempsUtilise = _durationSeconds - _remainingSeconds;
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (_, anim, __) => ExamenImmersifResultatsScreen(
          questions: _questions,
          answers: _answers,
          nomExamen: widget.nomExamen,
          icone: widget.icone,
          couleur: widget.couleur,
          nomCandidat: widget.nomCandidat,
          tempsUtilise: tempsUtilise,
        ),
        transitionsBuilder: (_, anim, __, child) => FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _guidanceTimer?.cancel();
    _timerPulseCtrl.dispose();
    _guidanceFadeCtrl.dispose();
    _questionsScroll.dispose();
    _reponsesScroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return _buildLoadingScreen();
    if (_error != null) return _buildErrorScreen();
    if (_questions.isEmpty) return _buildEmptyScreen();

    final isWide = MediaQuery.of(context).size.width >= 700;
    final answeredCount = _answeredCount;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _confirmQuit();
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F5F0),
        body: Column(
          children: [
            _buildExamBar(context, answeredCount),
            _buildSurveillantBar(),
            Expanded(
              child: isWide ? _buildDeuxColonnes() : _buildMobileView(),
            ),
            _buildSubmitBar(answeredCount),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingScreen() {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F0),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: widget.couleur, strokeWidth: 3),
            const SizedBox(height: 24),
            Text(
              '🎓 Chargement de l\'examen...',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: widget.couleur),
            ),
            const SizedBox(height: 8),
            Text(
              widget.nomExamen,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: Colors.black54),
            ),
            const SizedBox(height: 16),
            const Text(
              'Veuillez patienter quelques instants...',
              style: TextStyle(fontSize: 11, color: Colors.black38),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorScreen() {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F0),
      appBar: AppBar(
        backgroundColor: widget.couleur,
        foregroundColor: Colors.white,
        title: Text(widget.nomExamen, style: const TextStyle(fontSize: 14)),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.wifi_off_rounded, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              const Text('Erreur de chargement', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Text(_error!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 12, color: Colors.black54)),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _loadQuestions,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Réessayer'),
                style: ElevatedButton.styleFrom(backgroundColor: widget.couleur, foregroundColor: Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyScreen() {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F0),
      appBar: AppBar(
        backgroundColor: widget.couleur,
        foregroundColor: Colors.white,
        title: Text(widget.nomExamen),
      ),
      body: const Center(
        child: Text('Aucune question disponible.', style: TextStyle(fontSize: 15, color: Colors.black54)),
      ),
    );
  }

  // ── Barre supérieure avec timer pulsant ───────────────────────
  Widget _buildExamBar(BuildContext context, int answeredCount) {
    return Container(
      decoration: BoxDecoration(
        color: widget.couleur,
        boxShadow: [
          BoxShadow(
            color: widget.couleur.withValues(alpha: 0.45),
            blurRadius: 10,
            offset: const Offset(0, 3),
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
          GestureDetector(
            onTap: _confirmQuit,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.close_rounded, color: Colors.white, size: 20),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.nomExamen,
                  style: const TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w700,
                    color: Colors.white, fontFamily: 'Poppins',
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Row(
                  children: [
                    Text(
                      '$answeredCount/${_questions.length} réponses',
                      style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.8)),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: _questions.isNotEmpty ? answeredCount / _questions.length : 0,
                          backgroundColor: Colors.white.withValues(alpha: 0.2),
                          color: Colors.white,
                          minHeight: 4,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          // Timer avec pulsation
          _buildTimer(),
        ],
      ),
    );
  }

  Widget _buildTimer() {
    final timerWidget = Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: _remainingSeconds <= 10 * 60
            ? Colors.red.withValues(alpha: 0.35)
            : Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _timerColor.withValues(alpha: 0.7), width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.timer_rounded, size: 18, color: _timerColor),
          const SizedBox(width: 5),
          Text(
            _timerDisplay,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: _timerColor,
              fontFamily: 'monospace',
              letterSpacing: 1.5,
            ),
          ),
        ],
      ),
    );

    if (_timerShouldPulse) {
      return ScaleTransition(scale: _timerPulseAnim, child: timerWidget);
    }
    return timerWidget;
  }

  // ── Banière surveillant pendant l'examen ──────────────────────
  Widget _buildSurveillantBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      child: Row(
        children: [
          const Text('👨‍🏫', style: TextStyle(fontSize: 16)),
          const SizedBox(width: 8),
          Expanded(
            child: FadeTransition(
              opacity: _guidanceFadeAnim,
              child: Text(
                _kGuidanceMessages[_guidanceMsgIdx],
                style: TextStyle(
                  fontSize: 11,
                  color: widget.couleur.withValues(alpha: 0.85),
                  fontStyle: FontStyle.italic,
                  fontFamily: 'Georgia',
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: widget.couleur.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              '${_answers.length}/50',
              style: TextStyle(
                fontSize: 10,
                color: widget.couleur,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Interface 2 colonnes (≥ 700px) ──────────────────────────
  Widget _buildDeuxColonnes() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 58,
          child: Container(
            color: const Color(0xFFFFFDF8),
            child: _buildFeuilleQuestions(),
          ),
        ),
        Container(width: 1.5, color: const Color(0xFFDDD8D0)),
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

  // ── Vue mobile (onglets) ─────────────────────────────────────
  Widget _buildMobileView() {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          Container(
            color: Colors.white,
            child: TabBar(
              labelColor: widget.couleur,
              unselectedLabelColor: Colors.black38,
              indicatorColor: widget.couleur,
              indicatorWeight: 3,
              tabs: [
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.menu_book_rounded, size: 16, color: widget.couleur),
                      const SizedBox(width: 6),
                      const Text('QUESTIONS', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.edit_rounded, size: 16, color: widget.couleur),
                      const SizedBox(width: 6),
                      const Text('RÉPONSES', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
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

  // ── FEUILLE DE QUESTIONS ──────────────────────────────────────
  Widget _buildFeuilleQuestions() {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            border: const Border(bottom: BorderSide(color: Color(0xFFE0DDD5), width: 1)),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 4, offset: const Offset(0, 2)),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  border: Border.all(color: widget.couleur.withValues(alpha: 0.5), width: 1.5),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Feuille de questions',
                  style: TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w700,
                    color: widget.couleur, fontFamily: 'Georgia',
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                '${_questions.length} questions',
                style: const TextStyle(fontSize: 11, color: Colors.black45),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            controller: _questionsScroll,
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 80),
            itemCount: _questions.length,
            itemBuilder: (ctx, i) => _buildQuestionItem(i, _questions[i] as Map<String, dynamic>),
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
    final matiere = (q['matiere'] ?? q['matiere_nom'] ?? '').toString();

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: answered ? widget.couleur.withValues(alpha: 0.04) : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: answered ? widget.couleur.withValues(alpha: 0.35) : const Color(0xFFE0DDD5),
          width: answered ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: answered
                ? widget.couleur.withValues(alpha: 0.08)
                : Colors.black.withValues(alpha: 0.03),
            blurRadius: answered ? 6 : 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 42, height: 42,
                  decoration: BoxDecoration(
                    color: answered ? widget.couleur : Colors.grey[200],
                    shape: BoxShape.circle,
                    boxShadow: answered ? [
                      BoxShadow(color: widget.couleur.withValues(alpha: 0.35), blurRadius: 6, offset: const Offset(0, 2)),
                    ] : null,
                  ),
                  child: Center(
                    child: Text(
                      '${i + 1}',
                      style: TextStyle(
                        fontSize: 19, fontWeight: FontWeight.w900,
                        color: answered ? Colors.white : Colors.grey[600],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (matiere.isNotEmpty) ...[
                        Text(
                          matiere.toUpperCase(),
                          style: TextStyle(
                            fontSize: 11, fontWeight: FontWeight.w700,
                            color: widget.couleur.withValues(alpha: 0.6),
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 3),
                      ],
                      MathTextWidget(
                        text: texte,
                        textStyle: const TextStyle(
                          fontSize: 18, fontFamily: 'Georgia', height: 1.7,
                          color: Color(0xFF2C3E50), fontWeight: FontWeight.w600,
                        ),
                        mathSize: 18,
                        mathColor: const Color(0xFF2C3E50),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (options.isNotEmpty) ...[
              const SizedBox(height: 8),
              const Divider(height: 1, thickness: 0.5, color: Color(0xFFEEEAE0)),
              const SizedBox(height: 6),
              ...options.map((opt) => Padding(
                padding: const EdgeInsets.only(bottom: 7),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 38, height: 38,
                      decoration: BoxDecoration(
                        color: widget.couleur.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: widget.couleur.withValues(alpha: 0.3), width: 1),
                      ),
                      child: Center(
                        child: Text(
                          opt.key,
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: widget.couleur),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: MathTextWidget(
                        text: opt.value,
                        textStyle: const TextStyle(
                          fontSize: 16, fontFamily: 'Georgia', height: 1.65,
                          color: Color(0xFF2C3E50),
                        ),
                        mathSize: 16,
                        mathColor: const Color(0xFF2C3E50),
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

  // ── FEUILLE DE RÉPONSES ─────────────────────────────────────
  Widget _buildFeuilleReponses() {
    return Column(
      children: [
        // En-tête
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            border: const Border(bottom: BorderSide(color: Color(0xFFE0DDD5), width: 1)),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 4, offset: const Offset(0, 2)),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFF1565C0).withValues(alpha: 0.5), width: 1.5),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'Feuille de réponse',
                  style: TextStyle(
                    fontSize: 17, fontWeight: FontWeight.w700,
                    color: Color(0xFF1565C0), fontFamily: 'Georgia',
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
              const Spacer(),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: Text(
                  '${_answers.length}/${_questions.length}',
                  key: ValueKey(_answers.length),
                  style: TextStyle(
                    fontSize: 17,
                    color: _answers.length == _questions.length
                        ? Colors.green[700]
                        : Colors.black45,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Instruction
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          color: const Color(0xFFE8F4FD),
          child: const Text(
            'Cochez toutes les cases correspondant à votre réponse (une ou plusieurs).',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 17, color: Color(0xFF1565C0),
              fontStyle: FontStyle.italic, fontFamily: 'Georgia',
            ),
          ),
        ),

        // Tableau
        Expanded(
          child: SingleChildScrollView(
            controller: _reponsesScroll,
            padding: const EdgeInsets.fromLTRB(8, 6, 8, 80),
            child: Column(
              children: [
                // En-tête du tableau
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 4),
                  decoration: BoxDecoration(
                    color: widget.couleur,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const SizedBox(
                        width: 52,
                        child: Text('N°', textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 15)),
                      ),
                      ...['A', 'B', 'C', 'D', 'E'].map((l) => Expanded(
                        child: Text(l, textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 15)),
                      )),
                    ],
                  ),
                ),
                const SizedBox(height: 3),

                // Lignes du tableau
                ...List.generate(_questions.length, (i) {
                  final q = _questions[i] as Map<String, dynamic>;
                  final hasE = (q['option_e'] ?? '').toString().isNotEmpty;
                  final selectedLetters = _answers[i] ?? <String>{};
                  final isEven = i % 2 == 0;
                  final isLastAnswered = _lastAnswered == i;

                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.only(bottom: 2),
                    decoration: BoxDecoration(
                      color: isLastAnswered
                          ? widget.couleur.withValues(alpha: 0.06)
                          : (isEven ? Colors.white : const Color(0xFFF7F5F0)),
                      borderRadius: BorderRadius.circular(6),
                      border: selectedLetters.isNotEmpty
                          ? Border.all(color: widget.couleur.withValues(alpha: 0.3), width: 1)
                          : null,
                    ),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 52, height: 56,
                          child: Center(
                            child: Text(
                              '${i + 1}',
                              style: TextStyle(
                                fontSize: 15, fontWeight: FontWeight.w700,
                                color: selectedLetters.isNotEmpty ? widget.couleur : Colors.grey[400],
                              ),
                            ),
                          ),
                        ),
                        ...['A', 'B', 'C', 'D', 'E'].map((letter) {
                          if (letter == 'E' && !hasE) {
                            return const Expanded(child: SizedBox.shrink());
                          }
                          final isSelected = selectedLetters.contains(letter);
                          return Expanded(
                            child: GestureDetector(
                              onTap: () => _toggleAnswer(i, letter),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                height: 54,
                                margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isSelected ? widget.couleur : Colors.white,
                                  border: Border.all(
                                    color: isSelected ? widget.couleur : Colors.grey.withValues(alpha: 0.3),
                                    width: isSelected ? 2 : 1.2,
                                  ),
                                  boxShadow: isSelected ? [
                                    BoxShadow(
                                      color: widget.couleur.withValues(alpha: 0.4),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    ),
                                  ] : null,
                                ),
                                child: Center(
                                  child: Text(
                                    letter,
                                    style: TextStyle(
                                      fontSize: 15, fontWeight: FontWeight.w800,
                                      color: isSelected ? Colors.white : Colors.grey.shade400,
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

  // ── Barre de soumission ──────────────────────────────────────
  Widget _buildSubmitBar(int answeredCount) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 14,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: _canSubmit
            ? Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_isAdmin)
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 6),
                      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF3E0),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFFF6F00).withValues(alpha: 0.4)),
                      ),
                      child: const Text(
                        '⚙️  MODE ADMIN — Soumission débloquée',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 11, color: Color(0xFFE65100), fontWeight: FontWeight.w700),
                      ),
                    ),
                  SizedBox(
                    width: double.infinity,
                    height: 60,
                    child: ElevatedButton(
                      onPressed: () => _terminerExamen(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: widget.couleur,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 3,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.check_circle_rounded, size: 24),
                          const SizedBox(width: 8),
                          Text(
                            'REMETTRE MA COPIE ($answeredCount/${_questions.length})',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, fontFamily: 'Poppins'),
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
                      '🔒  Soumission dans ${_secondsBeforeCanSubmit ~/ 60}min ${_secondsBeforeCanSubmit % 60}s',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 15, color: Colors.black45, fontWeight: FontWeight.w700),
                    ),
                    const Text(
                      'Vous ne pouvez pas soumettre avant 30 minutes',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13, color: Colors.black38),
                    ),
                  ],
                ),
              ),
        ),
      ),
    );
  }

  void _confirmQuit() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Quitter l\'examen ?'),
        content: const Text('Votre progression sera perdue. Êtes-vous sûr ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Continuer l\'examen'),
          ),
          TextButton(
            onPressed: () {
              _timer?.cancel();
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            child: const Text('Quitter', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════
// 3. PAGE DE RÉSULTATS — Score, correction détaillée, confettis, PDF
// ══════════════════════════════════════════════════════════════════════
class ExamenImmersifResultatsScreen extends StatefulWidget {
  final List<dynamic> questions;
  final Map<int, Set<String>> answers;
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
  late AnimationController _scoreController;
  late Animation<double> _scoreFade;
  late Animation<double> _scoreScale;
  late AnimationController _confettiController;
  bool _correctionVisible = false;
  final List<_Confetti> _confettis = [];
  Timer? _confettiTimer;

  @override
  void initState() {
    super.initState();

    _scoreController = AnimationController(
      duration: const Duration(milliseconds: 900),
      vsync: this,
    )..forward();
    _scoreFade = Tween<double>(begin: 0, end: 1)
        .animate(CurvedAnimation(parent: _scoreController, curve: Curves.easeIn));
    _scoreScale = Tween<double>(begin: 0.5, end: 1)
        .animate(CurvedAnimation(parent: _scoreController, curve: Curves.elasticOut));

    _confettiController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    );

    // Générer confettis si bon score
    if (_pct >= 50) {
      _generateConfettis();
    }

    Future.delayed(const Duration(milliseconds: 500), () {
      // Son selon le score : applaudissements si bon score, fin d'examen sinon
      if (_pct >= 50) {
        BellService.playApplause();
      } else {
        BellService.playEnd();
      }
      if (mounted && _pct >= 50) {
        _confettiController.forward();
        _confettiTimer = Timer(const Duration(seconds: 4), () {
          if (mounted) _confettiController.stop();
        });
      }
    });
  }

  void _generateConfettis() {
    final rng = math.Random();
    _confettis.addAll(List.generate(40, (i) => _Confetti(
      x: rng.nextDouble(),
      y: -rng.nextDouble() * 0.5,
      vx: (rng.nextDouble() - 0.5) * 0.01,
      vy: 0.003 + rng.nextDouble() * 0.005,
      color: [
        const Color(0xFFFFD700), const Color(0xFF1A5C38),
        const Color(0xFFFF6B6B), const Color(0xFF4ECDC4),
        const Color(0xFF45B7D1), Colors.white,
      ][rng.nextInt(6)],
      size: 6 + rng.nextDouble() * 8,
      rotation: rng.nextDouble() * math.pi * 2,
    )));
  }

  @override
  void dispose() {
    _scoreController.dispose();
    _confettiController.dispose();
    _confettiTimer?.cancel();
    super.dispose();
  }

  int get _correct {
    int c = 0;
    for (int i = 0; i < widget.questions.length; i++) {
      final q = widget.questions[i] as Map<String, dynamic>;
      final bonneRep = (q['bonne_reponse'] as String?)?.toUpperCase().trim() ?? '';
      final userReps = widget.answers[i] ?? <String>{};
      // Support multi-réponses : si la bonne réponse contient '/' c'est multi
      final bonnesReps = bonneRep
          .split(RegExp(r'[/,;]'))
          .map((s) => s.trim().toUpperCase())
          .where((s) => s.isNotEmpty)
          .toSet();
      if (bonnesReps.isNotEmpty && userReps.isNotEmpty &&
          userReps.containsAll(bonnesReps) && bonnesReps.containsAll(userReps)) {
        c++;
      }
    }
    return c;
  }

  int get _score => _correct;
  int get _total => widget.questions.length;
  double get _pct => _total > 0 ? (_correct / _total * 100) : 0;

  String get _mention {
    if (_pct >= 80) return 'Excellent ! 🏆';
    if (_pct >= 60) return 'Très Bien 👍';
    if (_pct >= 50) return 'Passable ✔️';
    if (_pct >= 40) return 'Insuffisant';
    return 'À améliorer 📚';
  }

  Color get _mentionColor {
    if (_pct >= 80) return const Color(0xFF1E8449);
    if (_pct >= 60) return const Color(0xFF2471A3);
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
                          onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst),
                          icon: const Icon(Icons.home_rounded),
                          label: const Text('Retour à l\'accueil',
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Confettis animés
          if (_pct >= 50)
            AnimatedBuilder(
              animation: _confettiController,
              builder: (_, __) {
                return IgnorePointer(
                  child: CustomPaint(
                    painter: _ConfettiPainter(
                      confettis: _confettis,
                      progress: _confettiController.value,
                    ),
                    size: Size.infinite,
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildResultHeader(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [widget.couleur, widget.couleur.withValues(alpha: 0.75)],
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
          GestureDetector(
            onTap: () => Navigator.of(context).popUntil((r) => r.isFirst),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.home_rounded, color: Colors.white, size: 22),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${widget.icone} ${widget.nomExamen}',
                  style: const TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w900,
                    color: Colors.white, fontFamily: 'Poppins',
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'Résultats de ${widget.nomCandidat}',
                  style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.8)),
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
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _mentionColor.withValues(alpha: 0.3), width: 2),
            boxShadow: [
              BoxShadow(
                color: _mentionColor.withValues(alpha: 0.15),
                blurRadius: 20,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            children: [
              Text(
                '$_score/$_total',
                style: TextStyle(
                  fontSize: 60, fontWeight: FontWeight.w900,
                  color: _mentionColor, fontFamily: 'Poppins',
                  height: 1,
                ),
              ),
              Text(
                '${_pct.toStringAsFixed(1)}%',
                style: TextStyle(
                  fontSize: 22, fontWeight: FontWeight.w700,
                  color: _mentionColor.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                decoration: BoxDecoration(
                  color: _mentionColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _mentionColor.withValues(alpha: 0.3)),
                ),
                child: Text(
                  _mention,
                  style: TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w800,
                    color: _mentionColor, fontFamily: 'Poppins',
                  ),
                ),
              ),
              const SizedBox(height: 14),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: _pct / 100,
                  backgroundColor: Colors.grey[200],
                  color: _mentionColor,
                  minHeight: 10,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsRow() {
    final nonRep = _total - widget.answers.length;
    final faux = widget.answers.length - _correct;
    return Row(
      children: [
        _buildStatCard('✅ Bonnes', _correct.toString(), Colors.green),
        const SizedBox(width: 8),
        _buildStatCard('❌ Fausses', faux.toString(), Colors.red),
        const SizedBox(width: 8),
        _buildStatCard('⬜ Sans rép.', nonRep.toString(), Colors.grey),
        const SizedBox(width: 8),
        _buildStatCard('⏱️ Temps', _tempsFormate, Colors.blue),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Column(
          children: [
            Text(label, textAlign: TextAlign.center,
                style: TextStyle(fontSize: 10, color: color.withValues(alpha: 0.7), fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text(value, textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: color)),
          ],
        ),
      ),
    );
  }

  Widget _buildPdfButtons(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => _exportPdf(context, correctionMode: false),
            icon: const Icon(Icons.picture_as_pdf_rounded, size: 18),
            label: const Text('Sujet PDF', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: widget.couleur,
              side: BorderSide(color: widget.couleur),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => _exportPdf(context, correctionMode: true),
            icon: const Icon(Icons.check_circle_rounded, size: 18),
            label: const Text('Correction PDF', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
            style: ElevatedButton.styleFrom(
              backgroundColor: widget.couleur,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCorrectionToggle() {
    return GestureDetector(
      onTap: () => setState(() => _correctionVisible = !_correctionVisible),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _correctionVisible
                ? widget.couleur.withValues(alpha: 0.4)
                : Colors.grey.withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          children: [
            Icon(
              _correctionVisible ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
              color: widget.couleur,
            ),
            const SizedBox(width: 10),
            Text(
              _correctionVisible ? 'Masquer la correction' : '📖 Voir la correction détaillée',
              style: TextStyle(
                fontSize: 14, fontWeight: FontWeight.w700,
                color: widget.couleur,
              ),
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
        final bonneRep = (q['bonne_reponse'] as String?)?.toUpperCase().trim() ?? '';
        final userReps = widget.answers[i] ?? <String>{};
        final userRepDisplay = userReps.isEmpty ? '' : (userReps.toList()..sort()).join('+');
        final bonnesReps = bonneRep
            .split(RegExp(r'[/,;]'))
            .map((s) => s.trim().toUpperCase())
            .where((s) => s.isNotEmpty)
            .toSet();
        final isCorrect = bonnesReps.isNotEmpty && userReps.isNotEmpty &&
            userReps.containsAll(bonnesReps) && bonnesReps.containsAll(userReps);
        final nonRepondu = userReps.isEmpty;
        final bonneRepDisplay = bonnesReps.isEmpty ? bonneRep : (bonnesReps.toList()..sort()).join('+');

        final color = isCorrect
            ? Colors.green
            : nonRepondu
                ? Colors.grey
                : Colors.red;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color.withValues(alpha: 0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 32, height: 32,
                    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                    child: Center(
                      child: Text('${i + 1}',
                          style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w900)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      (q['enonce'] ?? q['question'] ?? '').toString(),
                      style: const TextStyle(fontSize: 16, fontFamily: 'Georgia',
                          height: 1.5, fontWeight: FontWeight.w600),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Row(
                    children: [
                      if (!nonRepondu) Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: isCorrect ? Colors.green.withValues(alpha: 0.15) : Colors.red.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: isCorrect ? Colors.green : Colors.red),
                        ),
                        child: Text(userRepDisplay,
                            style: TextStyle(color: isCorrect ? Colors.green[700] : Colors.red[700],
                                fontWeight: FontWeight.w900, fontSize: 15)),
                      ),
                      if (!isCorrect) ...[
                        const SizedBox(width: 4),
                        const Text('→', style: TextStyle(color: Colors.black38)),
                        const SizedBox(width: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.green.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: Colors.green),
                          ),
                          child: Text(bonneRepDisplay,
                              style: TextStyle(color: Colors.green[700], fontWeight: FontWeight.w900, fontSize: 15)),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
              if (q['explication'] != null &&
                  (q['explication'] as String).isNotEmpty) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.grey.withValues(alpha: 0.15)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('💡', style: TextStyle(fontSize: 15)),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          q['explication'].toString(),
                          style: const TextStyle(
                            fontSize: 14, color: Colors.black54,
                            fontFamily: 'Georgia', height: 1.5,
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
    );
  }

  // ── Nettoyer le texte pour le PDF (supprimer LaTeX, URL, cases à cocher, caractères parasites) ────
  static String _cleanForPdf(String text) {
    if (text.isEmpty) return text;

    // 1. Supprimer les cases à coix / checkbox Unicode (☒☑☐✓✔✗✘)
    String s = text
        .replaceAll('\u2612', '')  // ☒ ballot box with X
        .replaceAll('\u2611', '')  // ☑ ballot box with check
        .replaceAll('\u2610', '')  // ☐ ballot box
        .replaceAll('\u2713', '')  // ✓ check mark
        .replaceAll('\u2714', '')  // ✔ heavy check mark
        .replaceAll('\u2717', '')  // ✗ ballot X
        .replaceAll('\u2718', '')  // ✘ heavy ballot X
        .replaceAll('\u25A1', '')  // □ white square
        .replaceAll('\u25A0', '')  // ■ black square
        .replaceAll('\u2B1C', '')  // ⬜ large white square
        .replaceAll('\u2B1B', ''); // ⬛ large black square

    // 2. Convertir LaTeX inline $...$ en texte Unicode lisible
    // D'abord traiter les blocs $$...$$
    s = s.replaceAllMapped(
      RegExp(r'\$\$([^$]+)\$\$'),
      (m) => MathTextWidget.latexToReadablePublic(m.group(1) ?? ''),
    );
    // Puis les $ inline $...$
    s = s.replaceAllMapped(
      RegExp(r'\$([^$\n]+)\$'),
      (m) => MathTextWidget.latexToReadablePublic(m.group(1) ?? ''),
    );

    // 3. Appliquer la conversion LaTeX globale
    s = MathTextWidget.latexToReadablePublic(s);

    // 4. Supprimer les signes $ résiduels
    s = s.replaceAll(r'$', '');

    // 5. Remplacer ^ { } _ résiduels par du texte lisible
    // ^{...} → exposant textuel
    s = s.replaceAllMapped(
      RegExp(r'\^\{([^}]*)\}'),
      (m) => '^${m.group(1)}',
    );
    // ^n → exposant n (sans accolades)
    // _{...} → indice textuel
    s = s.replaceAllMapped(
      RegExp(r'_\{([^}]*)\}'),
      (m) => '_${m.group(1)}',
    );

    // 6. Supprimer les accolades résiduelles
    s = s.replaceAll('{', '').replaceAll('}', '');

    // 7. Supprimer les commandes LaTeX résiduelles \commande
    s = s.replaceAllMapped(
      RegExp(r'\\([a-zA-Z]+)\s*'),
      (m) {
        // Garder les caractères connus comme symboles
        final cmd = m.group(1) ?? '';
        const knownSymbols = {
          'times': '×', 'div': '÷', 'pm': '±', 'mp': '∓',
          'cdot': '·', 'infty': '∞', 'pi': 'π', 'alpha': 'α',
          'beta': 'β', 'gamma': 'γ', 'delta': 'δ', 'sigma': 'Σ',
          'sqrt': '√', 'sum': 'Σ', 'int': '∫', 'frac': '/',
          'geq': '≥', 'leq': '≤', 'neq': '≠', 'approx': '≈',
          'rightarrow': '→', 'leftarrow': '←', 'Rightarrow': '⇒',
          'in': '∈', 'notin': '∉', 'subset': '⊂', 'cup': '∪', 'cap': '∩',
          'triangle': '△', 'angle': '∠', 'perp': '⊥',
          'degree': '°', 'partial': '∂', 'nabla': '∇',
        };
        if (knownSymbols.containsKey(cmd)) return knownSymbols[cmd]!;
        return ''; // Supprimer les commandes inconnues
      },
    );

    // 8. Supprimer URL de développement
    s = s.replaceAll(RegExp(r'https?://[^\s]+'), '');
    s = s.replaceAll('ef-fort-bf.pages.dev', '');
    s = s.replaceAll('ef-fort-bf', 'EF-FORT.BF');
    s = s.replaceAll('yembuaro29.workers.dev', '');

    // 9. Nettoyer les guillemets et caractères parasites en début/fin de texte d'option
    // Supprimer les backslash seuls et antislashes orphelins
    s = s.replaceAll(RegExp(r'\\(?!\w)'), '');

    // 10. Nettoyer espaces multiples et normaliser
    s = s.replaceAll(RegExp(r'\s{2,}'), ' ').trim();

    return s.isEmpty ? text : s;
  }

  // ── Export PDF — Copie corrigée propre (taille 14px, logo centré, score encerclé) ───
  Future<void> _exportPdf(BuildContext context, {required bool correctionMode}) async {
    try {
      final pdf = pw.Document();
      final now = DateTime.now();
      final dateStr = '${now.day.toString().padLeft(2,'0')}/${now.month.toString().padLeft(2,'0')}/${now.year}';
      final nomExamenClean = _cleanForPdf(widget.nomExamen);

      // ── Charger le logo EF-FORT.BF ──
      pw.ImageProvider? logoImage;
      try {
        final logoBytes = await rootBundle.load('assets/images/logo_effort.png');
        logoImage = pw.MemoryImage(logoBytes.buffer.asUint8List());
      } catch (_) {
        try {
          final logoBytes = await rootBundle.load('assets/icons/logo_effort.png');
          logoImage = pw.MemoryImage(logoBytes.buffer.asUint8List());
        } catch (_) {
          try {
            final logoBytes = await rootBundle.load('assets/logo/aes_logo.png');
            logoImage = pw.MemoryImage(logoBytes.buffer.asUint8List());
          } catch (_) {
            logoImage = null;
          }
        }
      }

      // ── Couleurs ──
      final rouge       = PdfColor.fromHex('C62828');
      final rougeFonce  = PdfColor.fromHex('8B0000');
      final vert        = PdfColor.fromHex('2E7D32');
      final vertClair   = PdfColor.fromHex('E8F5E9');
      final rougeClair  = PdfColor.fromHex('FFEBEE');
      final greyLight   = PdfColor.fromHex('F5F5F5');
      final greyMed     = PdfColor.fromHex('BDBDBD');
      final greyDark    = PdfColor.fromHex('424242');
      final greyText    = PdfColor.fromHex('6C757D');
      final borderVert  = PdfColor.fromHex('A5D6A7');
      final borderRouge = PdfColor.fromHex('EF9A9A');
      final noir        = PdfColors.black;

      // ── Note sur 50 pour les examens ──
      final noteSur50  = _total > 0 ? (_score / _total * 50) : 0.0;
      final noteStr    = noteSur50.toStringAsFixed(1);
      final pctVal     = _total > 0 ? (_score / _total * 100).round() : 0;

      String getMention() {
        if (pctVal >= 90) return 'EXCELLENT';
        if (pctVal >= 80) return 'TRES BIEN';
        if (pctVal >= 70) return 'BIEN';
        if (pctVal >= 60) return 'ASSEZ BIEN';
        if (pctVal >= 50) return 'PASSABLE';
        return 'INSUFFISANT';
      }

      PdfColor getMentionColor() {
        if (pctVal >= 70) return vert;
        if (pctVal >= 50) return PdfColor.fromHex('F57C00');
        return rouge;
      }

      String getAppreciation() {
        if (pctVal >= 90) return 'Excellent ! Vous maîtrisez parfaitement le sujet. Continuez ainsi !';
        if (pctVal >= 80) return 'Excellent travail ! Vous maîtrisez bien les notions. Visez la perfection.';
        if (pctVal >= 70) return 'Très bien ! Bon niveau. Quelques révisions vous permettront d\'atteindre l\'excellence.';
        if (pctVal >= 60) return 'Bien ! Fondamentaux assimilés. Concentrez-vous sur les points manqués.';
        if (pctVal >= 50) return 'Passable. Revoyez certaines notions importantes. Persévérez !';
        return 'Des efforts supplémentaires sont nécessaires. Revoyez le cours attentivement. Vous pouvez y arriver !';
      }

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.fromLTRB(40, 36, 40, 36),
          // ═══════════════════════════════════════════════════════
          // EN-TÊTE : Logo centré + Titre + Nom
          // ═══════════════════════════════════════════════════════
          header: (ctx) => pw.Column(
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
          // ═══════════════════════════════════════════════════════
          // PIED DE PAGE : Slogan centré
          // ═══════════════════════════════════════════════════════
          footer: (ctx) => pw.Column(
            children: [
              pw.Divider(color: greyMed, thickness: 0.5),
              pw.SizedBox(height: 4),
              pw.Text(
                'Chaque effort te rapproche de ton admission — EF-FORT.BF',
                textAlign: pw.TextAlign.center,
                style: pw.TextStyle(fontSize: 11, color: greyText, fontStyle: pw.FontStyle.italic),
              ),
              pw.SizedBox(height: 2),
              pw.Text('Page ${ctx.pageNumber}/${ctx.pagesCount}',
                  textAlign: pw.TextAlign.center,
                  style: pw.TextStyle(fontSize: 10, color: greyMed)),
            ],
          ),
          // ═══════════════════════════════════════════════════════
          // CORPS DU PDF
          // ═══════════════════════════════════════════════════════
          build: (ctx) {
            final List<pw.Widget> content = [];

            // ── Titre + Infos candidat + Score encerclé ──
            content.add(
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
                          pw.Text(
                            correctionMode ? 'CORRECTION — $nomExamenClean' : 'SUJET D\'EXAMEN — $nomExamenClean',
                            style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, color: greyDark),
                          ),
                          pw.SizedBox(height: 6),
                          pw.Text('Candidat(e) : ${widget.nomCandidat}',
                              style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                          pw.SizedBox(height: 3),
                          pw.Text('Date : $dateStr   |   ${widget.questions.length} questions   |   Durée : 1h30',
                              style: pw.TextStyle(fontSize: 12, color: greyText)),
                          if (correctionMode) ...[
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
                        ],
                      ),
                    ),
                  ),
                  if (correctionMode) ...[
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
                                pw.Text('50',
                                    style: pw.TextStyle(fontSize: 14, color: rouge)),
                              ],
                            ),
                          ),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text('$_score/$_total  ($pctVal%)',
                            textAlign: pw.TextAlign.center,
                            style: pw.TextStyle(fontSize: 11, color: greyText)),
                      ],
                    ),
                  ],
                ],
              ),
            );
            content.add(pw.SizedBox(height: 14));

            // ── Questions ──
            for (int i = 0; i < widget.questions.length; i++) {
              final q = widget.questions[i] as Map<String, dynamic>;
              final enonce = _cleanForPdf((q['enonce'] ?? q['question'] ?? '').toString());
              final bonneRep = (q['bonne_reponse'] as String?)?.toUpperCase().trim() ?? '';
              final userReps = correctionMode ? (widget.answers[i] ?? <String>{}) : <String>{};
              final userRepDisplay = userReps.isEmpty ? 'Aucune' : (userReps.toList()..sort()).join('+');
              final bonnesReps = bonneRep
                  .split(RegExp(r'[/,;]'))
                  .map((s) => s.trim().toUpperCase())
                  .where((s) => s.isNotEmpty)
                  .toSet();
              final bonneRepDisplay = bonnesReps.isEmpty ? bonneRep : (bonnesReps.toList()..sort()).join('+');
              final isCorrect = correctionMode && bonnesReps.isNotEmpty && userReps.isNotEmpty &&
                  userReps.containsAll(bonnesReps) && bonnesReps.containsAll(userReps);
              final nonRepondu = correctionMode && userReps.isEmpty;

              final bgColor = correctionMode
                  ? (isCorrect ? vertClair : (nonRepondu ? greyLight : rougeClair))
                  : PdfColors.white;
              final brdColor = correctionMode
                  ? (isCorrect ? borderVert : (nonRepondu ? greyMed : borderRouge))
                  : greyMed;
              final numColor = correctionMode
                  ? (isCorrect ? vert : (nonRepondu ? greyText : rouge))
                  : greyDark;
              final statusTxt = correctionMode
                  ? (isCorrect ? 'CORRECT' : (nonRepondu ? 'NON REPONDU' : 'INCORRECT'))
                  : '';

              content.add(
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
                      // Ligne numéro + énoncé + statut
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
                          if (correctionMode) ...[
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
                        ],
                      ),
                      if (correctionMode) ...[
                        pw.SizedBox(height: 4),
                        // Réponse donnée et bonne réponse
                        pw.Text(
                          'Votre réponse : $userRepDisplay   |   Bonne(s) réponse(s) : $bonneRepDisplay',
                          style: pw.TextStyle(
                            fontSize: 14,
                            fontWeight: pw.FontWeight.bold,
                            color: isCorrect ? vert : rouge,
                          ),
                        ),
                      ],
                      pw.SizedBox(height: 6),
                      // Options A B C D E
                      ...['A', 'B', 'C', 'D', 'E'].map((letter) {
                        final optKey = 'option_${letter.toLowerCase()}';
                        final opt = _cleanForPdf((q[optKey] ?? '').toString());
                        if (opt.isEmpty) return pw.SizedBox();
                        final isBonne = correctionMode && bonnesReps.contains(letter);
                        final isChoisie = correctionMode && userReps.contains(letter);
                        final textColor = isBonne ? vert : (isChoisie ? rouge : greyText);
                        final fontW = isBonne ? pw.FontWeight.bold : pw.FontWeight.normal;
                        return pw.Padding(
                          padding: const pw.EdgeInsets.only(left: 34, bottom: 4),
                          child: pw.Row(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text('$letter. ',
                                  style: pw.TextStyle(fontSize: 14, fontWeight: fontW, color: textColor)),
                              pw.Expanded(
                                child: pw.Text(
                                  opt + (isBonne ? '  ✓ Bonne réponse' : (isChoisie && correctionMode ? '  ✗ Votre réponse' : '')),
                                  style: pw.TextStyle(fontSize: 14, color: textColor, fontWeight: fontW, lineSpacing: 2),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                      // Explication (mode correction uniquement)
                      if (correctionMode &&
                          q['explication'] != null &&
                          (q['explication'] as String).trim().isNotEmpty) ...[
                        pw.SizedBox(height: 6),
                        pw.Container(
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
                                  _cleanForPdf(q['explication'].toString()),
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
            return content;
          },
        ),
      );

      final nomSafe = widget.nomExamen
          .replaceAll(RegExp(r'[^a-zA-Z0-9\u00C0-\u024F_-]'), '_')
          .replaceAll(RegExp(r'_+'), '_');
      final pdfName = correctionMode
          ? 'EF-FORT_Correction_$nomSafe.pdf'
          : 'EF-FORT_Sujet_$nomSafe.pdf';

      if (!context.mounted) return;
      await Printing.sharePdf(bytes: await pdf.save(), filename: pdfName);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur PDF : $e'), backgroundColor: Colors.red),
        );
      }
    }
  }
}

// ── Confettis ────────────────────────────────────────────────────
class _Confetti {
  double x, y, vx, vy, size, rotation;
  final Color color;
  _Confetti({
    required this.x, required this.y, required this.vx, required this.vy,
    required this.size, required this.rotation, required this.color,
  });
}

class _ConfettiPainter extends CustomPainter {
  final List<_Confetti> confettis;
  final double progress;

  const _ConfettiPainter({required this.confettis, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    for (final c in confettis) {
      final x = (c.x + c.vx * progress * 100) % 1.0;
      final y = c.y + c.vy * progress * 100;
      if (y > 1.2) continue;

      final paint = Paint()..color = c.color.withValues(alpha: 1.0 - progress * 0.5);
      final cx = x * size.width;
      final cy = y * size.height;
      final rot = c.rotation + progress * math.pi * 3;

      canvas.save();
      canvas.translate(cx, cy);
      canvas.rotate(rot);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset.zero, width: c.size, height: c.size * 0.5),
          const Radius.circular(1),
        ),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => old.progress != progress;
}
