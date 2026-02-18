import 'package:flutter/material.dart';
import 'dart:ui';
import 'voice_orb.dart';

void main() {
  runApp(const OpenClawVoiceApp());
}

class OpenClawVoiceApp extends StatelessWidget {
  const OpenClawVoiceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'OpenClaw Voice',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF020617), // Slate 950
        useMaterial3: true,
        fontFamily: 'Roboto', // Default, but use Inter if available
        colorScheme: const ColorScheme.dark(
          primary: Colors.white,
          secondary: Color(0xFF6366F1), // Indigo
        ),
      ),
      home: const VoiceChatScreen(),
    );
  }
}

class VoiceChatScreen extends StatefulWidget {
  const VoiceChatScreen({super.key});

  @override
  State<VoiceChatScreen> createState() => _VoiceChatScreenState();
}

class _VoiceChatScreenState extends State<VoiceChatScreen> {
  bool isListening = false;
  bool isMuted = false;

  void _toggleListening() {
    setState(() {
      isListening = !isListening;
    });
  }

  void _toggleMute() {
    setState(() {
      isMuted = !isMuted;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0F172A), // Slate 900
              Color(0xFF1E1B4B), // Indigo 950
              Color(0xFF000000), // Black
            ],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              Column(
                children: [
                   // Top Status
                   Padding(
                     padding: const EdgeInsets.only(top: 20.0),
                     child: Text(
                       "OpenClaw Live",
                       style: TextStyle(
                         color: Colors.white.withOpacity(0.5),
                         fontSize: 14,
                         letterSpacing: 2.0,
                         fontWeight: FontWeight.w600,
                       ),
                     ),
                   ),
                   
                   const Spacer(flex: 3),
                   
                   // Orb
                   Center(
                     child: GestureDetector(
                       onTap: _toggleListening,
                       child: VoiceOrb(isListening: isListening),
                     ),
                   ),
                   
                   // Interactive Text
                   Padding(
                     padding: const EdgeInsets.only(top: 60.0),
                     child: AnimatedOpacity(
                       duration: const Duration(milliseconds: 500),
                       opacity: isListening ? 1.0 : 0.7,
                       child: Text(
                         isListening ? "Listening..." : "Tap orb to speak",
                         style: const TextStyle(
                           color: Colors.white,
                           fontSize: 24,
                           fontWeight: FontWeight.w300,
                           letterSpacing: 0.5,
                         ),
                       ),
                     ),
                   ),
      
                   const Spacer(flex: 4),
      
                   // Glassmorphism Control Bar
                   Padding(
                     padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
                     child: ClipRRect(
                       borderRadius: BorderRadius.circular(50),
                       child: BackdropFilter(
                         filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                         child: Container(
                           padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 30),
                           decoration: BoxDecoration(
                             color: Colors.white.withOpacity(0.1),
                             border: Border.all(color: Colors.white.withOpacity(0.1)),
                             borderRadius: BorderRadius.circular(50),
                           ),
                           child: Row(
                             mainAxisAlignment: MainAxisAlignment.spaceBetween,
                             children: [
                               _buildGlassButton(
                                 icon: isMuted ? Icons.mic_off : Icons.mic_none,
                                 isActive: isMuted,
                                 onTap: _toggleMute,
                               ),
                               _buildGlassButton(
                                 icon: Icons.close,
                                 color: const Color(0xFFEF4444), // Red 500
                                 isFilled: true,
                                 size: 64,
                                 iconSize: 32,
                                 onTap: () => setState(() => isListening = false),
                               ),
                               _buildGlassButton(
                                 icon: Icons.videocam_outlined,
                                 onTap: () {}, 
                               ),
                             ],
                           ),
                         ),
                       ),
                     ),
                   ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGlassButton({
    required IconData icon,
    VoidCallback? onTap,
    Color color = Colors.white,
    bool isActive = false,
    bool isFilled = false,
    double size = 50,
    double iconSize = 28,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: isFilled ? color : (isActive ? Colors.white.withOpacity(0.2) : Colors.transparent),
          shape: BoxShape.circle,
          border: isFilled ? null : Border.all(color: Colors.white.withOpacity(0.3), width: 1.5),
        ),
        child: Icon(
          icon, 
          color: isFilled ? Colors.white : (isActive ? Colors.white : Colors.white70), 
          size: iconSize
        ),
      ),
    );
  }
}
