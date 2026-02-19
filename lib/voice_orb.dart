import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:livekit_client/livekit_client.dart';

class VoiceOrb extends StatefulWidget {
  final bool isListening;
  final AudioTrack? audioTrack;
  final AudioTrack? localTrack;

  const VoiceOrb({
    super.key, 
    required this.isListening, 
    this.audioTrack,
    this.localTrack,
  });

  @override
  State<VoiceOrb> createState() => _VoiceOrbState();
}

class _VoiceOrbState extends State<VoiceOrb> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  double _currentVolume = 0.0;
  AudioVisualizer? _remoteVisualizer;
  AudioVisualizer? _localVisualizer;

  @override
  void initState() {
    super.initState();
    print("[DEBUG] VoiceOrb Init - Visualizer Version 2.0"); 
    _controller = AnimationController(
      vsync: this, 
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    
    _setupListeners();
  }

  @override
  void didUpdateWidget(covariant VoiceOrb oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.audioTrack != widget.audioTrack || oldWidget.localTrack != widget.localTrack) {
      _setupListeners();
    }
  }

  void _setupListeners() {
    _remoteVisualizer?.dispose();
    _localVisualizer?.dispose();
    _remoteVisualizer = null;
    _localVisualizer = null;

    void onVolumeEvent(AudioVisualizerEvent event) {
      final bands = event.event as List<double>;
      if (bands.isNotEmpty) {
        double sum = 0;
        for (var band in bands) {
          sum += band;
        }
        
        if (mounted) {
          setState(() {
            final avg = sum / bands.length;
            // print("Avg Volume: $avg"); // Commented out to reduce noise, enable if needed
            // Smooth transition
            _currentVolume += (avg - _currentVolume) * 0.2;
          });
        }
      }
    }

    if (widget.audioTrack != null) {
      print("[DEBUG] Setting up remote visualizer");
      _remoteVisualizer = createVisualizer(widget.audioTrack!, options: const AudioVisualizerOptions(barCount: 7));
      _remoteVisualizer!.events.on<AudioVisualizerEvent>(onVolumeEvent);
      _remoteVisualizer!.start();
    }
    
    if (widget.localTrack != null) {
      print("[DEBUG] Setting up local visualizer");
      _localVisualizer = createVisualizer(widget.localTrack!, options: const AudioVisualizerOptions(barCount: 7));
      _localVisualizer!.events.on<AudioVisualizerEvent>(onVolumeEvent);
      _localVisualizer!.start();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _localVisualizer?.dispose();
    _remoteVisualizer?.dispose();
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
            volume: _currentVolume * 3.0, // Amplify for visual effect
          ),
          child: Container(
            width: 300,
            height: 300,
          ),
        );
      },
    );
  }
}

class OrbPainter extends CustomPainter {
  final double animationValue;
  final bool isListening;
  final double volume;

  OrbPainter({
    required this.animationValue, 
    required this.isListening,
    required this.volume,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2;

    // Breathing effect base
    double breathe = math.sin(animationValue * 2 * math.pi) * 0.05 + 1.0;
    
    // React to volume
    if (isListening || volume > 0.05) {
       // Add volume reaction to breathe
       breathe += volume * 0.5; 
       breathe = breathe.clamp(0.8, 1.4);
    }
    
    // Active state faster pulse
    if (isListening && volume < 0.01) {
       breathe = math.sin(animationValue * 4 * math.pi) * 0.08 + 1.1; 
    }

    // Glowing core
    final paint = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.white.withOpacity(0.9),
          const Color(0xFF6366F1).withOpacity(0.7), // Indigo
          const Color(0xFF8B5CF6).withOpacity(0.3), // Violet
          Colors.transparent,
        ],
        stops: const [0.0, 0.4, 0.7, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius * breathe));

    canvas.drawCircle(center, radius * breathe, paint);
    
    // Outer Rings (Echo)
    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..color = Colors.white.withOpacity(0.2);
      
    // Draw expanding rings based on volume history or animation
    double ringSize = radius * (breathe + 0.2);
    canvas.drawCircle(center, ringSize, ringPaint);
    
    canvas.drawCircle(center, radius * (breathe * 0.8), 
       Paint()..style = PaintingStyle.stroke ..strokeWidth=1 ..color=Colors.white.withOpacity(0.1));
  }

  @override
  bool shouldRepaint(covariant OrbPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue ||
        oldDelegate.isListening != isListening ||
        oldDelegate.volume != volume;
  }
}
