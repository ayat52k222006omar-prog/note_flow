import 'dart:math';
import 'package:flutter/material.dart';
import '../core/app_theme.dart';

class CelebrationController {
  void Function()? _trigger;

  void _attach(void Function() trigger) {
    _trigger = trigger;
  }

  void _detach() {
    _trigger = null;
  }

  void celebrate() {
    _trigger?.call();
  }
}

class CelebrationOverlay extends StatefulWidget {
  final CelebrationController controller;
  final Widget child;

  const CelebrationOverlay({
    super.key,
    required this.controller,
    required this.child,
  });

  @override
  State<CelebrationOverlay> createState() => _CelebrationOverlayState();
}

class _CelebrationOverlayState extends State<CelebrationOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  final Random _random = Random();
  List<_ConfettiPiece> _pieces = [];
  bool _isAnimating = false;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1450),
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed && mounted) {
          setState(() => _isAnimating = false);
        }
      });

    widget.controller._attach(_startConfetti);
  }

  void _startConfetti() {
    final colors = [
      AppColors.primaryDark,
      AppColors.slateBlue,
      AppColors.warmSand,
      AppColors.softLavender,
      const Color(0xFF3E9C82), // أخضر نعناعي مريح
      const Color(0xFFE08E55), // برتقالي كهرماني هادئ
      const Color(0xFF5B9BD5), // أزرق سماوي لطيف
    ];

    _pieces = List.generate(52, (index) {
      final isLeftBurst = index % 2 == 0;
      return _ConfettiPiece(
        originX: isLeftBurst
            ? 0.15 + _random.nextDouble() * 0.35
            : 0.50 + _random.nextDouble() * 0.35,
        originY: 0.28 + _random.nextDouble() * 0.14,
        velocityX: (_random.nextDouble() - 0.5) * 260,
        velocityY: -180 - _random.nextDouble() * 190,
        gravity: 540 + _random.nextDouble() * 220,
        swayAmplitude: 10 + _random.nextDouble() * 18,
        swayFrequency: 4 + _random.nextDouble() * 6,
        size: 7 + _random.nextDouble() * 7,
        spinX: (_random.nextDouble() - 0.5) * 12,
        spinY: (_random.nextDouble() - 0.5) * 12,
        spinZ: (_random.nextDouble() - 0.5) * 12,
        color: colors[index % colors.length],
        shape: _ConfettiShape.values[index % _ConfettiShape.values.length],
      );
    });

    setState(() => _isAnimating = true);
    _animController.forward(from: 0);
  }

  @override
  void dispose() {
    widget.controller._detach();
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (_isAnimating)
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedBuilder(
                animation: _animController,
                builder: (context, _) {
                  return CustomPaint(
                    painter: _ConfettiDemoPainter(
                      t: _animController.value,
                      durationSec: _animController.duration!.inMilliseconds / 1000.0,
                      pieces: _pieces,
                    ),
                  );
                },
              ),
            ),
          ),
      ],
    );
  }
}

enum _ConfettiShape { rect, circle, diamond }

class _ConfettiPiece {
  final double originX;
  final double originY;
  final double velocityX;
  final double velocityY;
  final double gravity;
  final double swayAmplitude;
  final double swayFrequency;
  final double size;
  final double spinX;
  final double spinY;
  final double spinZ;
  final Color color;
  final _ConfettiShape shape;

  _ConfettiPiece({
    required this.originX,
    required this.originY,
    required this.velocityX,
    required this.velocityY,
    required this.gravity,
    required this.swayAmplitude,
    required this.swayFrequency,
    required this.size,
    required this.spinX,
    required this.spinY,
    required this.spinZ,
    required this.color,
    required this.shape,
  });
}

class _ConfettiDemoPainter extends CustomPainter {
  final double t;
  final double durationSec;
  final List<_ConfettiPiece> pieces;

  _ConfettiDemoPainter({
    required this.t,
    required this.durationSec,
    required this.pieces,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final elapsed = t * durationSec;
    final fadeOut = t < 0.72 ? 1.0 : ((1.0 - t) / 0.28).clamp(0.0, 1.0);

    for (final p in pieces) {
      final startPxX = p.originX * size.width;
      final startPxY = p.originY * size.height;

      // حركة قذف للأعلى ثم سقوط بتأثير الجاذبية مع تماوج أفقي
      final sway = sin(elapsed * p.swayFrequency) * p.swayAmplitude * t;
      final x = startPxX + p.velocityX * elapsed + sway;
      final y = startPxY + p.velocityY * elapsed + 0.5 * p.gravity * elapsed * elapsed;

      final paint = Paint()
        ..color = p.color.withOpacity(fadeOut)
        ..style = PaintingStyle.fill;

      // محاكاة دوران ثلاثي الأبعاد للورقة
      final flipScaleY = cos(elapsed * p.spinX).abs().clamp(0.25, 1.0);
      final flipScaleX = cos(elapsed * p.spinY).abs().clamp(0.35, 1.0);

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(elapsed * p.spinZ);
      canvas.scale(flipScaleX, flipScaleY);

      switch (p.shape) {
        case _ConfettiShape.rect:
          final rect = Rect.fromCenter(
            center: Offset.zero,
            width: p.size * 1.35,
            height: p.size * 0.65,
          );
          canvas.drawRRect(
            RRect.fromRectAndRadius(rect, const Radius.circular(2)),
            paint,
          );
          break;
        case _ConfettiShape.circle:
          canvas.drawCircle(Offset.zero, p.size * 0.48, paint);
          break;
        case _ConfettiShape.diamond:
          final path = Path()
            ..moveTo(0, -p.size * 0.65)
            ..lineTo(p.size * 0.5, 0)
            ..lineTo(0, p.size * 0.65)
            ..lineTo(-p.size * 0.5, 0)
            ..close();
          canvas.drawPath(path, paint);
          break;
      }

      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiDemoPainter oldDelegate) {
    return oldDelegate.t != t || oldDelegate.pieces != pieces;
  }
}