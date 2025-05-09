import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:audioplayers/audioplayers.dart';
import 'blind_result.dart';

class BlindScanPage extends StatefulWidget {
  const BlindScanPage({super.key});

  @override
  _BlindScanPageState createState() => _BlindScanPageState();
}

class _BlindScanPageState extends State<BlindScanPage> with SingleTickerProviderStateMixin {
  final AudioPlayer _audioPlayer = AudioPlayer();
  final MobileScannerController _controller = MobileScannerController();
  bool isScanning = true;
  bool isTorchOn = false;

  late AnimationController _animationController;
  late Animation<double> _animation;

  void _playBeep() async {
    await _audioPlayer.play(AssetSource('sounds/beep.mp3'));
  }

  void _onBarcodeScanned(String barcode) async {
    if (!isScanning) return;
    setState(() => isScanning = false);
    _playBeep();

    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => BlindResultsPage(barcode: barcode)),
    ).then((_) => setState(() => isScanning = true));
  }

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _animation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scanBoxHeight = 300.0;
    final scanBoxWidth = 280.0;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: const Color(0xFF4A4EDA),
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "Scan Product",
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: Icon(
              isTorchOn ? Icons.flash_on : Icons.flash_off,
              color: Colors.white,
            ),
            onPressed: () {
              setState(() => isTorchOn = !isTorchOn);
              _controller.toggleTorch();
            },
          ),
          IconButton(
            icon: const Icon(Icons.cameraswitch, color: Colors.white),
            onPressed: () => _controller.switchCamera(),
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: (capture) {
              final barcode = capture.barcodes.first.rawValue;
              if (barcode != null) {
                _onBarcodeScanned(barcode);
              }
            },
          ),
          Center(
            child: Stack(
              children: [
                Container(
                  width: scanBoxWidth,
                  height: scanBoxHeight,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.redAccent, width: 2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                AnimatedBuilder(
                  animation: _animationController,
                  builder: (context, child) {
                    return Positioned(
                      top: _animation.value * scanBoxHeight,
                      left: 0,
                      right: 0,
                      child: Container(
                        height: 2,
                        width: scanBoxWidth,
                        color: Colors.red,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          Positioned(
            bottom: 40,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.black87.withOpacity(0.6),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                "Align the barcode inside the box to scan automatically.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70, fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
