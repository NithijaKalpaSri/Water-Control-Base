import 'dart:ui';
import 'dart:math';
import 'package:flutter/material.dart';

class GlassBox extends StatelessWidget {
  final Widget child;
  final double borderRadius;

  const GlassBox({required this.child, this.borderRadius = 24, super.key});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.12),
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(color: Colors.white24),
          ),
          child: child,
        ),
      ),
    );
  }
}

class WaterWavePainter extends CustomPainter {
  final double animationValue;
  final Color color;

  WaterWavePainter({required this.animationValue, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final path = Path();
    final waveHeight = size.height * 0.08;
    final midHeight = size.height * 0.5;

    path.moveTo(0, size.height);
    for (double x = 0; x <= size.width; x += 1) {
      final sineValue = sin(
        (x / size.width * 2 * pi) + animationValue * 2 * pi,
      );
      final y = midHeight + sineValue * waveHeight;
      path.lineTo(x, y);
    }
    path.lineTo(size.width, size.height);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant WaterWavePainter oldDelegate) {
    return oldDelegate.animationValue != animationValue ||
        oldDelegate.color != color;
  }
}
