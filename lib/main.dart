import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:livekit_client/livekit_client.dart';
import 'package:permission_handler/permission_handler.dart';
import 'voice_orb.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const LiveChattyApp());
}

class LiveChattyApp extends StatelessWidget {
  const LiveChattyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Live Chatty',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF020617), // Slate 950
        useMaterial3: true,
        fontFamily: 'Roboto', 
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
  bool isConnected = false;
  bool isMuted = false;
  Room? _room;
  EventsListener<RoomEvent>? _listener;
  AudioTrack? _remoteAudioTrack;
  AudioTrack? _localAudioTrack;

  // TODO: In a real app, fetch this token from your backend!
  // For dev/testing, we paste a temporary token here.
  final String _liveKitUrl = 'wss://voice2text-7hticrc9.livekit.cloud';
  final String _token = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJuYW1lIjoiRmx1dHRlciBVc2VyIiwidmlkZW8iOnsicm9vbUpvaW4iOnRydWUsInJvb20iOiJvcGVuY2xhdy1yb29tLTEiLCJjYW5QdWJsaXNoIjp0cnVlLCJjYW5TdWJzY3JpYmUiOnRydWUsImNhblB1Ymxpc2hEYXRhIjp0cnVlfSwic3ViIjoiZmx1dHRlcl91c2VyIiwiaXNzIjoiQVBJTXRUelRTYzVpWld5IiwibmJmIjoxNzcxNTIzNDYxLCJleHAiOjE4MDMwNTk0NjF9.PGVBqsBUG-eYmlG8syJo07rv4eXFU4IoFqXqdLEhfkg';  

  @override
  void initState() {
    super.initState();
    _connectToRoom();
  }

  Future<void> _connectToRoom() async {
    // 1. Request Permissions
    await Permission.microphone.request();

    // 2. Configure Options
    final roomOptions = RoomOptions(
      adaptiveStream: true,
      dynacast: true,
      defaultAudioPublishOptions: const AudioPublishOptions(
        name: 'user_mic',
        encoding: AudioEncoding(
          maxBitrate: 32000, 
        ),
        dtx: true, // Discontinuous transmission
      ),
    );

    // 3. Connect
    final room = Room();
    try {
      print("[DEBUG] Connecting to room...");
      await room.connect(_liveKitUrl, _token, roomOptions: roomOptions);
      print("[DEBUG] Connected to room: ${room.name}");
      
      print("[DEBUG] Enabling microphone...");
      await room.localParticipant?.setMicrophoneEnabled(true);
      print("[DEBUG] Microphone enabled request sent.");
      
      // Get local track (a bit of a hack to find the first audio track)
      AudioTrack? localTrack;
      final publications = room.localParticipant?.trackPublications.values ?? [];
      for (var pub in publications) {
        if (pub.kind == TrackType.AUDIO && pub.track != null) {
          localTrack = pub.track as AudioTrack;
          print("[DEBUG] Found existing local audio track: ${localTrack.sid}");
          break;
        }
      }

      if (mounted) {
        setState(() {
          _room = room;
          _localAudioTrack = localTrack;
          _listener = room.createListener();
          isConnected = true;
        });
      }

      _setUpListeners();
      
    } catch (e) {
      print('[ERROR] Failed to connect: $e');
    }
  }

  void _setUpListeners() {
    _listener?.on<TrackSubscribedEvent>((event) {
      print("[DEBUG] Request Subscribed: ${event.track.sid}");
      if (event.track is AudioTrack) {
        setState(() {
          _remoteAudioTrack = event.track as AudioTrack;
          _remoteAudioTrack?.start(); // Ensure audio plays
        });
      }
    });
    
    // Listen for local track publication if it happened async
    _listener?.on<LocalTrackPublishedEvent>((event) {
       print("[DEBUG] Local Track Published: ${event.publication.sid}");
       if (event.publication.track is AudioTrack) {
          print("[DEBUG] It is an audio track!");
          setState(() {
             _localAudioTrack = event.publication.track as AudioTrack;
          });
       }
    });

    _listener?.on<TrackUnsubscribedEvent>((event) {
      if (event.track == _remoteAudioTrack) {
        setState(() {
          _remoteAudioTrack = null;
        });
      }
    });
    
    _listener?.on<RoomDisconnectedEvent>((event) {
       print("[DEBUG] Room Disconnected");
       if (mounted) {
         setState(() => isConnected = false);
       }
    });
  }

  void _toggleMute() async {
    if (_room != null) {
      isMuted = !isMuted;
      await _room!.localParticipant?.setMicrophoneEnabled(!isMuted);
      setState(() {});
    }
  }
  
  void _disconnect() async {
    await _room?.disconnect();
    if (mounted) {
      setState(() => isConnected = false);
    }
  }

  @override
  void dispose() {
    _listener?.dispose();
    _room?.disconnect();
    super.dispose();
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
                       isConnected ? "Live Chatty Live" : "Ready",
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
                     child: VoiceOrb(
                       isListening: isConnected, 
                       audioTrack: _remoteAudioTrack,
                       localTrack: _localAudioTrack,
                     ),
                   ),
                   
                   // Interactive Text
                   Padding(
                     padding: const EdgeInsets.only(top: 60.0),
                     child: AnimatedOpacity(
                       duration: const Duration(milliseconds: 500),
                       opacity: isConnected ? 1.0 : 0.7,
                       child: Text(
                         isConnected ? "Listening..." : "Tap to Connect",
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
                                 icon: isConnected ? Icons.call_end : Icons.call,
                                 color: isConnected ? const Color(0xFFEF4444) : const Color(0xFF14B8A6), // Red vs Teal
                                 isFilled: true,
                                 size: 72,
                                 iconSize: 36,
                                 onTap: isConnected ? _disconnect : _connectToRoom,
                               ),
                               // Spacer to replace Camera Button for balance
                               const SizedBox(width: 50), 
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
