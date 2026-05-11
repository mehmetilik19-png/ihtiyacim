import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

class SplashPage extends StatefulWidget {
  final Widget nextPage;

  const SplashPage({
    super.key,
    required this.nextPage,
  });

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  bool showText = false;
  bool showCard = false;
  bool finish = false;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 5200),
    )..repeat();

    _start();
  }

  Future<void> _start() async {
    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;
    setState(() => showText = true);

    await Future.delayed(const Duration(milliseconds: 850));
    if (!mounted) return;
    setState(() => showCard = true);

    await Future.delayed(const Duration(milliseconds: 3900));
    if (!mounted) return;
    setState(() => finish = true);

    await Future.delayed(const Duration(milliseconds: 650));
    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => widget.nextPage),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  double _scale(double start, double end) {
    final v = (_controller.value - start) / (end - start);
    return v.clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedOpacity(
        opacity: finish ? 0 : 1,
        duration: const Duration(milliseconds: 650),
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            return Stack(
              children: [
                Positioned.fill(
                  child: CustomPaint(
                    painter: _AuroraPainter(_controller.value),
                  ),
                ),

                Positioned(
                  top: -80,
                  right: -90,
                  child: _GlowCircle(
                    size: 230,
                    color: const Color(0xFF7C4DFF).withOpacity(0.28),
                  ),
                ),

                Positioned(
                  bottom: -110,
                  left: -80,
                  child: _GlowCircle(
                    size: 260,
                    color: const Color(0xFF00D4FF).withOpacity(0.22),
                  ),
                ),

                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 28),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AnimatedScale(
                          scale: showText ? 1 : 0.82,
                          duration: const Duration(milliseconds: 800),
                          curve: Curves.easeOutBack,
                          child: AnimatedOpacity(
                            opacity: showText ? 1 : 0,
                            duration: const Duration(milliseconds: 650),
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                Container(
                                  width: 122,
                                  height: 122,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: RadialGradient(
                                      colors: [
                                        Colors.white.withOpacity(0.85),
                                        Colors.white.withOpacity(0.25),
                                        Colors.white.withOpacity(0.05),
                                      ],
                                    ),
                                  ),
                                ),
                                Container(
                                  width: 96,
                                  height: 96,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(30),
                                    gradient: const LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        Color(0xFF00C6FF),
                                        Color(0xFF246BFF),
                                        Color(0xFF7C4DFF),
                                      ],
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFF246BFF)
                                            .withOpacity(0.35),
                                        blurRadius: 38,
                                        offset: const Offset(0, 18),
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.handshake_rounded,
                                    color: Colors.white,
                                    size: 50,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 26),

                        AnimatedOpacity(
                          opacity: showText ? 1 : 0,
                          duration: const Duration(milliseconds: 800),
                          child: AnimatedSlide(
                            duration: const Duration(milliseconds: 800),
                            curve: Curves.easeOutCubic,
                            offset:
                            showText ? Offset.zero : const Offset(0, 0.18),
                            child: Column(
                              children: [
                                const Text(
                                  'İHTİYACIM',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Color(0xFF071533),
                                    fontSize: 43,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 2.0,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  width: 132,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(999),
                                    gradient: const LinearGradient(
                                      colors: [
                                        Color(0xFF00C6FF),
                                        Color(0xFF246BFF),
                                        Color(0xFF9B5CFF),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 14),
                                const Text(
                                  'Paylaşmanın en kolay hali',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Color(0xFF41506F),
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 34),

                        AnimatedOpacity(
                          opacity: showCard ? 1 : 0,
                          duration: const Duration(milliseconds: 900),
                          child: AnimatedSlide(
                            duration: const Duration(milliseconds: 900),
                            curve: Curves.easeOutCubic,
                            offset:
                            showCard ? Offset.zero : const Offset(0, 0.22),
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.fromLTRB(22, 22, 22, 22),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.78),
                                borderRadius: BorderRadius.circular(30),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.95),
                                  width: 1.2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF3A5DAE)
                                        .withOpacity(0.14),
                                    blurRadius: 36,
                                    offset: const Offset(0, 18),
                                  ),
                                ],
                              ),
                              child: Column(
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: const [
                                      _MiniIcon(
                                        icon: Icons.inventory_2_outlined,
                                        color1: Color(0xFFFF7A1A),
                                        color2: Color(0xFFFF3D00),
                                      ),
                                      SizedBox(width: 10),
                                      _MiniIcon(
                                        icon: Icons.favorite_rounded,
                                        color1: Color(0xFFFF4FA3),
                                        color2: Color(0xFFFF1F5B),
                                      ),
                                      SizedBox(width: 10),
                                      _MiniIcon(
                                        icon: Icons.storefront_outlined,
                                        color1: Color(0xFF28DB8F),
                                        color2: Color(0xFF00A85A),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 18),
                                  const Text(
                                    'Birinin fazlası,\nbaşkasının ihtiyacı olabilir.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: Color(0xFF10132E),
                                      fontSize: 21,
                                      height: 1.22,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                  const SizedBox(height: 14),
                                  const Text(
                                    'İhtiyacın olanı bul, elindekini paylaş,\n'
                                        'yakınındaki insanlara destek ol.\n'
                                        'Küçük bir paylaşım, büyük bir iyiliğe dönüşebilir.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: Color(0xFF5B6380),
                                      fontSize: 14.5,
                                      height: 1.45,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 28),

                        AnimatedOpacity(
                          opacity: showCard ? 1 : 0,
                          duration: const Duration(milliseconds: 900),
                          child: SizedBox(
                            width: 150,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(999),
                              child: LinearProgressIndicator(
                                minHeight: 6,
                                value: 0.25 + (_scale(0.0, 1.0) * 0.75),
                                backgroundColor: Colors.white.withOpacity(0.55),
                                valueColor: const AlwaysStoppedAnimation<Color>(
                                  Color(0xFF246BFF),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _MiniIcon extends StatelessWidget {
  final IconData icon;
  final Color color1;
  final Color color2;

  const _MiniIcon({
    required this.icon,
    required this.color1,
    required this.color2,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color1, color2],
        ),
        boxShadow: [
          BoxShadow(
            color: color2.withOpacity(0.28),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Icon(
        icon,
        color: Colors.white,
        size: 25,
      ),
    );
  }
}

class _GlowCircle extends StatelessWidget {
  final double size;
  final Color color;

  const _GlowCircle({
    required this.size,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
      ),
    );
  }
}

class _AuroraPainter extends CustomPainter {
  final double t;

  _AuroraPainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    final bg = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFFEAF6FF),
          Color(0xFFDCEBFF),
          Color(0xFFF7F4FF),
        ],
      ).createShader(rect);

    canvas.drawRect(rect, bg);

    final p1 = Paint()
      ..color = const Color(0xFF246BFF).withOpacity(0.22)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 70);

    final p2 = Paint()
      ..color = const Color(0xFF9B5CFF).withOpacity(0.20)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 75);

    final p3 = Paint()
      ..color = const Color(0xFF00C6FF).withOpacity(0.18)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 65);

    canvas.drawCircle(
      Offset(
        size.width * (0.22 + sin(t * pi * 2) * 0.04),
        size.height * 0.20,
      ),
      150,
      p1,
    );

    canvas.drawCircle(
      Offset(
        size.width * (0.82 + cos(t * pi * 2) * 0.04),
        size.height * 0.42,
      ),
      180,
      p2,
    );

    canvas.drawCircle(
      Offset(
        size.width * 0.48,
        size.height * (0.82 + sin(t * pi * 2) * 0.03),
      ),
      190,
      p3,
    );

    final dotPaint = Paint()
      ..color = Colors.white.withOpacity(0.50);

    for (int i = 0; i < 36; i++) {
      final x = (i * 83.0 + sin(t * pi * 2 + i) * 14) % size.width;
      final y = (i * 61.0 + cos(t * pi * 2 + i) * 18) % size.height;
      final r = 1.4 + (i % 3) * 0.8;
      canvas.drawCircle(Offset(x, y), r, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _AuroraPainter oldDelegate) {
    return oldDelegate.t != t;
  }
}