import 'package:flutter/material.dart';
import 'dart:math' as math;

class VoiceOrb extends StatefulWidget {
  final bool isListening;

  const VoiceOrb({super.key, required this.isListening});

  @override
  State<VoiceOrb> createState() => _VoiceOrbState();
}

class _VoiceOrbState extends State<VoiceOrb> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this, duration: const Duration(seconds: 6))
      ..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          painter: OrbPainter(
            animationValue: _controller.value,
            isListening: widget.isListening,
          ),
          child: Container(
            width: 350,
            height: 350,
          ),
        );
      },
    );
  }
}

class OrbPainter extends CustomPainter {
  final double animationValue;
  final bool isListening;

  OrbPainter({required this.animationValue, required this.isListening});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2;

    // 1. Outer Glow (Soft Violet)
    final outerGlowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFF8B5CF6).withOpacity(0.2), // Violet
          const Color(0xFF3B82F6).withOpacity(0.0), // Blue transparent
        ],
        stops: const [0.5, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius * 1.2));
      
    canvas.drawCircle(center, radius * 1.2, outerGlowPaint);

    // 2. Main Native Orb (Deep Blue/Cyber Cyan)
    final paint = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.white.withOpacity(0.9),
          const Color(0xFF6366F1).withOpacity(0.6), // Indigo
          const Color(0xFF0F172A).withOpacity(0.0), // Dark Slate
        ],
        stops: const [0.1, 0.5, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius));

    // Breathing math
    double breathe = math.sin(animationValue * 2 * math.pi) * 0.05 + 1.0;
    
    // Turbulent ripples when listening
    double ripple = 0;
    if (isListening) {
       breathe = math.sin(animationValue * 5 * math.pi) * 0.08 + 1.1; 
       ripple = math.cos(animationValue * 10 * math.pi) * 5;
    }

    canvas.drawCircle(center, (radius * breathe) + ripple, paint);
    
    // 3. Inner Core Ring (Sharp White)
    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..color = Colors.white.withOpacity(0.15)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
      
     canvas.drawCircle(center, radius * breathe * 0.6, ringPaint);
     
    // 4. Orbiting Particles (Simple)
    final particlePaint = Paint()..color = Colors.white.withOpacity(0.4);
    double particleAngle = animationValue * 2 * math.pi;
    double particleX = center.dx + math.cos(particleAngle) * (radius * 0.8);
    double particleY = center.dy + math.sin(particleAngle) * (radius * 0.8);
    canvas.drawCircle(Offset(particleX, particleY), 3, particlePaint);
  }

  @override
  bool shouldRepaint(covariant OrbPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue ||
        oldDelegate.isListening != isListening;
  }
}
