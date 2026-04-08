import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/tutorial_service.dart';
import 'home_screen.dart';
import 'onboarding_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  // Master timeline that drives all reveal animations (0.0 -> 1.0)
  late AnimationController _master;
  // Continuous loops
  late AnimationController _ringRotation;
  late AnimationController _pulse;
  late AnimationController _particles;
  late AnimationController _road;
  late AnimationController _shimmer;

  // Reveal stage animations
  late Animation<double> _logoScale;
  late Animation<double> _logoRotation;
  late Animation<double> _gaugeFill;
  late Animation<double> _titleReveal;
  late Animation<double> _taglineFade;
  late Animation<double> _chipsReveal;
  late Animation<double> _bottomReveal;

  // Particles for the background — generated once
  late final List<_Particle> _particleList;

  static const _featurePills = [
    _Feature(Icons.local_gas_station_rounded, 'Track Fuel'),
    _Feature(Icons.savings_rounded, 'Save Money'),
    _Feature(Icons.speed_rounded, 'Drive Smart'),
  ];

  @override
  void initState() {
    super.initState();

    final rng = math.Random(42);
    _particleList = List.generate(22, (i) {
      return _Particle(
        x: rng.nextDouble(),
        startY: rng.nextDouble(),
        size: 2 + rng.nextDouble() * 6,
        speed: 0.3 + rng.nextDouble() * 0.7,
        opacity: 0.15 + rng.nextDouble() * 0.45,
        drift: (rng.nextDouble() - 0.5) * 0.15,
      );
    });

    _master = AnimationController(
      duration: const Duration(milliseconds: 3600),
      vsync: this,
    );
    _ringRotation = AnimationController(
      duration: const Duration(seconds: 12),
      vsync: this,
    )..repeat();
    _pulse = AnimationController(
      duration: const Duration(milliseconds: 1800),
      vsync: this,
    )..repeat(reverse: true);
    _particles = AnimationController(
      duration: const Duration(seconds: 8),
      vsync: this,
    )..repeat();
    _road = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat();
    _shimmer = AnimationController(
      duration: const Duration(milliseconds: 2200),
      vsync: this,
    )..repeat();

    _logoScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _master,
        curve: const Interval(0.0, 0.30, curve: Curves.elasticOut),
      ),
    );
    _logoRotation = Tween<double>(begin: -math.pi / 4, end: 0.0).animate(
      CurvedAnimation(
        parent: _master,
        curve: const Interval(0.0, 0.35, curve: Curves.easeOutBack),
      ),
    );
    _gaugeFill = CurvedAnimation(
      parent: _master,
      curve: const Interval(0.20, 0.55, curve: Curves.easeOutCubic),
    );
    _titleReveal = CurvedAnimation(
      parent: _master,
      curve: const Interval(0.30, 0.65, curve: Curves.easeOutCubic),
    );
    _taglineFade = CurvedAnimation(
      parent: _master,
      curve: const Interval(0.50, 0.72, curve: Curves.easeIn),
    );
    _chipsReveal = CurvedAnimation(
      parent: _master,
      curve: const Interval(0.60, 0.88, curve: Curves.easeOutCubic),
    );
    _bottomReveal = CurvedAnimation(
      parent: _master,
      curve: const Interval(0.75, 1.0, curve: Curves.easeOut),
    );

    _master.forward().whenComplete(_navigateToHome);
  }

  Future<void> _navigateToHome() async {
    await Future.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;
    final onboardingDone = await TutorialService.isOnboardingCompleted();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 700),
        pageBuilder: (_, __, ___) =>
            onboardingDone ? const HomeScreen() : const OnboardingScreen(),
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(
            opacity: animation,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.96, end: 1.0).animate(
                CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
              ),
              child: child,
            ),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _master.dispose();
    _ringRotation.dispose();
    _pulse.dispose();
    _particles.dispose();
    _road.dispose();
    _shimmer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ============ LAYER 1: Animated background gradient ============
          AnimatedBuilder(
            animation: _pulse,
            builder: (context, _) {
              return Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color.lerp(
                        const Color(0xFF667eea),
                        const Color(0xFF5568d3),
                        _pulse.value,
                      )!,
                      const Color(0xFF764ba2),
                      Color.lerp(
                        const Color(0xFF2196F3),
                        const Color(0xFF1976D2),
                        _pulse.value,
                      )!,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              );
            },
          ),

          // ============ LAYER 2: Floating fuel-drop particles ============
          AnimatedBuilder(
            animation: _particles,
            builder: (context, _) {
              return CustomPaint(
                size: size,
                painter: _ParticlePainter(
                  particles: _particleList,
                  progress: _particles.value,
                ),
              );
            },
          ),

          // ============ LAYER 3: Soft radial vignette ============
          IgnorePointer(
            child: Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.center,
                  radius: 1.2,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.25),
                  ],
                ),
              ),
            ),
          ),

          // ============ LAYER 4: Main content ============
          SafeArea(
            child: Column(
              children: [
                const Spacer(flex: 3),

                // ====== CENTER: Logo + animated rings + gauge ======
                _buildCenterLogo(),

                const SizedBox(height: 44),

                // ====== TITLE: letter-by-letter reveal ======
                _buildAnimatedTitle(),

                const SizedBox(height: 14),

                // ====== TAGLINE with shimmer ======
                _buildTagline(),

                const SizedBox(height: 36),

                // ====== FEATURE PILLS ======
                _buildFeaturePills(),

                const Spacer(flex: 3),

                // ====== BOTTOM: animated road + loader ======
                _buildBottomSection(),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────
  // CENTER LOGO: rotating dashed ring + pulsing glow + gauge arc
  //              + fuel pump icon with vertical liquid fill
  // ─────────────────────────────────────────────────────────────────
  Widget _buildCenterLogo() {
    return AnimatedBuilder(
      animation: Listenable.merge([
        _master,
        _ringRotation,
        _pulse,
      ]),
      builder: (context, _) {
        final logoScale = _logoScale.value;
        if (logoScale == 0) return const SizedBox(width: 200, height: 200);

        return Transform.scale(
          scale: logoScale,
          child: Transform.rotate(
            angle: _logoRotation.value,
            child: SizedBox(
              width: 220,
              height: 220,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Outer pulsing glow halo
                  Transform.scale(
                    scale: 1.0 + (_pulse.value * 0.15),
                    child: Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            Colors.white.withValues(alpha: 0.25),
                            Colors.white.withValues(alpha: 0.0),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Outermost rotating dashed ring
                  Transform.rotate(
                    angle: _ringRotation.value * 2 * math.pi,
                    child: CustomPaint(
                      size: const Size(210, 210),
                      painter: _DashedRingPainter(
                        color: Colors.white.withValues(alpha: 0.55),
                        strokeWidth: 2,
                        dashCount: 36,
                        gap: 0.55,
                      ),
                    ),
                  ),

                  // Counter-rotating inner dashed ring
                  Transform.rotate(
                    angle: -_ringRotation.value * 2 * math.pi * 1.6,
                    child: CustomPaint(
                      size: const Size(178, 178),
                      painter: _DashedRingPainter(
                        color: Colors.white.withValues(alpha: 0.35),
                        strokeWidth: 1.5,
                        dashCount: 60,
                        gap: 0.7,
                      ),
                    ),
                  ),

                  // Gauge arc that "fills" during reveal
                  CustomPaint(
                    size: const Size(160, 160),
                    painter: _GaugeArcPainter(
                      progress: _gaugeFill.value,
                      color: Colors.white,
                    ),
                  ),

                  // Inner glassmorphism circle
                  Container(
                    width: 130,
                    height: 130,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.white.withValues(alpha: 0.32),
                          Colors.white.withValues(alpha: 0.10),
                        ],
                      ),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.5),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.white.withValues(alpha: 0.4),
                          blurRadius: 30,
                          spreadRadius: 2,
                        ),
                        BoxShadow(
                          color: const Color(0xFF2196F3).withValues(alpha: 0.6),
                          blurRadius: 50,
                          spreadRadius: 6,
                        ),
                      ],
                    ),
                    // Fuel pump icon with a "liquid fill" overlay
                    child: ClipOval(
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Outline icon
                          Icon(
                            Icons.local_gas_station_rounded,
                            size: 70,
                            color: Colors.white.withValues(alpha: 0.35),
                          ),
                          // Filled icon revealed by a rising mask
                          ClipRect(
                            clipper: _BottomUpClipper(_gaugeFill.value),
                            child: const Icon(
                              Icons.local_gas_station_rounded,
                              size: 70,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Sparkle dots orbiting around the logo
                  ..._buildSparkles(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  List<Widget> _buildSparkles() {
    const sparkleCount = 6;
    return List.generate(sparkleCount, (i) {
      final angle = (i / sparkleCount) * 2 * math.pi +
          _ringRotation.value * 2 * math.pi;
      const radius = 105.0;
      final x = math.cos(angle) * radius;
      final y = math.sin(angle) * radius;
      final twinkle =
          (math.sin(_pulse.value * math.pi * 2 + i) + 1) / 2;
      return Transform.translate(
        offset: Offset(x, y),
        child: Container(
          width: 6 + twinkle * 4,
          height: 6 + twinkle * 4,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withValues(alpha: 0.4 + twinkle * 0.5),
            boxShadow: [
              BoxShadow(
                color: Colors.white.withValues(alpha: 0.6),
                blurRadius: 8,
                spreadRadius: 1,
              ),
            ],
          ),
        ),
      );
    });
  }

  // ─────────────────────────────────────────────────────────────────
  // TITLE: "FUEL COST" with letter-by-letter staggered reveal
  // ─────────────────────────────────────────────────────────────────
  Widget _buildAnimatedTitle() {
    const text = 'FUEL COST';
    return AnimatedBuilder(
      animation: _titleReveal,
      builder: (context, _) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(text.length, (i) {
            final letterStart = i / text.length * 0.7;
            final letterEnd = letterStart + 0.4;
            final t = ((_titleReveal.value - letterStart) /
                    (letterEnd - letterStart))
                .clamp(0.0, 1.0);
            final eased = Curves.easeOutBack.transform(t);

            return Transform.translate(
              offset: Offset(0, (1 - eased) * 30),
              child: Opacity(
                opacity: t.clamp(0.0, 1.0),
                child: Text(
                  text[i],
                  style: GoogleFonts.exo2(
                    fontSize: 44,
                    fontWeight: FontWeight.w900,
                    fontStyle: FontStyle.italic,
                    color: Colors.white,
                    letterSpacing: 2,
                    shadows: [
                      Shadow(
                        color: Colors.black.withValues(alpha: 0.35),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                      Shadow(
                        color: const Color(0xFF2196F3).withValues(alpha: 0.6),
                        blurRadius: 20,
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }

  // ─────────────────────────────────────────────────────────────────
  // TAGLINE pill with shimmer sweep
  // ─────────────────────────────────────────────────────────────────
  Widget _buildTagline() {
    return FadeTransition(
      opacity: _taglineFade,
      child: AnimatedBuilder(
        animation: _shimmer,
        builder: (context, _) {
          return Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 22, vertical: 9),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.35),
                width: 1,
              ),
              gradient: LinearGradient(
                begin: Alignment(-1.5 + _shimmer.value * 3, 0),
                end: Alignment(0.0 + _shimmer.value * 3, 0),
                colors: [
                  Colors.white.withValues(alpha: 0.10),
                  Colors.white.withValues(alpha: 0.30),
                  Colors.white.withValues(alpha: 0.10),
                ],
              ),
            ),
            child: Text(
              'TRACK  •  CALCULATE  •  SAVE',
              style: TextStyle(
                fontSize: 12,
                color: Colors.white.withValues(alpha: 0.95),
                fontWeight: FontWeight.w700,
                letterSpacing: 2.2,
              ),
            ),
          );
        },
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────
  // FEATURE PILLS: three glass chips that pop in
  // ─────────────────────────────────────────────────────────────────
  Widget _buildFeaturePills() {
    return AnimatedBuilder(
      animation: _chipsReveal,
      builder: (context, _) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(_featurePills.length, (i) {
            final start = i * 0.25;
            final end = start + 0.55;
            final t =
                ((_chipsReveal.value - start) / (end - start)).clamp(0.0, 1.0);
            final eased = Curves.easeOutCubic.transform(t);
            final pill = _featurePills[i];

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Transform.translate(
                offset: Offset(0, (1 - eased) * 25),
                child: Opacity(
                  opacity: t,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.3),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(pill.icon,
                            size: 16,
                            color: Colors.white.withValues(alpha: 0.95)),
                        const SizedBox(width: 6),
                        Text(
                          pill.label,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }

  // ─────────────────────────────────────────────────────────────────
  // BOTTOM: animated road dashes + custom dot loader + version
  // ─────────────────────────────────────────────────────────────────
  Widget _buildBottomSection() {
    return FadeTransition(
      opacity: _bottomReveal,
      child: Column(
        children: [
          // Animated road dashes (gives illusion of motion)
          AnimatedBuilder(
            animation: _road,
            builder: (context, _) {
              return CustomPaint(
                size: const Size(double.infinity, 18),
                painter: _RoadPainter(progress: _road.value),
              );
            },
          ),
          const SizedBox(height: 18),

          // Three-dot bouncing loader
          AnimatedBuilder(
            animation: _pulse,
            builder: (context, _) {
              return Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(3, (i) {
                  final phase =
                      (_pulse.value * 2 + i * 0.33) % 1.0;
                  final scale =
                      0.7 + math.sin(phase * math.pi).abs() * 0.6;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Transform.scale(
                      scale: scale,
                      child: Container(
                        width: 9,
                        height: 9,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white
                              .withValues(alpha: 0.6 + scale * 0.3),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.white.withValues(alpha: 0.5),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              );
            },
          ),

          const SizedBox(height: 14),
          Text(
            'Starting your journey…',
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withValues(alpha: 0.75),
              fontWeight: FontWeight.w500,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'v1.0.0',
            style: TextStyle(
              fontSize: 10,
              color: Colors.white.withValues(alpha: 0.45),
              fontWeight: FontWeight.w500,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════
// SUPPORTING CLASSES
// ═════════════════════════════════════════════════════════════════════

class _Feature {
  final IconData icon;
  final String label;
  const _Feature(this.icon, this.label);
}

class _Particle {
  final double x;        // 0..1 horizontal position
  final double startY;   // 0..1 starting vertical
  final double size;
  final double speed;
  final double opacity;
  final double drift;    // small horizontal drift

  _Particle({
    required this.x,
    required this.startY,
    required this.size,
    required this.speed,
    required this.opacity,
    required this.drift,
  });
}

// Painter for falling fuel-drop particles
class _ParticlePainter extends CustomPainter {
  final List<_Particle> particles;
  final double progress;

  _ParticlePainter({required this.particles, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      final paint = Paint()
        ..color = Colors.white.withValues(alpha: p.opacity)
        ..style = PaintingStyle.fill;

      final phase = (p.startY + progress * p.speed) % 1.2;
      final dy = phase * size.height;
      final dx = (p.x + math.sin(progress * 2 * math.pi + p.startY * 6) *
              p.drift) *
          size.width;

      // Draw a teardrop-ish circle (simple circle works well + glow)
      canvas.drawCircle(Offset(dx, dy), p.size, paint);
      // Soft halo
      final glowPaint = Paint()
        ..color = Colors.white.withValues(alpha: p.opacity * 0.4)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
      canvas.drawCircle(Offset(dx, dy), p.size * 1.6, glowPaint);
    }
  }

  @override
  bool shouldRepaint(_ParticlePainter old) =>
      old.progress != progress;
}

// Painter for the dashed rotating ring
class _DashedRingPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final int dashCount;
  final double gap; // 0..1 — fraction of dash that is gap

  _DashedRingPainter({
    required this.color,
    required this.strokeWidth,
    required this.dashCount,
    required this.gap,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final radius = size.width / 2;
    final center = Offset(radius, radius);
    final segment = (2 * math.pi) / dashCount;
    final dashLen = segment * (1 - gap);

    for (int i = 0; i < dashCount; i++) {
      final start = i * segment;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius - strokeWidth),
        start,
        dashLen,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_DashedRingPainter old) =>
      old.color != color ||
      old.strokeWidth != strokeWidth ||
      old.dashCount != dashCount ||
      old.gap != gap;
}

// Painter for the gauge arc (sweeps from -135° based on progress)
class _GaugeArcPainter extends CustomPainter {
  final double progress;
  final Color color;

  _GaugeArcPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final radius = size.width / 2;
    final center = Offset(radius, radius);
    final rect = Rect.fromCircle(center: center, radius: radius - 4);

    // Background track
    final trackPaint = Paint()
      ..color = color.withValues(alpha: 0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      rect,
      math.pi * 0.75,
      math.pi * 1.5,
      false,
      trackPaint,
    );

    // Active sweep
    final sweepPaint = Paint()
      ..shader = SweepGradient(
        startAngle: math.pi * 0.75,
        endAngle: math.pi * 0.75 + math.pi * 1.5,
        colors: [
          color.withValues(alpha: 0.4),
          color,
          color.withValues(alpha: 0.9),
        ],
      ).createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      rect,
      math.pi * 0.75,
      math.pi * 1.5 * progress,
      false,
      sweepPaint,
    );

    // Needle dot at the end of the sweep
    if (progress > 0.02) {
      final angle = math.pi * 0.75 + math.pi * 1.5 * progress;
      final dotX = center.dx + math.cos(angle) * (radius - 4);
      final dotY = center.dy + math.sin(angle) * (radius - 4);
      final dotPaint = Paint()..color = Colors.white;
      canvas.drawCircle(Offset(dotX, dotY), 5, dotPaint);
      final glowPaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.6)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
      canvas.drawCircle(Offset(dotX, dotY), 9, glowPaint);
    }
  }

  @override
  bool shouldRepaint(_GaugeArcPainter old) =>
      old.progress != progress || old.color != color;
}

// Clipper that reveals content from bottom to top based on progress 0..1
class _BottomUpClipper extends CustomClipper<Rect> {
  final double progress;
  _BottomUpClipper(this.progress);

  @override
  Rect getClip(Size size) {
    final h = size.height * progress;
    return Rect.fromLTWH(0, size.height - h, size.width, h);
  }

  @override
  bool shouldReclip(_BottomUpClipper old) => old.progress != progress;
}

// Painter for the animated road dashes at the bottom
class _RoadPainter extends CustomPainter {
  final double progress;

  _RoadPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    const dashWidth = 28.0;
    const dashHeight = 4.0;
    const gap = 18.0;
    final totalSegment = dashWidth + gap;
    final offset = -progress * totalSegment;
    final centerY = size.height / 2;

    double x = offset;
    while (x < size.width) {
      // Compute fade from horizontal center for cinematic feel
      final centerDist = ((x + dashWidth / 2) - size.width / 2).abs() /
          (size.width / 2);
      final alpha = (1 - centerDist * 0.7).clamp(0.2, 1.0);
      final dashPaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.55 * alpha);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, centerY - dashHeight / 2, dashWidth, dashHeight),
          const Radius.circular(2),
        ),
        dashPaint,
      );
      x += totalSegment;
    }
  }

  @override
  bool shouldRepaint(_RoadPainter old) => old.progress != progress;
}
