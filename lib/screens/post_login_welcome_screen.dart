import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../services/bell_service.dart';
import 'home_screen.dart';

// ══════════════════════════════════════════════════════════════════════
// POST LOGIN WELCOME SCREEN — EF-FORT.BF v1.0
// Affiché après la connexion, avant le dashboard
// Style Minecraft : blocs pixelisés, animations, son fanfare/cloche
// "Chargement de votre espace..." avec effet de blocs qui se construisent
// ══════════════════════════════════════════════════════════════════════

class PostLoginWelcomeScreen extends StatefulWidget {
  final String? userName;
  const PostLoginWelcomeScreen({super.key, this.userName});

  @override
  State<PostLoginWelcomeScreen> createState() => _PostLoginWelcomeScreenState();
}

class _PostLoginWelcomeScreenState extends State<PostLoginWelcomeScreen>
    with TickerProviderStateMixin {
  // ── Controllers ─────────────────────────────────────────────────────
  late AnimationController _fadeController;
  late AnimationController _blocksController;
  late AnimationController _progressController;
  late AnimationController _pulseController;

  // ── Animations ──────────────────────────────────────────────────────
  late Animation<double> _fadeAnim;
  late Animation<double> _blocksAnim;
  late Animation<double> _progressAnim;
  late Animation<double> _pulseAnim;

  // ── État ────────────────────────────────────────────────────────────
  bool _soundPlayed = false;
  int _loadingStep = 0;
  Timer? _stepTimer;
  Timer? _navigationTimer;
  bool _navigating = false;

  // ── Messages de chargement style Minecraft ─────────────────────────
  final List<String> _loadingMessages = [
    'Initialisation du tableau de bord...',
    'Chargement des matières...',
    'Préparation des QCM...',
    'Synchronisation des données...',
    'Construction de votre espace...',
    'Bienvenue dans EF-FORT.BF !',
  ];

  // ── Blocs Minecraft aléatoires ──────────────────────────────────────
  final math.Random _random = math.Random(42);
  late List<_MinecraftBlock> _blocks;

  @override
  void initState() {
    super.initState();
    _initBlocks();
    _initAnimations();
    _startSequence();
  }

  void _initBlocks() {
    _blocks = List.generate(40, (i) {
      final colors = [
        const Color(0xFF4CAF50), // vert herbe
        const Color(0xFF8B6914), // marron terre
        const Color(0xFF607D8B), // gris pierre
        const Color(0xFFD4A017), // or
        const Color(0xFF1A5C38), // vert foncé
        const Color(0xFF2E7D32), // vert moyen
        const Color(0xFF5D4037), // marron foncé
        const Color(0xFF37474F), // ardoise
      ];
      return _MinecraftBlock(
        x: _random.nextDouble(),
        y: _random.nextDouble(),
        size: 16 + _random.nextDouble() * 24,
        color: colors[_random.nextInt(colors.length)],
        delay: _random.nextDouble() * 0.7,
        speed: 0.3 + _random.nextDouble() * 0.4,
      );
    });
  }

  void _initAnimations() {
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _blocksController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    );
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOut),
    );
    _blocksAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _blocksController, curve: Curves.linear),
    );
    _progressAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _progressController, curve: Curves.easeInOut),
    );
    _pulseAnim = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  Future<void> _startSequence() async {
    await Future.delayed(const Duration(milliseconds: 200));
    if (!mounted) return;

    _fadeController.forward();
    _progressController.forward();

    // Jouer le son de bienvenue
    await _playWelcomeSound();

    // Afficher les messages progressivement
    int step = 0;
    _stepTimer = Timer.periodic(const Duration(milliseconds: 550), (t) {
      if (!mounted) { t.cancel(); return; }
      if (step < _loadingMessages.length - 1) {
        setState(() => _loadingStep = ++step);
      } else {
        t.cancel();
      }
    });

    // Naviguer vers HomeScreen après le chargement
    _navigationTimer = Timer(const Duration(milliseconds: 3800), () {
      if (!mounted || _navigating) return;
      _goToDashboard();
    });
  }

  Future<void> _playWelcomeSound() async {
    if (_soundPlayed) return;
    _soundPlayed = true;
    try {
      // BellService gère Web (Web Audio API) ET Mobile (audioplayers)
      await BellService.playStart();
    } catch (_) {}
  }

  void _goToDashboard() {
    if (!mounted || _navigating) return;
    _navigating = true;
    _stepTimer?.cancel();
    _navigationTimer?.cancel();
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (_, anim, __) => const HomeScreen(),
        transitionsBuilder: (_, anim, __, child) => FadeTransition(
          opacity: anim,
          child: child,
        ),
        transitionDuration: const Duration(milliseconds: 600),
      ),
    );
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _blocksController.dispose();
    _progressController.dispose();
    _pulseController.dispose();
    _stepTimer?.cancel();
    _navigationTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final prenom = widget.userName?.split(' ').first ?? 'Candidat';

    return Scaffold(
      body: GestureDetector(
        onTap: _goToDashboard,
        child: Stack(
          children: [
            // ── Fond noir/vert foncé style Minecraft ──────────────────
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFF0A1A0A),
                    Color(0xFF0D2E14),
                    Color(0xFF0A1A0A),
                  ],
                ),
              ),
            ),

            // ── Blocs Minecraft animés en arrière-plan ─────────────
            AnimatedBuilder(
              animation: _blocksAnim,
              builder: (_, __) => CustomPaint(
                painter: _MinecraftBlocksPainter(
                  blocks: _blocks,
                  progress: _blocksAnim.value,
                  screenSize: size,
                ),
                size: Size.infinite,
              ),
            ),

            // ── Grille pixelisée en overlay ────────────────────────
            Opacity(
              opacity: 0.04,
              child: CustomPaint(
                painter: _GridPainter(),
                size: Size.infinite,
              ),
            ),

            // ── Contenu principal ──────────────────────────────────
            SafeArea(
              child: FadeTransition(
                opacity: _fadeAnim,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Spacer(flex: 2),

                        // ── Logo pixelisé ──────────────────────────
                        ScaleTransition(
                          scale: _pulseAnim,
                          child: _buildMinecraftLogo(),
                        ),

                        const SizedBox(height: 32),

                        // ── Titre EF-FORT.BF ───────────────────────
                        _buildPixelTitle(),

                        const SizedBox(height: 12),

                        // ── Message de bienvenue ───────────────────
                        _buildWelcomeMessage(prenom),

                        const Spacer(flex: 2),

                        // ── Barre de progression style Minecraft ───
                        _buildProgressBar(),

                        const SizedBox(height: 16),

                        // ── Message de chargement ──────────────────
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          transitionBuilder: (child, anim) => FadeTransition(
                            opacity: anim,
                            child: SlideTransition(
                              position: Tween<Offset>(
                                begin: const Offset(0, 0.3),
                                end: Offset.zero,
                              ).animate(anim),
                              child: child,
                            ),
                          ),
                          child: Text(
                            _loadingMessages[_loadingStep],
                            key: ValueKey(_loadingStep),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF4CAF50),
                              fontFamily: 'monospace',
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),

                        const SizedBox(height: 40),

                        // ── Bouton skip ────────────────────────────
                        TextButton(
                          onPressed: _goToDashboard,
                          child: const Text(
                            'Appuyez pour passer →',
                            style: TextStyle(
                              color: Color(0xFF4CAF50),
                              fontSize: 12,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Logo style pixel art ─────────────────────────────────────────────
  Widget _buildMinecraftLogo() {
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        color: const Color(0xFF1A5C38),
        border: Border.all(color: const Color(0xFFD4A017), width: 3),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4CAF50).withValues(alpha: 0.5),
            blurRadius: 24,
            spreadRadius: 6,
          ),
          BoxShadow(
            color: const Color(0xFFD4A017).withValues(alpha: 0.3),
            blurRadius: 40,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Stack(
        children: [
          // Coins pixelisés
          Positioned(top: 0, left: 0, child: Container(width: 8, height: 8, color: const Color(0xFF0A3D20))),
          Positioned(top: 0, right: 0, child: Container(width: 8, height: 8, color: const Color(0xFF0A3D20))),
          Positioned(bottom: 0, left: 0, child: Container(width: 8, height: 8, color: const Color(0xFF0A3D20))),
          Positioned(bottom: 0, right: 0, child: Container(width: 8, height: 8, color: const Color(0xFF0A3D20))),
          // Texte
          const Center(
            child: Text(
              'EF',
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.w900,
                color: Color(0xFFD4A017),
                fontFamily: 'monospace',
                letterSpacing: 2,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Titre pixelisé ───────────────────────────────────────────────────
  Widget _buildPixelTitle() {
    return Column(
      children: [
        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [Color(0xFF4CAF50), Color(0xFFD4A017), Color(0xFF4CAF50)],
          ).createShader(bounds),
          blendMode: BlendMode.srcIn,
          child: const Text(
            'EF-FORT.BF',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              fontFamily: 'monospace',
              letterSpacing: 3,
              shadows: [
                Shadow(
                  color: Color(0xFF4CAF50),
                  offset: Offset(2, 2),
                  blurRadius: 0,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFF4CAF50), width: 1),
            color: const Color(0xFF4CAF50).withValues(alpha: 0.08),
          ),
          child: const Text(
            '▶  PLATEFORME N°1 AU BURKINA FASO  ◀',
            style: TextStyle(
              fontSize: 8,
              color: Color(0xFF4CAF50),
              fontFamily: 'monospace',
              letterSpacing: 1.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }

  // ── Message de bienvenue ─────────────────────────────────────────────
  Widget _buildWelcomeMessage(String prenom) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFF4CAF50).withValues(alpha: 0.4), width: 1),
        color: const Color(0xFF4CAF50).withValues(alpha: 0.06),
      ),
      child: Column(
        children: [
          Text(
            '🎓  Bienvenue, $prenom !',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: Color(0xFFD4A017),
              fontFamily: 'monospace',
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Votre espace de préparation est prêt.\nBonne révision et bonne chance ! 🇧🇫',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11.5,
              color: Color(0xFF81C784),
              height: 1.6,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }

  // ── Barre de progression style Minecraft ─────────────────────────────
  Widget _buildProgressBar() {
    return AnimatedBuilder(
      animation: _progressAnim,
      builder: (_, __) {
        return Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'CHARGEMENT',
                  style: TextStyle(
                    fontSize: 10,
                    color: Color(0xFF4CAF50),
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.w700,
                    letterSpacing: 2,
                  ),
                ),
                Text(
                  '${(_progressAnim.value * 100).toInt()}%',
                  style: const TextStyle(
                    fontSize: 10,
                    color: Color(0xFFD4A017),
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            // Barre style Minecraft (blocs)
            SizedBox(
              height: 20,
              child: ClipRRect(
                child: Stack(
                  children: [
                    // Fond
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.black,
                        border: Border.all(color: const Color(0xFF2E7D32), width: 1),
                      ),
                    ),
                    // Blocs de progression
                    FractionallySizedBox(
                      widthFactor: _progressAnim.value,
                      child: CustomPaint(
                        painter: _ProgressBlocksPainter(),
                      ),
                    ),
                    // Reflet
                    Container(
                      height: 4,
                      color: Colors.white.withValues(alpha: 0.06),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

// ══════════════════════════════════════════════════════════════
// DATA MODEL : Bloc Minecraft
// ══════════════════════════════════════════════════════════════
class _MinecraftBlock {
  final double x;
  final double y;
  final double size;
  final Color color;
  final double delay;
  final double speed;

  const _MinecraftBlock({
    required this.x,
    required this.y,
    required this.size,
    required this.color,
    required this.delay,
    required this.speed,
  });
}

// ══════════════════════════════════════════════════════════════
// PAINTER : Blocs Minecraft flottants
// ══════════════════════════════════════════════════════════════
class _MinecraftBlocksPainter extends CustomPainter {
  final List<_MinecraftBlock> blocks;
  final double progress;
  final Size screenSize;

  const _MinecraftBlocksPainter({
    required this.blocks,
    required this.progress,
    required this.screenSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final block in blocks) {
      final animProgress = ((progress * block.speed + block.delay) % 1.0);
      final x = block.x * size.width;
      final y = size.height - (animProgress * (size.height + block.size * 2)) + block.size;
      final opacity = animProgress < 0.1
          ? animProgress / 0.1
          : animProgress > 0.9
              ? (1.0 - animProgress) / 0.1
              : 1.0;

      final paint = Paint()
        ..color = block.color.withValues(alpha: opacity * 0.25)
        ..style = PaintingStyle.fill;

      final borderPaint = Paint()
        ..color = block.color.withValues(alpha: opacity * 0.4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1;

      final rect = Rect.fromCenter(
        center: Offset(x, y),
        width: block.size,
        height: block.size,
      );

      canvas.drawRect(rect, paint);
      canvas.drawRect(rect, borderPaint);

      // Détail pixelisé (coin)
      final cornerPaint = Paint()
        ..color = Colors.white.withValues(alpha: opacity * 0.08)
        ..style = PaintingStyle.fill;
      canvas.drawRect(
        Rect.fromLTWH(rect.left + 2, rect.top + 2, 4, 4),
        cornerPaint,
      );
    }
  }

  @override
  bool shouldRepaint(_MinecraftBlocksPainter old) => old.progress != progress;
}

// ══════════════════════════════════════════════════════════════
// PAINTER : Grille pixel art
// ══════════════════════════════════════════════════════════════
class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF4CAF50)
      ..strokeWidth = 0.5;

    const step = 32.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_GridPainter old) => false;
}

// ══════════════════════════════════════════════════════════════
// PAINTER : Blocs de progression
// ══════════════════════════════════════════════════════════════
class _ProgressBlocksPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const blockW = 12.0;
    const gap = 1.0;
    int i = 0;
    for (double x = 0; x < size.width; x += blockW + gap) {
      final shade = (i % 3 == 0) ? 0.9 : (i % 3 == 1) ? 0.75 : 0.85;
      final paint = Paint()
        ..color = Color.lerp(
          const Color(0xFF2E7D32),
          const Color(0xFF4CAF50),
          shade,
        )!;
      canvas.drawRect(
        Rect.fromLTWH(x, 0, math.min(blockW, size.width - x), size.height),
        paint,
      );
      i++;
    }
  }

  @override
  bool shouldRepaint(_ProgressBlocksPainter old) => false;
}
