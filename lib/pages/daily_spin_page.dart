import 'dart:math';
import 'package:flutter/material.dart';
import '../game/daily_spin_repo.dart';

class DailySpinPage extends StatefulWidget {
  const DailySpinPage({super.key});

  @override
  State<DailySpinPage> createState() => _DailySpinPageState();
}

class _DailySpinPageState extends State<DailySpinPage> with SingleTickerProviderStateMixin {
  final repo = DailySpinRepo();

  late final AnimationController _ctrl;
  late Animation<double> _anim;

  bool _spinning = false;
  bool _canSpin = true;

  final List<_Prize> prizes = const [
    _Prize('😶 Boş', 0),
    _Prize('🪙 +2', 2),
    _Prize('🪙 +3', 3),
    _Prize('🪙 +5', 5),
    _Prize('🪙 +7', 7),
    _Prize('🪙 +10', 10),
    _Prize('🪙 +15', 15),
    _Prize('🪙 +20', 20),
  ];

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 2800));
    _anim = Tween<double>(begin: 0, end: 0).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    _load();
  }

  Future<void> _load() async {
    _canSpin = await repo.canSpin();
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _spin() async {
    if (_spinning || !_canSpin) return;
    setState(() => _spinning = true);

    final rnd = Random();
    final targetIndex = rnd.nextInt(prizes.length);

    final slice = (2 * pi) / prizes.length;
    final fullTurns = 5 + rnd.nextInt(4);
    final targetAngle = (fullTurns * 2 * pi) + (targetIndex * slice) + (slice / 2);

    _anim = Tween<double>(begin: 0, end: targetAngle).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic),
    );

    _ctrl.reset();
    await _ctrl.forward();


    // kayıt + coin ekle
    final applied = await repo.spin();

    _canSpin = false;

    if (!mounted) return;
    setState(() => _spinning = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Kazandın: 🪙 +$applied')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF1F5),
      appBar: AppBar(
        title: const Text('Günlük Çark'),
        centerTitle: true,
        backgroundColor: const Color(0xFFFFE4EC),
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Icon(Icons.arrow_drop_down, size: 44),
            const SizedBox(height: 8),
            Expanded(
              child: Center(
                child: AnimatedBuilder(
                  animation: _ctrl,
                  builder: (_, __) => Transform.rotate(
                    angle: _anim.value,
                    child: CustomPaint(
                      size: const Size(280, 280),
                      painter: _WheelPainter(prizes),
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: (_canSpin && !_spinning) ? _spin : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFD6E5),
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: Text(_canSpin ? (_spinning ? 'Dönüyor...' : 'ÇEVİR') : 'Bugün hakkın bitti'),
              ),
            ),
            const SizedBox(height: 10),
            const Text('Günde 1 kez çevirebilirsin.', style: TextStyle(color: Colors.black54)),
          ],
        ),
      ),
    );
  }
}

class _Prize {
  final String label;
  final int coins;
  const _Prize(this.label, this.coins);
}

class _WheelPainter extends CustomPainter {
  final List<_Prize> prizes;
  _WheelPainter(this.prizes);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2;

    final paint = Paint()..style = PaintingStyle.fill;
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = Colors.black12;

    final slice = (2 * pi) / prizes.length;

    for (int i = 0; i < prizes.length; i++) {
      paint.color = i.isEven ? const Color(0xFFFFD6E5) : const Color(0xFFFFFAFB);
      final start = -pi / 2 + (i * slice);

      canvas.drawArc(Rect.fromCircle(center: center, radius: radius), start, slice, true, paint);
      canvas.drawArc(Rect.fromCircle(center: center, radius: radius), start, slice, true, stroke);

      final tp = TextPainter(
        text: TextSpan(
          text: prizes[i].label,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.black),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      final angle = start + slice / 2;
      final pos = Offset(center.dx + cos(angle) * radius * 0.6, center.dy + sin(angle) * radius * 0.6);

      canvas.save();
      canvas.translate(pos.dx, pos.dy);
      canvas.rotate(angle + pi / 2);
      canvas.translate(-tp.width / 2, -tp.height / 2);
      tp.paint(canvas, Offset.zero);
      canvas.restore();
    }

    canvas.drawCircle(center, 18, Paint()..color = Colors.white);
    canvas.drawCircle(center, 18, stroke);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}