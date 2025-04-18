import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'camera_screen.dart';
import 'home_screen.dart';

class BlindPage extends StatefulWidget {
  const BlindPage({super.key});

  @override
  State<BlindPage> createState() => _BlindPageState();
}

class _BlindPageState extends State<BlindPage> {
  final FlutterTts flutterTts = FlutterTts();
  DateTime? _lastTapTime;

  @override
  void initState() {
    super.initState();
    speakInstructions();
  }

  Future<void> speakInstructions() async {
    await flutterTts.setLanguage("en-US");
    await flutterTts.setSpeechRate(0.5);
    await flutterTts.speak(
      "Tap 1 time to scan product barcode, and tap 2 times to search product through voice.",
    );
  }

  void handleTap() {
    final now = DateTime.now();
    if (_lastTapTime != null &&
        now.difference(_lastTapTime!) < const Duration(milliseconds: 500)) {
      _lastTapTime = null;
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => HomeScreen()),
      );
    } else {
      _lastTapTime = now;
      Future.delayed(const Duration(milliseconds: 600), () {
        if (_lastTapTime != null && DateTime.now().difference(_lastTapTime!) >= const Duration(milliseconds: 500)) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ScanPage()),
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: handleTap,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Text(
            'Blind Mode Activated',
            style: TextStyle(color: Colors.white, fontSize: 24),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
